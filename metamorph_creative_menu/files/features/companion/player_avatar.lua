if type(METAMORPH_CREATIVE_MENU_PLAYER_AVATAR) == "table" then return METAMORPH_CREATIVE_MENU_PLAYER_AVATAR end

local player_avatar = {}
local ew_runtime = dofile("mods/metamorph_creative_menu/files/integrations/ew/runtime.lua")
local companion_request = dofile("mods/metamorph_creative_menu/files/integrations/ew/companion_request.lua")
local CLONE_PATH = "mods/metamorph_creative_menu/files/features/companion/player_clone.xml"
local WAND_FALLBACK = "data/entities/items/wand_level_01.xml"
local companion_health = dofile("mods/metamorph_creative_menu/files/features/companion/health.lua")
local pending_health_guards = {}

local function valid(entity)
    return entity ~= nil and entity ~= 0 and EntityGetIsAlive(entity)
end

local function first_component(entity, component_type, tag)
    local ok, component = pcall(EntityGetFirstComponentIncludingDisabled, entity, component_type, tag)
    return ok and component ~= nil and component ~= 0 and component or nil
end

local function copy_scalar(source, target, field)
    if source == nil or target == nil then return false end
    local ok, value = pcall(ComponentGetValue2, source, field)
    if not ok or value == nil then return false end
    return pcall(ComponentSetValue2, target, field, value)
end

local function copy_object_scalar(source, target, object, field)
    if source == nil or target == nil then return false end
    local ok, value = pcall(ComponentObjectGetValue2, source, object, field)
    if not ok or value == nil then return false end
    return pcall(ComponentObjectSetValue2, target, object, field, value)
end

local function copy_health(player, clone)
    local source = first_component(player, "DamageModelComponent")
    local target = first_component(clone, "DamageModelComponent")
    if source == nil or target == nil then return nil, nil end
    local hp = tonumber(ComponentGetValue2(source, "hp")) or 1
    local max_hp = math.max(0.04, tonumber(ComponentGetValue2(source, "max_hp")) or hp)
    local source_cap = tonumber(ComponentGetValue2(source, "max_hp_cap")) or 0
    -- DamageModel clamps max_hp to max_hp_cap. The clone XML's vanilla cap can be 1,
    -- so copy/raise the cap before max_hp or a 4 HP owner becomes a 1/1 companion.
    local target_cap = source_cap > 0 and math.max(source_cap, max_hp) or max_hp
    pcall(ComponentSetValue2, target, "max_hp_cap", target_cap)
    pcall(ComponentSetValue2, target, "max_hp", max_hp)
    -- A spawned companion starts as a fresh ally: inherit the owner's maximum HP,
    -- but do not inherit the owner's current wounds.
    pcall(ComponentSetValue2, target, "hp", max_hp)
    return max_hp, max_hp
end

local function named_child(parent, wanted)
    wanted = string.lower(tostring(wanted or ""))
    for _, child in ipairs(EntityGetAllChildren(parent) or {}) do
        if string.lower(tostring(EntityGetName(child) or "")) == wanted then return child end
    end
    return 0
end

local function enabled_sprite(entity, wanted_tag)
    if not valid(entity) then return nil end
    for _, sprite in ipairs(EntityGetComponentIncludingDisabled(entity, "SpriteComponent") or {}) do
        local tags = "," .. tostring(ComponentGetTags(sprite) or "") .. ","
        local tagged = wanted_tag == nil or string.find(tags, "," .. wanted_tag .. ",", 1, true) ~= nil
        if tagged and ComponentGetIsEnabled(sprite) then return sprite end
    end
    return nil
end

local function copy_visuals(player, clone)
    local body_source = enabled_sprite(player, "character")
    local body_target = enabled_sprite(clone, "character")
    for _, field in ipairs({"image_file", "offset_x", "offset_y", "alpha", "special_scale_x", "special_scale_y", "has_special_scale"}) do
        copy_scalar(body_source, body_target, field)
    end

    local source_arm = named_child(player, "arm_r")
    local target_arm = named_child(clone, "arm_r")
    local arm_source = enabled_sprite(source_arm, "with_item") or enabled_sprite(source_arm)
    local arm_target = enabled_sprite(target_arm, "with_item") or enabled_sprite(target_arm)
    for _, field in ipairs({"image_file", "alpha", "special_scale_x", "special_scale_y", "has_special_scale"}) do
        copy_scalar(arm_source, arm_target, field)
    end
end

local function human_blueprint(player, x, y)
    local manager = dofile("mods/metamorph_creative_menu/files/features/forms/manager.lua")
    local active_form = type(manager.has_active_form) == "function" and manager.has_active_form()
    if not active_form and not EntityHasTag(player, "polymorphed_player") then return player, false end
    -- A host may be spawning a companion for a remote peer. Its local form session
    -- belongs only to the host and must never be used as that peer's appearance.
    if type(manager.current_player) ~= "function" or manager.current_player() ~= player then
        return player, false
    end
    local backup = type(manager.original_player_backup) == "function" and manager.original_player_backup() or nil
    if type(backup) ~= "string" or backup == "" or type(np) ~= "table"
        or type(np.DeserializeEntity) ~= "function" or type(EntityCreateNew) ~= "function"
    then return player, false end
    local source = EntityCreateNew("metamorph_creative_menu_clone_blueprint") or 0
    if source == 0 then return player, false end
    local ok = pcall(np.DeserializeEntity, source, backup, x, y)
    if not ok or not valid(source) then
        if valid(source) then EntityKill(source) end
        return player, false
    end
    -- This source lives for only this function call. Strip every ownership marker
    -- before reading it so EW and the HUD can never observe another player entity.
    for _, tag in ipairs({"player_unit", "ew_notplayer", "ew_peer", "ew_client"}) do
        EntityRemoveTag(source, tag)
    end
    for _, kind in ipairs({"AudioListenerComponent", "InventoryGuiComponent", "PlatformShooterPlayerComponent"}) do
        for _, component in ipairs(EntityGetComponentIncludingDisabled(source, kind) or {}) do
            pcall(EntitySetComponentIsEnabled, source, component, false)
        end
    end
    return source, true
end

local function active_wand(player)
    local inventory = first_component(player, "Inventory2Component")
    if inventory == nil then return 0 end
    for _, field in ipairs({"mActiveItem", "mActualActiveItem"}) do
        local ok, item = pcall(ComponentGetValue2, inventory, field)
        if ok and valid(item) then
            if EntityHasTag(item, "wand") then return item end
            local ability = first_component(item, "AbilityComponent")
            local ok_gun, use_gun_script = pcall(ComponentGetValue2, ability, "use_gun_script")
            if ok_gun and use_gun_script == true then return item end
        end
    end
    return 0
end

local function disable_procedural_initializers(wand)
    for _, component in ipairs(EntityGetComponentIncludingDisabled(wand, "LuaComponent") or {}) do
        local source = tostring(ComponentGetValue2(component, "script_source_file") or "")
        if string.find(source, "/gun/procedural/", 1, true) then
            pcall(EntitySetComponentIsEnabled, wand, component, false)
        end
    end
end

local function clear_action_children(wand)
    for _, child in ipairs(EntityGetAllChildren(wand) or {}) do
        if first_component(child, "ItemActionComponent") ~= nil then EntityKill(child) end
    end
end

local function deserialize_wand(source, x, y)
    if type(np) ~= "table" or type(np.SerializeEntity) ~= "function"
        or type(np.DeserializeEntity) ~= "function" or type(EntityCreateNew) ~= "function"
    then return 0 end
    local ok_data, data = pcall(np.SerializeEntity, source)
    if not ok_data or data == nil then return 0 end
    local target = EntityCreateNew("metamorph_creative_menu_clone_wand") or 0
    if target == 0 then return 0 end
    local ok = pcall(np.DeserializeEntity, target, data, x, y)
    if not ok or not valid(target) then
        if valid(target) then EntityKill(target) end
        return 0
    end
    -- A clone must never reuse the source item's EW network identity.
    for _, value in ipairs(EntityGetComponentIncludingDisabled(target, "VariableStorageComponent") or {}) do
        if ComponentGetValue2(value, "name") == "ew_gid_lid" then
            pcall(ComponentSetValue2, value, "value_bool", false)
        end
    end
    return target
end

local function copy_actions(source, target)
    local count = 0
    for _, child in ipairs(EntityGetAllChildren(source) or {}) do
        local action = first_component(child, "ItemActionComponent")
        local action_id = action and tostring(ComponentGetValue2(action, "action_id") or "") or ""
        if action_id ~= "" then
            local created = CreateItemActionEntity(action_id, 0, 0) or 0
            if created ~= 0 then
                local source_item = first_component(child, "ItemComponent")
                local target_item = first_component(created, "ItemComponent")
                if source_item ~= nil and target_item ~= nil then
                    local ok, slot_x, slot_y = pcall(ComponentGetValue2, source_item, "inventory_slot")
                    if ok then pcall(ComponentSetValue2, target_item, "inventory_slot", slot_x, slot_y) end
                    for _, field in ipairs({"uses_remaining", "permanently_attached"}) do
                        copy_scalar(source_item, target_item, field)
                    end
                end
                EntityAddChild(target, created)
                EntitySetComponentsWithTagEnabled(created, "enabled_in_world", false)
                count = count + 1
            end
        end
    end
    return count
end

local function copy_wand(source, x, y)
    if not valid(source) then return 0, 0 end
    local exact = deserialize_wand(source, x, y)
    if exact ~= 0 then
        EntityAddTag(exact, "metamorph_creative_menu_clone_wand")
        local count = 0
        for _, child in ipairs(EntityGetAllChildren(exact) or {}) do
            if first_component(child, "ItemActionComponent") ~= nil then count = count + 1 end
        end
        return exact, count
    end
    local path = tostring(EntityGetFilename(source) or "")
    if path == "" or not ModDoesFileExist(path) then path = WAND_FALLBACK end
    local target = EntityLoad(path, x, y) or 0
    if target == 0 then return 0, 0 end
    disable_procedural_initializers(target)

    local source_ability = first_component(source, "AbilityComponent")
    local target_ability = first_component(target, "AbilityComponent")
    for _, field in ipairs({
        "mana", "mana_max", "mana_charge_speed", "item_recoil_recovery_speed",
        "use_gun_script", "ui_name", "sprite_file", "throw_as_item"
    }) do copy_scalar(source_ability, target_ability, field) end
    for _, field in ipairs({"shuffle_deck_when_empty", "actions_per_round", "deck_capacity", "reload_time"}) do
        copy_object_scalar(source_ability, target_ability, "gun_config", field)
    end
    for _, field in ipairs({"fire_rate_wait", "spread_degrees", "speed_multiplier"}) do
        copy_object_scalar(source_ability, target_ability, "gunaction_config", field)
    end

    local source_sprite = first_component(source, "SpriteComponent", "item") or first_component(source, "SpriteComponent")
    local target_sprite = first_component(target, "SpriteComponent", "item") or first_component(target, "SpriteComponent")
    for _, field in ipairs({"image_file", "rect_animation", "offset_x", "offset_y", "special_scale_x", "special_scale_y", "has_special_scale"}) do
        copy_scalar(source_sprite, target_sprite, field)
    end

    clear_action_children(target)
    local actions = copy_actions(source, target)
    EntityAddTag(target, "metamorph_creative_menu_clone_wand")
    return target, actions
end

local function named_inventory(player, wanted)
    for _, child in ipairs(EntityGetAllChildren(player) or {}) do
        if EntityGetName(child) == wanted then return child end
    end
    return 0
end

local function equip_wand(player, clone, x, y)
    local source = active_wand(player)
    if source == 0 then return false, 0, "no_active_wand" end
    local wand, actions = copy_wand(source, x, y)
    if wand == 0 then return false, actions, "wand_copy" end
    local quick = named_inventory(clone, "inventory_quick")
    local item = first_component(wand, "ItemComponent")
    local inv2 = first_component(clone, "Inventory2Component")
    if quick == 0 or item == nil or inv2 == nil then
        EntityKill(wand); return false, actions, "inventory_components"
    end
    if EntityGetParent(wand) ~= 0 then EntityRemoveFromParent(wand) end
    EntityAddChild(quick, wand)
    ComponentSetValue2(item, "inventory_slot", 0, 0)
    EntitySetComponentsWithTagEnabled(wand, "enabled_in_world", false)
    EntitySetComponentsWithTagEnabled(wand, "enabled_in_inventory", false)
    EntitySetComponentsWithTagEnabled(wand, "enabled_in_hand", true)
    ComponentSetValue2(inv2, "mItemHolstered", false)
    ComponentSetValue2(inv2, "mActiveItem", wand)
    ComponentSetValue2(inv2, "mActualActiveItem", wand)
    ComponentSetValue2(inv2, "mForceRefresh", true)
    if type(np) == "table" and type(np.SetActiveHeldEntity) == "function" then
        pcall(np.SetActiveHeldEntity, clone, wand, false, false)
    end
    if EntityGetParent(wand) == quick then return true, actions, "exact_inventory" end
    if valid(wand) then EntityKill(wand) end
    return false, actions, "inventory_attach"
end

local function build_clone(player, x, y)
    local clone = EntityLoad(CLONE_PATH, x, y) or 0
    if clone == 0 then return 0, "load" end
    if type(GenomeSetHerdId) == "function" then pcall(GenomeSetHerdId, clone, "player") end
    local genome = first_component(clone, "GenomeDataComponent")
    if genome ~= nil then pcall(ComponentSetValue2, genome, "herd_id", "player") end
    local inv2 = first_component(clone, "Inventory2Component")
    if inv2 ~= nil then pcall(ComponentSetValue2, inv2, "quick_inventory_slots", 8) end
    for _, script in ipairs(EntityGetComponentIncludingDisabled(clone, "LuaComponent") or {}) do
        if not ComponentHasTag(script, "metamorph_creative_menu_companion_ai") then
            EntitySetComponentIsEnabled(clone, script, false)
        end
    end
    EntityAddComponent2(clone, "VariableStorageComponent", {
        _tags="mcm_companion_owner", name="mcm_companion_owner", value_int=player,
    })
    EntityAddComponent2(clone, "VariableStorageComponent", {
        _tags="mcm_companion_target", name="mcm_companion_target", value_int=0,
    })
    local source, temporary = human_blueprint(player, x, y)
    copy_health(source, clone)
    copy_visuals(source, clone)
    equip_wand(source, clone, x, y)
    -- Record the intended health after construction. The companion controller guards
    -- this value briefly because base_humanoid can perform a later XML initialization.
    local _, final_max = copy_health(source, clone)
    if tonumber(final_max) ~= nil and final_max > 0 then
        EntityAddComponent2(clone, "VariableStorageComponent", {
            _tags="mcm_companion_health_target", name="mcm_companion_health_target",
            value_float=final_max, value_int=GameGetFrameNum(), value_bool=false,
        })
    end
    EntityAddComponent2(clone, "LuaComponent", {
        _tags="mcm_companion_spawn_guard",
        script_source_file="mods/metamorph_creative_menu/files/features/companion/spawn_guard.lua",
        execute_on_added=true,
        execute_every_n_frame=1,
        remove_after_executed=false,
    })
    -- Main-context clones also get a lifecycle-level guard. This is intentionally the
    -- same companion_health.repair() implementation as the per-entity component above,
    -- not a second health algorithm. It closes the real-engine case where a dynamically
    -- added LuaComponent is scheduled too late to beat base_humanoid's 1/1 clamp.
    pending_health_guards[clone] = true
    if temporary and valid(source) then EntityKill(source) end
    return clone, "ok"
end

function player_avatar.spawn_visual_copy(player, offset_x, offset_y)
    if not valid(player) or not ModDoesFileExist(CLONE_PATH) then return 0 end
    local px, py = EntityGetTransform(player)
    if px == nil then return 0 end
    local ok, clone = xpcall(function()
        return build_clone(player, px + (offset_x or 32), py + (offset_y or -4))
    end, function(err)
        return type(debug) == "table" and type(debug.traceback) == "function" and debug.traceback(tostring(err), 2) or tostring(err)
    end)
    if not ok then
        return 0
    end
    return clone or 0
end


function player_avatar.update()
    for clone in pairs(pending_health_guards) do
        if not valid(clone) then
            pending_health_guards[clone] = nil
        else
            local _, finished = companion_health.repair(clone)
            if finished then pending_health_guards[clone] = nil end
        end
    end
end

function player_avatar.request_spawn(player, offset_x, offset_y)
    if ew_runtime.mode() ~= "client" then
        return player_avatar.spawn_visual_copy(player, offset_x, offset_y) ~= 0, "local"
    end
    return companion_request.enqueue(offset_x, offset_y)
end

METAMORPH_CREATIVE_MENU_PLAYER_AVATAR = player_avatar
return player_avatar
