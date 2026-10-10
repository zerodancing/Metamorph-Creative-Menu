local root = assert(arg[1], "root required")

METAMORPH_CREATIVE_MENU_PLAYER_TOOLS = nil

local frame = 10
local loaded = true
local scans = 0
local camera = {}
local transforms = { [1]={0,0}, [2]={100,200} }
local globals = {}
local velocity = nil
local free_request = nil

function GameGetFrameNum() return frame end
function EntityGetIsAlive(entity) return transforms[entity] ~= nil end
function EntityGetWithTag(tag)
    scans = scans + 1
    if tag == "ew_client" or tag == "ew_peer" then return {2} end
    if tag == "player_unit" then return {1} end
    return {}
end
function EntityGetTransform(entity)
    local value = assert(transforms[entity], "unexpected entity")
    return value[1], value[2]
end
function EntitySetTransform(entity, x, y) transforms[entity] = {x,y} end
function EntityGetName(entity) return entity == 2 and "peer-two" or "" end
function DoesWorldExistAt() return loaded end
function FindFreePositionForBody(x, y, vx, vy, radius)
    free_request = {x=x,y=y,vx=vx,vy=vy,radius=radius}
    return x + 3, y - 10
end
function EntityGetFirstComponentIncludingDisabled() return 77 end
function ComponentSetValue2(component, field, x, y) velocity={component,field,x,y} end
function EntityLoad() return 90 end
function GameSetCameraPos(x, y) camera[#camera+1]={x,y} end
function GlobalsGetValue(key, fallback) return globals[key] or fallback end
function GlobalsSetValue(key, value) globals[key]=tostring(value) end

local service = assert(loadfile(root .. "/files/features/player_tools/service.lua"))()

assert(scans == 0, "player list was scanned while the service loaded")
local idle, idle_reason = service.update()
assert(idle == false and idle_reason == "idle" and scans == 0,
    "idle per-frame update scanned network players")

local visible = service.visible_players()
assert(#visible == 2 and scans == 4, "demand-driven player enumeration lost or duplicated peers")

local ok, reason = service.teleport_to(2, 1)
assert(ok == true and reason == "teleported", "loaded player teleport did not complete")
assert(free_request.x == 118 and free_request.y == 200 and free_request.radius == 9,
    "teleport did not request free space beside the target")
assert(transforms[1][1] == 121 and transforms[1][2] == 190,
    "safe position returned by the engine was not used")
assert(velocity and velocity[3] == 0 and velocity[4] == 0,
    "velocity was not cleared before teleport")

loaded = false
ok, reason = service.teleport_location("tree", 1)
assert(ok == true and reason == "streaming" and service.has_pending_teleport(),
    "unloaded location was not queued for streaming")
assert(#camera == 1 and camera[1][1] == -1902 and camera[1][2] == -1405,
    "camera did not start destination streaming")
frame = frame + 1
local waiting, waiting_reason = service.update()
assert(waiting == false and waiting_reason == "streaming" and #camera == 2,
    "pending destination was not kept alive while unloaded")
loaded = true
frame = frame + 1
ok, reason = service.update()
assert(ok == true and reason == "teleported" and not service.has_pending_teleport(),
    "streamed location did not finish at a free position")

ok, reason = service.bring_to_me(2, 1)
assert(ok == true and reason == "queued", "bring request was not queued")
assert(globals.mcm_teleport_bring_outbox_seq_v1 == "1"
    and globals.mcm_teleport_bring_outbox_peer_v1_1 == "peer-two",
    "bring request did not preserve the authoritative peer identity")

print("player_tools_safe_teleport=PASS demand_driven=true free_space=true streaming=true bring_outbox=true")
