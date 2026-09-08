if type(METAMORPH_CREATIVE_MENU_NATIVE_GAMEOVER_PATCH) == "table" then
    return METAMORPH_CREATIVE_MENU_NATIVE_GAMEOVER_PATCH
end

-- Thin Lua facade over mcm_native_gameover.dll.
--
-- Native ownership deliberately lives in the DLL rather than LuaJIT FFI:
--   * the DLL owns the request byte and localization-key storage for its whole lifetime;
--   * it validates and patches the exact profiled noita.exe code sites;
--   * the stock hidden Save Replay button builder becomes MCM's fourth stock button;
--   * its click handler only raises an MCM-owned request byte;
--   * Game Over is released only from the normal OnWorldPreUpdate recovery path.
--
-- Lua owns orchestration only. It never writes executable memory or holds pointers used
-- by patched machine code.
local native_gameover_patch = {}

local PROFILE = {
    name = "noita_808d2a0ab51e_gameover_native_dll_r9",
    exe_sha256 = "808d2a0ab51ea0b46e9ad2aeb3327a4b0ce3feae04f32ba26326bf585b5779bd",
    replay_gate_va = 0x006e62a7,
    replay_label_va = 0x006e62e1,
    replay_click_va = 0x006e6393,
    gameover_update_call_va = 0x006b2bce,
    gameover_trigger_va = 0x006b8519,
    gameover_dispatch_va = 0x006b2b54,
    world_preupdate_dispatch_va = 0x006b321b,
}

local MODULE_NAME = "mcm_native_gameover"
local MODULE_CPATH = "./mods/metamorph_creative_menu/?.dll"

local state = {
    module = nil,
    load_attempted = false,
    load_reason = nil,
    installed = false,
    install_reason = nil,
}

local function ew_active()
    if type(ModIsEnabled) ~= "function" then return false end
    local ok, enabled = pcall(ModIsEnabled, "quant.ew")
    return ok and enabled == true
end

local function append_cpath_once()
    local cpath = tostring(package and package.cpath or "")
    if not cpath:find(MODULE_CPATH, 1, true) then
        package.cpath = cpath .. ";" .. MODULE_CPATH
    end
end

local function load_native_module()
    if type(state.module) == "table" then return state.module end
    if state.load_attempted then return nil, state.load_reason end
    state.load_attempted = true

    if type(package) ~= "table" or type(package.cpath) ~= "string" then
        state.load_reason = "package_loader_unavailable"
        return nil, state.load_reason
    end

    append_cpath_once()
    local ok, module_or_error = pcall(require, MODULE_NAME)
    if not ok then
        state.load_reason = "native_dll_load_failed:" .. tostring(module_or_error)
        return nil, state.load_reason
    end
    if type(module_or_error) ~= "table" then
        state.load_reason = "native_dll_invalid_module"
        return nil, state.load_reason
    end

    local required = {
        "install", "is_installed", "has_revive_request", "clear_revive_request",
        "is_game_over_active", "cancel_game_over_state", "cleanup_post_revive", "reason",
    }
    for _, name in ipairs(required) do
        if type(module_or_error[name]) ~= "function" then
            state.load_reason = "native_dll_missing_api:" .. name
            return nil, state.load_reason
        end
    end

    state.module = module_or_error
    state.load_reason = nil
    return state.module
end

function native_gameover_patch.install()
    -- Death recovery is deliberately singleplayer-only. In Entangled Worlds the network
    -- health/notplayer lifecycle owns Game Over, so do not even load the native DLL.
    -- Besides avoiding state conflicts, this makes a different noita.exe build on a peer
    -- incapable of crashing startup through this optional feature.
    if ew_active() then
        state.install_reason = "disabled_in_entangled_worlds"
        return false, state.install_reason
    end
    local module, load_reason = load_native_module()
    if module == nil then
        state.install_reason = load_reason
        return false, load_reason
    end

    local ok, installed, reason = pcall(module.install)
    if not ok then
        reason = "native_dll_install_call_failed:" .. tostring(installed)
        state.install_reason = reason
        return false, reason
    end
    state.installed = installed == true
    state.install_reason = tostring(reason or (state.installed and "installed" or "unknown"))
    return state.installed, state.install_reason
end

function native_gameover_patch.is_installed()
    local module = state.module
    if type(module) ~= "table" then return false end
    local ok, value = pcall(module.is_installed)
    state.installed = ok and value == true
    return state.installed
end

function native_gameover_patch.has_revive_request()
    local module = state.module
    if type(module) ~= "table" then return false end
    local ok, value = pcall(module.has_revive_request)
    return ok and value == true
end

function native_gameover_patch.clear_revive_request()
    local module = state.module
    if type(module) ~= "table" then return false end
    local ok, value = pcall(module.clear_revive_request)
    return ok and value == true
end

function native_gameover_patch.is_game_over_active()
    local module = state.module
    if type(module) ~= "table" then return false, "native_dll_unavailable" end
    local ok, value = pcall(module.is_game_over_active)
    if not ok then return false, "native_dll_gameover_query_failed:" .. tostring(value) end
    return value == true, "ok"
end

function native_gameover_patch.cancel_game_over_state()
    local module = state.module
    if type(module) ~= "table" then return false, "native_dll_unavailable" end
    local ok, value, reason = pcall(module.cancel_game_over_state)
    if not ok then return false, "native_dll_cancel_failed:" .. tostring(value) end
    return value == true, tostring(reason or (value and "cleared" or "unknown"))
end

function native_gameover_patch.cleanup_post_revive()
    local module = state.module
    if type(module) ~= "table" then return false, "native_dll_unavailable" end
    local ok, value, reason = pcall(module.cleanup_post_revive)
    if not ok then return false, "native_dll_cleanup_failed:" .. tostring(value) end
    return value == true, tostring(reason or (value and "post_revive_cleaned" or "unknown"))
end

function native_gameover_patch.status()
    local native_reason = nil
    if type(state.module) == "table" and type(state.module.reason) == "function" then
        local ok, value = pcall(state.module.reason)
        if ok then native_reason = tostring(value) end
    end
    return {
        installed = native_gameover_patch.is_installed(),
        load_reason = state.load_reason,
        install_reason = state.install_reason,
        native_reason = native_reason,
        profile = PROFILE.name,
        backend = "native_x86_lua_c_module",
        revive_request_pending = native_gameover_patch.has_revive_request(),
        stock_button_builder = "save_replay_slot",
        network_disabled = ew_active(),
    }
end

function native_gameover_patch.profile()
    return PROFILE
end

METAMORPH_CREATIVE_MENU_NATIVE_GAMEOVER_PATCH = native_gameover_patch
return native_gameover_patch
