dofile_once("data/scripts/lib/utilities.lua")

local dev_mode_value = dofile("mods/metamorph_creative_menu/dev_mode.lua")
local DEV_MODE = tonumber(dev_mode_value) == 1
METAMORPH_CREATIVE_MENU_DEV_MODE = DEV_MODE

-- init.lua is intentionally only the lifecycle/composition root. Feature state and
-- behavior live in services, form adapters and UI tab modules under files/.
local localization = dofile("mods/metamorph_creative_menu/files/platform/noita/localization.lua")
local input_guard = dofile("mods/metamorph_creative_menu/files/platform/noita/input_guard.lua")
local action_bindings = dofile("mods/metamorph_creative_menu/files/platform/noita/action_bindings.lua")
local diagnostics = DEV_MODE and dofile("mods/metamorph_creative_menu/files/diagnostics/service.lua") or nil
local qa_controller = DEV_MODE and dofile("mods/metamorph_creative_menu/files/qa/controller.lua") or nil
local form_manager = dofile("mods/metamorph_creative_menu/files/features/forms/manager.lua")
local weather = dofile("mods/metamorph_creative_menu/files/features/weather/service.lua")
local world_rules = dofile("mods/metamorph_creative_menu/files/features/world_rules/service.lua")
local menu_controller = dofile("mods/metamorph_creative_menu/files/ui/menu_controller.lua")
local keybinds = dofile("mods/metamorph_creative_menu/files/features/possession/keybinds.lua")
local ew_resilience = dofile("mods/metamorph_creative_menu/files/integrations/ew/resilience.lua")
-- Load the legacy peer-local perk API for compatibility; its old mailbox has no producer
-- and is intentionally not part of the per-frame lifecycle anymore.
dofile("mods/metamorph_creative_menu/files/integrations/ew/perk_sync.lua")
local perk_service = dofile("mods/metamorph_creative_menu/files/features/perks/service.lua")
local effect_service = dofile("mods/metamorph_creative_menu/files/features/effects/service.lua")
local player_avatar = dofile("mods/metamorph_creative_menu/files/features/companion/player_avatar.lua")
local material_painter = dofile("mods/metamorph_creative_menu/files/features/materials/painter.lua")
local player_tools = dofile("mods/metamorph_creative_menu/files/features/player_tools/service.lua")

local MOD_NAME = "Metamorph: Creative Menu"
local EW_RULES_MODULE = "mods/metamorph_creative_menu/files/integrations/ew/bootstrap.lua"
local PERK_PICKUP_HOOK = "mods/metamorph_creative_menu/files/features/perks/pickup_hook.lua"
local runtime_error_seen = {}
local RUNTIME_ERROR_REPEAT_FRAMES = 600

local function translated(key, fallback)
    if type(localization.translate) == "function" then
        local ok, value = pcall(localization.translate, key, fallback)
        if ok and type(value) == "string" and value ~= "" then return value end
    end
    if type(GameTextGetTranslatedOrNot) == "function" then
        local ok, value = pcall(GameTextGetTranslatedOrNot, key)
        if ok and type(value) == "string" and value ~= "" and value ~= key then return value end
    end
    return fallback
end

local function report_runtime_error(scope, failure)
    scope = tostring(scope or "unknown")
    failure = tostring(failure)
    local signature = scope .. "|" .. failure
    local frame = 0
    if type(GameGetFrameNum) == "function" then
        local ok, value = pcall(GameGetFrameNum)
        if ok then frame = tonumber(value) or 0 end
    end
    local last = runtime_error_seen[signature]
    if last ~= nil and frame - last < RUNTIME_ERROR_REPEAT_FRAMES then return end
    runtime_error_seen[signature] = frame
    local diagnostic_message = "[" .. MOD_NAME .. "] " .. scope .. " failed: " .. failure
    local user_message = translated("$mcm_runtime_error", "Mod runtime error")
        .. ": " .. scope .. " — " .. failure
    print(diagnostic_message)
    if type(GlobalsSetValue) == "function" then
        pcall(GlobalsSetValue, "mcm_runtime_error_last_v1", scope .. ": " .. tostring(failure))
    end
    if type(GamePrint) == "function" then pcall(GamePrint, user_message) end
    if type(METAMORPH_CREATIVE_MENU_DIAGNOSTICS_CAPTURE) == "function" then
        pcall(METAMORPH_CREATIVE_MENU_DIAGNOSTICS_CAPTURE, "runtime." .. scope, tostring(failure))
    end
end

local function protected_call(scope, callback, ...)
    if type(callback) ~= "function" then
        report_runtime_error(scope, "callback_unavailable")
        return false, nil
    end
    local ok, first, second, third = pcall(callback, ...)
    if not ok then
        report_runtime_error(scope, first)
        return false, nil
    end
    return true, first, second, third
end

local teleport_cursor = 0
local function native_inventory_open()
    if type(GameIsInventoryOpen) ~= "function" then return false end
    local ok, value = pcall(GameIsInventoryOpen)
    return ok and value == true
end

local function run_assignable_world_actions(player, menu_was_open)
    if menu_was_open == true or native_inventory_open() then return end
    if action_bindings.consume("brush_smaller") then
        protected_call("hotkey.brush_smaller", material_painter.adjust_brush, -1)
    end
    if action_bindings.consume("brush_larger") then
        protected_call("hotkey.brush_larger", material_painter.adjust_brush, 1)
    end
    if action_bindings.consume("paint_toggle") then
        local enabled = material_painter.is_enabled() == true
        local _, ok, reason = protected_call("hotkey.paint_toggle", material_painter.set_enabled, not enabled)
        if ok ~= true and type(GamePrint) == "function" then
            pcall(GamePrint, translated("$mcm_material_backend_failed", "Material brush unavailable")
                .. ": " .. tostring(reason or "backend"))
        end
    end
    if action_bindings.consume("effects_clear") then
        protected_call("hotkey.effects_clear", effect_service.remove_all, player)
    end
    if action_bindings.consume("weather_release") then
        protected_call("hotkey.weather_release", weather.release)
    end
    if action_bindings.consume("rules_reset") then
        protected_call("hotkey.rules_reset", world_rules.reset)
    end
    if action_bindings.consume("teleport_next_player") then
        local ok, visible = protected_call("hotkey.players", player_tools.visible_players)
        local targets = {}
        if ok and type(visible) == "table" then
            for _, entity in ipairs(visible) do
                if tonumber(entity) ~= tonumber(player) then targets[#targets + 1] = entity end
            end
        end
        table.sort(targets, function(a, b) return (tonumber(a) or 0) < (tonumber(b) or 0) end)
        if #targets > 0 then
            teleport_cursor = teleport_cursor % #targets + 1
            protected_call("hotkey.teleport", player_tools.teleport_to, targets[teleport_cursor], player)
        end
    end
end

function OnModPreInit()
    protected_call("localization.register", localization.register)
    -- Observe real vanilla perk pickups from temples/other mods as well as menu pickups.
    -- This makes later removal use the same ownership journal regardless of acquisition source.
    protected_call("perk_pickup_hook.append", ModLuaFileAppend, "data/scripts/perks/perk.lua", PERK_PICKUP_HOOK)
    protected_call("ew_resilience.pre_init", ew_resilience.pre_init)
    -- EW's stable RPC API is available only inside EW's own Lua context. Registering
    -- this file as an official extra module lets EW load it after net/ctx exist while
    -- keeping all source and behaviour owned by this mod.
    if ModIsEnabled("quant.ew") and ModDoesFileExist(EW_RULES_MODULE) then
        protected_call("ew_extra_module.append", ModLuaFileAppend,
            "mods/quant.ew/files/api/extra_modules.lua", EW_RULES_MODULE)
    end
end

function OnModPostInit()
    local ok_resilience, seed_fallbacks, biome_fallbacks, crosscall_guards =
        protected_call("ew_resilience.post_init", ew_resilience.post_init)
    if not ok_resilience then seed_fallbacks, biome_fallbacks, crosscall_guards = 0, 0, 0 end
    if (tonumber(seed_fallbacks) or 0) > 0 or (tonumber(biome_fallbacks) or 0) > 0
        or (tonumber(crosscall_guards) or 0) > 0
    then
        print("[" .. MOD_NAME .. "] EW resilience: seed=" .. tostring(seed_fallbacks)
            .. ", biome=" .. tostring(biome_fallbacks) .. ", crosscall=" .. tostring(crosscall_guards))
    end
    -- Noita resolves polymorph effect entity paths early enough that publishing the
    -- generated XML only from a menu click is not reliable on every runtime path.
    -- Prewarm the exact effect wrappers after all mods finish VFS setup; transform_creature()
    -- keeps its lazy publisher as a fallback for dynamically-added creature paths.
    local ok_forms, prepared = pcall(form_manager.prepare_exact_effect_paths_from_catalog)
    if not ok_forms then
        if type(METAMORPH_CREATIVE_MENU_DIAGNOSTICS_CAPTURE) == "function" then
            pcall(METAMORPH_CREATIVE_MENU_DIAGNOSTICS_CAPTURE, "init.polymorph_prewarm", tostring(prepared))
        end
        print("[" .. MOD_NAME .. "] polymorph prewarm failed: " .. tostring(prepared))
    elseif DEV_MODE and tonumber(prepared) ~= nil then
        print("[" .. MOD_NAME .. "] polymorph effects prepared: " .. tostring(prepared))
    end

end

function OnWorldPreUpdate()
    protected_call("input_guard.update", input_guard.update)
    protected_call("action_bindings.update", action_bindings.update)
    if diagnostics ~= nil then protected_call("diagnostics.update", diagnostics.update) end
    protected_call("effect_service.update", effect_service.update)
    if qa_controller ~= nil then protected_call("qa_controller.update", qa_controller.update) end
    protected_call("weather.update.pre", weather.update)
    protected_call("world_rules.update", world_rules.update)
    -- Reserved legacy perk-removal mailbox has no producer. Keep the compatibility
    -- module/API loaded, but do not poll an acknowledge-only Global every frame.
    local _, current = protected_call("form_manager.current_player", form_manager.current_player)
    local _, menu_was_open = protected_call("menu_controller.is_open", menu_controller.is_open)
    run_assignable_world_actions(tonumber(current) or 0, menu_was_open == true)
    -- Material painting follows the assignable paint-draw action (middle mouse by
    -- default) and writes directly to Noita's loaded cell grid. It runs in pre-update so
    -- the world operation is not coupled to GUI timing.
    protected_call("material_painter.update", material_painter.update, tonumber(current) or 0)
    -- This is O(1) while idle. It only advances a location teleport whose destination
    -- is currently being streamed; player lists are never scanned in the background.
    protected_call("player_tools.update", player_tools.update)
    protected_call("perk_service.update", perk_service.update, tonumber(current) or 0)
    protected_call("player_avatar.update", player_avatar.update)
    protected_call("form_manager.update", form_manager.update)
    -- Vanilla HUD already reads the playerized form DamageModelComponent. The legacy
    -- draw_form_health hook is retained for compatibility but is a deliberate no-op and
    -- does not belong in the per-frame runtime path.
    protected_call("possession_keybinds.update", keybinds.update, menu_was_open == true)

    -- The assignable return-human action (TAB by default) belongs to the form lifecycle.
    -- Input quarantine blocks stale focus-transition input after Alt-Tab before forms or
    -- UI consume it.
    local _, input_blocked = protected_call("input_guard.blocked", input_guard.blocked)
    local return_pressed = false
    if menu_was_open ~= true then
        local _, has_form = protected_call("form_manager.has_active_form", form_manager.has_active_form)
        if has_form == true then
            local _, pressed = protected_call("action_bindings.return_human", action_bindings.consume, "return_human")
            return_pressed = pressed == true
        end
    end
    local _, handled_return = protected_call("form_manager.handle_tab_return",
        form_manager.handle_tab_return, input_blocked == true, return_pressed)
    if handled_return == true then
        -- A form return changes the controlled player entity. Do not carry an armed
        -- world brush across that lifecycle boundary.
        protected_call("material_painter.disable_on_form_return", material_painter.set_enabled, false)
        return
    end

    protected_call("menu_controller.draw", menu_controller.draw)
end

function OnWorldPostUpdate()
    -- Reassert persistent weather after world scripts and restore inventory selection
    -- if vanilla InventoryGui saw the same wheel event as our scroll container.
    protected_call("weather.update.post", weather.update)
    protected_call("world_rules.post_update", world_rules.post_update)
    protected_call("form_manager.post_update", form_manager.post_update)
    protected_call("menu_controller.post_update", menu_controller.post_update)
end
