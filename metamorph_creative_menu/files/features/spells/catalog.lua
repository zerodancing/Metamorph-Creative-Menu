if type(METAMORPH_CREATIVE_MENU_SPELL_CATALOG) == "table" then return METAMORPH_CREATIVE_MENU_SPELL_CATALOG end

local spell_catalog = {}
local loaded = false
local unique_actions = nil
local actions_by_id = nil
local filters = nil
local actions_by_filter = {}

local BACKGROUND_BY_TYPE = nil

local function load_vanilla_actions()
    if loaded then return unique_actions ~= nil end
    loaded = true

    local enums_loaded = pcall(dofile_once, "data/scripts/gun/gun_enums.lua")
    local actions_loaded = pcall(dofile_once, "data/scripts/gun/gun_actions.lua")
    if not enums_loaded or not actions_loaded or type(actions) ~= "table" then return false end

    unique_actions = {}
    actions_by_id = {}
    local seen_action_ids = {}
    for _, action_data in ipairs(actions) do
        if type(action_data) == "table" and type(action_data.id) == "string"
            and action_data.id ~= "" and not seen_action_ids[action_data.id]
        then
            seen_action_ids[action_data.id] = true
            unique_actions[#unique_actions + 1] = action_data
            actions_by_id[action_data.id] = action_data
        end
    end

    table.sort(unique_actions, function(left_action, right_action)
        local left_type = tonumber(left_action.type) or 999
        local right_type = tonumber(right_action.type) or 999
        if left_type ~= right_type then return left_type < right_type end
        return left_action.id < right_action.id
    end)

    filters = {
        { key="$mcm_spell_filter_all", fallback="ALL", action_type=nil },
        { key="$mcm_spell_filter_projectiles", fallback="PROJECT.", action_type=ACTION_TYPE_PROJECTILE },
        { key="$mcm_spell_filter_static", fallback="STATIC", action_type=ACTION_TYPE_STATIC_PROJECTILE },
        { key="$mcm_spell_filter_modifiers", fallback="MODIFIERS", action_type=ACTION_TYPE_MODIFIER },
        { key="$mcm_spell_filter_multicasts", fallback="MULTI", action_type=ACTION_TYPE_DRAW_MANY },
        { key="$mcm_spell_filter_materials", fallback="MATERIAL", action_type=ACTION_TYPE_MATERIAL },
        { key="$mcm_spell_filter_other", fallback="OTHER", action_type=ACTION_TYPE_OTHER },
        { key="$mcm_spell_filter_utility", fallback="UTILITY", action_type=ACTION_TYPE_UTILITY },
        { key="$mcm_spell_filter_passive", fallback="PASSIVE", action_type=ACTION_TYPE_PASSIVE },
    }

    BACKGROUND_BY_TYPE = {
        [ACTION_TYPE_PROJECTILE] = "data/ui_gfx/inventory/item_bg_projectile.png",
        [ACTION_TYPE_STATIC_PROJECTILE] = "data/ui_gfx/inventory/item_bg_static_projectile.png",
        [ACTION_TYPE_MODIFIER] = "data/ui_gfx/inventory/item_bg_modifier.png",
        [ACTION_TYPE_DRAW_MANY] = "data/ui_gfx/inventory/item_bg_draw_many.png",
        [ACTION_TYPE_MATERIAL] = "data/ui_gfx/inventory/item_bg_material.png",
        [ACTION_TYPE_OTHER] = "data/ui_gfx/inventory/item_bg_other.png",
        [ACTION_TYPE_UTILITY] = "data/ui_gfx/inventory/item_bg_utility.png",
        [ACTION_TYPE_PASSIVE] = "data/ui_gfx/inventory/item_bg_passive.png",
    }
    return true
end

function spell_catalog.load()
    return load_vanilla_actions()
end

function spell_catalog.all()
    if not load_vanilla_actions() then return nil end
    return unique_actions
end

function spell_catalog.by_id()
    if not load_vanilla_actions() then return nil end
    return actions_by_id
end

function spell_catalog.filters()
    if not load_vanilla_actions() then return nil end
    return filters
end

function spell_catalog.for_filter(filter_index)
    if not load_vanilla_actions() then return {} end
    filter_index = tonumber(filter_index) or 1
    if actions_by_filter[filter_index] ~= nil then return actions_by_filter[filter_index] end

    local filter = filters[filter_index]
    if filter == nil then return {} end
    local matching_actions = {}
    for _, action_data in ipairs(unique_actions) do
        if filter.action_type == nil or action_data.type == filter.action_type then
            matching_actions[#matching_actions + 1] = action_data
        end
    end
    actions_by_filter[filter_index] = matching_actions
    return matching_actions
end

function spell_catalog.background_path(action_data)
    if type(action_data) ~= "table" or not load_vanilla_actions() then return nil end
    return BACKGROUND_BY_TYPE[action_data.type]
end

METAMORPH_CREATIVE_MENU_SPELL_CATALOG = spell_catalog
return spell_catalog
