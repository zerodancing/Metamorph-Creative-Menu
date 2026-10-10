local root = assert(arg[1], "root required")
local applied = {}
ctx = { my_id="me", rpc_peer_id="peer", rpc_player_data={entity=42, currently_polymorphed=true, fps=60} }
EntityGetIsAlive = function(entity) return entity == 42 or entity == 43 end
EntityHasTag = function(entity, tag) return tag == "ew_client" and (entity == 42 or entity == 43) end
EntityGetTransform = function(entity) return entity * 1.0, 0, 0, 1, 1 end
EntitySetTransform = function(entity, x, y) applied[#applied + 1] = {entity=entity, x=x, y=y} end
EntityGetFirstComponentIncludingDisabled = function(entity, component_type)
    if component_type == "CharacterDataComponent" then return entity + 100 end
    return nil
end
ComponentSetValue2 = function(component, field, x, y)
    if field == "mVelocity" then applied[#applied + 1] = {component=component, x=x, y=y} end
end
EntityGetComponentIncludingDisabled = function() return {} end
GameGetRealWorldTimeSinceStarted = function() return 1 end
GlobalsSetValue = function() end
util = {}
local rpc = { opts_reliable=function() end, opts_everywhere=function() end }
local forms = assert(dofile(root .. "/files/integrations/ew/bridge/forms.lua"))
forms.register_pose(rpc, {})

rpc.sync_form_pose(100, 10, 20, 0, 1, 1, false, 1, 3, 4, 0)
local sent, received = forms.metrics()
assert(received == 1, "first generation pose was not accepted")

-- Simulate EW replacing the remote player's entity after a reconnect/restart. The new
-- sender process can legitimately have a much lower GameGetFrameNum().
ctx.rpc_player_data.entity = 43
rpc.sync_form_pose(5, 30, 40, 0, 1, 1, false, 1, 5, 6, 0)
sent, received = forms.metrics()
assert(received == 2, "new remote entity inherited stale source-frame watermark")

-- Reordering protection must still work inside the new generation.
rpc.sync_form_pose(4, 50, 60, 0, 1, 1, false, 1, 7, 8, 0)
sent, received = forms.metrics()
assert(received == 2, "older pose was accepted inside the same remote generation")
print("form_pose_entity_generation=PASS reconnect_frame_reset=true reorder_guard_preserved=true")
