if type(METAMORPH_CREATIVE_MENU_CREATURE_COMPATIBILITY) == "table" then return METAMORPH_CREATIVE_MENU_CREATURE_COMPATIBILITY end

local compatibility = {}
local overrides = dofile("mods/metamorph_creative_menu/files/features/creatures/compatibility_overrides.lua")

local native_polymorph_paths = nil

local function normalized_path(path)
    return string.lower(tostring(path or ""))
end

local function copy_map(source)
    local result = {}
    for path, reason in pairs(type(source) == "table" and source or {}) do
        result[normalized_path(path)] = tostring(reason or "manual")
    end
    return result
end

local safe_paths = copy_map(overrides.safe)
local unsafe_paths = copy_map(overrides.unsafe)
local canonical_paths = {}
for source, target in pairs(type(overrides.canonical) == "table" and overrides.canonical or {}) do
    canonical_paths[normalized_path(source)] = tostring(target or "")
end

local function load_native_polymorph_paths()
    if native_polymorph_paths ~= nil then return native_polymorph_paths end
    -- Do not permanently cache "unavailable" during early mod load; Noita exposes the
    -- polymorph tables later than some Lua modules can be parsed/loaded.
    if type(PolymorphTableGet) ~= "function" then return {} end
    native_polymorph_paths = {}
    for _, rare in ipairs({ false, true }) do
        local ok, values = pcall(PolymorphTableGet, rare)
        if ok and type(values) == "table" then
            for _, path in ipairs(values) do
                if type(path) == "string" and path ~= "" then
                    native_polymorph_paths[normalized_path(path)] = rare and "noita_polymorph_rare" or "noita_polymorph_common"
                end
            end
        end
    end
    return native_polymorph_paths
end

function compatibility.unsafe_reason(path)
    return unsafe_paths[normalized_path(path)]
end

function compatibility.safe_reason(path)
    local key = normalized_path(path)
    if unsafe_paths[key] ~= nil then return nil end
    if safe_paths[key] ~= nil then return safe_paths[key] end
    return load_native_polymorph_paths()[key]
end

function compatibility.canonical_target(path)
    local target = canonical_paths[normalized_path(path)]
    if type(target) ~= "string" or target == "" then return nil end
    return target
end

function compatibility.status(path, structurally_supported)
    local unsafe = compatibility.unsafe_reason(path)
    if unsafe ~= nil then
        return "unsafe", unsafe
    end
    local safe = compatibility.safe_reason(path)
    if safe ~= nil then
        return "verified", safe
    end
    if structurally_supported == true then
        return "candidate", "structural_preflight_only"
    end
    return "unsupported", "no_supported_creature_structure"
end

function compatibility.known_safe_forms()
    local result = {}
    for path, reason in pairs(safe_paths) do result[path] = reason end
    return result
end

function compatibility.known_unsafe_forms()
    local result = {}
    for path, reason in pairs(unsafe_paths) do result[path] = reason end
    return result
end

function compatibility.invalidate_runtime_cache()
    native_polymorph_paths = nil
end

METAMORPH_CREATIVE_MENU_CREATURE_COMPATIBILITY = compatibility
return compatibility
