local root = assert(arg[1], "root required")
local globals = {}
local created = {}
local time_calls = 0
local enable_calls = 0

ctx = {
    my_id = "me",
    rpc_peer_id = "peer",
    rpc_player_data = { entity=42, currently_polymorphed=true, fps=60 },
}
GameGetRealWorldTimeSinceStarted = function()
    time_calls = time_calls + 1
    return time_calls == 1 and 10.000 or 10.012
end
GameGetFrameNum = function() return 100 end
GlobalsSetValue = function(key, value) globals[key] = tostring(value) end
EntityGetIsAlive = function(entity) return entity == 42 or entity == 43 or entity == 44 end
EntityHasTag = function(entity, tag) return entity == 42 and tag == "ew_client" end
EntityGetAllChildren = function(entity)
    if entity == 42 then return {43,44} end
    return {}
end
EntityGetTransform = function() return 0, 0, 0, 1, 1 end
EntitySetTransform = function() end
EntitySetComponentIsEnabled = function(entity, component, enabled)
    assert(enabled == false or enabled == true)
    enable_calls = enable_calls + 1
end
EntityGetComponentIncludingDisabled = function(entity, component_type)
    if component_type == "VariableStorageComponent" and entity == 42 then return {501} end
    if component_type == "WormAIComponent" and entity == 42 then return {301} end
    if component_type == "CellEaterComponent" and entity == 43 then return {302} end
    if component_type == "AIAttackComponent" and entity == 44 then return {303} end
    return {}
end
ComponentGetValue2 = function(component, field)
    if component == 501 then
        if field == "name" then return "metamorph_creative_menu_network_source" end
        if field == "value_string" then return "data/entities/animals/boss_dragon.xml" end
    end
    if component == 101 then
        local values = {
            speed=2, acceleration=3, part_distance=10, ground_check_offset=0,
            hitbox_radius=1, bite_damage=2, target_kill_radius=1,
            target_kill_ragdoll_force=1, eat_anim_wait_mult=0.05, jump_cam_shake=20,
        }
        return values[field] or 0
    end
    if component == 202 and field == "mDirection" then return 0, 0 end
    if component == 201 and (field == "mTargetSpeed" or field == "speed") then return 2 end
    return 0
end
ComponentSetValue2 = function() end
EntityGetFirstComponentIncludingDisabled = function(entity, component_type)
    if entity ~= 42 then return nil end
    if component_type == "BossDragonComponent" then return 101 end
    if component_type == "WormComponent" then return created.WormComponent end
    if component_type == "WormPlayerComponent" then return created.WormPlayerComponent end
    return nil
end
EntityAddComponent2 = function(entity, component_type, values)
    assert(entity == 42)
    local id = component_type == "WormComponent" and 201 or 202
    created[component_type] = id
    return id
end
util = {}

local rpc = {
    opts_reliable=function() end,
    opts_everywhere=function() end,
}
local forms = assert(dofile(root .. "/files/integrations/ew/bridge/forms.lua"))
forms.set_profiling_enabled(true)
forms.register_pose(rpc, {})
assert(type(rpc.sync_form_pose) == "function", "pose rpc was not registered")
rpc.sync_form_pose(10, 100, 200, 0, 1, 1, false, 5, 1, 0, 2)
assert(globals.mcm_form_remote_prepare_ms_v1 == "12.000", "remote prepare timing wrong")
assert(globals.mcm_form_remote_prepare_entities_v1 == "3", "remote tree count wrong")
assert(globals.mcm_form_remote_prepare_components_v1 == "3", "remote component count wrong")
assert(globals.mcm_form_remote_prepare_kind_v1 == "5", "remote kind missing")
assert(globals.mcm_form_remote_prepare_source_v1 == "data/entities/animals/boss_dragon.xml", "remote source missing")
assert(created.WormComponent == 201 and created.WormPlayerComponent == 202, "profiling changed articulated preparation")
local first_time_calls = time_calls
rpc.sync_form_pose(11, 101, 200, 0, 1, 1, false, 5, 1, 0, 2)
assert(time_calls == first_time_calls, "cached pose path still pays profiling timer cost")
print("form_remote_prepare_profile=PASS first_prepare_only=true cached_hotpath_unchanged=true")
