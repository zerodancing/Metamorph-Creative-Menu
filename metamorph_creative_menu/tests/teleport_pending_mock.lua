local root=assert(arg[1])
local frame=1
local pos={0,0}
local old_loaded=false
function GameGetFrameNum() return frame end
function EntityGetIsAlive(e) return e==1 end
function EntityGetTransform() return pos[1],pos[2] end
function EntitySetTransform(_,x,y) pos={x,y} end
function EntityGetFirstComponentIncludingDisabled() return 7 end
function ComponentSetValue2() end
function DoesWorldExistAt(minx,_,maxx) local x=(minx+maxx)/2; if math.abs(x-1000)<100 then return old_loaded end; return true end
function FindFreePositionForBody(x,y) return x,y end
function EntityLoad() return 2 end
function GameSetCameraPos() end
function GlobalsGetValue(_,f) return f end
function GlobalsSetValue() end
METAMORPH_CREATIVE_MENU_PLAYER_TOOLS=nil
local service=assert(loadfile(root..'/files/features/player_tools/service.lua'))()
local ok,why=service.teleport_position(1,1000,0)
assert(ok and why=='streaming' and service.has_pending_teleport(),'old unloaded teleport was not queued')
ok,why=service.teleport_position(1,200,0)
assert(ok and why=='teleported' and pos[1]==200 and not service.has_pending_teleport(),'new immediate teleport did not supersede old pending request')
old_loaded=true; frame=2
ok,why=service.update()
assert(ok==false and why=='idle' and pos[1]==200,'older pending teleport fired after newer teleport')
print('teleport_pending=PASS newer_supersedes_old=true')
