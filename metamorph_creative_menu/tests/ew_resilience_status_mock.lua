local root = assert(arg[1], "root required")
local native_dofile = dofile
dofile = function(path)
    if path == "mods/metamorph_creative_menu/files/integrations/ew/resilience_patches.lua" then
        return native_dofile(root .. "/files/integrations/ew/resilience_patches.lua")
    end
    if path == "mods/metamorph_creative_menu/dev_mode.lua" then return 1 end
    return native_dofile(path)
end
local world_path = "mods/quant.ew/files/system/world_sync/world_sync.lua"
local material_scene_path = "mods/quant.ew/files/system/wang_hooks/synced_pixel_scenes.lua"
local perk_path = "mods/quant.ew/files/core/perk_fns.lua"
local helper_path = "mods/quant.ew/files/system/homunculus/homunculus.lua"
local mutation_path = "mods/quant.ew/files/system/perk_patches/perk_patches.lua"
local polymorph_path = "mods/quant.ew/files/system/polymorph/polymorph.lua"
local contents = {
    [world_path] = "-- mcm_poly_world_sync_v3\nreturn {}",
    [material_scene_path] = "-- mcm_material_brush_pixel_scene_v1\nreturn {}",
    [perk_path] = "local global_perks = {} -- mcm_peer_perk_sync_v4\n-- mcm_peer_perk_removal_v1\nreturn {}",
    [helper_path] = "-- mcm_perk_helper_sync_v1\nreturn {}",
    [mutation_path] = "-- mcm_perk_mutation_sync_v1\nreturn {}",
    [polymorph_path] = "-- mcm_poly_profile_v1\n-- mcm_poly_death_intercept_v1\nreturn {}",
}
local globals = {}
local game_messages = {}
local ew_enabled = true

ModIsEnabled = function(id) return id == "quant.ew" and ew_enabled end
ModTextFileGetContent = function(path) return contents[path] or "-- unrelated file" end
ModTextFileSetContent = function(path, content) contents[path] = content end
GlobalsSetValue = function(key, value) globals[key] = tostring(value) end
GamePrint = function(message) game_messages[#game_messages + 1] = tostring(message) end

local resilience = assert(native_dofile(root .. "/files/integrations/ew/resilience.lua"))
resilience.pre_init()
local status = resilience.critical_patch_status()
assert(status.form_death == "already_present", "existing form-death patch was not recognized")
assert(status.world_sync == "already_present", "existing world-sync patch was not recognized")
assert(status.material_scenes == "already_present", "existing material-scene patch was not recognized")
assert(status.peer_perks == "already_present", "existing peer-perk patch was not recognized")
assert(status.perk_helpers == "already_present", "existing perk-helper patch was not recognized")
assert(status.perk_mutations == "already_present", "existing perk-mutation patch was not recognized")
assert(globals.mcm_compat_world_sync_patch_v1 == "already_present", "world-sync patch status was not published")
assert(globals.mcm_compat_form_death_patch_v1 == "already_present", "form-death patch status was not published")
assert(globals.mcm_compat_material_scene_patch_v1 == "already_present", "material-scene patch status was not published")
assert(globals.mcm_compat_peer_perk_patch_v1 == "already_present", "peer-perk patch status was not published")
assert(globals.mcm_compat_perk_helper_patch_v1 == "already_present", "perk-helper patch status was not published")
assert(globals.mcm_compat_perk_mutation_patch_v1 == "already_present", "perk-mutation patch status was not published")
assert(globals.mcm_compat_poly_profile_patch_v1 == "already_present", "polymorph profiler patch status was not published")

contents[world_path] = "-- incompatible world sync source"
contents[material_scene_path] = "-- incompatible material scene source"
contents[perk_path] = "-- incompatible perk source"
contents[helper_path] = "-- incompatible helper source"
contents[mutation_path] = "-- incompatible mutation source"
contents[polymorph_path] = "-- incompatible polymorph source"
resilience.pre_init()
status = resilience.critical_patch_status()
assert(status.form_death == "anchor_mismatch", "form-death anchor mismatch was not surfaced")
assert(status.world_sync == "anchor_mismatch", "world-sync anchor mismatch was not surfaced")
assert(status.material_scenes == "anchor_mismatch", "material-scene anchor mismatch was not surfaced")
assert(status.peer_perks == "anchor_mismatch", "peer-perk anchor mismatch was not surfaced")
assert(status.perk_helpers == "anchor_mismatch", "perk-helper anchor mismatch was not surfaced")
assert(status.perk_mutations == "anchor_mismatch", "perk-mutation anchor mismatch was not surfaced")
resilience.post_init()
assert(#game_messages >= 6, "critical EW compatibility failures remained hidden from the player")
local visible = table.concat(game_messages, "\n")
assert(string.find(visible, "world_sync", 1, true), "world-sync failure was not shown to the player")
assert(string.find(visible, "form_death", 1, true), "form-death failure was not shown to the player")

ew_enabled = false
resilience.pre_init()
status = resilience.critical_patch_status()
assert(status.form_death == "disabled" and status.world_sync == "disabled" and status.material_scenes == "disabled" and status.peer_perks == "disabled" and status.perk_helpers == "disabled" and status.perk_mutations == "disabled", "disabled EW state was not explicit")
assert(globals.mcm_compat_poly_profile_patch_v1 == "disabled", "disabled profiler patch state was not explicit")
print("ew_resilience_status=PASS verified_critical_patches=true")
