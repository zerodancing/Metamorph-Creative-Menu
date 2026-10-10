if type(METAMORPH_CREATIVE_MENU_DIAGNOSTIC_RUNTIME_RECORDER) == "table" then return METAMORPH_CREATIVE_MENU_DIAGNOSTIC_RUNTIME_RECORDER end

local recorder = {}
local logger = dofile("mods/metamorph_creative_menu/files/diagnostics/logger.lua")
local entity_inspection = dofile("mods/metamorph_creative_menu/files/diagnostics/entity_inspection.lua")
local runtime_context = dofile("mods/metamorph_creative_menu/files/diagnostics/runtime_context.lua")

local previous_controls = {}
local last_control_entity = 0
local player_locator = nil
local last_inventory_open = nil
local last_hp = nil
local last_held_item = nil
local last_player_file = nil
local hp_min, hp_max = nil, nil
local control_transition_count, last_control_summary = 0, ""
local passive_last_time = nil
local passive_samples = 0
local passive_sum_ms = 0
local passive_max_ms = 0
local passive_last_log_frame = -100000
local PASSIVE_HEARTBEAT_FRAMES = 1800
local last_peer_count = nil
local last_peer_watch_frame = -100000
local last_remote_qa_sequence = ""
local last_spike_frame = -100000
local last_spike_level = 0

local CONTROL_FIELDS = {
    left="mButtonDownLeft", right="mButtonDownRight", up="mButtonDownUp", down="mButtonDownDown",
    fly="mButtonDownFly", fire="mButtonDownFire", fire2="mButtonDownFire2",
    kick="mButtonDownKick", use="mButtonDownInteract", throw="mButtonDownThrow",
}

local function finite(value)
    return type(value) == "number" and value == value and math.abs(value) < 1000000000
end

local entity_summary = entity_inspection.summary

local function get_player_locator()
    if player_locator == nil then
        local ok, module = pcall(dofile, "mods/metamorph_creative_menu/files/platform/noita/player_locator.lua")
        player_locator = ok and type(module) == "table" and module or false
    end
    return player_locator ~= false and player_locator or nil
end

local function current_player()
    local locator = get_player_locator()
    if locator == nil or type(locator.get) ~= "function" then return 0 end
    local ok, entity = pcall(locator.get)
    return ok and tonumber(entity) or 0
end

local function record_controls()
    local player = current_player()
    if player == 0 or not EntityGetIsAlive(player) then return end
    local filename = tostring(EntityGetFilename(player) or "")
    if last_player_file ~= nil and last_player_file ~= filename and METAMORPH_CREATIVE_MENU_QA_ACTIVE ~= true then
        logger.event("STATE", "player_file=" .. logger.one_line(last_player_file) .. " -> " .. logger.one_line(filename))
    end
    last_player_file = filename

    local damage_model = EntityGetFirstComponentIncludingDisabled(player, "DamageModelComponent")
    if damage_model ~= nil and damage_model ~= 0 then
        local ok_hp, hp = pcall(ComponentGetValue2, damage_model, "hp")
        hp = ok_hp and tonumber(hp) or nil
        if hp ~= nil then
            hp_min = hp_min == nil and hp or math.min(hp_min, hp)
            hp_max = hp_max == nil and hp or math.max(hp_max, hp)
            if last_hp ~= nil and hp <= 0 and last_hp > 0 then logger.event("STATE", "hp_depleted from=" .. tostring(last_hp)) end
            last_hp = hp
        end
    end

    local inventory = EntityGetFirstComponentIncludingDisabled(player, "Inventory2Component")
    if inventory ~= nil and inventory ~= 0 then
        local ok_held, held_item = pcall(ComponentGetValue2, inventory, "mActualActiveItem")
        held_item = ok_held and tonumber(held_item) or 0
        if last_held_item ~= nil and last_held_item ~= held_item and METAMORPH_CREATIVE_MENU_QA_ACTIVE ~= true then
            logger.event("STATE", "held_item=" .. tostring(last_held_item) .. " -> " .. tostring(held_item))
        end
        last_held_item = held_item
    end

    if type(GameIsInventoryOpen) == "function" then
        local ok_open, inventory_open = pcall(GameIsInventoryOpen)
        inventory_open = ok_open and inventory_open == true or false
        if last_inventory_open ~= nil and last_inventory_open ~= inventory_open and METAMORPH_CREATIVE_MENU_QA_ACTIVE ~= true then
            logger.user_action(inventory_open and "inventory.open" or "inventory.close", "")
        end
        last_inventory_open = inventory_open
    end

    local controls = EntityGetFirstComponentIncludingDisabled(player, "ControlsComponent")
    if controls == nil or controls == 0 then return end
    if player ~= last_control_entity then
        previous_controls = {}
        last_control_entity = player
        if METAMORPH_CREATIVE_MENU_QA_ACTIVE ~= true then logger.event("PLAYER_ENTITY", entity_summary(player)) end
    end

    local changed = {}
    for name, field in pairs(CONTROL_FIELDS) do
        local ok, value = pcall(ComponentGetValue2, controls, field)
        value = ok and value == true or false
        if previous_controls[name] ~= nil and previous_controls[name] ~= value then
            changed[#changed + 1] = name .. "=" .. (value and "1" or "0")
        end
        previous_controls[name] = value
    end
    if #changed == 0 then return end

    control_transition_count = control_transition_count + #changed
    last_control_summary = table.concat(changed, ",")
    local discrete = {}
    for _, token in ipairs(changed) do
        if string.find(token, "fire=", 1, true) or string.find(token, "fire2=", 1, true)
            or string.find(token, "kick=", 1, true) or string.find(token, "use=", 1, true)
            or string.find(token, "throw=", 1, true) then
            discrete[#discrete + 1] = token
        end
    end
    if #discrete > 0 then
        local x, y = EntityGetTransform(player)
        logger.event("INPUT", table.concat(discrete, ",") .. string.format(" pos=%.1f,%.1f", tonumber(x) or 0, tonumber(y) or 0))
    end
end

local variable_value = entity_inspection.variable_string

local qa_context = runtime_context.qa
local world_sync_context = runtime_context.world_sync

local function remote_qa_watch()
    local sequence = GlobalsGetValue("mcm_remote_qa_seq_v1", "")
    if sequence == "" or sequence == last_remote_qa_sequence then return end
    last_remote_qa_sequence = sequence
    logger.event("EW REMOTE QA", "seq=" .. tostring(sequence) .. " state=" .. logger.one_line(GlobalsGetValue("mcm_remote_qa_last_v1", "")))
end

local function peer_watch()
    local current_frame = logger.now_frame()
    if current_frame - last_peer_watch_frame < 10 then return end
    last_peer_watch_frame = current_frame
    remote_qa_watch()
    local peers = EntityGetWithTag("ew_client") or {}
    local peer_count = #peers
    if last_peer_count ~= nil and peer_count ~= last_peer_count then
        local descriptions = {}
        for index, entity in ipairs(peers) do
            if index > 6 then break end
            descriptions[#descriptions + 1] = tostring(entity) .. ":" .. logger.one_line(EntityGetFilename(entity) or "") ..
                ":src=" .. logger.one_line(variable_value(entity, "mcm_light_source"))
        end
        logger.event("EW PEERS", "count=" .. tostring(last_peer_count) .. "->" .. tostring(peer_count) ..
            " peers=" .. table.concat(descriptions, ",") .. " " .. qa_context() .. " " .. world_sync_context())
    end
    last_peer_count = peer_count
end

local function log_frame_spike(milliseconds)
    if not finite(milliseconds) or milliseconds < 50 then return end
    local level = milliseconds >= 1000 and 4 or milliseconds >= 250 and 3 or milliseconds >= 100 and 2 or 1
    local current_frame = logger.now_frame()
    if current_frame - last_spike_frame < 30 and level <= last_spike_level then return end
    last_spike_frame, last_spike_level = current_frame, level

    local player = current_player()
    local filename, x, y, hp, max_hp = "", 0, 0, nil, nil
    if player ~= 0 and EntityGetIsAlive(player) then
        filename = tostring(EntityGetFilename(player) or "")
        x, y = EntityGetTransform(player)
        local damage_model = EntityGetFirstComponentIncludingDisabled(player, "DamageModelComponent")
        if damage_model ~= nil and damage_model ~= 0 then
            pcall(function()
                hp = ComponentGetValue2(damage_model, "hp")
                max_hp = ComponentGetValue2(damage_model, "max_hp")
            end)
        end
    end
    local lua_kb = nil
    if type(collectgarbage) == "function" then
        local ok, value = pcall(collectgarbage, "count")
        if ok then lua_kb = tonumber(value) end
    end
    local enemies = #(EntityGetWithTag("enemy") or {})
    local synced = #(EntityGetWithTag("ew_synced") or {})
    local world_items = #(EntityGetWithTag("ew_global_item") or {})
    logger.event("FRAME SPIKE", string.format("dt_ms=%.2f level=%d player=%d file=%s pos=%.1f,%.1f hp=%s/%s poly=%s remote=%d lua_kb=%s entities=%d/%d/%d form_pose=%s/%s form_sync=%s %s %s",
        milliseconds, level, player, logger.one_line(filename), tonumber(x) or 0, tonumber(y) or 0, tostring(hp), tostring(max_hp),
        tostring(player ~= 0 and EntityGetIsAlive(player) and EntityHasTag(player, "polymorphed_player") or false),
        #(EntityGetWithTag("ew_client") or {}), tostring(lua_kb), enemies, synced, world_items,
        tostring(GlobalsGetValue("mcm_form_pose_sent_v1", "?")), tostring(GlobalsGetValue("mcm_form_pose_received_v1", "?")),
        tostring(GlobalsGetValue("mcm_form_sync_mode_v1", "?")), qa_context(), world_sync_context()))
end

local function passive_heartbeat()
    local current_time = logger.now_seconds()
    if current_time ~= nil and passive_last_time ~= nil then
        local milliseconds = (current_time - passive_last_time) * 1000
        if finite(milliseconds) and milliseconds >= 0 and milliseconds < 5000 then
            passive_samples = passive_samples + 1
            passive_sum_ms = passive_sum_ms + milliseconds
            passive_max_ms = math.max(passive_max_ms, milliseconds)
            log_frame_spike(milliseconds)
        end
    end
    passive_last_time = current_time

    local current_frame = logger.now_frame()
    if current_frame - passive_last_log_frame < PASSIVE_HEARTBEAT_FRAMES then return end
    passive_last_log_frame = current_frame
    local player = current_player()
    local filename, x, y, hp = "", 0, 0, nil
    if player ~= 0 and EntityGetIsAlive(player) then
        filename = tostring(EntityGetFilename(player) or "")
        x, y = EntityGetTransform(player)
        local damage_model = EntityGetFirstComponentIncludingDisabled(player, "DamageModelComponent")
        if damage_model ~= nil and damage_model ~= 0 then
            local ok, value = pcall(ComponentGetValue2, damage_model, "hp")
            if ok then hp = value end
        end
    end
    local average_ms = passive_samples > 0 and passive_sum_ms / passive_samples or 0
    logger.event("PASSIVE", string.format("samples=%d avg_ms=%.2f max_ms=%.2f player=%d file=%s pos=%.1f,%.1f hp=%s hp_range=%s..%s input_changes=%d last_input=%s remote=%d %s %s",
        passive_samples, average_ms, passive_max_ms, player, logger.one_line(filename), tonumber(x) or 0, tonumber(y) or 0, tostring(hp),
        tostring(hp_min), tostring(hp_max), control_transition_count, logger.one_line(last_control_summary), #(EntityGetWithTag("ew_client") or {}),
        qa_context(), world_sync_context()))
    passive_samples, passive_sum_ms, passive_max_ms = 0, 0, 0
    hp_min, hp_max = nil, nil
    control_transition_count, last_control_summary = 0, ""
end

function recorder.update()
    record_controls()
    peer_watch()
    passive_heartbeat()
end

METAMORPH_CREATIVE_MENU_DIAGNOSTIC_RUNTIME_RECORDER = recorder
return recorder
