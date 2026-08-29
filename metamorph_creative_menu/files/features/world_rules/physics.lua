if type(METAMORPH_CREATIVE_MENU_WORLD_RULE_PHYSICS) == "table" then return METAMORPH_CREATIVE_MENU_WORLD_RULE_PHYSICS end

local physics_adapter = {}
local rule_math = dofile("mods/metamorph_creative_menu/files/core/rule_math.lua")
local player_locator = dofile("mods/metamorph_creative_menu/files/platform/noita/player_locator.lua")
local recovery = dofile("mods/metamorph_creative_menu/files/features/world_rules/recovery.lua")

local PHYSICS_SCAN_HALF_WIDTH = 1024
local PHYSICS_SCAN_HALF_HEIGHT = 768
-- Use a wider query shell when deciding whether a previously modified body is still
-- safe to touch. If Box2D no longer returns it there, relinquish the record instead of
-- calling native getters on a potentially expired body ID.
local PHYSICS_RESTORE_HALF_WIDTH = PHYSICS_SCAN_HALF_WIDTH + 192
local PHYSICS_RESTORE_HALF_HEIGHT = PHYSICS_SCAN_HALF_HEIGHT + 192
local CHARACTER_SCAN_RADIUS = 1024

local physics_state = {
    bodies = {},
    characters = {},
    local_gravity_native = {},
    player_recovery_cache = {},
}

local function values_equal(a, b)
    if type(a) == "number" or type(b) == "number" then return rule_math.same(a, b) end
    return a == b
end

local function body_record(id, frame)
    local record = physics_state.bodies[id]
    if record ~= nil then
        record.last_seen = frame
        return record
    end
    local ok_g, gravity = pcall(PhysicsBodyIDGetGravityScale, id)
    local ok_d, linear, angular = pcall(PhysicsBodyIDGetDamping, id)
    if not ok_g or gravity == nil or not ok_d or linear == nil then return nil end
    record = { gravity=gravity, linear=linear, angular=angular or linear, last_seen=frame }
    physics_state.bodies[id] = record
    return record
end

local function set_body_gravity(id, record, factor)
    local target = rule_math.scaled(record.gravity, factor)
    if target == nil then return false end
    -- Most managed bodies already contain our target on the next scan. Read first and
    -- avoid a redundant Box2D write+readback in that steady state. If EW/another mod
    -- changed it, retain the original write and verification path.
    local current_ok, current = pcall(PhysicsBodyIDGetGravityScale, id)
    if current_ok and current ~= nil and values_equal(current, target) then
        record.last_gravity = current
        return true
    end
    local ok = pcall(PhysicsBodyIDSetGravityScale, id, target)
    local ok_read, after = pcall(PhysicsBodyIDGetGravityScale, id)
    if ok and ok_read and after ~= nil and values_equal(after, target) then
        record.last_gravity = after
        -- Changing Box2D gravity scale does not guarantee a sleeping prop wakes up.
        -- A zero force is state-neutral but asks the physics body to participate again
        -- on runtimes that expose the body-id force API. This is done only when the
        -- gravity value actually changed, never on steady-state scans.
        if type(PhysicsBodyIDApplyForce) == "function" and not values_equal(record.gravity, target) then
            pcall(PhysicsBodyIDApplyForce, id, 0, 0)
        end
        return true
    end
    return false
end

local function set_body_damping(id, record, factor)
    local linear = math.max(0, math.min(1, record.linear * factor))
    local angular = math.max(0, math.min(1, record.angular * factor))
    local current_ok, current_l, current_a = pcall(PhysicsBodyIDGetDamping, id)
    if current_ok and current_l ~= nil and values_equal(current_l, linear)
        and values_equal(current_a or current_l, angular)
    then
        record.last_linear, record.last_angular = current_l, current_a or current_l
        return true
    end
    local ok = pcall(PhysicsBodyIDSetDamping, id, linear, angular)
    local ok_read, after_l, after_a = pcall(PhysicsBodyIDGetDamping, id)
    if ok and ok_read and after_l ~= nil and values_equal(after_l, linear) and values_equal(after_a or after_l, angular) then
        record.last_linear, record.last_angular = after_l, after_a or after_l
        return true
    end
    return false
end

local function restore_body_gravity(id, record)
    if record.last_gravity == nil then return true, "unowned" end
    local ok_g, current_g = pcall(PhysicsBodyIDGetGravityScale, id)
    if not ok_g or current_g == nil then return false, "gone" end
    if values_equal(current_g, record.last_gravity) then
        local wrote = pcall(PhysicsBodyIDSetGravityScale, id, record.gravity)
        local read_ok, after = pcall(PhysicsBodyIDGetGravityScale, id)
        if not wrote or not read_ok or not values_equal(after, record.gravity) then return false, "gravity" end
        record.last_gravity = nil
    else
        -- A newer owner changed the body after us. Relinquish only our gravity field;
        -- retaining last_gravity here kept stale body IDs alive indefinitely.
        record.last_gravity = nil
    end
    return true, "ok"
end

local function restore_body_damping(id, record)
    if record.last_linear == nil then return true, "unowned" end
    local ok_d, current_l, current_a = pcall(PhysicsBodyIDGetDamping, id)
    if not ok_d or current_l == nil then return false, "gone" end
    if values_equal(current_l, record.last_linear)
        and values_equal(current_a or current_l, record.last_angular or record.last_linear)
    then
        local wrote = pcall(PhysicsBodyIDSetDamping, id, record.linear, record.angular)
        local read_ok, after_l, after_a = pcall(PhysicsBodyIDGetDamping, id)
        if not wrote or not read_ok or not values_equal(after_l, record.linear) or not values_equal(after_a or after_l, record.angular) then return false, "damping" end
        record.last_linear, record.last_angular = nil, nil
    else
        record.last_linear, record.last_angular = nil, nil
    end
    return true, "ok"
end

local function restore_body(id, record)
    local g, gr = restore_body_gravity(id, record)
    if not g and gr == "gone" then return false, gr end
    local d, dr = restore_body_damping(id, record)
    if not d and dr == "gone" then return false, dr end
    return g and d, (g and d) and "ok" or "partial"
end

local function character_record(comp, field, frame, recovery_key, recovery_meta)
    local key = tostring(comp) .. ":" .. field
    local record = physics_state.characters[key]
    if record ~= nil then
        record.last_seen = frame
        if recovery_key ~= nil then
            record.recovery_key = recovery_key
            record.recovery_meta = recovery_meta
        end
        return record, key
    end
    local ok, value = pcall(ComponentGetValue2, comp, field)
    if not ok or tonumber(value) == nil then return nil, key end
    local ok_type, component_type = pcall(ComponentGetTypeName, comp)
    local ok_owner, owner = pcall(ComponentGetEntity, comp)
    record = {
        component=comp,
        component_type=ok_type and component_type or "",
        owner=ok_owner and owner or 0,
        field=field,
        original=tonumber(value),
        last_seen=frame,
        recovery_key=recovery_key,
        recovery_meta=recovery_meta,
    }
    physics_state.characters[key] = record
    return record, key
end

local function set_character_gravity(comp, field, factor, frame, target_base, recovery_key, recovery_meta)
    local record = character_record(comp, field, frame, recovery_key, recovery_meta)
    if record == nil then return false end
    local base = tonumber(target_base) or record.original
    local target = rule_math.scaled(base, factor)
    if target == nil then return false end
    local current_ok, current = pcall(ComponentGetValue2, comp, field)
    if current_ok and current ~= nil and values_equal(current, target) then
        record.last_written = tonumber(current)
        return true
    end
    local ok = pcall(ComponentSetValue2, comp, field, target)
    local ok_read, after = pcall(ComponentGetValue2, comp, field)
    if ok and ok_read and values_equal(after, target) then
        record.last_written = tonumber(after)
        return true
    end
    return false
end

local function clear_character_recovery(record)
    if record == nil or record.recovery_key == nil then return end
    local persisted = recovery.read("player_gravity", record.recovery_key)
    if persisted ~= nil and (record.recovery_meta == nil or persisted.meta == tostring(record.recovery_meta or "")) then
        recovery.clear("player_gravity", record.recovery_key)
        physics_state.player_recovery_cache[record.recovery_key] = nil
    end
end

local function restore_character_record(key, record)
    if record == nil or record.component == nil then return false, "gone" end
    local ok_type, current_type = pcall(ComponentGetTypeName, record.component)
    local ok_owner, current_owner = pcall(ComponentGetEntity, record.component)
    if not ok_type or current_type ~= record.component_type
        or not ok_owner or current_owner ~= record.owner
    then
        clear_character_recovery(record)
        physics_state.characters[key] = nil
        return true, "gone"
    end
    local ok, current = pcall(ComponentGetValue2, record.component, record.field)
    if not ok or current == nil then
        clear_character_recovery(record)
        physics_state.characters[key] = nil
        return true, "gone"
    end
    -- This component is still the exact entity/component/field we captured.  Other
    -- systems (including EW) may rewrite gravity between frames, so a CAS-style
    -- comparison cannot be used for RESET: it previously discarded the snapshot and
    -- left the player at 0 or 0.25 gravity forever.  Native means the captured native
    -- value, unconditionally.
    local wrote = pcall(ComponentSetValue2, record.component, record.field, record.original)
    if not wrote then return false, "write" end
    local read_ok, after = pcall(ComponentGetValue2, record.component, record.field)
    if not read_ok or not values_equal(after, record.original) then return false, "readback" end
    clear_character_recovery(record)
    physics_state.characters[key] = nil
    return true, "ok"
end

local function scan_physics_bodies(player, half_width, half_height)
    if type(PhysicsBodyIDQueryBodies) ~= "function" then return {} end
    player = player or player_locator.get()
    if player == nil or player == 0 or not EntityGetIsAlive(player) then return {} end
    local x, y = EntityGetTransform(player)
    if x == nil then return {} end
    half_width = tonumber(half_width) or PHYSICS_SCAN_HALF_WIDTH
    half_height = tonumber(half_height) or PHYSICS_SCAN_HALF_HEIGHT
    local ok, bodies = pcall(PhysicsBodyIDQueryBodies, x - half_width, y - half_height, x + half_width, y + half_height, false, false)
    return ok and type(bodies) == "table" and bodies or {}
end

local function body_set(bodies)
    local result = {}
    for _, body_id in ipairs(bodies or {}) do result[body_id] = true end
    return result
end

local function confirmed_restore_bodies(player)
    return body_set(scan_physics_bodies(player, PHYSICS_RESTORE_HALF_WIDTH, PHYSICS_RESTORE_HALF_HEIGHT))
end

local function relinquish_body(record)
    if record == nil then return end
    record.last_gravity = nil
    record.last_linear = nil
    record.last_angular = nil
end


local function local_gravity_key(comp, field)
    return tostring(comp) .. ":" .. tostring(field)
end

local function cleanup_local_native_records()
    local keys = {}
    for key in pairs(physics_state.local_gravity_native) do keys[#keys + 1] = key end
    for _, key in ipairs(keys) do
        local record = physics_state.local_gravity_native[key]
        local ok_type, current_type = pcall(ComponentGetTypeName, record.component)
        local ok_owner, current_owner = pcall(ComponentGetEntity, record.component)
        local alive_ok, alive = false, false
        if ok_owner and current_owner ~= nil and current_owner ~= 0 then
            alive_ok, alive = pcall(EntityGetIsAlive, current_owner)
        end
        local owner_alive = alive_ok and alive == true
        if not ok_type or current_type ~= record.component_type or not ok_owner or current_owner ~= record.owner or not owner_alive then
            physics_state.local_gravity_native[key] = nil
        end
    end
end

local function capture_local_player_native_gravity(player)
    cleanup_local_native_records()
    if player == nil or player == 0 or not EntityGetIsAlive(player) then return end
    local function capture(kind, field)
        for _, comp in ipairs(EntityGetComponentIncludingDisabled(player, kind) or {}) do
            local key = local_gravity_key(comp, field)
            local current = physics_state.local_gravity_native[key]
            local ok_type, component_type = pcall(ComponentGetTypeName, comp)
            local ok_owner, owner = pcall(ComponentGetEntity, comp)
            if current == nil or current.component_type ~= (ok_type and component_type or "")
                or current.owner ~= (ok_owner and owner or 0) then
                local ok, value = pcall(ComponentGetValue2, comp, field)
                value = ok and tonumber(value) or nil
                if value ~= nil then
                    physics_state.local_gravity_native[key] = {
                        component=comp, field=field, owner=ok_owner and owner or player,
                        component_type=ok_type and component_type or "", native=value,
                    }
                end
            end
        end
    end
    capture("CharacterDataComponent", "gravity")
    capture("CharacterPlatformingComponent", "pixel_gravity")
end

local function player_recovery_id(kind, field, index)
    return tostring(kind) .. "|" .. tostring(field) .. "|" .. tostring(index)
end

local function ensure_player_recovery(recovery_key, original, meta)
    local cached = physics_state.player_recovery_cache[recovery_key]
    meta = tostring(meta or "")
    if cached ~= nil and cached.meta == meta and values_equal(cached.original, original) then return cached end
    local persisted = recovery.read("player_gravity", recovery_key)
    if persisted == nil or persisted.meta ~= meta or not values_equal(persisted.original, original) then
        recovery.replace("player_gravity", recovery_key, original, meta)
        persisted = {original=original,last=nil,meta=meta}
    end
    cached = {original=original,last=persisted.last,meta=meta}
    physics_state.player_recovery_cache[recovery_key] = cached
    return cached
end

local function update_player_recovery_last(recovery_key, value)
    local cached = physics_state.player_recovery_cache[recovery_key]
    if cached == nil then return end
    value = tonumber(value)
    if value == nil then return end
    if cached.last == nil or not values_equal(cached.last, value) then
        recovery.update_last("player_gravity", recovery_key, value)
        cached.last = value
    end
end

local function reassert_local_player_gravity(player, factor, frame)
    if player == nil or player == 0 or not EntityGetIsAlive(player) then return false end
    local wrote = false
    local player_filename = type(EntityGetFilename) == "function" and (EntityGetFilename(player) or "") or ""
    local function apply(kind, field)
        for index, comp in ipairs(EntityGetComponentIncludingDisabled(player, kind) or {}) do
            local key = local_gravity_key(comp, field)
            local native = physics_state.local_gravity_native[key]
            if native ~= nil then
                local ok_type, current_type = pcall(ComponentGetTypeName, comp)
                local ok_owner, current_owner = pcall(ComponentGetEntity, comp)
                if not ok_type or current_type ~= native.component_type or not ok_owner or current_owner ~= native.owner then
                    physics_state.local_gravity_native[key] = nil
                    native = nil
                end
            end
            if native == nil then
                local ok, value = pcall(ComponentGetValue2, comp, field)
                value = ok and tonumber(value) or nil
                local ok_type, component_type = pcall(ComponentGetTypeName, comp)
                local ok_owner, owner = pcall(ComponentGetEntity, comp)
                if value ~= nil then
                    native = {component=comp,field=field,owner=ok_owner and owner or player,
                        component_type=ok_type and component_type or "",native=value}
                    physics_state.local_gravity_native[key] = native
                end
            end
            if native ~= nil then
                local recovery_key = player_recovery_id(kind, field, index)
                ensure_player_recovery(recovery_key, native.native, player_filename)
                if set_character_gravity(comp, field, factor, frame, native.native, recovery_key, player_filename) then
                    local read_ok, current = pcall(ComponentGetValue2, comp, field)
                    if read_ok and tonumber(current) ~= nil then update_player_recovery_last(recovery_key, tonumber(current)) end
                    wrote = true
                end
            end
        end
    end
    apply("CharacterDataComponent", "gravity")
    apply("CharacterPlatformingComponent", "pixel_gravity")
    return wrote
end

local function parse_player_recovery_id(id)
    local kind, field, index = string.match(tostring(id), "^([^|]+)|([^|]+)|(%d+)$")
    return kind, field, tonumber(index)
end

local function recover_persisted_local_gravity(player)
    local ids = recovery.list("player_gravity")
    if #ids == 0 then return true end
    if player == nil or player == 0 or not EntityGetIsAlive(player) then return false end
    local player_filename = type(EntityGetFilename) == "function" and (EntityGetFilename(player) or "") or ""
    local all_resolved = true
    for _, id in ipairs(ids) do
        local record = recovery.read("player_gravity", id)
        local kind, field, index = parse_player_recovery_id(id)
        if record == nil then
            recovery.clear("player_gravity", id)
            physics_state.player_recovery_cache[id] = nil
        elseif kind == nil or field == nil or index == nil then
            recovery.clear("player_gravity", id)
            physics_state.player_recovery_cache[id] = nil
        elseif record.meta ~= "" and record.meta ~= player_filename then
            -- The save resumed in a different player/form entity. Its native gravity is
            -- not the old form's baseline, so never write the old value into the new form.
            recovery.clear("player_gravity", id)
            physics_state.player_recovery_cache[id] = nil
        else
            local components = EntityGetComponentIncludingDisabled(player, kind) or {}
            local comp = components[index]
            if comp == nil then
                recovery.clear("player_gravity", id)
                physics_state.player_recovery_cache[id] = nil
            else
                local read_ok, current = pcall(ComponentGetValue2, comp, field)
                current = read_ok and tonumber(current) or nil
                if current == nil then
                    all_resolved = false
                elseif values_equal(current, record.original) then
                    recovery.clear("player_gravity", id)
                    physics_state.player_recovery_cache[id] = nil
                elseif record.last ~= nil and values_equal(current, record.last) then
                    local wrote = pcall(ComponentSetValue2, comp, field, record.original)
                    local verify_ok, after = pcall(ComponentGetValue2, comp, field)
                    after = verify_ok and tonumber(after) or nil
                    if wrote and after ~= nil and values_equal(after, record.original) then
                        recovery.clear("player_gravity", id)
                        physics_state.player_recovery_cache[id] = nil
                    else
                        all_resolved = false
                    end
                else
                    recovery.clear("player_gravity", id)
                    physics_state.player_recovery_cache[id] = nil
                end
            end
        end
    end
    return all_resolved
end

local function scan_character_gravity(factor, frame, player)
    if type(EntityGetInRadius) ~= "function" then return end
    player = player or player_locator.get()
    if player == nil or player == 0 or not EntityGetIsAlive(player) then return end
    local x, y = EntityGetTransform(player); if x == nil then return end
    local ok, nearby = pcall(EntityGetInRadius, x, y, CHARACTER_SCAN_RADIUS)
    local entities, seen = { player }, { [player]=true }
    if ok and type(nearby) == "table" then
        for _, entity in ipairs(nearby) do
            if not seen[entity] then seen[entity] = true; entities[#entities + 1] = entity end
        end
    end
    for _, entity in ipairs(entities) do
        for _, comp in ipairs(EntityGetComponentIncludingDisabled(entity, "CharacterDataComponent") or {}) do
            local native = entity == player and physics_state.local_gravity_native[local_gravity_key(comp, "gravity")] or nil
            set_character_gravity(comp, "gravity", factor, frame, native and native.native or nil)
        end
        for _, comp in ipairs(EntityGetComponentIncludingDisabled(entity, "CharacterPlatformingComponent") or {}) do
            local native = entity == player and physics_state.local_gravity_native[local_gravity_key(comp, "pixel_gravity")] or nil
            set_character_gravity(comp, "pixel_gravity", factor, frame, native and native.native or nil)
        end
    end
end


function physics_adapter.supported(kind)
    if kind == "physics_gravity" then
        return type(PhysicsBodyIDQueryBodies) == "function" and type(PhysicsBodyIDSetGravityScale) == "function"
    end
    if kind == "physics_damping" then
        return type(PhysicsBodyIDQueryBodies) == "function" and type(PhysicsBodyIDSetDamping) == "function"
    end
    return false
end

function physics_adapter.capture_local_native(player)
    capture_local_player_native_gravity(player)
end

function physics_adapter.reassert_local(player, factor, frame)
    return reassert_local_player_gravity(player, factor, frame)
end

function physics_adapter.scan(player, gravity_factor, damping_factor, frame)
    if player == nil or player == 0 or not EntityGetIsAlive(player) then return end
    local scanned_bodies = scan_physics_bodies(player)
    local confirmed_bodies = confirmed_restore_bodies(player)
    local live_bodies = {}
    for _, body_id in ipairs(scanned_bodies) do
        live_bodies[body_id] = true
        local record = body_record(body_id, frame)
        if record ~= nil then
            if gravity_factor ~= nil then set_body_gravity(body_id, record, gravity_factor) end
            if damping_factor ~= nil then set_body_damping(body_id, record, damping_factor) end
        end
    end
    local body_ids = {}
    for body_id in pairs(physics_state.bodies) do body_ids[#body_ids + 1] = body_id end
    for _, body_id in ipairs(body_ids) do
        local record = physics_state.bodies[body_id]
        if record ~= nil and record.last_seen ~= frame and not live_bodies[body_id] then
            if confirmed_bodies[body_id] then
                local restored, reason = restore_body(body_id, record)
                if restored or reason == "gone" then physics_state.bodies[body_id] = nil end
            else
                -- Calling any PhysicsBodyID getter on an expired ID emits a native Lua
                -- error even behind pcall. Never feed a stale ID back into Noita.
                relinquish_body(record)
                physics_state.bodies[body_id] = nil
            end
        end
    end
    if gravity_factor ~= nil then scan_character_gravity(gravity_factor, frame, player) end
    local character_keys = {}
    for key in pairs(physics_state.characters) do character_keys[#character_keys + 1] = key end
    for _, key in ipairs(character_keys) do
        local record = physics_state.characters[key]
        if record ~= nil and record.last_seen ~= frame then restore_character_record(key, record) end
    end
end

function physics_adapter.restore_rule(kind)
    local all_restored = true
    local confirmed_bodies = confirmed_restore_bodies(player_locator.get())
    local body_ids = {}
    for body_id in pairs(physics_state.bodies) do body_ids[#body_ids + 1] = body_id end
    for _, body_id in ipairs(body_ids) do
        local record = physics_state.bodies[body_id]
        local restored, reason
        if not confirmed_bodies[body_id] then
            relinquish_body(record)
            physics_state.bodies[body_id] = nil
            restored, reason = true, "gone"
        elseif kind == "physics_gravity" then
            restored, reason = restore_body_gravity(body_id, record)
        else
            restored, reason = restore_body_damping(body_id, record)
        end
        if reason == "gone" then physics_state.bodies[body_id] = nil
        elseif not restored then all_restored = false
        elseif record.last_gravity == nil and record.last_linear == nil then physics_state.bodies[body_id] = nil end
    end
    if kind == "physics_gravity" then
        local character_keys = {}
        for key in pairs(physics_state.characters) do character_keys[#character_keys + 1] = key end
        for _, key in ipairs(character_keys) do
            local restored, reason = restore_character_record(key, physics_state.characters[key])
            if not restored and reason ~= "gone" then all_restored = false end
        end
    end
    return all_restored, all_restored and "ok" or "restore_failed"
end

function physics_adapter.reset_all()
    local all_restored = true
    local confirmed_bodies = confirmed_restore_bodies(player_locator.get())
    local body_ids = {}
    for body_id in pairs(physics_state.bodies) do body_ids[#body_ids + 1] = body_id end
    for _, body_id in ipairs(body_ids) do
        local record = physics_state.bodies[body_id]
        local restored, reason
        if confirmed_bodies[body_id] then
            restored, reason = restore_body(body_id, record)
        else
            relinquish_body(record)
            restored, reason = true, "gone"
        end
        if restored or reason == "gone" then physics_state.bodies[body_id] = nil else all_restored = false end
    end
    local character_keys = {}
    for key in pairs(physics_state.characters) do character_keys[#character_keys + 1] = key end
    for _, key in ipairs(character_keys) do
        local restored, reason = restore_character_record(key, physics_state.characters[key])
        if not restored and reason ~= "gone" then all_restored = false end
    end
    return all_restored
end

function physics_adapter.recover_persisted_local(player)
    return recover_persisted_local_gravity(player)
end

function physics_adapter.has_persisted_local_recovery()
    return recovery.has("player_gravity")
end

function physics_adapter.debug_local_gravity(player, factor)
    local rows = {}
    if player == nil or player == 0 or not EntityGetIsAlive(player) then return {player=0, factor=factor, rows=rows} end
    for _, pair in ipairs({{"CharacterDataComponent","gravity"},{"CharacterPlatformingComponent","pixel_gravity"}}) do
        for _, component_id in ipairs(EntityGetComponentIncludingDisabled(player, pair[1]) or {}) do
            local key = local_gravity_key(component_id, pair[2])
            local baseline = physics_state.local_gravity_native[key]
            local read_succeeded, current_value = pcall(ComponentGetValue2, component_id, pair[2])
            rows[#rows + 1] = {
                component=component_id, field=pair[2], current=read_succeeded and tonumber(current_value) or nil,
                native=baseline and baseline.native or nil,
                expected=(baseline and factor) and rule_math.scaled(baseline.native, factor) or nil,
            }
        end
    end
    return {player=player, factor=factor, rows=rows}
end


function physics_adapter.has_gravity_overrides()
    for _, record in pairs(physics_state.bodies) do
        if type(record) == "table" and record.last_gravity ~= nil then return true end
    end
    if next(physics_state.characters) ~= nil then return true end
    return false
end

function physics_adapter.has_damping_overrides()
    for _, record in pairs(physics_state.bodies) do
        if type(record) == "table" and record.last_linear ~= nil then return true end
    end
    return false
end

function physics_adapter.has_overrides()
    return next(physics_state.bodies) ~= nil or next(physics_state.characters) ~= nil
end

METAMORPH_CREATIVE_MENU_WORLD_RULE_PHYSICS = physics_adapter
return physics_adapter
