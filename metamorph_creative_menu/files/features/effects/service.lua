local existing_effect_service = METAMORPH_CREATIVE_MENU_EFFECT_SERVICE or METAMORPH_CREATIVE_MENU_EFFECT_EDITOR
if type(existing_effect_service) == "table" then return existing_effect_service end

local effect_service = {}
local effect_catalog = dofile("mods/metamorph_creative_menu/files/features/effects/catalog.lua")
local RESERVED_EFFECTS = effect_catalog.reserved_effects()
local pending_expiry = {}
local pending_status_expiry = {}
local owned_statuses = {}
local matches_entry

local function valid_player(player)
    return player ~= nil and player ~= 0 and EntityGetIsAlive(player)
end

function effect_service.catalog()
    return effect_catalog.entries()
end

local function status_vector_value(player, entry)
    local comp = EntityGetFirstComponentIncludingDisabled(player, "StatusEffectDataComponent")
    if comp == nil or comp == 0 then return 0 end
    local values = ComponentGetValue2(comp, "stain_effects")
    local index = (tonumber(entry.status_index) or 0) + 1
    if type(values) ~= "table" or index < 2 or index > #values then return 0 end
    return tonumber(values[index]) or 0
end

local function status_owner_key(entry)
    return tostring(entry and (entry.id or entry.game_effect or entry.custom_effect_id or entry.path) or "")
end

local function mark_owned_status(player, entry)
    local key = status_owner_key(entry)
    if key == "" then return end
    owned_statuses[player] = owned_statuses[player] or {}
    owned_statuses[player][key] = true
end

local function owns_status(player, entry)
    local key = status_owner_key(entry)
    return key ~= "" and owned_statuses[player] ~= nil and owned_statuses[player][key] == true
end

local function schedule_status_expiry(player, entry)
    if not owns_status(player, entry) then return end
    local key = tostring(player) .. "|" .. status_owner_key(entry)
    pending_status_expiry[key] = { player=player, entry=entry, started=GameGetFrameNum() }
end

local function add_surface_status(player, entry)
    local material = entry.material
    if type(material) == "string" and material ~= "" then
        local ok_type, material_type = pcall(CellFactory_GetType, material)
        if ok_type and material_type ~= nil and tonumber(material_type) ~= nil and tonumber(material_type) >= 0 then
            -- StatusEffectDataComponent is refreshed by the material system after the
            -- Lua callback. Requiring same-frame vector readback falsely reported e.g.
            -- BLOODY as failed even though the stain appeared on the next update.
            local ok_stain = pcall(EntityAddRandomStains, player, material_type, 400)
            return ok_stain
        end
    end
    return false
end

local function game_effect_name(entity)
    local comp = EntityGetFirstComponentIncludingDisabled(entity, "GameEffectComponent")
    if comp == nil or comp == 0 then return "" end
    local effect = tostring(ComponentGetValue2(comp, "effect") or "")
    if effect == "CUSTOM" then return tostring(ComponentGetValue2(comp, "custom_effect_id") or "") end
    return effect
end

local function apply_game_effect(player, entry, frames)
    if type(entry.path) ~= "string" or entry.path == "" or not ModDoesFileExist(entry.path) then return false, "missing" end
    local ok, effect_entity = pcall(LoadGameEffectEntityTo, player, entry.path)
    if not ok or effect_entity == nil or effect_entity == 0 then return false, "load" end
    EntityAddTag(effect_entity, "metamorph_creative_menu_effect")
    local comp = EntityGetFirstComponentIncludingDisabled(effect_entity, "GameEffectComponent")
    if comp ~= nil and comp ~= 0 then
        local duration = tonumber(frames)
        if duration ~= nil then pcall(ComponentSetValue2, comp, "frames", duration < 0 and -1 or math.max(1, math.floor(duration))) end
    end

    -- Use Noita's own right-side HUD rather than a second mod-owned timer panel. A
    -- UIIconComponent on the same child entity as GameEffectComponent is the standard
    -- presentation path; the GameEffect frames remain the single source of duration.
    local icon = EntityGetFirstComponentIncludingDisabled(effect_entity, "UIIconComponent")
    if icon == nil or icon == 0 then
        local ok_icon, created = pcall(EntityAddComponent2, effect_entity, "UIIconComponent", {
            icon_sprite_file = tostring(entry.icon or ""),
            name = tostring(entry.display_name or entry.id or ""),
            description = tostring(entry.display_description or ""),
            display_in_hud = true,
            display_above_head = false,
            is_perk = false,
        })
        if ok_icon then icon = created end
    elseif icon ~= nil and icon ~= 0 then
        pcall(ComponentSetValue2, icon, "display_in_hud", true)
        pcall(ComponentSetValue2, icon, "is_perk", false)
        if tostring(entry.icon or "") ~= "" then pcall(ComponentSetValue2, icon, "icon_sprite_file", tostring(entry.icon)) end
    end
    return true, game_effect_name(effect_entity)
end

function effect_service.add(player, entry, frames)
    if not valid_player(player) or type(entry) ~= "table" then return false, "target" end
    if entry.kind == "status" then
        -- Only genuine material stains belong in StatusEffectDataComponent.stain_effects.
        -- Earlier builds wrote *every* status id into that vector and then also loaded
        -- its GameEffect entity, creating two independent presentations of e.g. BERSERK
        -- and other timed effects. This is the actual source of many duplicate/blank HUD
        -- statuses. Non-material effects now have exactly one owner: GameEffectComponent.
        if type(entry.material) == "string" and entry.material ~= "" then
            local before = status_vector_value(player, entry)
            local changed = add_surface_status(player, entry)
            -- Only claim cleanup ownership when the status was not already present.
            -- This keeps final QA cleanup from deleting a stain/effect another system
            -- owned before the menu touched it.
            if changed and before < 0.05 then mark_owned_status(player, entry) end
            return changed, changed and "status" or "status_failed"
        end
        if type(entry.path) == "string" and entry.path ~= "" and ModDoesFileExist(entry.path) then
            return apply_game_effect(player, entry, frames)
        end
        return false, "unsupported_status"
    end
    return apply_game_effect(player, entry, frames)
end

local function effective_component_id(comp)
    if comp == nil or comp == 0 then return "" end
    local effect = tostring(ComponentGetValue2(comp, "effect") or "")
    if effect == "CUSTOM" then
        local custom = tostring(ComponentGetValue2(comp, "custom_effect_id") or "")
        if custom ~= "" then return custom end
    end
    return effect
end

local function is_user_facing_effect_entity(entity)
    if EntityHasTag(entity, "metamorph_creative_menu_effect") then return true end
    local icon = EntityGetFirstComponentIncludingDisabled(entity, "UIIconComponent")
    if icon ~= nil and icon ~= 0 then return true end
    local filename = tostring(EntityGetFilename(entity) or "")
    if filename == "" then return false end
    -- The effect catalog is the allow-list for non-icon effect entities. Hidden
    -- service effects are deliberately not treated as removable UI effects.
    for _, entry in ipairs(effect_service.catalog()) do
        if entry.kind == "game_effect" and entry.path == filename then return true end
    end
    return false
end

local function expire_effect_entity(entity)
    if entity == nil or entity == 0 or not EntityGetIsAlive(entity) then return false, false end
    local comp = EntityGetFirstComponentIncludingDisabled(entity, "GameEffectComponent")
    if comp == nil or comp == 0 then return false, false end
    local effect = effective_component_id(comp)
    if RESERVED_EFFECTS[effect] or not is_user_facing_effect_entity(entity) then return false, false end

    -- First ask Noita to expire the effect normally. Some persistent GameEffect entities
    -- keep their XML child alive even after frames reaches 1, however; merely observing
    -- frames<=1 made the old QA report success while PROTECTION_ALL was still resident.
    -- For effects created by this service we therefore keep a short, bounded retirement
    -- journal: the engine gets several updates to run normal expiry callbacks, then only
    -- the still-resident mod-owned entity is retired. Pre-existing/perk effects are never
    -- force-killed by this fallback.
    local before = tonumber(ComponentGetValue2(comp, "frames")) or -1
    local ok = pcall(ComponentSetValue2, comp, "frames", 1)
    local after = ok and tonumber(ComponentGetValue2(comp, "frames")) or before
    local changed = ok and after ~= nil and after <= 1 and (before == -1 or before > 1)
    if changed and EntityHasTag(entity, "metamorph_creative_menu_effect") then
        pending_expiry[entity] = GameGetFrameNum()
    end
    return changed
end

function effect_service.update()
    local frame = GameGetFrameNum()
    for entity, started in pairs(pending_expiry) do
        if entity == nil or entity == 0 or not EntityGetIsAlive(entity)
            or not EntityHasTag(entity, "metamorph_creative_menu_effect")
        then
            pending_expiry[entity] = nil
        else
            local age = frame - (tonumber(started) or frame)
            local comp = EntityGetFirstComponentIncludingDisabled(entity, "GameEffectComponent")
            if comp == nil or comp == 0 then
                pending_expiry[entity] = nil
            else
                -- Escalate once after the normal frames=1 request. frames=0 gives the
                -- GameEffect lifecycle another deterministic expiry tick before fallback.
                if age >= 2 then pcall(ComponentSetValue2, comp, "frames", 0) end
                if age >= 4 then
                    -- Only our own tagged child reaches this path. It has already had
                    -- multiple normal expiry updates, so retiring it cannot delete a
                    -- pre-existing status or a perk-owned effect from another subsystem.
                    pcall(EntityKill, entity)
                    pending_expiry[entity] = nil
                end
            end
        end
    end

    for key, record in pairs(pending_status_expiry) do
        local player = tonumber(record.player) or 0
        local entry = record.entry
        if not valid_player(player) or type(entry) ~= "table" then
            pending_status_expiry[key] = nil
            owned_statuses[player] = nil
        else
            local age = frame - (tonumber(record.started) or frame)
            -- StatusEffectDataComponent and its helper GameEffect child update on
            -- different engine ticks. Repeat native removal first, then retire only
            -- the matching child for a status this service itself introduced.
            if age >= 2 and type(entry.id) == "string" then
                pcall(EntityRemoveStainStatusEffect, player, entry.id, 0)
            end
            if age >= 4 then
                for _, child in ipairs(EntityGetAllChildren(player) or {}) do
                    if EntityGetIsAlive(child) and not EntityHasTag(child, "perk_entity")
                        and type(matches_entry) == "function" and matches_entry(child, entry)
                    then
                        pcall(EntityKill, child)
                    end
                end
                local owner_key = status_owner_key(entry)
                if owned_statuses[player] ~= nil then
                    owned_statuses[player][owner_key] = nil
                    if next(owned_statuses[player]) == nil then owned_statuses[player] = nil end
                end
                pending_status_expiry[key] = nil
            end
        end
    end
end

matches_entry = function(child, entry)
    local filename = EntityGetFilename(child)
    if type(entry.path) == "string" and entry.path ~= "" and filename == entry.path then return true end
    local comp = EntityGetFirstComponentIncludingDisabled(child, "GameEffectComponent")
    if comp == nil or comp == 0 then return false end
    local effect = tostring(ComponentGetValue2(comp, "effect") or "")
    if effect == "CUSTOM" then effect = tostring(ComponentGetValue2(comp, "custom_effect_id") or "") end
    if type(entry.game_effect) == "string" and entry.game_effect ~= "" and effect == entry.game_effect then return true end
    if type(entry.custom_effect_id) == "string" and entry.custom_effect_id ~= "" and effect == entry.custom_effect_id then return true end
    return false
end

function effect_service.remove(player, entry)
    if not valid_player(player) or type(entry) ~= "table" then return 0 end
    local removed = 0
    if type(entry.id) == "string" and entry.kind == "status"
        and type(entry.material) == "string" and entry.material ~= ""
    then
        local before = status_vector_value(player, entry)
        local ok = pcall(EntityRemoveStainStatusEffect, player, entry.id, 0)
        if ok and before >= 0.05 then removed = removed + 1 end
        if ok then schedule_status_expiry(player, entry) end
    end
    for _, child in ipairs(EntityGetAllChildren(player) or {}) do
        if not EntityHasTag(child, "perk_entity") and matches_entry(child, entry) then
            if expire_effect_entity(child) then removed = removed + 1 end
        end
    end
    return removed
end

function effect_service.flush_owned(player)
    if not valid_player(player) then return 0 end
    local retired = 0
    -- Direct GameEffect entries are explicitly tagged at creation.
    for _, child in ipairs(EntityGetAllChildren(player) or {}) do
        if EntityGetIsAlive(child) and EntityHasTag(child, "metamorph_creative_menu_effect") then
            if expire_effect_entity(child) then retired = retired + 1 end
        end
    end
    -- Surface statuses cannot tag the engine-created helper entity synchronously, so
    -- ownership is tracked only when this service added a previously-inactive status.
    local owners = owned_statuses[player]
    if owners ~= nil then
        for _, entry in ipairs(effect_service.catalog()) do
            if entry.kind == "status" and type(entry.material) == "string" and entry.material ~= ""
                and owners[status_owner_key(entry)]
            then
                pcall(EntityRemoveStainStatusEffect, player, entry.id, 0)
                schedule_status_expiry(player, entry)
                retired = retired + 1
            end
        end
    end
    return retired
end

function effect_service.remove_all(player)
    if not valid_player(player) then return 0 end
    local removed = 0
    local seen_status = {}
    for _, entry in ipairs(effect_catalog.status_entries()) do
        if type(entry.material) == "string" and entry.material ~= "" and not seen_status[entry.id] then
            seen_status[entry.id] = true
            local before = status_vector_value(player, entry)
            local ok = pcall(EntityRemoveStainStatusEffect, player, entry.id, 0)
            if ok and before >= 0.05 then removed = removed + 1 end
        end
    end
    for _, child in ipairs(EntityGetAllChildren(player) or {}) do
        if not EntityHasTag(child, "perk_entity") and expire_effect_entity(child) then removed = removed + 1 end
    end
    return removed
end

function effect_service.residue_count(player, entry)
    if not valid_player(player) or type(entry) ~= "table" then return 0 end
    local count = 0
    if entry.kind == "status" and type(entry.material) == "string" and entry.material ~= "" then
        if status_vector_value(player, entry) >= 0.05 then count = count + 1 end
    end
    for _, child in ipairs(EntityGetAllChildren(player) or {}) do
        if EntityGetIsAlive(child) and not EntityHasTag(child, "perk_entity") and matches_entry(child, entry) then
            count = count + 1
        end
    end
    return count
end

function effect_service.active_snapshot(player)
    local snapshot = { player = player, status_values = nil, paths = {}, effect_ids = {} }
    if not valid_player(player) then return snapshot end

    local status = EntityGetFirstComponentIncludingDisabled(player, "StatusEffectDataComponent")
    if status ~= nil and status ~= 0 then
        local values = ComponentGetValue2(status, "stain_effects")
        if type(values) == "table" then snapshot.status_values = values end
    end

    for _, child in ipairs(EntityGetAllChildren(player) or {}) do
        local comp = EntityGetFirstComponentIncludingDisabled(child, "GameEffectComponent")
        if comp ~= nil and comp ~= 0 then
            local frames = tonumber(ComponentGetValue2(comp, "frames")) or 0
            if frames == -1 or frames > 1 then
                local filename = EntityGetFilename(child)
                if type(filename) == "string" and filename ~= "" then snapshot.paths[filename] = true end
                local effect = tostring(ComponentGetValue2(comp, "effect") or "")
                if effect == "CUSTOM" then effect = tostring(ComponentGetValue2(comp, "custom_effect_id") or "") end
                if effect ~= "" then snapshot.effect_ids[effect] = true end
            end
        end
    end
    return snapshot
end

function effect_service.is_active(player, entry, snapshot)
    if not valid_player(player) or type(entry) ~= "table" then return false end
    if type(snapshot) == "table" and snapshot.player == player then
        if entry.kind == "status" and type(entry.material) == "string" and entry.material ~= "" then
            local values = snapshot.status_values
            local vector_index = (tonumber(entry.status_index) or 0) + 1
            if type(values) == "table" and vector_index >= 2
                and (tonumber(values[vector_index]) or 0) >= 0.05
            then return true end
        end
        local path = tostring(entry.path or "")
        if path ~= "" and snapshot.paths[path] then return true end
        local game_effect = tostring(entry.game_effect or "")
        if game_effect ~= "" and snapshot.effect_ids[game_effect] then return true end
        local custom_effect = tostring(entry.custom_effect_id or "")
        if custom_effect ~= "" and snapshot.effect_ids[custom_effect] then return true end
        return false
    end

    -- Compatibility fallback for callers outside the EFFECTS tab.
    if entry.kind == "status" and type(entry.material) == "string" and entry.material ~= "" then
        local comp = EntityGetFirstComponentIncludingDisabled(player, "StatusEffectDataComponent")
        if comp ~= nil and comp ~= 0 then
            local values = ComponentGetValue2(comp, "stain_effects")
            local vector_index = (tonumber(entry.status_index) or 0) + 1
            if type(values) == "table" and vector_index >= 2 and (tonumber(values[vector_index]) or 0) >= 0.05 then return true end
        end
    end
    for _, child in ipairs(EntityGetAllChildren(player) or {}) do
        if matches_entry(child, entry) then
            local comp = EntityGetFirstComponentIncludingDisabled(child, "GameEffectComponent")
            local frames = comp ~= nil and comp ~= 0 and tonumber(ComponentGetValue2(comp, "frames")) or 0
            if frames == -1 or frames > 1 then return true end
        end
    end
    return false
end

METAMORPH_CREATIVE_MENU_EFFECT_SERVICE = effect_service
-- Legacy singleton alias kept so older external integrations do not break.
METAMORPH_CREATIVE_MENU_EFFECT_EDITOR = effect_service
return effect_service
