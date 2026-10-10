local external_observer = {}

local perk_service = dofile("mods/metamorph_creative_menu/files/features/perks/service.lua")
local perk_transactions = dofile("mods/metamorph_creative_menu/files/features/perks/transactions.lua")
local root_companions = dofile("mods/metamorph_creative_menu/files/features/perks/root_companions.lua")
local perk_catalog = dofile("mods/metamorph_creative_menu/files/features/perks/catalog.lua")
local player_locator = dofile("mods/metamorph_creative_menu/files/platform/noita/player_locator.lua")
local nested_pickups = dofile("mods/metamorph_creative_menu/files/features/perks/nested_pickups.lua")

local catalog_by_id = nil

local function ensure_catalog()
    if catalog_by_id ~= nil then return catalog_by_id end
    catalog_by_id = {}
    for _, perk in ipairs(perk_catalog.all() or {}) do
        if type(perk) == "table" and type(perk.id) == "string" and perk.id ~= "" then
            catalog_by_id[perk.id] = perk
        end
    end
    return catalog_by_id
end

local function count_for(perk_id)
    local flag = type(get_perk_picked_flag_name) == "function" and get_perk_picked_flag_name(perk_id)
        or ("PERK_PICKED_" .. tostring(perk_id))
    return math.max(0, tonumber(GlobalsGetValue(flag .. "_PICKUP_COUNT", "0")) or 0)
end

local function snapshot_counts()
    local result = {}
    for perk_id in pairs(ensure_catalog()) do result[perk_id] = count_for(perk_id) end
    return result
end

local function exact_id(value)
    value = tostring(value or "")
    return ensure_catalog()[value] ~= nil and value or nil
end

local function resolve_from_pickup_entity(perk_entity, item_name)
    local direct = exact_id(item_name)
    if direct ~= nil then return direct end
    if perk_entity == nil or perk_entity == 0 or type(EntityGetIsAlive) ~= "function" or not EntityGetIsAlive(perk_entity) then return nil end

    local entity_name = type(EntityGetName) == "function" and tostring(EntityGetName(perk_entity) or "") or ""
    direct = exact_id(entity_name)
    if direct ~= nil then return direct end

    if type(EntityGetComponentIncludingDisabled) == "function" then
        for _, storage_component in ipairs(EntityGetComponentIncludingDisabled(perk_entity, "VariableStorageComponent") or {}) do
            local ok_name, storage_name = pcall(ComponentGetValue2, storage_component, "name")
            local ok_value, stored_value = pcall(ComponentGetValue2, storage_component, "value_string")
            storage_name = ok_name and tostring(storage_name or "") or ""
            stored_value = ok_value and tostring(stored_value or "") or ""
            direct = exact_id(stored_value)
            if direct ~= nil then return direct end
            if storage_name == "perk_id" or storage_name == "perk" then
                direct = exact_id(stored_value)
                if direct ~= nil then return direct end
            end
        end
    end

    -- Vanilla commonly passes the perk's UI name as item_name. Keep this only as an
    -- exact catalogue match; never guess from substrings or translated fragments.
    for perk_id, perk in pairs(ensure_catalog()) do
        if tostring(perk.ui_name or "") ~= "" and (tostring(perk.ui_name) == tostring(item_name)
            or tostring(perk.ui_name) == entity_name)
        then
            return perk_id
        end
    end
    return nil
end

local function local_player_matches(player_entity)
    local local_player = player_locator.get()
    return local_player ~= nil and local_player ~= 0 and player_entity == local_player
end

function external_observer.before_pickup(perk_entity, player_entity, item_name, environment)
    if METAMORPH_CREATIVE_MENU_PERK_CAPTURE_ACTIVE == true or not local_player_matches(player_entity) then return nil end
    local resolved_perk_id = resolve_from_pickup_entity(perk_entity, item_name)
    local counts_before = snapshot_counts()
    local token
    local all_root_companions_before = nil
    if resolved_perk_id ~= nil then
        token = perk_service.begin_pickup(player_entity, ensure_catalog()[resolved_perk_id] or resolved_perk_id)
    else
        token = perk_transactions.begin(player_entity, "")
        all_root_companions_before = root_companions.capture_all_before(player_entity)
    end
    if token == nil then return nil end
    local parent_scope = nested_pickups.claim_parent(player_entity)
    if type(parent_scope) == "table" then
        token.parent_transaction_id = parent_scope.parent_transaction_id
        token.parent_perk_id = parent_scope.parent_perk_id
    end
    perk_service.start_pickup_capture(token, environment or _G)
    return {
        player = player_entity,
        perk_id = resolved_perk_id,
        token = token,
        counts_before = counts_before,
        root_companions_before = all_root_companions_before,
    }
end

local function resolve_from_count_delta(context)
    local increased = {}
    for perk_id, before_count in pairs(context.counts_before or {}) do
        local after_count = count_for(perk_id)
        if after_count > (tonumber(before_count) or 0) then increased[#increased + 1] = perk_id end
    end
    if #increased == 1 then return increased[1] end
    return nil
end

function external_observer.after_pickup(context, pickup_succeeded)
    if type(context) ~= "table" or type(context.token) ~= "table" then return false, "no_context" end
    perk_service.stop_pickup_capture(context.token)
    local perk_id = context.perk_id or resolve_from_count_delta(context)
    if perk_id == nil then return false, "unresolved_perk" end
    perk_transactions.set_perk_id(context.token, perk_id)
    if context.root_companions_before ~= nil then
        root_companions.commit_from_all(perk_id, context.player, context.root_companions_before)
    end
    local tracked, reason = perk_service.commit_pickup(context.token)
    if pickup_succeeded ~= true and tracked then
        local perk = ensure_catalog()[perk_id]
        if perk ~= nil then pcall(perk_service.remove_one, context.player, perk) end
    end
    return tracked == true, reason, perk_id
end

return external_observer
