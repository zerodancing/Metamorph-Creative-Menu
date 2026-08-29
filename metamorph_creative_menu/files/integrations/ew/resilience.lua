local ew_resilience = {}

local SEEDED_RANDOM_FILES = {
    "data/scripts/gun/procedural/wand_petri.lua",
    "data/scripts/gun/procedural/chargegun.lua",
    "data/scripts/gun/procedural/digger_01_setup.lua",
    "data/scripts/gun/procedural/elite_machinegun.lua",
    "data/scripts/gun/procedural/elite_pistol.lua",
    "data/scripts/gun/procedural/elite_shotgun.lua",
    "data/scripts/gun/procedural/general_gun.lua",
    "data/scripts/gun/procedural/gun_procedural.lua",
    "data/scripts/gun/procedural/gun_procedural_better.lua",
    "data/scripts/gun/procedural/handgun.lua",
    "data/scripts/gun/procedural/level_1_wand.lua",
    "data/scripts/gun/procedural/machinegun.lua",
    "data/scripts/gun/procedural/nukelauncher.lua",
    "data/scripts/gun/procedural/rocketlauncher.lua",
    "data/scripts/gun/procedural/shotgun.lua",
    "data/scripts/gun/procedural/starting_bomb_wand.lua",
    "data/scripts/gun/procedural/starting_bomb_wand_daily.lua",
    "data/scripts/gun/procedural/starting_wand.lua",
    "data/scripts/gun/procedural/starting_wand_daily.lua",
    "data/scripts/gun/procedural/submachinegun.lua",
    "data/scripts/gun/procedural/wand_daily.lua",
    "data/scripts/items/potion_starting.lua",
}

-- These files execute outside EW's main module context (LuaComponents, appended
-- vanilla callbacks and entity scripts). EW leaves a Lua fallback named CrossCall
-- installed even when the matching optional system is disabled; that fallback then
-- indexes a missing callback and can generate thousands of errors followed by a Lua
-- stack overflow. Keep the call when registered and provide conservative semantics
-- only for the missing-handler case.
-- Never prepend a lexical CrossCall wrapper into Entangled Worlds itself. EW installs
-- and replaces CrossCall handlers as systems initialize; capturing a nil/string value at
-- file-load time poisoned the stable inventory API and produced the observed
-- ew_ff / ew_api_force_send_inventory failures. Keep the helper patcher below only for
-- explicit future compatibility use, but do not apply it to EW core/modules.
local EW_CROSSCALL_FILES = {}

local resilience_patches = dofile("mods/metamorph_creative_menu/files/integrations/ew/resilience_patches.lua")
local DEV_MODE = tonumber(dofile("mods/metamorph_creative_menu/dev_mode.lua")) == 1

-- Compatibility exports: callers that used the old resilience.patch_* API keep working,
-- while the implementation now lives in the dedicated pure patch module.
ew_resilience.patch_crosscall_source = resilience_patches.patch_crosscall_source
ew_resilience.patch_wand_pickup_killself_source = resilience_patches.patch_wand_pickup_killself_source
ew_resilience.patch_seed_source = resilience_patches.patch_seed_source
ew_resilience.patch_detour_source = resilience_patches.patch_detour_source
ew_resilience.patch_world_sync_source = resilience_patches.patch_world_sync_source
ew_resilience.patch_polymorph_death_source = resilience_patches.patch_polymorph_death_source
ew_resilience.patch_polymorph_profile_source = resilience_patches.patch_polymorph_profile_source
ew_resilience.patch_material_pixel_scene_source = resilience_patches.patch_material_pixel_scene_source
ew_resilience.patch_peer_perk_isolation_source = resilience_patches.patch_peer_perk_isolation_source
ew_resilience.patch_perk_helper_sync_source = resilience_patches.patch_perk_helper_sync_source
ew_resilience.patch_perk_mutation_sync_source = resilience_patches.patch_perk_mutation_sync_source

local function enabled()
    local ok, value = pcall(ModIsEnabled, "quant.ew")
    return ok and value == true
end

local function patch_file(path, patcher)
    local ok, content = pcall(ModTextFileGetContent, path)
    if not ok or type(content) ~= "string" or content == "" then return 0 end
    local changed, count = patcher(content)
    if tonumber(count) ~= nil and count > 0 then ModTextFileSetContent(path, changed) end
    return tonumber(count) or 0
end

local CRITICAL_PATCHES = {
    form_death = {
        path = "mods/quant.ew/files/system/polymorph/polymorph.lua",
        marker = "mcm_poly_death_intercept_v1",
        patcher = ew_resilience.patch_polymorph_death_source,
        global_key = "mcm_compat_form_death_patch_v1",
    },
    world_sync = {
        path = "mods/quant.ew/files/system/world_sync/world_sync.lua",
        marker = "mcm_poly_world_sync_v3",
        patcher = function(content) return ew_resilience.patch_world_sync_source(content, DEV_MODE) end,
        global_key = "mcm_compat_world_sync_patch_v1",
    },
    material_scenes = {
        path = "mods/quant.ew/files/system/wang_hooks/synced_pixel_scenes.lua",
        marker = "mcm_material_brush_pixel_scene_v1",
        patcher = ew_resilience.patch_material_pixel_scene_source,
        global_key = "mcm_compat_material_scene_patch_v1",
    },
    peer_perks = {
        path = "mods/quant.ew/files/core/perk_fns.lua",
        marker = "mcm_peer_perk_sync_v4",
        patcher = ew_resilience.patch_peer_perk_isolation_source,
        global_key = "mcm_compat_peer_perk_patch_v1",
    },
    perk_helpers = {
        path = "mods/quant.ew/files/system/homunculus/homunculus.lua",
        marker = "mcm_perk_helper_sync_v1",
        patcher = ew_resilience.patch_perk_helper_sync_source,
        global_key = "mcm_compat_perk_helper_patch_v1",
    },
    perk_mutations = {
        path = "mods/quant.ew/files/system/perk_patches/perk_patches.lua",
        marker = "mcm_perk_mutation_sync_v1",
        patcher = ew_resilience.patch_perk_mutation_sync_source,
        global_key = "mcm_compat_perk_mutation_patch_v1",
    },
}

local critical_patch_status = {form_death="unknown", world_sync="unknown", material_scenes="unknown", peer_perks="unknown", perk_helpers="unknown", perk_mutations="unknown"}
local surfaced_patch_failures = {}

local function translated(key, fallback)
    if type(GameTextGetTranslatedOrNot) == "function" then
        local ok, value = pcall(GameTextGetTranslatedOrNot, key)
        if ok and type(value) == "string" and value ~= "" and value ~= key then return value end
    end
    return fallback
end

local function publish_patch_status(name, status)
    critical_patch_status[name] = status
    local spec = CRITICAL_PATCHES[name]
    if spec ~= nil and type(GlobalsSetValue) == "function" then
        pcall(GlobalsSetValue, spec.global_key, tostring(status))
    end
    return status
end

local function surface_critical_patch_failures()
    for name, status in pairs(critical_patch_status) do
        if status ~= "applied" and status ~= "already_present" and status ~= "disabled" then
            local signature = tostring(name) .. ":" .. tostring(status)
            if not surfaced_patch_failures[signature] then
                surfaced_patch_failures[signature] = true
                local diagnostic_message = "[Metamorph: Creative Menu] Entangled Worlds compatibility patch failed: "
                    .. tostring(name) .. " (" .. tostring(status) .. ")"
                local user_message = translated("$mcm_ew_compat_failed",
                    "Entangled Worlds compatibility error") .. ": "
                    .. tostring(name) .. " (" .. tostring(status) .. ")"
                print(diagnostic_message)
                if type(GamePrint) == "function" then pcall(GamePrint, user_message) end
                if type(METAMORPH_CREATIVE_MENU_DIAGNOSTICS_CAPTURE) == "function" then
                    pcall(METAMORPH_CREATIVE_MENU_DIAGNOSTICS_CAPTURE,
                        "ew.compatibility." .. tostring(name), tostring(status))
                end
            end
        end
    end
end

local function apply_verified_patch(name)
    local spec = CRITICAL_PATCHES[name]
    if spec == nil then return "unknown" end
    local read_ok, content = pcall(ModTextFileGetContent, spec.path)
    if not read_ok or type(content) ~= "string" or content == "" then
        return publish_patch_status(name, "read_failed")
    end
    if string.find(content, spec.marker, 1, true) ~= nil then
        return publish_patch_status(name, "already_present")
    end
    local patch_ok, changed, count = pcall(spec.patcher, content)
    if not patch_ok or type(changed) ~= "string" or tonumber(count) == nil or tonumber(count) <= 0 then
        return publish_patch_status(name, "anchor_mismatch")
    end
    if string.find(changed, spec.marker, 1, true) == nil then
        return publish_patch_status(name, "verification_failed")
    end
    local write_ok = pcall(ModTextFileSetContent, spec.path, changed)
    if not write_ok then return publish_patch_status(name, "write_failed") end
    return publish_patch_status(name, "applied")
end

local function patch_world_sync_file()
    return apply_verified_patch("world_sync")
end

local function patch_polymorph_profile_file()
    local path = "mods/quant.ew/files/system/polymorph/polymorph.lua"
    local function finish(status)
        if type(GlobalsSetValue) == "function" then
            pcall(GlobalsSetValue, "mcm_compat_poly_profile_patch_v1", tostring(status))
        end
        return status
    end
    local ok, content = pcall(ModTextFileGetContent, path)
    if not ok or type(content) ~= "string" or content == "" then return finish("read_failed") end
    if string.find(content, "mcm_poly_profile_v1", 1, true) ~= nil then return finish("already_present") end
    local patch_ok, changed, count = pcall(ew_resilience.patch_polymorph_profile_source, content)
    if not patch_ok or type(changed) ~= "string" or (tonumber(count) or 0) <= 0
        or string.find(changed, "mcm_poly_profile_v1", 1, true) == nil
    then return finish("anchor_mismatch") end
    if not pcall(ModTextFileSetContent, path, changed) then return finish("write_failed") end
    return finish("applied")
end

local function patch_peer_perk_isolation_file()
    return apply_verified_patch("peer_perks")
end

local function patch_perk_helper_sync_file()
    return apply_verified_patch("perk_helpers")
end

function ew_resilience.critical_patch_status()
    return {
        form_death=critical_patch_status.form_death,
        world_sync=critical_patch_status.world_sync,
        material_scenes=critical_patch_status.material_scenes,
        peer_perks=critical_patch_status.peer_perks,
        perk_helpers=critical_patch_status.perk_helpers,
        perk_mutations=critical_patch_status.perk_mutations,
    }
end

local function attribute_values(content, name)
    local result = {}
    local pattern = name .. '%s*=%s*"([^"]+)"'
    for value in string.gmatch(content or "", pattern) do result[#result + 1] = value end
    local single = name .. "%s*=%s*'([^']+)'"
    for value in string.gmatch(content or "", single) do result[#result + 1] = value end
    return result
end

local function biome_scripts()
    local scripts, seen = {}, {}
    local function add(path)
        if type(path) == "string" and path ~= "" and not seen[path] then
            seen[path] = true
            scripts[#scripts + 1] = path
        end
    end
    for _, path in ipairs({
        "data/scripts/biome_scripts.lua",
        "data/biome_impl/static_tile/watchtower.lua",
        "data/biome_impl/static_tile/temples_common.lua",
    }) do add(path) end

    local ok, all_biomes = pcall(ModTextFileGetContent, "data/biome/_biomes_all.xml")
    if ok and type(all_biomes) == "string" then
        for _, biome in ipairs(attribute_values(all_biomes, "biome_filename")) do
            local read_ok, xml = pcall(ModTextFileGetContent, biome)
            if read_ok and type(xml) == "string" then
                for _, script in ipairs(attribute_values(xml, "lua_script")) do add(script) end
            end
        end
    end
    return scripts
end

local function patch_seed_files()
    local count = 0
    for _, path in ipairs(SEEDED_RANDOM_FILES) do count = count + patch_file(path, ew_resilience.patch_seed_source) end
    return count
end

local function patch_crosscall_files()
    local count = 0
    for _, relative in ipairs(EW_CROSSCALL_FILES) do
        count = count + patch_file("mods/quant.ew/" .. relative, ew_resilience.patch_crosscall_source)
    end
    -- This helper executes in an entity Lua VM. If a save resumes before EW's
    -- ew_is_wand_pickup callback is registered, the unguarded line survives forever
    -- and throws once per frame. Conservative failure semantics are to retire the
    -- temporary helper, exactly as the normal false result does.
    count = count + patch_file(
        "mods/quant.ew/files/system/entity_sync_helper/scripts/killself.lua",
        ew_resilience.patch_wand_pickup_killself_source)
    return count
end

function ew_resilience.pre_init()
    if not enabled() then
        publish_patch_status("form_death", "disabled")
        publish_patch_status("world_sync", "disabled")
        publish_patch_status("material_scenes", "disabled")
        publish_patch_status("peer_perks", "disabled")
        publish_patch_status("perk_helpers", "disabled")
        publish_patch_status("perk_mutations", "disabled")
        if type(GlobalsSetValue) == "function" then
            pcall(GlobalsSetValue, "mcm_compat_poly_profile_patch_v1", "disabled")
        end
        return 0
    end
    apply_verified_patch("form_death")
    patch_world_sync_file()
    if DEV_MODE then
        patch_polymorph_profile_file()
    elseif type(GlobalsSetValue) == "function" then
        pcall(GlobalsSetValue, "mcm_compat_poly_profile_patch_v1", "disabled")
    end
    apply_verified_patch("material_scenes")
    patch_peer_perk_isolation_file()
    patch_perk_helper_sync_file()
    apply_verified_patch("perk_mutations")
    return patch_seed_files(), patch_crosscall_files()
end

function ew_resilience.post_init()
    if not enabled() then
        publish_patch_status("form_death", "disabled")
        publish_patch_status("world_sync", "disabled")
        publish_patch_status("material_scenes", "disabled")
        publish_patch_status("peer_perks", "disabled")
        publish_patch_status("perk_helpers", "disabled")
        publish_patch_status("perk_mutations", "disabled")
        if type(GlobalsSetValue) == "function" then
            pcall(GlobalsSetValue, "mcm_compat_poly_profile_patch_v1", "disabled")
        end
        return 0, 0
    end
    local seeds = patch_seed_files()
    local detours = 0
    for _, path in ipairs(biome_scripts()) do detours = detours + patch_file(path, ew_resilience.patch_detour_source) end
    local crosscalls = patch_crosscall_files()
    apply_verified_patch("form_death")
    patch_world_sync_file()
    if DEV_MODE then
        patch_polymorph_profile_file()
    elseif type(GlobalsSetValue) == "function" then
        pcall(GlobalsSetValue, "mcm_compat_poly_profile_patch_v1", "disabled")
    end
    apply_verified_patch("material_scenes")
    patch_peer_perk_isolation_file()
    patch_perk_helper_sync_file()
    apply_verified_patch("perk_mutations")
    surface_critical_patch_failures()
    return seeds, detours, crosscalls
end

return ew_resilience
