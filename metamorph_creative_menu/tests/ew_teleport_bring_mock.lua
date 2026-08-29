local root = assert(arg[1], "root required")

local globals = {}
local sends = {}
local errors = {}
local receiver = nil
local camera = {}
local loaded = true
local frame = 20
local transforms = { [10]={0,0}, [20]={100,100}, [30]={220,100} }

ctx = {
    my_id="peer-target",
    my_player={entity=10},
    players={
        ["peer-target"]={entity=10},
        ["peer-source"]={entity=20},
        ["peer-other"]={entity=30},
    },
    rpc_player_data={entity=20},
}

function GlobalsGetValue(key, fallback) return globals[key] or fallback end
function GlobalsSetValue(key, value) globals[key]=tostring(value) end
function GameGetFrameNum() return frame end
function DoesWorldExistAt() return loaded end
function FindFreePositionForBody(x, y, _, _, radius) return x + 2, y - radius end
function EntityGetIsAlive(entity) return transforms[entity] ~= nil end
function EntityGetTransform(entity) return transforms[entity][1], transforms[entity][2] end
function EntitySetTransform(entity, x, y) transforms[entity]={x,y} end
function EntityGetFirstComponentIncludingDisabled() return 70 end
function ComponentSetValue2() end
function GameSetCameraPos(x, y) camera[#camera+1]={x,y} end

local rpc_proxy = {}
setmetatable(rpc_proxy, {
    __newindex=function(table_value, key, value)
        if key == "request_bring" then
            receiver = value
            rawset(table_value, key, function(...)
                sends[#sends+1]={...}
            end)
        else
            rawset(table_value, key, value)
        end
    end,
})
function rpc_proxy.opts_reliable() end
function rpc_proxy.opts_everywhere() end

local ew_api = {
    new_rpc_namespace=function(namespace)
        assert(namespace == "metamorph_creative_menu:teleport:v1:", "teleport RPC namespace changed")
        return rpc_proxy
    end,
}
local common = {
    finite_number=function(value)
        value=tonumber(value)
        return value ~= nil and value == value and value ~= math.huge and value ~= -math.huge
    end,
    report_error=function(scope, reason) errors[#errors+1]={scope,reason} end,
}

local bridge = assert(loadfile(root .. "/files/integrations/ew/bridge/teleport.lua"))()
bridge.register(ew_api, common)
assert(type(receiver) == "function", "bring receiver was not registered")

globals.mcm_teleport_bring_outbox_seq_v1="1"
globals.mcm_teleport_bring_outbox_peer_v1_1="peer-other"
globals.mcm_teleport_bring_outbox_target_x_v1_1="220"
globals.mcm_teleport_bring_outbox_target_y_v1_1="100"
globals.mcm_teleport_bring_outbox_dest_x_v1_1="18"
globals.mcm_teleport_bring_outbox_dest_y_v1_1="0"
bridge.update()
assert(#sends == 1 and sends[1][1] == "peer-other" and sends[1][2] == 18 and sends[1][3] == 0,
    "bring outbox was not routed to the selected peer")
assert(globals.mcm_teleport_bring_outbox_ack_v1 == "1" and #errors == 0,
    "bring outbox was not acknowledged atomically")

local camera_before = #camera
receiver("peer-target", 500, 500)
assert(#camera == camera_before, "untrusted destination far from sender was accepted")
receiver("another-peer", 118, 100)
assert(#camera == camera_before, "bring request was accepted by a non-target peer")

loaded = false
receiver("peer-target", 118, 100)
assert(#camera == camera_before + 1, "valid bring request did not begin streaming")
bridge.update()
assert(transforms[10][1] == 0 and transforms[10][2] == 0,
    "player moved before the destination was loaded")
loaded = true
frame = frame + 1
bridge.update()
assert(transforms[10][1] == 120 and transforms[10][2] == 91,
    "target peer did not use the engine-provided free position")

print("ew_teleport_bring=PASS targeted=true sender_bounded=true streaming=true safe_position=true")
