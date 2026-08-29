local materials_bridge = {}

-- Material paint deliberately travels over transports already understood by an
-- unmodified EW peer. Every operation first seeds each touched 128x128 area through
-- EW's own aligned world-frame encoder. Every brush stamp then uses a short-lived
-- vanilla MagicConvertMaterialComponent entity, uploaded through EW's normal entity
-- sync. Seeding is required even for
-- solid paint: EW encodes solids as air, but the frame gives the proxy an authoritative
-- chunk to which the following relay can apply. Without that ordering, paint
-- in a previously unknown chunk is ignored by the proxy and is soon restored by its
-- current authority. The converter is still essential because EW's world decoder
-- deliberately preserves solid cells.
-- Nothing received by the other game points back into MCM's files.
local ok_ffi, ffi = pcall(require, "ffi")
local transport = dofile("mods/metamorph_creative_menu/files/integrations/ew/material_paint_sync.lua")

local OUTBOX_RESULT = "mcm_material_paint_outbox_result_v3"
local KEY_WORLD_FRAME = 0
local KEY_WORLD_END = 1
local CHUNK_SIZE = 128
local MAX_ENCODED_BYTES = 90000
local MAX_MATERIAL_ID = 32767 -- EW EncodedArea.PixelRun.material is signed int16.
local MAX_BATCHES_PER_UPDATE = 8
local MAX_CHUNKS_PER_UPDATE = 1
local CHUNK_SEND_INTERVAL = 1
local CHUNK_RESEND_COOLDOWN = 6
local CHUNK_QUEUE_CAPACITY = 64
local RELAY_QUEUE_CAPACITY = 16
local MAX_RELAY_POINTS = 24
-- One relay per frame keeps the current chunk authority painted before its next native
-- world snapshot can restore a newly drawn area. Queue bounds still cap burst cost.
local RELAY_SEND_INTERVAL = 1
local RELAY_LIFETIME = 8
local BRUSH_RADII = { [1] = 0, [2] = 1, [3] = 2, [4] = 4, [5] = 6 }

local last_sequence = transport.ack_sequence()
local rpc, common
local world = nil
local encoded_area = nil

local function new_queue(capacity)
    return { data = {}, head = 1, tail = 0, size = 0, capacity = capacity }
end

local function queue_push(queue, value)
    if queue.size >= queue.capacity then return false end
    queue.tail = (queue.tail % queue.capacity) + 1
    queue.data[queue.tail] = value
    queue.size = queue.size + 1
    return true
end

local function queue_peek(queue)
    if queue.size == 0 then return nil end
    return queue.data[queue.head]
end

local function queue_last(queue)
    if queue.size == 0 then return nil end
    return queue.data[queue.tail]
end

local function queue_pop(queue)
    if queue.size == 0 then return nil end
    local value = queue.data[queue.head]
    queue.data[queue.head] = nil
    queue.head = (queue.head % queue.capacity) + 1
    queue.size = queue.size - 1
    return value
end

local function queue_rotate(queue)
    local value = queue_pop(queue)
    if value ~= nil then queue_push(queue, value) end
    return value
end

local chunk_queue = new_queue(CHUNK_QUEUE_CAPACITY)
local chunk_pending = {}
local chunk_last_sent = {}
local world_frame_open = false
local world_frame_world_number = nil
local active_world_number = nil
local relay_queue = new_queue(RELAY_QUEUE_CAPACITY)

local metrics = {
    chunks = 0,
    bytes = 0,
    relays = 0,
    overwritten_batches = 0,
}
local metrics_enabled = false

local function clean_error(err)
    if common ~= nil and type(common.clean) == "function" then return common.clean(err) end
    return tostring(err)
end

local function report_error(scope, err)
    GlobalsSetValue("mcm_material_sync_last_error_v1", tostring(scope) .. ":" .. clean_error(err))
    if common ~= nil and type(common.report_error) == "function" then
        common.report_error(scope, err)
    end
end

local function frame_number()
    if type(GameGetFrameNum) ~= "function" then return 0 end
    local ok, value = pcall(GameGetFrameNum)
    return ok and (tonumber(value) or 0) or 0
end

local function radius_for_brush(brush_index)
    return BRUSH_RADII[math.floor(tonumber(brush_index) or 1)] or 2
end

local function resolve_material_id(material_name)
    if type(CellFactory_GetType) ~= "function" then return nil end
    local ok, value = pcall(CellFactory_GetType, material_name)
    value = tonumber(value)
    if not ok or value == nil or value < 0 or value > MAX_MATERIAL_ID then return nil end
    return math.floor(value)
end

local function ensure_world_modules()
    if world ~= nil and encoded_area ~= nil then return true end
    if not ok_ffi then return false, "ffi_unavailable" end
    local ok, loaded = pcall(dofile_once, "mods/quant.ew/files/system/world_sync/world.lua")
    if not ok then return false, loaded end
    if type(loaded) ~= "table" or type(loaded.encode_area) ~= "function"
        or (type(loaded.EncodedArea) ~= "cdata" and type(loaded.EncodedArea) ~= "function")
        or type(loaded.encoded_size) ~= "function"
    then
        return false, "world_api"
    end
    local area_ok, area = pcall(loaded.EncodedArea)
    if not area_ok or area == nil then return false, area or "encoded_area" end
    world, encoded_area = loaded, area
    return true
end

local function chunk_key(cx, cy)
    return tostring(cx) .. ":" .. tostring(cy)
end

local function current_world_number()
    if type(ctx) == "table" and type(ctx.proxy_opt) == "table" then
        return math.floor(tonumber(ctx.proxy_opt.world_num) or 0)
    end
    return 0
end

local function complete_chunk(frame)
    local completed = queue_pop(chunk_queue)
    if completed ~= nil then
        chunk_pending[completed.key] = nil
        chunk_last_sent[completed.key] = tonumber(frame) or frame_number()
    end
end

local function point_chunk_keys(x, y, radius)
    local keys = {}
    local min_cx = math.floor((x - radius) / CHUNK_SIZE)
    local max_cx = math.floor((x + radius) / CHUNK_SIZE)
    local min_cy = math.floor((y - radius) / CHUNK_SIZE)
    local max_cy = math.floor((y + radius) / CHUNK_SIZE)
    for cy = min_cy, max_cy do
        for cx = min_cx, max_cx do
            keys[#keys + 1] = chunk_key(cx, cy)
        end
    end
    return keys
end

local function primary_chunk_key(point)
    return chunk_key(math.floor(point[1] / CHUNK_SIZE), math.floor(point[2] / CHUNK_SIZE))
end

local function collect_chunks(points, radius)
    local result, seen = {}, {}
    for i = 1, #points do
        local x, y = points[i][1], points[i][2]
        local min_cx = math.floor((x - radius) / CHUNK_SIZE)
        local max_cx = math.floor((x + radius) / CHUNK_SIZE)
        local min_cy = math.floor((y - radius) / CHUNK_SIZE)
        local max_cy = math.floor((y + radius) / CHUNK_SIZE)
        for cy = min_cy, max_cy do
            for cx = min_cx, max_cx do
                local key = chunk_key(cx, cy)
                if not seen[key] and not chunk_pending[key] then
                    seen[key] = true
                    result[#result + 1] = {
                        cx = cx, cy = cy, key = key,
                        ready_frame = (chunk_last_sent[key] or -100000) + CHUNK_RESEND_COOLDOWN,
                    }
                end
            end
        end
    end
    return result
end

local function commit_chunks(chunks)
    for i = 1, #chunks do
        queue_push(chunk_queue, chunks[i])
        chunk_pending[chunks[i].key] = true
    end
end

local function append_dependency_keys(job, keys)
    job.dependency_seen = job.dependency_seen or {}
    job.dependencies = job.dependencies or {}
    for i = 1, #keys do
        local key = keys[i]
        if not job.dependency_seen[key] then
            job.dependency_seen[key] = true
            job.dependencies[#job.dependencies + 1] = key
        end
    end
end

local function make_relay_groups(points, material_name, material_id, radius)
    local groups = {}
    local current = nil
    for i = 1, #points do
        local point = points[i]
        local anchor_key = primary_chunk_key(point)
        if current == nil or current.anchor_key ~= anchor_key
            or #current.points >= MAX_RELAY_POINTS
        then
            current = {
                material_name = material_name,
                material_id = material_id,
                radius = radius,
                anchor_key = anchor_key,
                points = {},
                dependencies = {},
                dependency_seen = {},
            }
            groups[#groups + 1] = current
        end
        current.points[#current.points + 1] = { point[1], point[2] }
        append_dependency_keys(current, point_chunk_keys(point[1], point[2], radius))
    end
    return groups
end

local function plan_relays(points, material_name, material_id, radius)
    local groups = make_relay_groups(points, material_name, material_id, radius)
    local tail = queue_last(relay_queue)
    local merge_first = #groups > 0 and tail ~= nil
        and tail.material_id == material_id and tail.material_name == material_name and tail.radius == radius
        and tail.anchor_key == groups[1].anchor_key
        and #tail.points + #groups[1].points <= MAX_RELAY_POINTS
    local new_jobs = #groups - (merge_first and 1 or 0)
    if relay_queue.size + new_jobs > relay_queue.capacity then return nil end
    return { groups = groups, merge_first = merge_first, tail = tail }
end

local function commit_native_operation(relay_plan)
    local first = 1
    if relay_plan.merge_first then
        local group = relay_plan.groups[1]
        local target = relay_plan.tail
        for i = 1, #group.points do
            target.points[#target.points + 1] = group.points[i]
        end
        append_dependency_keys(target, group.dependencies)
        first = 2
    end
    for i = first, #relay_plan.groups do
        queue_push(relay_queue, relay_plan.groups[i])
    end
end

local function accept_batch(payload)
    local decoded = transport.decode_batch(payload)
    if decoded == nil then return true, "invalid" end
    local material_id = resolve_material_id(decoded.material_name)
    if material_id == nil then return true, "invalid_material" end
    local radius = radius_for_brush(decoded.brush_index)
    -- Solid frames contain air where Noita has solid cells, but they still establish
    -- the native EW chunk ordering before the synchronized converter/emitter arrives.
    local chunks = collect_chunks(decoded.points, radius)
    if chunk_queue.size + #chunks > chunk_queue.capacity then
        return false, "backpressure"
    end
    local relay_plan = plan_relays(decoded.points, decoded.material_name, material_id, radius)
    if relay_plan == nil then return false, "backpressure" end

    -- Commit only after every destination has capacity. If backpressure stops mailbox
    -- acknowledgement, retrying the same batch cannot duplicate half of its operation.
    commit_chunks(chunks)
    commit_native_operation(relay_plan)
    return true, decoded.solid and "queued_solid" or "queued_dynamic"
end

local function drain_outbox()
    local next_sequence, newest = transport.first_available_sequence(last_sequence)
    if next_sequence > last_sequence + 1 then
        if metrics_enabled then
            metrics.overwritten_batches = metrics.overwritten_batches + (next_sequence - last_sequence - 1)
        end
        last_sequence = next_sequence - 1
        transport.mark_ack(last_sequence)
    end

    local budget = MAX_BATCHES_PER_UPDATE
    while last_sequence < newest and budget > 0 do
        local sequence = last_sequence + 1
        local payload = transport.read_outbox(sequence)
        local accepted, result
        if type(payload) == "string" and payload ~= "" then
            local ok, accepted_or_error, reason = pcall(accept_batch, payload)
            if not ok then
                report_error("material_paint_accept", accepted_or_error)
                break
            end
            accepted, result = accepted_or_error, reason
        else
            accepted, result = true, "missing"
        end

        if not accepted then break end
        transport.clear_outbox(sequence)
        last_sequence = sequence
        transport.mark_ack(sequence)
        GlobalsSetValue(OUTBOX_RESULT, tostring(sequence) .. ":" .. tostring(result or "accepted"))
        budget = budget - 1
    end
end

local function world_exists(x1, y1, x2, y2)
    if type(DoesWorldExistAt) ~= "function" then return true end
    local ok, exists = pcall(DoesWorldExistAt, x1, y1, x2, y2)
    if not ok then return false, exists end
    return exists == true, exists == true and nil or "unloaded"
end

local function encode_and_send_chunk(chunk)
    local modules_ok, modules_reason = ensure_world_modules()
    if not modules_ok then return false, modules_reason end
    local x, y = chunk.cx * CHUNK_SIZE, chunk.cy * CHUNK_SIZE
    local exists, exists_reason = world_exists(x, y, x + CHUNK_SIZE, y + CHUNK_SIZE)
    -- Never mark an unloaded dependency as complete. Releasing the following relay
    -- without a native frame recreates the exact one-chunk-only rollback bug.
    if not exists then return false, exists_reason end

    -- EW's native encoder has hard alignment and size preconditions in native code.
    -- Keeping this exactly 128x128 and aligned avoids the unsafe arbitrary rectangles
    -- used by the old bridge.
    local encode_ok, area = pcall(world.encode_area, x, y, x + CHUNK_SIZE, y + CHUNK_SIZE, encoded_area)
    if not encode_ok then return false, area end
    if area == nil then return false, "encode_nil" end
    local size_ok, size = pcall(world.encoded_size, area)
    size = tonumber(size)
    if not size_ok or size == nil or size <= 0 or size > MAX_ENCODED_BYTES then
        return false, "encoded_size"
    end
    local string_ok, payload = pcall(ffi.string, area, size)
    if not string_ok or type(payload) ~= "string" then return false, payload or "encode_string" end
    local send_ok, send_error = pcall(net.proxy_bin_send, KEY_WORLD_FRAME, payload)
    if not send_ok then return false, send_error end
    if metrics_enabled then
        metrics.chunks = metrics.chunks + 1
        metrics.bytes = metrics.bytes + #payload
    end
    return true, "sent"
end

local function send_world_end(world_number)
    world_number = math.floor(tonumber(world_number) or current_world_number())
    return pcall(net.proxy_bin_send, KEY_WORLD_END, string.char(0) .. tostring(world_number))
end

local function reset_for_world_change()
    local world_number = current_world_number()
    if active_world_number == nil then
        active_world_number = world_number
        return
    end
    if active_world_number == world_number then return end

    -- Paint from the previous world must never be released into the new world. The
    -- proxy owns a separate chunk store per world number, so its seed cache is scoped
    -- to that number as well.
    if world_frame_open then
        local closed, close_error = send_world_end(world_frame_world_number)
        if not closed then report_error("material_paint_old_world_end", close_error) end
    end
    chunk_queue = new_queue(CHUNK_QUEUE_CAPACITY)
    chunk_pending = {}
    chunk_last_sent = {}
    relay_queue = new_queue(RELAY_QUEUE_CAPACITY)
    world_frame_open = false
    world_frame_world_number = nil
    active_world_number = world_number
end

local function drain_chunks(frame)
    -- Once key 0 has been accepted, no later world frame may be started until its
    -- matching key 1 succeeds. Retrying only the terminator avoids both losing the
    -- accepted chunk and concatenating unrelated native frames after a transient error.
    if world_frame_open then
        local end_ok, end_error = send_world_end(world_frame_world_number)
        if not end_ok then
            report_error("material_paint_world_end", end_error)
            return
        end
        complete_chunk(frame)
        world_frame_open = false
        world_frame_world_number = nil
        return
    end
    if frame % CHUNK_SEND_INTERVAL ~= 0 then return end
    local budget = MAX_CHUNKS_PER_UPDATE
    local remaining_to_scan = chunk_queue.size
    while chunk_queue.size > 0 and budget > 0 and remaining_to_scan > 0 do
        local chunk = queue_peek(chunk_queue)
        local ok, reason
        if frame < (tonumber(chunk.ready_frame) or 0) then
            ok, reason = false, "cooldown"
        else
            ok, reason = encode_and_send_chunk(chunk)
        end
        if not ok then
            -- A chunk touching the streaming edge may become available a few frames
            -- later. Rotate only that dependency so it cannot freeze all loaded chunks
            -- encountered while the player keeps moving and drawing.
            if reason == "unloaded" or reason == "cooldown" then
                queue_rotate(chunk_queue)
                remaining_to_scan = remaining_to_scan - 1
            else
                report_error("material_paint_chunk", reason)
                break
            end
        else
            if reason == "sent" then
                world_frame_open = true
                world_frame_world_number = current_world_number()
                local end_ok, end_error = send_world_end(world_frame_world_number)
                if not end_ok then
                    report_error("material_paint_world_end", end_error)
                    return
                end
                world_frame_open = false
                world_frame_world_number = nil
            end
            complete_chunk(frame)
            budget = budget - 1
            remaining_to_scan = remaining_to_scan - 1
        end
    end
end

local function dependencies_ready(job)
    for i = 1, #(job.dependencies or {}) do
        if chunk_pending[job.dependencies[i]] then return false end
    end
    return true
end

local function kill_entity(entity_id)
    if entity_id ~= nil and tonumber(entity_id) ~= 0 and type(EntityKill) == "function" then
        pcall(EntityKill, entity_id)
    end
end

local function add_component(entity_id, component_name, values)
    if type(EntityAddComponent2) ~= "function" then return false, "component_api" end
    local ok, component = pcall(EntityAddComponent2, entity_id, component_name, values)
    if not ok or component == nil or component == 0 then return false, component or "component" end
    return true
end

local function create_relay(job)
    if type(EntityCreateNew) ~= "function" or type(EntitySetTransform) ~= "function"
        or type(EntityAddChild) ~= "function"
    then
        return nil, "entity_api"
    end
    if type(job.points) ~= "table" or #job.points == 0 then return nil, "relay_points" end

    local create_ok, root = pcall(EntityCreateNew, "mcm_material_relay")
    if not create_ok or root == nil or root == 0 then return nil, root or "relay_root" end
    local base_x, base_y = job.points[1][1], job.points[1][2]
    local transform_ok, transform_error = pcall(EntitySetTransform, root, base_x, base_y)
    if not transform_ok then kill_entity(root); return nil, transform_error end
    if type(EntityAddTag) == "function" then pcall(EntityAddTag, root, "mcm_material_relay") end

    local lifetime_ok, lifetime_error = add_component(root, "LifetimeComponent", {
        _tags = "enabled_in_world",
        lifetime = RELAY_LIFETIME,
    })
    if not lifetime_ok then kill_entity(root); return nil, lifetime_error end

    for i = 1, #job.points do
        local point = job.points[i]
        local child_ok, child = pcall(EntityCreateNew, "mcm_material_converter")
        if not child_ok or child == nil or child == 0 then
            kill_entity(root)
            return nil, child or "relay_child"
        end
        -- Position in world space before parenting, matching Noita's own EntityLoad(x,y)
        -- then EntityAddChild() pattern. Reparenting derives the correct relative offset
        -- and the serialized tree remains anchored at the painted chunk.
        local child_transform_ok, child_transform_error = pcall(EntitySetTransform,
            child, point[1], point[2])
        if not child_transform_ok then kill_entity(child); kill_entity(root); return nil, child_transform_error end
        local parent_ok, parent_error = pcall(EntityAddChild, root, child)
        if not parent_ok then kill_entity(child); kill_entity(root); return nil, parent_error end
        local convert_ok, convert_error = add_component(child, "MagicConvertMaterialComponent", {
            _tags = "enabled_in_world",
            radius = math.floor(job.radius),
            -- A brush stamp is a filled disc. Setting min_radius to radius turns the
            -- converter into an annulus and leaves the solid interior untouched on a
            -- stock peer (EW's normal world decoder intentionally preserves solids).
            min_radius = 0,
            is_circle = true,
            steps_per_frame = 256,
            from_any_material = true,
            to_material = math.floor(job.material_id),
            loop = true,
            kill_when_finished = false,
            convert_entities = false,
            -- Re-running the short-lived relay must not keep rebuilding cells that
            -- already have the requested material while they begin simulating.
            convert_same_material = false,
        })
        if not convert_ok then kill_entity(root); return nil, convert_error end
        -- MagicConvert changes existing cells but cannot reliably fill empty air for
        -- every material class. A one-frame real-particle emitter supplies seed cells
        -- on stock EW peers; the converter immediately expands them to the exact disc.
        local particle_count = math.max(1,
            math.floor(math.pi * (math.max(0, tonumber(job.radius) or 0) + 0.5) ^ 2))
        add_component(child, "ParticleEmitterComponent", {
            _tags = "enabled_in_world",
            emitted_material_name = tostring(job.material_name or ""),
            create_real_particles = true,
            emit_real_particles = false,
            emit_cosmetic_particles = false,
            emitter_lifetime_frames = 1,
            emission_interval_min_frames = 1,
            emission_interval_max_frames = 1,
            count_min = particle_count,
            count_max = particle_count,
            x_pos_offset_min = -math.floor(job.radius),
            x_pos_offset_max = math.floor(job.radius),
            y_pos_offset_min = -math.floor(job.radius),
            y_pos_offset_max = math.floor(job.radius),
            x_vel_min = 0,
            x_vel_max = 0,
            y_vel_min = 0,
            y_vel_max = 0,
            lifetime_min = 1,
            lifetime_max = 1,
            render_on_grid = true,
            set_magic_creation = true,
            is_emitting = true,
        })
        local child_lifetime_ok, child_lifetime_error = add_component(child, "LifetimeComponent", {
            _tags = "enabled_in_world",
            lifetime = RELAY_LIFETIME,
        })
        if not child_lifetime_ok then kill_entity(root); return nil, child_lifetime_error end
    end
    return root
end

local function upload_relay(root)
    -- EW exposes this primitive to its own ew_thrown bridge. Calling it directly
    -- uploads the freshly built component tree before its converters have a chance to
    -- run. CrossCall is retained as a compatibility fallback for other EW revisions.
    if type(ewext) == "table" and type(ewext.des_item_thrown) == "function" then
        return pcall(ewext.des_item_thrown, root)
    end
    if type(CrossCall) == "function" then return pcall(CrossCall, "ew_thrown", root) end
    return false, "entity_transport"
end

local function drain_relays(frame)
    if frame % RELAY_SEND_INTERVAL ~= 0 or relay_queue.size == 0 then return end
    local remaining_to_scan = relay_queue.size
    while remaining_to_scan > 0 do
        local job = queue_peek(relay_queue)
        if not dependencies_ready(job) then
            queue_rotate(relay_queue)
            remaining_to_scan = remaining_to_scan - 1
        else
            local root, create_error = create_relay(job)
            if root == nil then
                report_error("material_paint_relay_create", create_error)
                return
            end
            local uploaded, upload_error = upload_relay(root)
            if not uploaded then
                kill_entity(root)
                report_error("material_paint_relay_upload", upload_error)
                return
            end
            queue_pop(relay_queue)
            if metrics_enabled then metrics.relays = metrics.relays + 1 end
            return
        end
    end
end

local function publish_metrics(frame)
    if not metrics_enabled or frame % 60 ~= 0 then return end
    GlobalsSetValue("mcm_material_sync_sent_chunks_v1", tostring(metrics.chunks))
    GlobalsSetValue("mcm_material_sync_sent_bytes_v1", tostring(metrics.bytes))
    GlobalsSetValue("mcm_material_sync_relay_entities_v1", tostring(metrics.relays))
    GlobalsSetValue("mcm_material_sync_overwritten_batches_v1", tostring(metrics.overwritten_batches))
    GlobalsSetValue("mcm_material_sync_backlog_v1", table.concat({
        tostring(chunk_queue.size), tostring(relay_queue.size),
    }, ":"))
end

function materials_bridge.set_metrics_enabled(enabled) metrics_enabled = enabled == true end

function materials_bridge.register(shared_rpc, shared_common)
    rpc, common = shared_rpc, shared_common
    -- Slot 11 remains registered for wire compatibility with MCM v4 peers. Material
    -- state itself never relies on this handler, so a stock peer can safely lack it.
    rpc.opts_reliable()
    rpc.opts_everywhere()
    function rpc.sync_material_paint(_batch) return end
end

function materials_bridge.update()
    local frame = frame_number()
    reset_for_world_change()
    -- Accept/coalesce the newest brush points before encoding, so a continuous stroke
    -- is captured in the next native frame instead of one update late.
    drain_outbox()
    drain_chunks(frame)
    drain_relays(frame)
    publish_metrics(frame)
end

return materials_bridge
