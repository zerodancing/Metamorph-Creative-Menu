if type(METAMORPH_CREATIVE_MENU_BRIDGE_API) == "table" then return METAMORPH_CREATIVE_MENU_BRIDGE_API end

local patcher_bridge = {}

local cached = nil
local last_attempt_frame = -100000
local last_explicit_attempt_frame = -100000
local last_bootstrap_frame = -100000
local retry_frames = 60
local BUNDLED_PATCHER_PATH = "mods/metamorph_creative_menu/NoitaPatcher/load.lua"

local function valid_bridge(value, capability)
    if type(value) ~= "table" then return false end
    return capability == nil or type(value[capability]) == "function"
end

local function frame_number()
    local ok, value = pcall(GameGetFrameNum)
    return ok and tonumber(value) or 0
end

local function ew_enabled()
    local active = false
    pcall(function() active = ModIsEnabled("quant.ew") == true end)
    return active
end

local function from_globals(capability)
    if valid_bridge(METAMORPH_CREATIVE_MENU_NP, capability) then return METAMORPH_CREATIVE_MENU_NP end
    if valid_bridge(np, capability) then return np end
    return nil
end

local function try_require(capability)
    local bridge = from_globals(capability)
    if valid_bridge(bridge, capability) then return bridge end
    local ok, module = pcall(require, "noitapatcher")
    return ok and valid_bridge(module, capability) and module or nil
end

local function maybe_bootstrap(options)
    options = type(options) == "table" and options or {}
    local active = ew_enabled()
    local allow_installed = options.bootstrap_if_installed == true
    if not active and not allow_installed then return end

    if not patcher_bridge.bootstrap_available() then return end
    local frame = frame_number()
    if frame - last_bootstrap_frame < retry_frames then return end
    last_bootstrap_frame = frame

    -- Prefer an already-published NoitaPatcher bridge (including EW's instance).
    -- When none exists, explicit MCM features bootstrap the bundled local copy.
    -- This keeps singleplayer independent from the presence of quant.ew.
    pcall(dofile_once, BUNDLED_PATCHER_PATH)
end

function patcher_bridge.bootstrap_available()
    return type(ModDoesFileExist) == "function" and ModDoesFileExist(BUNDLED_PATCHER_PATH) == true
end

function patcher_bridge.get(options)
    options = type(options) == "table" and options or {}
    local capability = type(options.capability) == "string" and options.capability or nil
    if valid_bridge(cached, capability) then return cached end

    -- A bridge table can be published before all methods are attached. Never let a
    -- placeholder table poison discovery for the rest of the run: a missing requested
    -- capability invalidates the cache and re-enters discovery on the normal retry.
    if cached ~= nil and not valid_bridge(cached, capability) then cached = nil end

    local direct = from_globals(capability)
    if valid_bridge(direct, capability) then
        cached = direct
        return cached
    end

    local explicit_bootstrap = options.bootstrap_if_installed == true
    maybe_bootstrap(options)

    -- Bootstrap may publish the bridge directly. Recheck before touching require().
    direct = from_globals(capability)
    if valid_bridge(direct, capability) then
        cached = direct
        return cached
    end

    local frame = frame_number()
    -- Normal discovery is allowed at most once per retry window. Explicit bootstrap is
    -- tracked separately so a real transform can still acquire a bridge even when an
    -- idle discovery attempt happened earlier in the same frame, without turning the
    -- per-frame form update into an unbounded failed require loop.
    if explicit_bootstrap then
        if frame - last_explicit_attempt_frame < retry_frames then return nil end
        last_explicit_attempt_frame = frame
    else
        if frame - last_attempt_frame < retry_frames then return nil end
        last_attempt_frame = frame
    end
    local module = try_require(capability)
    if valid_bridge(module, capability) then
        cached = module
        METAMORPH_CREATIVE_MENU_NP = module
        return cached
    end
    return nil
end

function patcher_bridge.has(name, options)
    options = type(options) == "table" and options or {}
    options.capability = name
    local bridge = patcher_bridge.get(options)
    return bridge ~= nil and type(bridge[name]) == "function"
end

METAMORPH_CREATIVE_MENU_BRIDGE_API = patcher_bridge
return patcher_bridge
