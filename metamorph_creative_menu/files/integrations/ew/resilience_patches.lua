local resilience_patches = {}

function resilience_patches.patch_wand_pickup_killself_source(content)
    if type(content) ~= "string" or string.find(content, "mcm_wand_pickup_crosscall_guard_v1", 1, true) ~= nil then
        return content, 0
    end
    local anchor = 'if not CrossCall("ew_is_wand_pickup") then'
    local first, last = string.find(content, anchor, 1, true)
    if first == nil then return content, 0 end
    local replacement = [[-- mcm_wand_pickup_crosscall_guard_v1
local mcm_pickup_ok, mcm_is_wand_pickup = pcall(CrossCall, "ew_is_wand_pickup")
if not mcm_pickup_ok or not mcm_is_wand_pickup then]]
    return string.sub(content, 1, first - 1) .. replacement .. string.sub(content, last + 1), 1
end

function resilience_patches.patch_crosscall_source(content)
    if type(content) ~= "string" or string.find(content, "CrossCall", 1, true) == nil
        or string.find(content, "mcm_safe_crosscall_v1", 1, true) ~= nil
    then return content, 0 end
    local guard = [[-- mcm_safe_crosscall_v1
local mcm_crosscall_error_seen = {}
local function CrossCall(name, ...)
    -- Resolve the engine/EW global dynamically. Do not capture it while a LuaComponent
    -- is loading: some EW systems install their handler later in the same startup.
    local mcm_raw_crosscall = _G and _G.CrossCall or nil
    local mcm_ok, a, b, c, d, e
    if type(mcm_raw_crosscall) == "function" then
        mcm_ok, a, b, c, d, e = pcall(mcm_raw_crosscall, name, ...)
        if mcm_ok then return a, b, c, d, e end
    else
        mcm_ok, a = false, "CrossCall unavailable (" .. type(mcm_raw_crosscall) .. ")"
    end
    if name == "ew_per_peer_seed" then return 0, 0 end
    if name == "ew_is_wand_pickup" then return true end
    if name == "ew_do_i_own" then return false end
    if name == "ew_has_flag" then
        local flag = select(1, ...)
        return type(GameHasFlagRun) == "function" and GameHasFlagRun(flag) or false
    end
    if name == "ew_banned_spells" or name == "ew_perk_ban_list" then return {} end
    -- Preserve the old nil fallback for compatibility, but surface truly unexpected
    -- EW failures once per (call,error) signature. This is intentionally diagnostic
    -- only: changing fallback semantics here could break optional EW systems.
    local mcm_signature = tostring(name) .. "|" .. tostring(a)
    if not mcm_crosscall_error_seen[mcm_signature] then
        mcm_crosscall_error_seen[mcm_signature] = true
        if type(METAMORPH_CREATIVE_MENU_DIAGNOSTICS_CAPTURE) == "function" then
            pcall(METAMORPH_CREATIVE_MENU_DIAGNOSTICS_CAPTURE, "ew.crosscall." .. tostring(name), tostring(a))
        end
        print("[Metamorph: Creative Menu] unexpected EW CrossCall failure " .. tostring(name) .. ": " .. tostring(a))
    end
    return nil
end
]]
    return guard .. content, 1
end

function resilience_patches.patch_seed_source(content)
    if type(content) ~= "string" then return content, 0 end
    local replacement = [[local ew_seed_ok, sx, sy = pcall(CrossCall, "ew_per_peer_seed")
if not ew_seed_ok then sx, sy = 0, 0 end]]
    return string.gsub(content, 'local sx, sy = CrossCall%("ew_per_peer_seed"%)', replacement)
end

function resilience_patches.patch_detour_source(content)
    if type(content) ~= "string" then return content, 0 end
    return string.gsub(content,
        'CrossCall%("ew_wang_detour", EW_CURRENT_FILE, "([%w_]+)", x, y, w, h, is_open_path%)',
        function(original)
            return 'local ew_detour_ok = pcall(CrossCall, "ew_wang_detour", EW_CURRENT_FILE, "'
                .. original .. '", x, y, w, h, is_open_path)\n'
                .. '    if not ew_detour_ok then ' .. original .. '(x, y, w, h, is_open_path) end'
        end)
end

function resilience_patches.patch_world_sync_source(content, metrics_enabled)
    if type(content) ~= "string" or string.find(content, "mcm_poly_world_sync_v3", 1, true) ~= nil then
        return content, 0
    end
    local original = content
    -- ModTextFileGetContent can return either LF or CRLF depending on how the EW build
    -- was installed.  The patch below deliberately uses readable literal anchors, so
    -- normalize line endings before matching them.  Returning `original` on any failed
    -- anchor keeps the all-or-nothing guarantee; a successful patch is safe to publish
    -- with canonical LF endings, which Noita accepts.
    content = string.gsub(content, "\r\n", "\n")
    content = string.gsub(content, "\r", "\n")
    local changed = 0
    local function replace_once(source, before, after)
        local first, last = string.find(source, before, 1, true)
        if first == nil then return source, false end
        return string.sub(source, 1, first - 1) .. after .. string.sub(source, last + 1), true
    end

    -- State is deliberately tiny/bounded. It records chunks a fast polymorphed player
    -- has just left so destructive worm/dragon movement cannot outrun the normal EW
    -- camera-centred scheduler.
    local state_anchor = "local iter_slow_2 = 0"
    local metrics_literal = metrics_enabled == true and "true" or "false"
    local state_block = [[local iter_slow_2 = 0

-- mcm_poly_world_sync_v3
local EWCM_METRICS_ENABLED = ]] .. metrics_literal .. [[
local mcm_trail_queue = {}
local mcm_trail_seen = {}
local mcm_trail_head, mcm_trail_tail, mcm_trail_count = 1, 0, 0
local mcm_last_poly_cx, mcm_last_poly_cy = nil, nil
local mcm_sent_chunks, mcm_sent_bytes = 0, 0
local mcm_recv_chunks, mcm_recv_bytes = 0, 0
local mcm_trail_sent = 0
local mcm_trail_dropped = 0
local EWCM_TRAIL_LIMIT = 96]]
    local ok
    content, ok = replace_once(content, state_anchor, state_block)
    if not ok then return original, 0 end
    changed = changed + 1

    local send_anchor = [[            net.proxy_bin_send(KEY_WORLD_FRAME, str)
        end
    end
end
local int = 4 -- ctx.proxy_opt.world_sync_interval]]
    local send_block = [[            net.proxy_bin_send(KEY_WORLD_FRAME, str)
            if EWCM_METRICS_ENABLED then
                mcm_sent_chunks = mcm_sent_chunks + 1
                mcm_sent_bytes = mcm_sent_bytes + #str
            end
        end
    end
end

local function mcm_enqueue_trail(cx, cy)
    local key = tostring(cx) .. ":" .. tostring(cy)
    if mcm_trail_seen[key] then return end
    -- Preserve old trail chunks when saturated: they are no longer covered by EW's
    -- player-centred scheduler, while the newest/current chunks still are.  A fixed ring
    -- avoids the O(n) table.remove(1) shift in the network hot path.
    if mcm_trail_count >= EWCM_TRAIL_LIMIT then
        if EWCM_METRICS_ENABLED then mcm_trail_dropped = mcm_trail_dropped + 1 end
        return
    end
    mcm_trail_tail = (mcm_trail_tail % EWCM_TRAIL_LIMIT) + 1
    mcm_trail_seen[key] = true
    mcm_trail_queue[mcm_trail_tail] = { cx, cy }
    mcm_trail_count = mcm_trail_count + 1
end

local function mcm_note_poly_chunk(cx, cy)
    if mcm_last_poly_cx ~= nil and (cx ~= mcm_last_poly_cx or cy ~= mcm_last_poly_cy) then
        for oy = -1, 1 do
            for ox = -1, 1 do mcm_enqueue_trail(mcm_last_poly_cx + ox, mcm_last_poly_cy + oy) end
        end
    end
    mcm_last_poly_cx, mcm_last_poly_cy = cx, cy
end

local function mcm_drain_trail()
    -- One full authoritative chunk every other frame is enough to guarantee eventual
    -- convergence in steady state.  Drain every frame above half capacity so a burst can
    -- recover without discarding the oldest, least likely to be revisited chunks.
    if mcm_trail_count == 0
        or (mcm_trail_count <= EWCM_TRAIL_LIMIT / 2 and GameGetFrameNum() % 2 ~= 1)
    then return end
    local item = mcm_trail_queue[mcm_trail_head]
    mcm_trail_queue[mcm_trail_head] = nil
    mcm_trail_head = (mcm_trail_head % EWCM_TRAIL_LIMIT) + 1
    mcm_trail_count = mcm_trail_count - 1
    if item == nil then return end
    mcm_trail_seen[tostring(item[1]) .. ":" .. tostring(item[2])] = nil
    send_chunks(item[1], item[2])
    -- A binary world frame is a two-key protocol transaction. Closing this injected
    -- chunk immediately prevents it from leaking into a later stock scheduler frame,
    -- which can otherwise grow malformed native batches during sustained fast travel.
    net.proxy_bin_send(KEY_WORLD_END, string.char(0) .. tostring(ctx.proxy_opt.world_num or 0))
    if EWCM_METRICS_ENABLED then mcm_trail_sent = mcm_trail_sent + 1 end
end

local function mcm_publish_world_metrics()
    if not EWCM_METRICS_ENABLED or GameGetFrameNum() % 60 ~= 0 then return end
    GlobalsSetValue("mcm_world_sync_sent_chunks_v1", tostring(mcm_sent_chunks))
    GlobalsSetValue("mcm_world_sync_sent_bytes_v1", tostring(mcm_sent_bytes))
    GlobalsSetValue("mcm_world_sync_recv_chunks_v1", tostring(mcm_recv_chunks))
    GlobalsSetValue("mcm_world_sync_recv_bytes_v1", tostring(mcm_recv_bytes))
    GlobalsSetValue("mcm_world_sync_trail_backlog_v1", tostring(mcm_trail_count))
    GlobalsSetValue("mcm_world_sync_trail_sent_v1", tostring(mcm_trail_sent))
    GlobalsSetValue("mcm_world_sync_trail_dropped_v1", tostring(mcm_trail_dropped))
    GlobalsSetValue("mcm_world_sync_last_poly_chunk_v1", tostring(mcm_last_poly_cx or "") .. ":" .. tostring(mcm_last_poly_cy or ""))
end

local int = 4 -- ctx.proxy_opt.world_sync_interval]]
    content, ok = replace_once(content, send_anchor, send_block)
    if not ok then return original, 0 end
    changed = changed + 1

    local chunk_anchor = [[    local ocx, ocy = math.floor(px / CHUNK_SIZE), math.floor(py / CHUNK_SIZE)
    local n = 0]]
    local chunk_block = [[    local ocx, ocy = math.floor(px / CHUNK_SIZE), math.floor(py / CHUNK_SIZE)
    if EntityHasTag(ctx.my_player.entity, "polymorphed_player") then
        mcm_note_poly_chunk(ocx, ocy)
    else
        mcm_last_poly_cx, mcm_last_poly_cy = nil, nil
    end
    local n = 0]]
    content, ok = replace_once(content, chunk_anchor, chunk_block)
    if not ok then return original, 0 end
    changed = changed + 1

    local upstream_far = [[        if ctx.spectating_over_peer_id ~= nil and ctx.spectating_over_peer_id ~= ctx.my_id then
            if GameGetFrameNum() % 3 ~= 2 then
                get_all_chunks(cx, cy, pos_data, 16, false)
            else
                get_all_chunks(ocx, ocy, pos_data, 16, true)
            end
        else
            wait = GameGetFrameNum() + 30
        end]]
    local v2_far = [[        if ctx.spectating_over_peer_id ~= nil and ctx.spectating_over_peer_id ~= ctx.my_id then
            if GameGetFrameNum() % 3 ~= 2 then
                get_all_chunks(cx, cy, pos_data, 16, false)
            else
                get_all_chunks(ocx, ocy, pos_data, 16, true)
            end
        elseif EntityHasTag(ctx.my_player.entity, "polymorphed_player") then
            -- mcm_fast_poly_world_sync_v2
            -- Fast playable worms/dragons can outrun the camera by several chunks. The
            -- upstream pauses world sync for 30 frames in that case. An earlier patch tried to
            -- compensate by calling get_all_chunks only on frame%%int==0, which meant
            -- only the central chunk was ever emitted: get_all_chunks's neighbour-ring
            -- phases happen on other frame residues. Call the normal budgeted scheduler
            -- every frame around the *player* instead. It still sends only the chunks
            -- EW normally budgets for that frame, while destruction cannot outrun sync.
            get_all_chunks(ocx, ocy, pos_data, 0, true)
        else
            wait = GameGetFrameNum() + 30
        end]]
    local far_block = [[        if ctx.spectating_over_peer_id ~= nil and ctx.spectating_over_peer_id ~= ctx.my_id then
            if GameGetFrameNum() % 3 ~= 2 then
                get_all_chunks(cx, cy, pos_data, 16, false)
            else
                get_all_chunks(ocx, ocy, pos_data, 16, true)
            end
        elseif EntityHasTag(ctx.my_player.entity, "polymorphed_player") then
            -- Keep upstream's own per-frame ring scheduler centred on the actual form.
            -- The trail queue below separately guarantees delivery of chunks we left.
            get_all_chunks(ocx, ocy, pos_data, 0, true)
        else
            wait = GameGetFrameNum() + 30
        end]]
    content, ok = replace_once(content, upstream_far, far_block)
    if not ok then content, ok = replace_once(content, v2_far, far_block) end
    if not ok then return original, 0 end
    changed = changed + 1

    local tail_anchor = [[    end
end

local PixelRun_const_ptr]]
    local tail_block = [[    end
    -- Keep draining after returning to human. Otherwise the last destroyed chunks of
    -- a fast form could remain queued forever at the exact moment the form ends.
    mcm_drain_trail()
    mcm_publish_world_metrics()
end

local PixelRun_const_ptr]]
    content, ok = replace_once(content, tail_anchor, tail_block)
    if not ok then return original, 0 end
    changed = changed + 1

    local recv_anchor = [[function world_sync.handle_world_data(datum)
    local grid_world = world_ffi.get_grid_world()]]
    local recv_block = [[function world_sync.handle_world_data(datum)
    if EWCM_METRICS_ENABLED then
        mcm_recv_chunks = mcm_recv_chunks + 1
        if type(datum) == "string" then mcm_recv_bytes = mcm_recv_bytes + #datum end
    end
    local grid_world = world_ffi.get_grid_world()]]
    content, ok = replace_once(content, recv_anchor, recv_block)
    if not ok then return original, 0 end
    changed = changed + 1
    return content, changed
end

local POLYMORPH_DEATH_ANCHOR = [[        if has_hp_component and hp <= 0 and not gameover_requested then
            ctx.cap.health.on_poly_death()
            gameover_requested = true
        end]]

local POLYMORPH_DEATH_BLOCK = [[        if has_hp_component and hp <= 0 and not gameover_requested then
            -- mcm_poly_death_intercept_v1: a creative MCM form death is a form-lifecycle
            -- transition, not an EW player death. Give MCM one synchronous chance to
            -- commit its serialized human backup before local_health/shared-health can
            -- create notplayer or trigger game over. Ordinary EW polymorphs keep the
            -- exact upstream path when the acknowledgement is absent.
            local mcm_old_entity = ctx.my_player.entity
            local function mcm_death_ack_matches()
                if type(GlobalsGetValue) ~= "function" then return false end
                local ok_ack, ack = pcall(GlobalsGetValue, "mcm_form_death_intercept_ack_v1", "")
                if not ok_ack then return false end
                local ack_entity, ack_frame = tostring(ack or ""):match("^(%-?%d+):(%-?%d+)$")
                if tonumber(ack_entity) ~= tonumber(mcm_old_entity) then return false end
                if type(GameGetFrameNum) ~= "function" then return true end
                local ok_frame, frame = pcall(GameGetFrameNum)
                if not ok_frame then return true end
                return math.abs((tonumber(frame) or 0) - (tonumber(ack_frame) or -100000)) <= 2
            end
            -- The entity-side death() callback may have run earlier in this same frame.
            -- Accept that recent committed acknowledgement even though corpse handoff has
            -- already removed the MCM player-form tag from the old body.
            local mcm_poly_death_handled = mcm_death_ack_matches()
            -- EW replaces the global CrossCall in its own VM with a private local
            -- callback table. MCM's handler lives in the mod VM, so the synchronous
            -- fallback must use NoitaPatcher's native cross-VM entry point when present.
            local mcm_cross_call = type(np) == "table" and type(np.CrossCall) == "function"
                and np.CrossCall or CrossCall
            if not mcm_poly_death_handled
                and type(EntityHasTag) == "function"
                and EntityHasTag(mcm_old_entity, "metamorph_creative_menu_network_form")
                and type(mcm_cross_call) == "function"
            then
                if type(GlobalsSetValue) == "function" then
                    pcall(GlobalsSetValue, "mcm_form_death_intercept_ack_v1", "")
                end
                pcall(mcm_cross_call, "metamorph_creative_menu_form_died", mcm_old_entity,
                    "ew_poly_death", 0, nil, 0)
                mcm_poly_death_handled = mcm_death_ack_matches()
            end
            if not mcm_poly_death_handled then
                ctx.cap.health.on_poly_death()
                gameover_requested = true
            end
        end]]

-- Keep the player-death guard independently patchable from optional profiling. A future
-- EW revision may change serialization internals while retaining the same health path;
-- losing metrics must never silently re-enable notplayer for an MCM creative form.
function resilience_patches.patch_polymorph_death_source(content)
    if type(content) ~= "string" or string.find(content, "mcm_poly_death_intercept_v1", 1, true) ~= nil then
        return content, 0
    end
    local first, last = string.find(content, POLYMORPH_DEATH_ANCHOR, 1, true)
    if first == nil then return content, 0 end
    return string.sub(content, 1, first - 1) .. POLYMORPH_DEATH_BLOCK .. string.sub(content, last + 1), 1
end

-- Instrument only EW's polymorph entity replacement path. This is intentionally not
-- installed in util.serialize_entity()/deserialize_entity(), because those helpers are also
-- hot paths for projectiles and world items. The measurements below are one-shot per
-- polymorph replacement and do not alter the serialized payload.
function resilience_patches.patch_polymorph_profile_source(content)
    if type(content) ~= "string" or string.find(content, "mcm_poly_profile_v1", 1, true) ~= nil then
        return content, 0
    end
    local original = content
    local function replace_once(source, before, after)
        local first, last = string.find(source, before, 1, true)
        if first == nil then return source, false end
        return string.sub(source, 1, first - 1) .. after .. string.sub(source, last + 1), true
    end

    local module_anchor = "local module = {}"
    local helpers = [=[local module = {}

-- mcm_poly_profile_v1
local function mcm_poly_profile_now()
    if type(GameGetRealWorldTimeSinceStarted) ~= "function" then return nil end
    local ok, value = pcall(GameGetRealWorldTimeSinceStarted)
    value = ok and tonumber(value) or nil
    return value
end

local function mcm_poly_profile_source(entity)
    if entity == nil or entity == 0 then return "" end
    for _, component in ipairs(EntityGetComponentIncludingDisabled(entity, "VariableStorageComponent") or {}) do
        local ok_name, name = pcall(ComponentGetValue2, component, "name")
        if ok_name and name == "metamorph_creative_menu_network_source" then
            local ok_value, value = pcall(ComponentGetValue2, component, "value_string")
            if ok_value and type(value) == "string" then return value end
        end
    end
    local ok, filename = pcall(EntityGetFilename, entity)
    return ok and tostring(filename or "") or ""
end

local function mcm_poly_profile_kind(entity)
    if entity == nil or entity == 0 then return "unknown" end
    if EntityGetFirstComponentIncludingDisabled(entity, "BossDragonComponent") ~= nil then return "boss_dragon" end
    if EntityGetFirstComponentIncludingDisabled(entity, "WormComponent") ~= nil then return "worm" end
    if EntityGetFirstComponentIncludingDisabled(entity, "CharacterDataComponent") ~= nil then return "character" end
    if EntityGetFirstComponentIncludingDisabled(entity, "AdvancedFishAIComponent") ~= nil then return "fish" end
    return "other"
end

local function mcm_poly_profile_publish(prefix, entity, byte_count, started, finished)
    local tag_ok, is_mcm = false, false
    if type(EntityHasTag) == "function" then tag_ok, is_mcm = pcall(EntityHasTag, entity, "metamorph_creative_menu_network_form") end
    if not tag_ok or is_mcm ~= true then return end
    local elapsed_ms = -1
    if started ~= nil and finished ~= nil then elapsed_ms = math.max(0, (finished - started) * 1000) end
    local bytes = math.max(0, tonumber(byte_count) or 0)
    local source = mcm_poly_profile_source(entity)
    local kind = mcm_poly_profile_kind(entity)
    if type(GlobalsSetValue) == "function" then
        pcall(GlobalsSetValue, prefix .. "_ms_v1", string.format("%.3f", elapsed_ms))
        pcall(GlobalsSetValue, prefix .. "_bytes_v1", tostring(bytes))
        pcall(GlobalsSetValue, prefix .. "_source_v1", source)
        pcall(GlobalsSetValue, prefix .. "_kind_v1", kind)
        if type(GameGetFrameNum) == "function" then
            local ok, frame = pcall(GameGetFrameNum)
            if ok then pcall(GlobalsSetValue, prefix .. "_frame_v1", tostring(tonumber(frame) or -1)) end
        end
    end
    if type(print) == "function" then
        print("[MCM EW profile] " .. tostring(prefix) .. " ms=" .. string.format("%.3f", elapsed_ms)
            .. " bytes=" .. tostring(bytes) .. " kind=" .. tostring(kind) .. " source=" .. tostring(source))
    end
end]=]
    local ok
    content, ok = replace_once(content, module_anchor, helpers)
    if not ok then return original, 0 end

    if string.find(content, "mcm_poly_death_intercept_v1", 1, true) == nil then
        local death_patched, death_count = resilience_patches.patch_polymorph_death_source(content)
        if death_count ~= 1 then return original, 0 end
        content = death_patched
    end

    local serialize_anchor = [[        rpc.change_entity({ data = util.serialize_entity(ctx.my_player.entity) })]]
    local serialize_block = [[        local mcm_profile_serialize_started = mcm_poly_profile_now()
        local mcm_profile_serialized = util.serialize_entity(ctx.my_player.entity)
        local mcm_profile_serialize_finished = mcm_poly_profile_now()
        mcm_poly_profile_publish("mcm_ew_poly_serialize", ctx.my_player.entity,
            type(mcm_profile_serialized) == "string" and #mcm_profile_serialized or 0,
            mcm_profile_serialize_started, mcm_profile_serialize_finished)
        rpc.change_entity({ data = mcm_profile_serialized })]]
    content, ok = replace_once(content, serialize_anchor, serialize_block)
    if not ok then return original, 0 end

    local deserialize_anchor = [[        local ent = util.deserialize_entity(seri_ent.data)]]
    local deserialize_block = [[        local mcm_profile_deserialize_started = mcm_poly_profile_now()
        local ent = util.deserialize_entity(seri_ent.data)
        local mcm_profile_deserialize_finished = mcm_poly_profile_now()
        mcm_poly_profile_publish("mcm_ew_poly_deserialize", ent,
            type(seri_ent.data) == "string" and #seri_ent.data or 0,
            mcm_profile_deserialize_started, mcm_profile_deserialize_finished)]]
    content, ok = replace_once(content, deserialize_anchor, deserialize_block)
    if not ok then return original, 0 end

    return content, 1
end


-- EW mirrors LoadPixelScene calls by filename, but its stock RPC does not forward the
-- color_to_material_table argument. MCM's solid brush uses one tiny mask file plus a
-- dynamic color->material mapping, so replaying that scene remotely would either load
-- the wrong material or reference an MCM-owned file on a peer that does not have MCM.
-- Keep the local LoadPixelScene result and let EW's normal grid-world synchronization
-- transport the resulting cells instead. This patch affects only MCM brush assets.
function resilience_patches.patch_material_pixel_scene_source(content)
    if type(content) ~= "string" then return content, 0 end
    if string.find(content, "mcm_material_brush_pixel_scene_v1", 1, true) then return content, 0 end
    local original = content
    local function replace_material_scene_once(source, before, after)
        local first, last = string.find(source, before, 1, true)
        if first == nil then return source, false end
        return string.sub(source, 1, first - 1) .. after .. string.sub(source, last + 1), true
    end
    local anchor = [[    -- TODO there are a couple more parameters, tho they don't seem to be used in vanilla
    CrossCall(
        "ew_sync_pixel_scene",]]
    local replacement = [[    -- mcm_material_brush_pixel_scene_v1: the MCM solid brush supplies its
    -- material dynamically through color_to_material_table. EW's stock pixel-scene
    -- RPC intentionally forwards only filenames/position, so replaying this MCM-owned
    -- mask remotely cannot preserve the selected material and breaks peers without MCM.
    -- The scene has already been applied locally above. Do not send a filename-only
    -- replay that cannot represent the selected material; stock EW world synchronization
    -- remains responsible for whatever resulting grid state its normal model can encode.
    -- All non-MCM pixel scenes keep the exact upstream path.
    if string.find(tostring(materials_filename or ""),
        "mods/metamorph_creative_menu/files/features/materials/brushes/", 1, true) == 1
    then
        return
    end
    -- TODO there are a couple more parameters, tho they don't seem to be used in vanilla
    CrossCall(
        "ew_sync_pixel_scene",]]
    local changed, ok = replace_material_scene_once(content, anchor, replacement)
    if not ok then return original, 0 end
    return changed, 1
end

function resilience_patches.patch_peer_perk_isolation_source(content)
    if type(content) ~= "string" or string.find(content, "mcm_peer_perk_sync_v4", 1, true) ~= nil then
        return content, 0
    end
    local function replace_peer_once(source, before, after)
        local first, last = string.find(source, before, 1, true)
        if first == nil then return source, false end
        return string.sub(source, 1, first - 1) .. after .. string.sub(source, last + 1), true
    end
    local original = content

    -- 0) Some perks are known by EW itself to be unsafe when their full vanilla mechanics
    -- are executed on the synthetic remote-player replica. Keep the owner's real pickup
    -- untouched; only stop EW's replica reconstruction from running these mechanics a
    -- second time.
    if string.find(content, "mcm_peer_perk_remote_safety_v1", 1, true) == nil then
        local ignore_anchor = "local perks_to_ignore = {"
        local ignore_block = [[local perks_to_ignore = {
    -- mcm_peer_perk_remote_safety_v1: exact ids with unsafe/non-replica mechanics.
    ABILITY_ACTIONS_MATERIALIZED = true,
    RESPAWN = true,
    SAVING_GRACE = true,
    CORDYCEPS = true,]]
        local changed, ok = replace_peer_once(content, ignore_anchor, ignore_block)
        if not ok then return original, 0 end
        content = changed
    end

    -- 1) Do not rewrite EW's global-perk policy. Instead, hide only tracked creative
    -- copies from the *sender's* advertised count. A stock EW peer therefore never sees
    -- that creative layer and cannot grant it to its own real player, while ordinary
    -- vanilla pickups still follow EW's upstream global-perk semantics unchanged.
    if string.find(content, "mcm_peer_perk_sender_filter_v1", 1, true) == nil then
        local count_anchor = [[        local perk_count = tonumber(GlobalsGetValue(perk_flag_name .. "_PICKUP_COUNT", "0"))
        if perk_count > 0 then]]
        local count_block = [[        local perk_count = tonumber(GlobalsGetValue(perk_flag_name .. "_PICKUP_COUNT", "0"))
        -- mcm_peer_perk_sender_filter_v1
        if global_perks[perk_id] then
            local mcm_hidden = math.max(0, tonumber(GlobalsGetValue("mcm_creative_perk_hidden_count_v1:" .. perk_id, "0")) or 0)
            if mcm_hidden > 0 then perk_count = math.max(0, perk_count - mcm_hidden) end
        end
        if perk_count > 0 then]]
        local changed, ok = replace_peer_once(content, count_anchor, count_block)
        if not ok then return original, 0 end
        content = changed
    end

    -- 2) Reuse EW's own remote-perk rebuild path for removals. get_my_perks() omits
    -- zero-count perks, while update_perks() historically iterated only keys present in
    -- the new table. Add zero entries for previously replicated perks so its existing
    -- diff<0 branch can retire/rebuild the remote replica. No custom perk RPC is added.
    if string.find(content, "mcm_peer_perk_removal_v1", 1, true) == nil then
        local anchor = [[    local current_counts = util.get_ent_variable(entity, "ew_current_perks") or {}
    for perk_id, count in pairs(perk_data) do]]
        local replacement = [[    local current_counts = util.get_ent_variable(entity, "ew_current_perks") or {}
    -- mcm_peer_perk_removal_v1: preserve removed ids as explicit zeroes for EW's
    -- existing negative-diff cleanup path.
    for perk_id in pairs(current_counts) do
        if perk_data[perk_id] == nil then perk_data[perk_id] = 0 end
    end
    for perk_id, count in pairs(perk_data) do]]
        local changed, ok = replace_peer_once(content, anchor, replacement)
        if not ok then return original, 0 end
        content = changed
    end

    -- The marker is attached to the unchanged upstream global-perk table declaration so
    -- verification also proves we did not replace the table with an MCM-owned policy.
    local marker_anchor = "local global_perks = {"
    local marked, marked_ok = replace_peer_once(content, marker_anchor,
        marker_anchor .. " -- mcm_peer_perk_sync_v4")
    if not marked_ok then return original, 0 end
    return marked, 1
end

-- EW already owns replication of homunculus/Lukki-minion/ghost helper entities, but
-- upstream only reconciles a helper class when the incoming list is non-empty and sends
-- no final packet after the last local helper disappears. That makes the final remote
-- replica immortal until some unrelated helper of the same class appears. Keep the
-- existing RPC/protocol and make an empty list authoritative for that class.
function resilience_patches.patch_perk_helper_sync_source(content)
    if type(content) ~= "string" or string.find(content, "mcm_perk_helper_sync_v1", 1, true) ~= nil then
        return content, 0
    end
    local original = content
    local function replace_once(source, before, after)
        local first, last = string.find(source, before, 1, true)
        if first == nil then return source, false end
        return string.sub(source, 1, first - 1) .. after .. string.sub(source, last + 1), true
    end

    local ok
    content, ok = replace_once(content, "    if #ho ~= 0 then\n", "    if true then -- mcm_perk_helper_empty_homunculus_v1\n")
    if not ok then return original, 0 end
    content, ok = replace_once(content, "    if #lu ~= 0 then\n", "    if true then -- mcm_perk_helper_empty_lukki_v1\n")
    if not ok then return original, 0 end
    content, ok = replace_once(content, "    if #gh ~= 0 then\n", "    if true then -- mcm_perk_helper_empty_ghost_v1\n")
    if not ok then return original, 0 end

    local function_anchor = "function homunculus.on_world_update()"
    local function_header = [[-- mcm_perk_helper_sync_v1
GlobalsSetValue("mcm_perk_helper_sync_loaded_v1", "1")
local mcm_had_perk_helpers = false
function homunculus.on_world_update()]]
    content, ok = replace_once(content, function_anchor, function_header)
    if not ok then return original, 0 end

    local send_anchor = [[    if #ho ~= 0 or #lu ~= 0 or #gh ~= 0 then
        rpc.send_positions(ho, lu, gh, GameGetFrameNum())
    end]]
    local send_block = [[    local mcm_has_perk_helpers = #ho ~= 0 or #lu ~= 0 or #gh ~= 0
    -- Send one authoritative empty snapshot after the last helper disappears. While at
    -- least one class remains alive the existing per-frame packets now also reconcile
    -- any other class whose list became empty.
    if mcm_has_perk_helpers or mcm_had_perk_helpers then
        rpc.send_positions(ho, lu, gh, GameGetFrameNum())
    end
    mcm_had_perk_helpers = mcm_has_perk_helpers]]
    content, ok = replace_once(content, send_anchor, send_block)
    if not ok then return original, 0 end
    return content, 1
end


-- EW's existing mutation RPC only applies Rat/Fungus/Ghost/Lukki on false->true.  The
-- reverse transition is missing upstream, so a peer that removes the mutation can leave
-- the remote replica permanently mutated.  Extend the existing RPC with per-replica
-- baselines and true->false restoration; no new network message is introduced.
function resilience_patches.patch_perk_mutation_sync_source(content)
    if type(content) ~= "string" or string.find(content, "mcm_perk_mutation_sync_v1", 1, true) ~= nil then
        return content, 0
    end
    local original = content
    local function replace_once(source, before, after)
        local first, last = string.find(source, before, 1, true)
        if first == nil then return source, false end
        return string.sub(source, 1, first - 1) .. after .. string.sub(source, last + 1), true
    end

    local module_anchor = [[local module = {}]]
    local helpers = [=[local module = {}

-- mcm_perk_mutation_sync_v1
GlobalsSetValue("mcm_perk_mutation_sync_loaded_v1", "1")
local mcm_mutation_baselines = {}

local function mcm_baseline(entity)
    local value = mcm_mutation_baselines[entity]
    if value == nil then value = {}; mcm_mutation_baselines[entity] = value end
    return value
end

local function mcm_component_alive(component)
    if component == nil or component == 0 then return false end
    local ok, name = pcall(ComponentGetTypeName, component)
    return ok and type(name) == "string" and name ~= ""
end

local function mcm_capture_children(entity, filenames)
    local found = {}
    for _, child in ipairs(EntityGetAllChildren(entity) or {}) do
        if filenames[EntityGetFilename(child)] then found[child] = true end
    end
    return found
end

local function mcm_remove_new_children(entity, baseline, filenames)
    for _, child in ipairs(EntityGetAllChildren(entity) or {}) do
        if filenames[EntityGetFilename(child)] and not (baseline or {})[child] then EntityKill(child) end
    end
end

local function mcm_platform_rows(entity)
    local rows = {}
    for _, component in ipairs(EntityGetComponentIncludingDisabled(entity, "CharacterPlatformingComponent") or {}) do
        rows[#rows + 1] = {
            component = component,
            run = ComponentGetMetaCustom(component, "run_velocity"),
            minx = ComponentGetMetaCustom(component, "velocity_min_x"),
            maxx = ComponentGetMetaCustom(component, "velocity_max_x"),
        }
    end
    return rows
end

local function mcm_capture_platform_base(entity)
    local baseline = mcm_baseline(entity)
    if baseline.platform_base == nil then baseline.platform_base = mcm_platform_rows(entity) end
    return baseline.platform_base
end

local function mcm_sync_platform(entity, rat_active, lukki_active)
    local baseline = mcm_baseline(entity)
    local rows = baseline.platform_base
    if rows == nil then return end
    local factor = (rat_active and 1.15 or 1.0) * (lukki_active and 1.1 or 1.0)
    for _, row in ipairs(rows) do
        if mcm_component_alive(row.component) then
            local run = tonumber(row.run); local minx = tonumber(row.minx); local maxx = tonumber(row.maxx)
            if run ~= nil then ComponentSetMetaCustom(row.component, "run_velocity", run * factor) end
            if minx ~= nil then ComponentSetMetaCustom(row.component, "velocity_min_x", minx * factor) end
            if maxx ~= nil then ComponentSetMetaCustom(row.component, "velocity_max_x", maxx * factor) end
        end
    end
    if not rat_active and not lukki_active then baseline.platform_base = nil end
end

local function mcm_capture_rat(entity)
    local baseline = mcm_baseline(entity)
    if baseline.rat ~= nil then return end
    mcm_capture_platform_base(entity)
    baseline.rat = {
        children = mcm_capture_children(entity, { ["data/entities/verlet_chains/tail/verlet_tail.xml"] = true }),
    }
end

local function mcm_restore_rat(entity)
    local baseline = mcm_baseline(entity); local state = baseline.rat
    if state == nil then return end
    mcm_remove_new_children(entity, state.children, { ["data/entities/verlet_chains/tail/verlet_tail.xml"] = true })
    baseline.rat = nil
end

local function mcm_capture_lukki(entity)
    local baseline = mcm_baseline(entity)
    if baseline.lukki ~= nil then return end
    local enabled = {}
    for _, component in ipairs(EntityGetAllComponents(entity) or {}) do
        if ComponentHasTag(component, "lukki_enable") then enabled[component] = ComponentGetIsEnabled(component) == true end
    end
    local sprite = EntityGetFirstComponentIncludingDisabled(entity, "SpriteComponent", "lukki_disable")
    mcm_capture_platform_base(entity)
    baseline.lukki = {
        enabled = enabled, sprite = sprite,
        alpha = sprite ~= nil and ComponentGetValue2(sprite, "alpha") or nil,
    }
end

local function mcm_restore_lukki(entity)
    local baseline = mcm_baseline(entity); local state = baseline.lukki
    if state == nil then return end
    for component, enabled in pairs(state.enabled or {}) do
        if mcm_component_alive(component) then EntitySetComponentIsEnabled(entity, component, enabled) end
    end
    if mcm_component_alive(state.sprite) and state.alpha ~= nil then ComponentSetValue2(state.sprite, "alpha", state.alpha) end
    baseline.lukki = nil
end

local function mcm_capture_fungus(entity)
    local baseline = mcm_baseline(entity)
    if baseline.fungus ~= nil then return end
    local enabled = {}
    for _, component in ipairs(EntityGetAllComponents(entity) or {}) do
        if ComponentHasTag(component, "player_hat") or ComponentHasTag(component, "player_hat2_shadow") then
            enabled[component] = ComponentGetIsEnabled(component) == true
        end
    end
    local damage = {}
    for _, component in ipairs(EntityGetComponentIncludingDisabled(entity, "DamageModelComponent") or {}) do
        damage[#damage + 1] = { component = component,
            explosion = ComponentObjectGetValue(component, "damage_multipliers", "explosion") }
    end
    baseline.fungus = { enabled = enabled, damage = damage }
end

local function mcm_restore_fungus(entity)
    local baseline = mcm_baseline(entity); local state = baseline.fungus
    if state == nil then return end
    for component, enabled in pairs(state.enabled or {}) do
        if mcm_component_alive(component) then EntitySetComponentIsEnabled(entity, component, enabled) end
    end
    for _, row in ipairs(state.damage or {}) do
        if mcm_component_alive(row.component) and row.explosion ~= nil then
            ComponentObjectSetValue(row.component, "damage_multipliers", "explosion", row.explosion)
        end
    end
    baseline.fungus = nil
end

local function mcm_capture_ghost(entity)
    local baseline = mcm_baseline(entity)
    if baseline.ghost ~= nil then return end
    local recharge = {}
    for _, component in ipairs(EntityGetComponentIncludingDisabled(entity, "CharacterDataComponent") or {}) do
        recharge[#recharge + 1] = { component = component, value = ComponentGetValue2(component, "fly_recharge_spd") }
    end
    baseline.ghost = {
        recharge = recharge,
        children = mcm_capture_children(entity, {
            ["data/entities/misc/perks/ghostly_ghost.xml"] = true,
            ["data/entities/misc/perks/tiny_ghost_extra.xml"] = true,
        }),
    }
end

local function mcm_restore_ghost(entity)
    local baseline = mcm_baseline(entity); local state = baseline.ghost
    if state == nil then return end
    for _, row in ipairs(state.recharge or {}) do
        if mcm_component_alive(row.component) and row.value ~= nil then ComponentSetValue2(row.component, "fly_recharge_spd", row.value) end
    end
    mcm_remove_new_children(entity, state.children, {
        ["data/entities/misc/perks/ghostly_ghost.xml"] = true,
        ["data/entities/misc/perks/tiny_ghost_extra.xml"] = true,
    })
    baseline.ghost = nil
end]=]
    local ok
    content, ok = replace_once(content, module_anchor, helpers)
    if not ok then return original, 0 end

    local starts = {
        {"local function become_rat(entity_who_picked)\n", "local function become_rat(entity_who_picked)\n    mcm_capture_rat(entity_who_picked)\n"},
        {"local function become_fungus(entity_who_picked)\n", "local function become_fungus(entity_who_picked)\n    mcm_capture_fungus(entity_who_picked)\n"},
        {"local function become_luuki(entity_who_picked)\n", "local function become_luuki(entity_who_picked)\n    mcm_capture_lukki(entity_who_picked)\n"},
        {"local function become_ghost(entity_who_picked)\n", "local function become_ghost(entity_who_picked)\n    mcm_capture_ghost(entity_who_picked)\n"},
    }
    for _, pair in ipairs(starts) do
        content, ok = replace_once(content, pair[1], pair[2])
        if not ok then return original, 0 end
    end

    local transitions = {
        {[[    if ghost and not last.ghost then
        become_ghost(ent)
    end]], [[    if ghost and not last.ghost then
        become_ghost(ent)
    elseif not ghost and last.ghost then
        mcm_restore_ghost(ent)
    end]]},
        {[[    if luuki and not last.luuki then
        become_luuki(ent)
    end]], [[    if luuki and not last.luuki then
        become_luuki(ent)
    elseif not luuki and last.luuki then
        mcm_restore_lukki(ent)
    end]]},
        {[[    if rat and not last.rat then
        become_rat(ent)
    end]], [[    if rat and not last.rat then
        become_rat(ent)
    elseif not rat and last.rat then
        mcm_restore_rat(ent)
    end]]},
        {[[    if fungus and not last.fungus then
        become_fungus(ent)
    end]], [[    if fungus and not last.fungus then
        become_fungus(ent)
    elseif not fungus and last.fungus then
        mcm_restore_fungus(ent)
    end
    mcm_sync_platform(ent, rat, luuki)]]},
    }
    for _, pair in ipairs(transitions) do
        content, ok = replace_once(content, pair[1], pair[2])
        if not ok then return original, 0 end
    end
    return content, 1
end

return resilience_patches
