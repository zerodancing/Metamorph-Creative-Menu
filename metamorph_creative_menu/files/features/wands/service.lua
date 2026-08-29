if type(METAMORPH_CREATIVE_MENU_WAND_SERVICE) == "table" then return METAMORPH_CREATIVE_MENU_WAND_SERVICE end

local wand_service = {}
local wand_api = dofile("mods/metamorph_creative_menu/files/platform/noita/wand.lua")
local wand_sync = dofile("mods/metamorph_creative_menu/files/features/wands/sync.lua")
local wand_appearance = dofile("mods/metamorph_creative_menu/files/features/wands/appearance.lua")

-- Keep creative editing inside a conservative engine-safe envelope. Vanilla can very
-- rarely generate capacities above this, but this editor must never be able to create
-- the hundreds/thousands of slots that can destabilize inventory/action regeneration.
local MAX_EDITABLE_SLOTS = 64

local DEFINITIONS = {
    slots={kind="effective_capacity", min=1, max=MAX_EDITABLE_SLOTS, step=1, integer=true},
    actions_per_round={kind="object", object="gun_config", field="actions_per_round", min=1, max=1024, step=1, integer=true},
    reload_time={kind="object", object="gun_config", field="reload_time", min=-100000, max=100000, step=1, integer=true},
    fire_rate_wait={kind="object", object="gunaction_config", field="fire_rate_wait", min=-100000, max=100000, step=1, integer=true},
    spread_degrees={kind="object", object="gunaction_config", field="spread_degrees", min=-3600, max=3600, step=1},
    speed_multiplier={kind="object", object="gunaction_config", field="speed_multiplier", min=-1000, max=1000, step=0.05},
    mana_max={kind="scalar", field="mana_max", min=0, max=1000000000, step=50},
    mana_charge_speed={kind="scalar", field="mana_charge_speed", min=-1000000000, max=1000000000, step=50},
    item_recoil_recovery_speed={kind="scalar", field="item_recoil_recovery_speed", min=-1000000, max=1000000, step=1},
    gun_level={kind="scalar", field="gun_level", min=0, max=1000, step=1, integer=true},
}

local BOOLEAN_DEFINITIONS = {
    shuffle={kind="object", object="gun_config", field="shuffle_deck_when_empty"},
    never_reload={kind="scalar", field="never_reload"},
}

local function finite_number(value)
    value = tonumber(value)
    return value ~= nil and value == value and value > -math.huge and value < math.huge and value or nil
end

local function clamp_definition(definition, value)
    value = finite_number(value)
    if value == nil then return nil end
    value = math.max(definition.min, math.min(definition.max, value))
    if definition.integer then value = math.floor(value + (value >= 0 and 0.5 or -0.5)) end
    return value
end

local function action_shape(wand)
    local permanent, highest = 0, -1
    for _, child in ipairs(EntityGetAllChildren(wand) or {}) do
        local item = EntityGetFirstComponentIncludingDisabled(child, "ItemComponent")
        local action = EntityGetFirstComponentIncludingDisabled(child, "ItemActionComponent")
        if item ~= nil and item ~= 0 and action ~= nil and action ~= 0 then
            local ok_perm, is_perm = pcall(ComponentGetValue2, item, "permanently_attached")
            if ok_perm and is_perm == true then
                permanent = permanent + 1
            else
                local ok_slot, x, y = pcall(ComponentGetValue2, item, "inventory_slot")
                if ok_slot and (tonumber(y) or 0) == 0 then highest = math.max(highest, tonumber(x) or -1) end
            end
        end
    end
    return permanent, highest
end

local function read_definition(ability, definition)
    if definition.kind == "scalar" then
        local value, ok = wand_api.get_scalar(ability, definition.field)
        return ok and finite_number(value) or nil
    end
    local value, ok = wand_api.get_object(ability, definition.object, definition.field)
    return ok and finite_number(value) or nil
end

function wand_service.snapshot(wand)
    local ability = wand_api.ability(wand)
    if ability == 0 then return nil, "not_wand" end
    local snapshot = { wand=wand, ability=ability, stats={} }
    local permanent, highest = action_shape(wand)
    snapshot.permanent_actions, snapshot.highest_slot = permanent, highest
    for id, definition in pairs(DEFINITIONS) do
        if id ~= "slots" then snapshot.stats[id] = read_definition(ability, definition) end
    end
    local raw_capacity = select(1, wand_api.get_object(ability, "gun_config", "deck_capacity"))
    snapshot.raw_capacity = finite_number(raw_capacity)
    snapshot.stats.slots = math.max(1, math.floor((snapshot.raw_capacity or 1) - permanent))
    local mana = select(1, wand_api.get_scalar(ability, "mana"))
    snapshot.mana = finite_number(mana)
    for id, definition in pairs(BOOLEAN_DEFINITIONS) do
        local value, ok
        if definition.kind == "scalar" then value, ok = wand_api.get_scalar(ability, definition.field)
        else value, ok = wand_api.get_object(ability, definition.object, definition.field) end
        snapshot.stats[id] = ok and value == true or false
    end
    local sprite = select(1, wand_api.get_scalar(ability, "sprite_file"))
    snapshot.sprite_file = type(sprite) == "string" and sprite or ""
    return snapshot, "ok"
end

local function sync(player) wand_sync.inventory(player) end

function wand_service.definition(id)
    return DEFINITIONS[id] or BOOLEAN_DEFINITIONS[id]
end

function wand_service.max_slots()
    return MAX_EDITABLE_SLOTS
end

function wand_service.set_stat(player, wand, id, value)
    local snapshot, reason = wand_service.snapshot(wand)
    if snapshot == nil then return false, reason end
    local definition = DEFINITIONS[id]
    if definition == nil then return false, "unknown_stat" end
    value = clamp_definition(definition, value)
    if value == nil then return false, "invalid_value" end

    local ok
    if definition.kind == "effective_capacity" then
        local minimum = math.max(1, snapshot.highest_slot + 1)
        if value < minimum then return false, "occupied_slots" end
        local raw = value + snapshot.permanent_actions
        ok = wand_api.set_object(snapshot.ability, "gun_config", "deck_capacity", raw)
    elseif definition.kind == "scalar" then
        ok = wand_api.set_scalar(snapshot.ability, definition.field, value)
    else
        ok = wand_api.set_object(snapshot.ability, definition.object, definition.field, value)
    end
    if not ok then return false, "write_failed" end

    if id == "mana_max" and snapshot.mana ~= nil and snapshot.mana > value then
        wand_api.set_scalar(snapshot.ability, "mana", value)
    end
    sync(player)
    return true, "ok"
end

function wand_service.set_boolean(player, wand, id, value)
    local snapshot, reason = wand_service.snapshot(wand)
    if snapshot == nil then return false, reason end
    local definition = BOOLEAN_DEFINITIONS[id]
    if definition == nil then return false, "unknown_boolean" end
    value = value == true
    local ok
    if definition.kind == "scalar" then ok = wand_api.set_scalar(snapshot.ability, definition.field, value)
    else ok = wand_api.set_object(snapshot.ability, definition.object, definition.field, value) end
    if not ok then return false, "write_failed" end
    sync(player)
    return true, "ok"
end

function wand_service.set_sprite(player, wand, path)
    return wand_appearance.set_visual(player, wand, {sprite_file=path})
end


local function write_definition(ability, definition, value, raw_capacity)
    if definition.kind == "effective_capacity" then
        return wand_api.set_object(ability, "gun_config", "deck_capacity", raw_capacity)
    elseif definition.kind == "scalar" then
        return wand_api.set_scalar(ability, definition.field, value)
    end
    return wand_api.set_object(ability, definition.object, definition.field, value)
end

local function restore_snapshot(snapshot)
    if type(snapshot) ~= "table" or snapshot.ability == nil then return end
    for id, definition in pairs(DEFINITIONS) do
        if id == "slots" then
            if snapshot.raw_capacity ~= nil then pcall(wand_api.set_object, snapshot.ability, "gun_config", "deck_capacity", snapshot.raw_capacity) end
        elseif snapshot.stats[id] ~= nil then
            if definition.kind == "scalar" then pcall(wand_api.set_scalar, snapshot.ability, definition.field, snapshot.stats[id])
            else pcall(wand_api.set_object, snapshot.ability, definition.object, definition.field, snapshot.stats[id]) end
        end
    end
    for id, definition in pairs(BOOLEAN_DEFINITIONS) do
        if snapshot.stats[id] ~= nil then
            if definition.kind == "scalar" then pcall(wand_api.set_scalar, snapshot.ability, definition.field, snapshot.stats[id])
            else pcall(wand_api.set_object, snapshot.ability, definition.object, definition.field, snapshot.stats[id]) end
        end
    end
    if snapshot.sprite_file ~= nil and snapshot.sprite_file ~= "" then pcall(wand_api.set_scalar, snapshot.ability, "sprite_file", snapshot.sprite_file) end
    if snapshot.mana ~= nil then pcall(wand_api.set_scalar, snapshot.ability, "mana", snapshot.mana) end
end

-- Apply a complete wand configuration with one synchronization point. This is used by
-- persistent blueprints so ten scalar writes never become ten independent network/UI
-- commits. Any failed verified write restores the exact pre-edit configuration.
function wand_service.apply_configuration(player, wand, desired, options)
    desired = type(desired) == "table" and desired or {}
    options = type(options) == "table" and options or {}
    local before, reason = wand_service.snapshot(wand)
    if before == nil then return false, reason end
    local stats = type(desired.stats) == "table" and desired.stats or {}
    local permanent_count = math.max(0, math.floor(tonumber(options.permanent_count) or before.permanent_actions or 0))

    for id, definition in pairs(DEFINITIONS) do
        if stats[id] ~= nil then
            local value = clamp_definition(definition, stats[id])
            if value == nil then restore_snapshot(before); return false, "invalid_" .. id end
            local raw_capacity = id == "slots" and value + permanent_count or nil
            if not write_definition(before.ability, definition, value, raw_capacity) then
                restore_snapshot(before); return false, "write_" .. id
            end
        end
    end
    for id, definition in pairs(BOOLEAN_DEFINITIONS) do
        if stats[id] ~= nil then
            local value = stats[id] == true
            local ok
            if definition.kind == "scalar" then ok = wand_api.set_scalar(before.ability, definition.field, value)
            else ok = wand_api.set_object(before.ability, definition.object, definition.field, value) end
            if not ok then restore_snapshot(before); return false, "write_" .. id end
        end
    end

    local sprite = desired.sprite_file
    if type(sprite) == "string" and sprite ~= "" then
        local exists = type(ModDoesFileExist) ~= "function" or ModDoesFileExist(sprite)
        if exists and not wand_api.set_scalar(before.ability, "sprite_file", sprite) then
            restore_snapshot(before); return false, "write_sprite"
        end
    end
    local mana = finite_number(desired.mana)
    if mana ~= nil then
        local mana_max = finite_number(stats.mana_max) or finite_number(before.stats.mana_max) or mana
        mana = math.max(0, math.min(mana, mana_max))
        if not wand_api.set_scalar(before.ability, "mana", mana) then restore_snapshot(before); return false, "write_mana" end
    end

    if options.skip_sync ~= true then sync(player) end
    return true, "ok"
end

function wand_service.refresh(player)
    sync(player)
end

function wand_service.definitions()
    return DEFINITIONS, BOOLEAN_DEFINITIONS
end

METAMORPH_CREATIVE_MENU_WAND_SERVICE = wand_service
return wand_service
