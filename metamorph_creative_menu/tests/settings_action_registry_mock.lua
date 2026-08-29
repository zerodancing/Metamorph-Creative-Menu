local root=assert(arg[1],'root required')
local native_dofile=dofile
local registry=native_dofile(root..'/files/core/action_registry.lua')
local codec=native_dofile(root..'/files/core/binding_codec.lua')
local keycodes={matching_name_fragment=function() return {} end,resolve=function() return nil end,available=function() return {} end,pretty_name=function(v) return v end}
dofile=function(path)
    if path=='data/scripts/lib/mod_settings.lua' then return true end
    if path=='mods/metamorph_creative_menu/files/core/action_registry.lua' then return registry end
    if path=='mods/metamorph_creative_menu/files/core/binding_codec.lua' then return codec end
    if path=='mods/metamorph_creative_menu/files/platform/noita/keycodes.lua' then return keycodes end
    if path=='mods/metamorph_creative_menu/files/platform/noita/binding_capture.lua' then
        return native_dofile(root..'/files/platform/noita/binding_capture.lua')
    end
    if path=='mods/metamorph_creative_menu/files/platform/noita/localization.lua' then return {
        register=function() return true end,
        translate=function(key,fallback) return fallback or key end,
    } end
    return native_dofile(path)
end
MOD_SETTING_SCOPE_RUNTIME=1
mod_settings_update=function() end
mod_settings_gui_count=function() return 0 end
mod_settings_gui=function() end
assert(loadfile(root..'/settings.lua'))()
assert(#mod_settings==#registry.sections(),'keybindings were not grouped into registry sections')
local flattened={}
for _,category in ipairs(mod_settings) do
    assert(category.foldable==true and type(category.settings)=='table','settings category is not foldable')
    for _,setting in ipairs(category.settings) do flattened[#flattened+1]=setting end
end
assert(#flattened==#registry.actions(),'Noita settings and in-game action registry diverged')
local seen={}
for index,setting in ipairs(flattened) do
    local action=registry.actions()[index]
    assert(setting.id=='binding_'..action.id and setting.value_default==action.default,
        'settings ordering/default differs from action registry at '..tostring(index))
    assert(not seen[setting.id],'duplicate generated setting id: '..setting.id)
    seen[setting.id]=true
end
assert(mod_settings_version==5,'keybinding settings schema version was not bumped')
print('settings_action_registry=PASS generated=true actions='..tostring(#flattened)..' grouped=true defaults=true unique=true')
