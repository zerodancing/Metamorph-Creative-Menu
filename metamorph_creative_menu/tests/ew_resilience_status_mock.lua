local root = assert(arg[1], "root required")
local native_dofile = dofile
dofile = function(path)
    if path == "mods/metamorph_creative_menu/files/integrations/ew/resilience_patches.lua" then
        return native_dofile(root .. "/files/integrations/ew/resilience_patches.lua")
    end
    return native_dofile(path)
end
local world_path = "mods/quant.ew/files/system/world_sync/world_sync.lua"
local perk_path = "mods/quant.ew/files/core/perk_fns.lua"
local helper_path = "mods/quant.ew/files/system/homunculus/homunculus.lua"
local mutation_path = "mods/quant.ew/files/system/perk_patches/perk_patches.lua"
local contents = {
    [world_path] = "-- mcm_poly_world_sync_v3\nreturn {}",
    [perk_path] = "local global_perks = {} -- mcm_peer_perk_isolation_v1 mcm_peer_perk_sync_v3\n-- mcm_peer_perk_removal_v1\nreturn {}",
    [helper_path] = "-- mcm_perk_helper_sync_v1\nreturn {}",
    [mutation_path] = "-- mcm_perk_mutation_sync_v1\nreturn {}",
}
local globals = {}
local ew_enabled = true

ModIsEnabled = function(id) return id == "quant.ew" and ew_enabled end
ModTextFileGetContent = function(path) return contents[path] or "-- unrelated file" end
ModTextFileSetContent = function(path, content) contents[path] = content end
GlobalsSetValue = function(key, value) globals[key] = tostring(value) end

local resilience = assert(native_dofile(root .. "/files/integrations/ew/resilience.lua"))
resilience.pre_init()
local status = resilience.critical_patch_status()
assert(status.world_sync == "already_present", "existing world-sync patch was not recognized")
assert(status.peer_perks == "already_present", "existing peer-perk patch was not recognized")
assert(status.perk_helpers == "already_present", "existing perk-helper patch was not recognized")
assert(status.perk_mutations == "already_present", "existing perk-mutation patch was not recognized")
assert(globals.mcm_compat_world_sync_patch_v1 == "already_present", "world-sync patch status was not published")
assert(globals.mcm_compat_peer_perk_patch_v1 == "already_present", "peer-perk patch status was not published")
assert(globals.mcm_compat_perk_helper_patch_v1 == "already_present", "perk-helper patch status was not published")
assert(globals.mcm_compat_perk_mutation_patch_v1 == "already_present", "perk-mutation patch status was not published")

contents[world_path] = "-- incompatible world sync source"
contents[perk_path] = "-- incompatible perk source"
contents[helper_path] = "-- incompatible helper source"
contents[mutation_path] = "-- incompatible mutation source"
resilience.pre_init()
status = resilience.critical_patch_status()
assert(status.world_sync == "anchor_mismatch", "world-sync anchor mismatch was not surfaced")
assert(status.peer_perks == "anchor_mismatch", "peer-perk anchor mismatch was not surfaced")
assert(status.perk_helpers == "anchor_mismatch", "perk-helper anchor mismatch was not surfaced")
assert(status.perk_mutations == "anchor_mismatch", "perk-mutation anchor mismatch was not surfaced")

ew_enabled = false
resilience.pre_init()
status = resilience.critical_patch_status()
assert(status.world_sync == "disabled" and status.peer_perks == "disabled" and status.perk_helpers == "disabled" and status.perk_mutations == "disabled", "disabled EW state was not explicit")
print("ew_resilience_status=PASS verified_critical_patches=true")
