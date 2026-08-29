if type(METAMORPH_CREATIVE_MENU_ACTION_REGISTRY) == "table" then
    return METAMORPH_CREATIVE_MENU_ACTION_REGISTRY
end

-- The single source of truth for every assignable action. Keep this module engine-free:
-- settings.lua, the in-game controls tab and the runtime dispatcher all consume the
-- same ordered records, so a new action cannot exist in only one of those places.
local registry = {}

local sections = {
    { id="interface", key="$mcm_bind_section_interface", fallback="INTERFACE" },
    { id="sections", key="$mcm_bind_section_sections", fallback="OPEN SECTION" },
    { id="gameplay", key="$mcm_bind_section_gameplay", fallback="GAMEPLAY" },
    { id="world", key="$mcm_bind_section_world", fallback="WORLD TOOLS" },
}

local actions = {
    { id="menu_toggle", section="interface", key="$mcm_bind_menu_toggle", fallback="Open / close creative menu", default="Key_F4" },
    { id="menu_close", section="interface", key="$mcm_bind_menu_close", fallback="Close creative menu", default="NONE", menu_only=true },
    { id="tab_previous", section="interface", key="$mcm_bind_tab_previous", fallback="Previous section", default="NONE", menu_only=true },
    { id="tab_next", section="interface", key="$mcm_bind_tab_next", fallback="Next section", default="NONE", menu_only=true },

    { id="open_spells", section="sections", key="$mcm_tab_spells", fallback="SPELLS", default="NONE", tab="spells" },
    { id="open_items", section="sections", key="$mcm_tab_items", fallback="ITEMS", default="NONE", tab="items" },
    { id="open_materials", section="sections", key="$mcm_tab_materials", fallback="MATERIALS", default="NONE", tab="materials" },
    { id="open_perks", section="sections", key="$mcm_tab_perks", fallback="PERKS", default="NONE", tab="perks" },
    { id="open_mobs", section="sections", key="$mcm_tab_creatures", fallback="MOBS", default="NONE", tab="mobs" },
    { id="open_effects", section="sections", key="$mcm_tab_effects", fallback="EFFECTS", default="NONE", tab="effects" },
    { id="open_weather", section="sections", key="$mcm_tab_weather", fallback="WEATHER", default="NONE", tab="weather" },
    { id="open_rules", section="sections", key="$mcm_tab_rules", fallback="RULES", default="NONE", tab="rules" },
    { id="open_players", section="sections", key="$mcm_tab_players", fallback="TELEPORTATION", default="NONE", tab="players" },
    { id="open_controls", section="sections", key="$mcm_tab_controls", fallback="CONTROLS", default="NONE", tab="controls" },

    { id="return_human", section="gameplay", key="$mcm_bind_return_human", fallback="Return to human form", default="Key_TAB" },
    { id="possession", section="gameplay", key="$mcm_setting_possession_key", fallback="Possess creature under cursor", default="Key_g", legacy_setting="metamorph_creative_menu.possession_key" },
    { id="paint_toggle", section="gameplay", key="$mcm_bind_paint_toggle", fallback="Start / stop material painting", default="NONE" },
    { id="paint_draw", section="gameplay", key="$mcm_bind_paint_draw", fallback="Draw selected material", default="Mouse:3" },
    { id="brush_smaller", section="gameplay", key="$mcm_bind_brush_smaller", fallback="Smaller material brush", default="NONE" },
    { id="brush_larger", section="gameplay", key="$mcm_bind_brush_larger", fallback="Larger material brush", default="NONE" },

    { id="effects_clear", section="world", key="$mcm_effect_remove_all", fallback="Remove all effects", default="NONE" },
    { id="weather_release", section="world", key="$mcm_weather_release", fallback="Release weather override", default="NONE" },
    { id="rules_reset", section="world", key="$mcm_rules_reset", fallback="Reset world rules", default="NONE" },
    { id="teleport_next_player", section="world", key="$mcm_bind_teleport_next", fallback="Teleport to next network player", default="NONE" },
}

local by_id = {}
for index, action in ipairs(actions) do
    action.index = index
    action.setting_id = "metamorph_creative_menu.binding_" .. action.id
    by_id[action.id] = action
end

function registry.actions() return actions end
function registry.sections() return sections end
function registry.get(id) return by_id[tostring(id or "")] end
function registry.setting_id(id)
    local action = registry.get(id)
    return action and action.setting_id or nil
end

METAMORPH_CREATIVE_MENU_ACTION_REGISTRY = registry
return registry
