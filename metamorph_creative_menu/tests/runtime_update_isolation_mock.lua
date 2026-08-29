local root = assert(arg[1], "root required")
local calls = {}
local messages = {}
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
    ["mods/metamorph_creative_menu/files/integrations/ew/perk_sync.lua"]={update=function() hit("perk_sync") end},
    ["mods/metamorph_creative_menu/files/features/perks/service.lua"]={
        update=function(player) assert(player == 7); hit("perks") end,
    },
    ["mods/metamorph_creative_menu/files/features/effects/service.lua"]={
        update=function()
            hit("effects")
            effect_attempt = effect_attempt + 1
            error("intentional update failure " .. tostring(effect_attempt))
        end,
    },
    ["mods/metamorph_creative_menu/files/features/companion/player_avatar.lua"]={update=function() hit("companion") end},
    ["mods/metamorph_creative_menu/files/features/materials/painter.lua"]={update=function(player) assert(player==7); hit("materials") end, set_enabled=function() end},
    ["mods/metamorph_creative_menu/files/features/player_tools/service.lua"]={
        update=function() hit("player_tools") end,
        visible_players=function() return {} end,
        teleport_to=function() end,
    },
}

dofile_once = function() end
dofile = function(path)
    if path == "mods/metamorph_creative_menu/dev_mode.lua" then return 0 end
    if stubs[path] ~= nil then return stubs[path] end
    error("unexpected init dependency: " .. tostring(path))
end
ModIsEnabled=function() return false end
ModDoesFileExist=function() return false end
ModLuaFileAppend=function() end
GlobalsSetValue=function(key, value) calls[key]=tostring(value) end
GamePrint=function(message) messages[#messages+1]=tostring(message) end
GameIsInventoryOpen=function() return false end
print=function() end

assert(loadfile(root .. "/init.lua"))()
OnWorldPreUpdate()
OnWorldPostUpdate()
OnWorldPreUpdate()
OnWorldPostUpdate()

assert(calls.effects == 2, "failing subsystem was not retried on the next frame")
for _, name in ipairs({"weather","rules","materials","perks","companion","forms","keys","tab","menu","rules_post","forms_post","menu_post"}) do
    assert((calls[name] or 0) > 0, "later subsystem was skipped after runtime error: " .. name)
end
assert(calls.perk_sync == nil, "reserved acknowledge-only perk mailbox was still polled every frame")
assert(type(calls.mcm_runtime_error_last_v1) == "string"
    and string.find(calls.mcm_runtime_error_last_v1, "effect_service.update", 1, true),
    "last runtime error was not published")
assert(#messages == 2 and string.find(messages[1], "intentional update failure 1", 1, true)
    and string.find(messages[2], "intentional update failure 2", 1, true),
    "a distinct later failure in the same subsystem was hidden by scope-only deduplication")

print("runtime_update_isolation=PASS later_services_continue=true visible_error=true")
