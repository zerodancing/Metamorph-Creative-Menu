dofile_once("data/scripts/lib/utilities.lua")

-- init.lua is intentionally only the lifecycle/composition root. Feature state and
-- behavior live in services, form adapters and UI tab modules under files/.
local localization = dofile("mods/metamorph_creative_menu/files/platform/noita/localization.lua")
local input_guard = dofile("mods/metamorph_creative_menu/files/platform/noita/input_guard.lua")
local form_manager = dofile("mods/metamorph_creative_menu/files/features/forms/manager.lua")
local weather = dofile("mods/metamorph_creative_menu/files/features/weather/service.lua")
local world_rules = dofile("mods/metamorph_creative_menu/files/features/world_rules/service.lua")
local menu_controller = dofile("mods/metamorph_creative_menu/files/ui/menu_controller.lua")
local keybinds = dofile("mods/metamorph_creative_menu/files/features/possession/keybinds.lua")
local ew_resilience = dofile("mods/metamorph_creative_menu/files/integrations/ew/resilience.lua")
local ew_perk_sync = dofile("mods/metamorph_creative_menu/files/integrations/ew/perk_sync.lua")
local perk_service = dofile("mods/metamorph_creative_menu/files/features/perks/service.lua")
local effect_service = dofile("mods/metamorph_creative_menu/files/features/effects/service.lua")
local player_avatar = dofile("mods/metamorph_creative_menu/files/features/companion/player_avatar.lua")

local MOD_NAME = "Metamorph: Creative Menu"
local EW_RULES_MODULE = "mods/metamorph_creative_menu/files/integrations/ew/bootstrap.lua"
local PERK_PICKUP_HOOK = "mods/metamorph_creative_menu/files/features/perks/pickup_hook.lua"

function OnModPreInit()
    localization.register()
    -- Observe real vanilla perk pickups from temples/other mods as well as menu pickups.
    -- This makes later removal use the same ownership journal regardless of acquisition source.
    ModLuaFileAppend("data/scripts/perks/perk.lua", PERK_PICKUP_HOOK)
    ew_resilience.pre_init()
    -- EW's stable RPC API is available only inside EW's own Lua context. Registering
    -- this file as an official extra module lets EW load it after net/ctx exist while
    -- keeping all source and behaviour owned by this mod.
    if ModIsEnabled("quant.ew") and ModDoesFileExist(EW_RULES_MODULE) then
        ModLuaFileAppend("mods/quant.ew/files/api/extra_modules.lua", EW_RULES_MODULE)
    end
end

function OnModPostInit()
    ew_resilience.post_init()
    -- Noita resolves polymorph effect entity paths early enough that publishing the
    -- generated XML only from a menu click is not reliable on every runtime path.
    -- Prewarm the exact effect wrappers after all mods finish VFS setup; transform_creature()
    -- keeps its lazy publisher as a fallback for dynamically-added creature paths.
    local ok_forms, prepared = pcall(form_manager.prepare_exact_effect_paths_from_catalog)
    if not ok_forms then
        print("[" .. MOD_NAME .. "] polymorph prewarm failed: " .. tostring(prepared))
    end

end

function OnWorldPreUpdate()
    input_guard.update()
    effect_service.update()
    weather.update()
    world_rules.update()
    ew_perk_sync.update()
    perk_service.update(form_manager.current_player())
    player_avatar.update()
    form_manager.update()
    form_manager.draw_form_health()
    keybinds.update()

    -- TAB while transformed belongs to the form lifecycle. Input quarantine blocks
    -- the same physical key event after Alt-Tab before either forms or UI consume it.
    if form_manager.handle_tab_return(input_guard.blocked()) then
        return
    end

    menu_controller.draw()
end

function OnWorldPostUpdate()
    -- Reassert persistent weather after world scripts and restore inventory selection
    -- if vanilla InventoryGui saw the same wheel event as our scroll container.
    weather.update()
    world_rules.post_update()
    form_manager.post_update()
    menu_controller.post_update()
end
