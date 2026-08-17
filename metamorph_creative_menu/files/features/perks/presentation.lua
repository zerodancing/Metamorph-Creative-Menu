if type(METAMORPH_CREATIVE_MENU_PERK_PRESENTATION) == "table" then return METAMORPH_CREATIVE_MENU_PERK_PRESENTATION end

local presentation = {}
local pending_cleanup = dofile("mods/metamorph_creative_menu/files/features/perks/transactions/pending_cleanup.lua")

-- Presentation is intentionally separate from semantic perk rollback. It owns only
-- transient/UI residue: GameEffect lifetime, perk icons, particles and a short
-- zero-count maintenance window for effects that Noita can recreate a few frames late.

local ZERO_PRESENTATION_IDS = {
    PROTECTION_ELECTRICITY = true,
    PROTECTION_RADIOACTIVITY = true,
}

local maintenance_by_perk_id = {}
local perk_data_cache = {}

local function effect_name(component)
    local effect_id = tostring(ComponentGetValue2(component, "effect") or "")
    if effect_id == "CUSTOM" then
        return tostring(ComponentGetValue2(component, "custom_effect_id") or "")
    end
    return effect_id
end

local function walk_children(root_entity, visitor)
    local queue, index = { root_entity }, 1
    while index <= #queue do
        local current_entity = queue[index]
        index = index + 1
        for _, child_entity in ipairs(EntityGetAllChildren(current_entity) or {}) do
            queue[#queue + 1] = child_entity
            visitor(child_entity)
        end
    end
end

local function icon_matches(component, perk)
    local wanted_name = tostring(perk.ui_name or "")
    local wanted_icon = tostring(perk.ui_icon or "")
    local actual_name = tostring(ComponentGetValue2(component, "name") or "")
    local actual_icon = tostring(ComponentGetValue2(component, "icon_sprite_file") or "")

    if wanted_name ~= "" and wanted_icon ~= "" then
        return actual_name == wanted_name and actual_icon == wanted_icon
    elseif wanted_name ~= "" then
        return actual_name == wanted_name
    elseif wanted_icon ~= "" then
        return actual_icon == wanted_icon
    end
    return false
end

local function remove_matching_icons(player_entity, perk, require_perk_owner_tag)
    local victims = {}
    walk_children(player_entity, function(child_entity)
        if not require_perk_owner_tag or EntityHasTag(child_entity, "perk_entity") then
            local icon_component = EntityGetFirstComponentIncludingDisabled(child_entity, "UIIconComponent")
            if icon_component ~= nil and icon_component ~= 0 and icon_matches(icon_component, perk) then
                victims[#victims + 1] = child_entity
            end
        end
    end)
    for _, child_entity in ipairs(victims) do
        if EntityGetIsAlive(child_entity) then EntityKill(child_entity) end
    end
    return #victims
end

local function retire_all_game_effects(player_entity, wanted_effect_id, require_perk_owner_tag)
    if type(wanted_effect_id) ~= "string" or wanted_effect_id == "" then return 0 end
    local changed = 0
    walk_children(player_entity, function(child_entity)
        if not require_perk_owner_tag or EntityHasTag(child_entity, "perk_entity") then
            local effect_component = EntityGetFirstComponentIncludingDisabled(child_entity, "GameEffectComponent")
            if effect_component ~= nil and effect_component ~= 0 and effect_name(effect_component) == wanted_effect_id then
                -- Disable the exact GameEffect immediately so its gameplay/visual state
                -- cannot survive while Noita waits until end-of-frame to destroy entity.
                if type(EntitySetComponentIsEnabled) == "function" then
                    pcall(EntitySetComponentIsEnabled, child_entity, effect_component, false)
                end
                pending_cleanup.retire_entity(child_entity, "presentation:" .. wanted_effect_id)
                changed = changed + 1
            end
        end
    end)
    return changed
end

local function perk_data_by_id(perk_id)
    if perk_data_cache[perk_id] ~= nil then
        return perk_data_cache[perk_id] ~= false and perk_data_cache[perk_id] or nil
    end
    pcall(dofile_once, "data/scripts/perks/perk_list.lua")
    for _, perk in ipairs(type(perk_list) == "table" and perk_list or {}) do
        if type(perk) == "table" and perk.id == perk_id then
            perk_data_cache[perk_id] = perk
            return perk
        end
    end
    perk_data_cache[perk_id] = false
    return nil
end

local function remove_particle_if_last(player_entity, perk)
    if type(perk.particle_effect) ~= "string" or perk.particle_effect == "" then return end
    local particle_filename = "data/entities/particles/perks/" .. perk.particle_effect .. ".xml"
    for _, child_entity in ipairs(EntityGetAllChildren(player_entity) or {}) do
        if EntityHasTag(child_entity, "perk_entity") and EntityGetFilename(child_entity) == particle_filename then
            EntityKill(child_entity)
        end
    end
end

function presentation.expire_one_game_effect(player_entity, wanted_effect_id)
    if type(wanted_effect_id) ~= "string" or wanted_effect_id == "" then return false end
    -- Only perk-owned effects are eligible here. Potion/status/mod effects with the same
    -- GameEffect id are independent state and must survive removal of this perk.
    local matching_entity = nil
    walk_children(player_entity, function(child_entity)
        if matching_entity == nil and EntityHasTag(child_entity, "perk_entity") then
            local effect_component = EntityGetFirstComponentIncludingDisabled(child_entity, "GameEffectComponent")
            if effect_component ~= nil and effect_component ~= 0 and effect_name(effect_component) == wanted_effect_id then
                matching_entity = child_entity
                if type(EntitySetComponentIsEnabled) == "function" then
                    pcall(EntitySetComponentIsEnabled, child_entity, effect_component, false)
                end
            end
        end
    end)
    if matching_entity ~= nil then
        return select(1, pending_cleanup.retire_entity(matching_entity, "presentation_one:" .. wanted_effect_id)) == true
    end
    return false
end

function presentation.on_count_zero(player_entity, perk)
    remove_particle_if_last(player_entity, perk)

    -- Count zero is authoritative. Remove every exact declared effect, including
    -- orphan duplicates left by an older build or a double pickup event.
    local require_perk_owner_tag = perk.id == "INVISIBILITY" or not ZERO_PRESENTATION_IDS[perk.id]
    retire_all_game_effects(player_entity, perk.game_effect, require_perk_owner_tag)
    retire_all_game_effects(player_entity, perk.game_effect2, require_perk_owner_tag)

    -- Some vanilla perks put UIIconComponent and GameEffectComponent on the same
    -- perk_entity; RESPAWN can also create an icon without the perk_entity tag. At
    -- count zero matching the exact UI metadata is safe and removes that residue.
    remove_matching_icons(player_entity, perk, false)

    if perk.id == "INVISIBILITY" or ZERO_PRESENTATION_IDS[perk.id]
        or perk.id == "ANGRY_GHOST" or perk.id == "HUNGRY_GHOST" or perk.id == "DEATH_GHOST" then
        maintenance_by_perk_id[perk.id] = {
            until_frame = (tonumber(GameGetFrameNum()) or 0) + (perk.id == "INVISIBILITY" and 45 or 180),
            player_entity = player_entity,
            perk = perk,
        }
    end
end

function presentation.rebind_player(old_player_entity_id, new_player_entity_id)
    if old_player_entity_id == new_player_entity_id then return true end
    for _, record in pairs(maintenance_by_perk_id) do
        if type(record) == "table" and tonumber(record.player_entity) == tonumber(old_player_entity_id) then
            record.player_entity = new_player_entity_id
        end
    end
    return true
end

function presentation.update(player_entity, count_for_perk, semantic_maintenance_cleanup)
    local frame = tonumber(GameGetFrameNum()) or 0
    for perk_id, record in pairs(maintenance_by_perk_id) do
        local owner_entity = tonumber(record.player_entity) or 0
        if frame > (tonumber(record.until_frame) or 0)
            or count_for_perk(perk_id) > 0
            or owner_entity == 0 or not EntityGetIsAlive(owner_entity)
            or player_entity ~= owner_entity or EntityHasTag(owner_entity, "polymorphed_player") then
            maintenance_by_perk_id[perk_id] = nil
        else
            local perk = record.perk or perk_data_by_id(perk_id)
            if type(perk) == "table" then
                -- Repeated maintenance is stricter than immediate count-zero cleanup:
                -- only perk-owned entities may be touched so unrelated potion/mod UI
                -- that happens to use the same sprite remains intact.
                retire_all_game_effects(owner_entity, perk.game_effect, true)
                retire_all_game_effects(owner_entity, perk.game_effect2, true)
                remove_matching_icons(owner_entity, perk, true)
            end
            if type(semantic_maintenance_cleanup) == "function" then
                semantic_maintenance_cleanup(owner_entity, perk_id)
            end
        end
    end

    -- Repair residue from older sessions where entity-less perk_pickup applied an
    -- immunity presentation but no removable pickup count was maintained.
    if frame % 30 == 0 then
        for perk_id in pairs(ZERO_PRESENTATION_IDS) do
            if count_for_perk(perk_id) <= 0 then
                local perk = perk_data_by_id(perk_id)
                if type(perk) == "table" then
                    retire_all_game_effects(player_entity, perk.game_effect, true)
                    retire_all_game_effects(player_entity, perk.game_effect2, true)
                    remove_matching_icons(player_entity, perk, true)
                end
            end
        end
    end
end

function presentation.is_zero_presentation_perk(perk_id)
    return ZERO_PRESENTATION_IDS[perk_id] == true
end

METAMORPH_CREATIVE_MENU_PERK_PRESENTATION = presentation
return presentation
