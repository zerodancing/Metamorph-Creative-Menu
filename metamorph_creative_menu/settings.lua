dofile("data/scripts/lib/mod_settings.lua")

local mod_id = "metamorph_creative_menu"
mod_settings_version = 5

-- Mod settings use a separate Lua context on some Noita builds. Register translations
-- here as well as from init.lua so newly added action names never fall back to English.
local localization = dofile("mods/metamorph_creative_menu/files/platform/noita/localization.lua")
pcall(localization.register)

local registry = dofile("mods/metamorph_creative_menu/files/core/action_registry.lua")
local codec = dofile("mods/metamorph_creative_menu/files/core/binding_codec.lua")
local binding_capture = dofile("mods/metamorph_creative_menu/files/platform/noita/binding_capture.lua")
local capture_setting_id = nil
local capture_started_frame = -1

local function frame_number()
    local ok, frame = pcall(GameGetFrameNum)
    return ok and (tonumber(frame) or 0) or 0
end

local function tr(value, fallback)
    return localization.translate(value, fallback)
end

local function pretty_binding(value)
    return binding_capture.label(value, tr)
end

local function keybind_ui(mod_id_value, gui, in_main_menu, im_id, setting)
    local setting_id = mod_setting_get_id(mod_id_value, setting)
    local value = ModSettingGetNextValue(setting_id)
    value = codec.normalize(value, setting.value_default)
    local waiting = capture_setting_id == setting_id
    local label = waiting and tr("$mcm_controls_waiting_short", "PRESS...") or pretty_binding(value)
    local title = tr(setting.ui_name, setting.fallback_name)

    if GuiButton(gui, im_id, mod_setting_group_x_offset, 0, title .. ": [ " .. label .. " ]") then
        if waiting then capture_setting_id, capture_started_frame = nil, -1
        else capture_setting_id, capture_started_frame = setting_id, frame_number() end
    end
    mod_setting_tooltip(mod_id_value, gui, in_main_menu, setting)
    if capture_setting_id ~= setting_id then return end
    local event = binding_capture.poll(capture_started_frame, frame_number())
    if event == nil then return end
    if event.kind == "binding" then ModSettingSetNextValue(setting_id, event.value, false) end
    capture_setting_id, capture_started_frame = nil, -1
end

local settings_by_section = {}
mod_settings = {}
for _, section in ipairs(registry.sections()) do
    local category = {
        category_id = "binding_section_" .. section.id,
        ui_name = tr(section.key, section.fallback),
        ui_description = tr("$mcm_setting_keybind_desc", "Assign shortcuts for this group."),
        foldable = true,
        _folded = section.id ~= "interface",
        settings = {},
    }
    settings_by_section[section.id] = category.settings
    mod_settings[#mod_settings + 1] = category
end
for _, action in ipairs(registry.actions()) do
    local section_settings = settings_by_section[action.section]
    if section_settings ~= nil then
        section_settings[#section_settings + 1] = {
            id = "binding_" .. action.id,
            ui_name = action.key,
            fallback_name = action.fallback,
            ui_description = tr("$mcm_setting_keybind_desc", "Click and press a key or mouse button."),
            value_default = action.default,
            scope = MOD_SETTING_SCOPE_RUNTIME,
            ui_fn = keybind_ui,
        }
    end
end

function ModSettingsUpdate(init_scope) mod_settings_update(mod_id, mod_settings, init_scope) end
function ModSettingsGuiCount() return mod_settings_gui_count(mod_id, mod_settings) end
function ModSettingsGui(gui, in_main_menu) mod_settings_gui(mod_id, mod_settings, gui, in_main_menu) end
