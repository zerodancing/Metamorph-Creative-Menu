local root = assert(arg[1], "root required")
local calls = {}
local messages = {}
local printed = {}
local captured = {}
local native_dofile = dofile
local effect_attempt = 0
local function hit(name) calls[name] = (calls[name] or 0) + 1 end

local stubs = {
    ["mods/metamorph_creative_menu/files/platform/noita/localization.lua"]={register=function() end},
    ["mods/metamorph_creative_menu/files/platform/noita/input_guard.lua"]={
        update=function() hit("input") end,
        blocked=function() return false end,
    },
    ["mods/metamorph_creative_menu/files/platform/noita/action_bindings.lua"]={
        update=function() hit("action_bindings") end,
        consume=function() return false end,
    },
    ["mods/metamorph_creative_menu/files/features/forms/manager.lua"]={
        current_player=function() hit("player"); return 7 end,
        update=function() hit("forms") end,
        draw_form_health=function() hit("health") end,
        post_update=function() hit("forms_post") end,
        handle_tab_return=function() hit("tab"); return false end,
        has_active_form=function() return false end,
        prepare_exact_effect_paths_from_catalog=function() return 0 end,
    },
    ["mods/metamorph_creative_menu/files/features/weather/service.lua"]={update=function() hit("weather") end},
    ["mods/metamorph_creative_menu/files/features/world_rules/service.lua"]={
        update=function() hit("rules") end,
        post_update=function() hit("rules_post") end,
    },
    ["mods/metamorph_creative_menu/files/ui/menu_controller.lua"]={
        draw=function() hit("menu") end,
        post_update=function() hit("menu_post") end,
        is_open=function() return false end,
        active_tab=function() return "spells" end,
        is_hovered=function() return false end,
    },
    ["mods/metamorph_creative_menu/files/features/possession/keybinds.lua"]={update=function() hit("keys") end},
    ["mods/metamorph_creative_menu/files/integrations/ew/resilience.lua"]={
        pre_init=function() end,
        post_init=function() return 0,0,0 end,
    },
    ["mods/metamorph_creative_menu/files/integrations/ew/world_entities.lua"]={update=function() hit("ew_world_entities") end},
    ["mods/metamorph_creative_menu/files/integrations/ew/perk_sync.lua"]={update=function() hit("perk_sync") end},
    ["mods/metamorph_creative_menu/files/features/perks/service.lua"]={
        update=function(player) assert(player == 7); hit("perks") end,
    },
    ["mods/metamorph_creative_menu/files/features/effects/service.lua"]={
        update=function()
            hit("effects")
            effect_attempt = effect_attempt + 1
            error("intentional \"update\" <&%\\ \nЖ🔥 failure " .. tostring(effect_attempt))
        end,
    },
    ["mods/metamorph_creative_menu/files/features/companion/player_avatar.lua"]={update=function() hit("companion") end},
    ["mods/metamorph_creative_menu/files/features/materials/painter.lua"]={update=function(player) assert(player==7); hit("materials") end, set_enabled=function() end},
    ["mods/metamorph_creative_menu/files/platform/noita/assets.lua"]={prewarm=function() return 0,0 end},
    ["mods/metamorph_creative_menu/files/features/items/ui_catalog.lua"]={prewarm_icons=function() return 0,0 end},
    ["mods/metamorph_creative_menu/files/features/spells/slot_settler.lua"]={update=function() hit("spell_slots") end},
    ["mods/metamorph_creative_menu/files/features/death_recovery/service.lua"]={install=function() return true end,update=function() hit("death_recovery") end,pause_update=function() hit("death_pause") end},
    ["mods/metamorph_creative_menu/files/features/player_tools/service.lua"]={
        update=function() hit("player_tools") end,
        visible_players=function() return {} end,
        teleport_to=function() end,
    },
}

dofile_once = function() end
dofile = function(path)
    if path == "mods/metamorph_creative_menu/dev_mode.lua" then return 0 end
    if path == "mods/metamorph_creative_menu/files/core/global_text.lua" then
        return native_dofile(root .. "/files/core/global_text.lua")
    end
    if stubs[path] ~= nil then return stubs[path] end
    error("unexpected init dependency: " .. tostring(path))
end
ModIsEnabled=function() return false end
ModDoesFileExist=function() return false end
ModLuaFileAppend=function() end
GlobalsSetValue=function(key, value) calls[key]=tostring(value) end
GamePrint=function(message) messages[#messages+1]=tostring(message) end
GameIsInventoryOpen=function() return false end
print=function(message) printed[#printed+1]=tostring(message) end
METAMORPH_CREATIVE_MENU_DIAGNOSTICS_CAPTURE=function(scope, detail)
    captured[#captured+1]={scope=tostring(scope), detail=tostring(detail)}
end

assert(loadfile(root .. "/init.lua"))()
OnWorldPreUpdate()
OnWorldPostUpdate()
OnWorldPreUpdate()
OnWorldPostUpdate()

assert(calls.effects == 2, "failing subsystem was not retried on the next frame")
for _, name in ipairs({"spell_slots","weather","rules","materials","perks","companion","ew_world_entities","forms","keys","tab","menu","rules_post","forms_post","menu_post"}) do
    assert((calls[name] or 0) > 0, "later subsystem was skipped after runtime error: " .. name)
end
assert(calls.perk_sync == nil, "reserved acknowledge-only perk mailbox was still polled every frame")
assert(type(calls.mcm_runtime_error_last_v1) == "string"
    and string.find(calls.mcm_runtime_error_last_v1, "effect_service.update", 1, true),
    "last runtime error was not published")
assert(not string.find(calls.mcm_runtime_error_last_v1, '"', 1, true)
    and not string.find(calls.mcm_runtime_error_last_v1, "\n", 1, true)
    and string.find(calls.mcm_runtime_error_last_v1, "%22", 1, true)
    and string.find(calls.mcm_runtime_error_last_v1, "%D0%96", 1, true),
    "runtime diagnostic Global was not ASCII-safe encoded")
local raw1 = "intentional \"update\" <&%\\ \nЖ🔥 failure 1"
local raw2 = "intentional \"update\" <&%\\ \nЖ🔥 failure 2"
assert(#messages == 2 and string.find(messages[1], raw1, 1, true)
    and string.find(messages[2], raw2, 1, true),
    "human-readable GamePrint error was changed by Global encoding")
assert(#printed == 2 and string.find(printed[1], raw1, 1, true)
    and string.find(printed[2], raw2, 1, true),
    "human-readable print error was changed by Global encoding")
assert(#captured == 2 and string.find(captured[1].detail, raw1, 1, true)
    and string.find(captured[2].detail, raw2, 1, true),
    "file-log diagnostic detail was changed by Global encoding")

print("runtime_update_isolation=PASS later_services_continue=true visible_error=true")
