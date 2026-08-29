if type(METAMORPH_CREATIVE_MENU_WAND_BLUEPRINTS) == "table" then return METAMORPH_CREATIVE_MENU_WAND_BLUEPRINTS end

local blueprints = {}
local wand_service = dofile("mods/metamorph_creative_menu/files/features/wands/service.lua")
local appearance = dofile("mods/metamorph_creative_menu/files/features/wands/appearance.lua")
local spell_factory = dofile("mods/metamorph_creative_menu/files/features/spells/factory.lua")

local function valid(component) return component ~= nil and component ~= 0 end
local function alive(entity) return entity ~= nil and entity ~= 0 and EntityGetIsAlive(entity) == true end

local function action_children(wand)
    local result = {}
    for _, entity in ipairs(EntityGetAllChildren(wand) or {}) do
        local item = EntityGetFirstComponentIncludingDisabled(entity, "ItemComponent")
        local action = EntityGetFirstComponentIncludingDisabled(entity, "ItemActionComponent")
        if valid(item) and valid(action) then result[#result + 1] = {entity=entity,item=item,action=action} end
    end
    return result
end

local function read_optional(component, field)
    local ok, value = pcall(ComponentGetValue2, component, field)
    return ok and value or nil
end

local function permanent_count(blueprint)
    local count = 0
    for _, spec in ipairs(type(blueprint) == "table" and blueprint.spells or {}) do
        if spec.permanent == true then count = count + 1 end
    end
    return count
end

function blueprints.capture(wand)
    local snapshot, reason = wand_service.snapshot(wand)
    if snapshot == nil then return nil, reason end
    local visual = select(1, appearance.snapshot(wand))
    local blueprint = {
        version=2,
        stats={},
        mana=snapshot.mana,
        sprite_file=visual and visual.sprite_file or snapshot.sprite_file,
        meta={},
        spells={},
    }
    for id, value in pairs(snapshot.stats or {}) do blueprint.stats[id] = value end
    if visual ~= nil then
        blueprint.meta.name = visual.name
        blueprint.meta.show_name_in_ui = visual.show_name_in_ui == true
        blueprint.meta.wand_frozen = visual.wand_frozen == true
        blueprint.meta.image_file = visual.image_file
        blueprint.meta.sprite_offset_x = visual.offset_x
        blueprint.meta.sprite_offset_y = visual.offset_y
        blueprint.meta.tip_x = visual.tip_x
        blueprint.meta.tip_y = visual.tip_y
    end
    for _, record in ipairs(action_children(wand)) do
        local action_id = read_optional(record.action, "action_id")
        if type(action_id) == "string" and action_id ~= "" then
            local ok_slot, x, y = pcall(ComponentGetValue2, record.item, "inventory_slot")
            if not ok_slot then x, y = -1, 0 end
            local is_permanent = read_optional(record.item, "permanently_attached") == true
            blueprint.spells[#blueprint.spells + 1] = {
                action_id=action_id,
                slot=math.floor(tonumber(x) or -1),
                slot_y=math.floor(tonumber(y) or (is_permanent and -1 or 0)),
                permanent=is_permanent,
                uses_remaining=tonumber(read_optional(record.item, "uses_remaining")),
                frozen=read_optional(record.item, "is_frozen") == true,
            }
        end
    end
    table.sort(blueprint.spells, function(a,b)
        if a.permanent ~= b.permanent then return a.permanent == true end
        if a.slot_y ~= b.slot_y then return a.slot_y < b.slot_y end
        if a.slot ~= b.slot then return a.slot < b.slot end
        return a.action_id < b.action_id
    end)
    return blueprint, "ok"
end

local function configure_new_spell(spec)
    local entity, reason = spell_factory.create(spec.action_id)
    if entity == 0 then return nil, reason end
    local item = EntityGetFirstComponentIncludingDisabled(entity, "ItemComponent")
    local action = EntityGetFirstComponentIncludingDisabled(entity, "ItemActionComponent")
    if not valid(item) or not valid(action) then pcall(EntityKill, entity); return nil, "components_missing" end
    local slot_x = spec.permanent == true and -1 or math.max(0, math.floor(tonumber(spec.slot) or 0))
    local slot_y = spec.permanent == true and -1 or math.max(0, math.floor(tonumber(spec.slot_y) or 0))
    local writes = {
        {"inventory_slot",slot_x,slot_y},
        {"permanently_attached",spec.permanent == true},
        {"has_been_picked_by_player",true},
    }
    for _, write in ipairs(writes) do
        local ok
        if write[3] ~= nil then ok = pcall(ComponentSetValue2, item, write[1], write[2], write[3])
        else ok = pcall(ComponentSetValue2, item, write[1], write[2]) end
        if not ok then pcall(EntityKill, entity); return nil, "configure_failed" end
    end
    if spec.uses_remaining ~= nil and not pcall(ComponentSetValue2, item, "uses_remaining", spec.uses_remaining) then
        pcall(EntityKill, entity); return nil, "uses_write_failed"
    end
    if spec.frozen ~= nil and not pcall(ComponentSetValue2, item, "is_frozen", spec.frozen == true) then
        pcall(EntityKill, entity); return nil, "freeze_write_failed"
    end
    return {entity=entity,item=item,action=action,spec=spec}, "ok"
end

local function cleanup_new(records)
    for _, record in ipairs(records or {}) do
        if alive(record.entity) then
            pcall(EntityRemoveFromParent, record.entity)
            pcall(EntityKill, record.entity)
        end
    end
end

local function attach_verified(wand, record)
    local ok = pcall(EntityAddChild, wand, record.entity)
    if not ok then return false end
    if type(EntityGetParent) == "function" then
        local read, parent = pcall(EntityGetParent, record.entity)
        if not read or tonumber(parent) ~= tonumber(wand) then return false end
    end
    local read, action_id = pcall(ComponentGetValue2, record.action, "action_id")
    return read and tostring(action_id or "") == tostring(record.spec.action_id or "")
end

local function restore_old(wand, detached)
    for _, record in ipairs(detached or {}) do
        if alive(record.entity) then pcall(EntityAddChild, wand, record.entity) end
    end
end

local function restore_card_runtime(records)
    for _, record in ipairs(records or {}) do
        local spec = record.spec
        if alive(record.entity) then
            if spec.uses_remaining ~= nil then pcall(ComponentSetValue2, record.item, "uses_remaining", spec.uses_remaining) end
            if spec.frozen ~= nil then pcall(ComponentSetValue2, record.item, "is_frozen", spec.frozen == true) end
        end
    end
end

local function apply_non_spell_state(player, wand, blueprint, skip_sync)
    local ok, reason = wand_service.apply_configuration(player, wand, {
        stats=blueprint.stats or {}, mana=blueprint.mana,
    }, {permanent_count=permanent_count(blueprint),skip_sync=true})
    if not ok then return false, reason end
    local visual_ok, visual_reason = appearance.apply(player, wand, blueprint, {skip_sync=true})
    if not visual_ok then return false, visual_reason end
    if skip_sync ~= true then wand_service.refresh(player) end
    return true, "ok"
end

local function rollback(player, wand, before, old_records, prepared)
    cleanup_new(prepared)
    restore_old(wand, old_records)
    pcall(apply_non_spell_state, player, wand, before, true)
    if type(GameRegenItemActionsInContainer) == "function" then pcall(GameRegenItemActionsInContainer, wand) end
    if type(GameRegenItemActionsInPlayer) == "function" then pcall(GameRegenItemActionsInPlayer, player) end
    if before.mana ~= nil then
        pcall(wand_service.apply_configuration, player, wand, {stats={},mana=before.mana},
            {permanent_count=permanent_count(before),skip_sync=true})
    end
    wand_service.refresh(player)
end

function blueprints.apply(player, wand, blueprint)
    if type(blueprint) ~= "table" or type(blueprint.spells) ~= "table" or type(blueprint.stats) ~= "table" then
        return false, "invalid_blueprint"
    end
    blueprint.meta = type(blueprint.meta) == "table" and blueprint.meta or {}
    local before, reason = blueprints.capture(wand)
    if before == nil then return false, reason end
    local old = action_children(wand)
    local highest_requested = -1
    for _, spec in ipairs(blueprint.spells) do
        if type(spec.action_id) ~= "string" or spec.action_id == "" then return false, "invalid_spell" end
        if spec.permanent ~= true then
            local slot = math.floor(tonumber(spec.slot) or -1)
            if slot < 0 then return false, "invalid_slot" end
            highest_requested = math.max(highest_requested, slot)
        end
    end
    local max_slots = type(wand_service.max_slots) == "function" and wand_service.max_slots() or 64
    if highest_requested >= max_slots then return false, "invalid_capacity" end
    if tonumber(blueprint.stats.slots) ~= nil then
        local requested_capacity = tonumber(blueprint.stats.slots)
        if requested_capacity < highest_requested + 1 or requested_capacity > max_slots then
            return false, "invalid_capacity"
        end
    end

    local prepared = {}
    for _, spec in ipairs(blueprint.spells) do
        local record, prepare_reason = configure_new_spell(spec)
        if record == nil then cleanup_new(prepared); return false, prepare_reason end
        prepared[#prepared + 1] = record
    end
    for _, record in ipairs(prepared) do
        if not attach_verified(wand, record) then cleanup_new(prepared); return false, "attach_failed" end
        if type(EntitySetComponentsWithTagEnabled) == "function" then
            pcall(EntitySetComponentsWithTagEnabled, record.entity, "enabled_in_world", false)
        end
    end

    local detached = {}
    for _, record in ipairs(old) do
        local ok = pcall(EntityRemoveFromParent, record.entity)
        local parent_ok = ok
        if ok and type(EntityGetParent) == "function" then
            local read, parent = pcall(EntityGetParent, record.entity)
            parent_ok = read and tonumber(parent) == 0
        end
        if not parent_ok then
            cleanup_new(prepared)
            restore_old(wand, detached)
            return false, "old_detach_failed"
        end
        detached[#detached + 1] = record
    end

    local config_ok, config_reason = apply_non_spell_state(player, wand, blueprint, true)
    if not config_ok then
        rollback(player, wand, before, detached, prepared)
        return false, config_reason
    end

    -- Regeneration makes Noita rebuild the action view. Mutable card state is restored
    -- afterwards so loading a blueprint cannot silently refill limited-use cards.
    if type(GameRegenItemActionsInContainer) == "function" then pcall(GameRegenItemActionsInContainer, wand) end
    if type(GameRegenItemActionsInPlayer) == "function" then pcall(GameRegenItemActionsInPlayer, player) end
    restore_card_runtime(prepared)
    if blueprint.mana ~= nil then
        local mana_ok, mana_reason = wand_service.apply_configuration(player, wand, {stats={},mana=blueprint.mana},
            {permanent_count=permanent_count(blueprint),skip_sync=true})
        if not mana_ok then
            rollback(player, wand, before, detached, prepared)
            return false, mana_reason
        end
    end

    for _, record in ipairs(detached) do if alive(record.entity) then pcall(EntityKill, record.entity) end end
    wand_service.refresh(player)
    return true, "loaded"
end

METAMORPH_CREATIVE_MENU_WAND_BLUEPRINTS = blueprints
return blueprints
