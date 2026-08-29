local root=assert(arg[1],"root required")
local values={}

function GlobalsGetValue(key,default)
    local value=values[key]
    if value==nil or value=="" then return default end
    return value
end
function GlobalsSetValue(key,value) values[key]=tostring(value) end

local ew_enabled=true
function ModIsEnabled(name) return name=="quant.ew" and ew_enabled end

METAMORPH_CREATIVE_MENU_EW_MATERIAL_PAINT_SYNC=nil
local sync=assert(loadfile(root.."/files/integrations/ew/material_paint_sync.lua"))()
assert(sync.capacity()==32 and sync.max_points()==24,"bounded transport constants changed")
assert(sync.publish_batch("bad|material",false,1,{{1,2}})==false,"unsafe material identifier accepted")
assert(sync.publish_batch("water",false,1,{})==false,"empty point batch accepted")
assert(sync.publish_batch("water",false,1,{{0/0,2}})==false,"non-finite coordinate accepted")

assert(sync.publish_batch("water",false,3,{{12,-7},{13,-6}})==true,"valid paint batch rejected")
assert(sync.outbox_sequence()==1,"first sequence was not published")
local payload=assert(sync.read_outbox(1),"first outbox slot missing")
local decoded=assert(sync.decode_batch(payload),"valid payload did not decode")
assert(decoded.material_name=="water" and decoded.solid==false and decoded.brush_index==3,"payload metadata changed")
assert(decoded.points[1][1]==12 and decoded.points[1][2]==-7 and #decoded.points==2,"payload coordinates changed")

sync.mark_ack(1)
assert(sync.ack_sequence()==1,"acknowledge did not advance")
sync.mark_ack(0)
assert(sync.ack_sequence()==1,"acknowledge moved backwards")

for i=2,sync.capacity()+6 do
    assert(sync.publish_batch("rock_static",true,1,{{i,-i}})==true,"ring publish failed at "..i)
end
local newest=sync.outbox_sequence()
local oldest=select(1,sync.first_available_sequence(0))
assert(oldest==newest-sync.capacity()+1,"first available ring sequence is wrong")
assert(sync.read_outbox(oldest-1)==nil,"overwritten ring slot was exposed as current")
local newest_payload=assert(sync.read_outbox(newest),"newest ring slot missing")
sync.clear_outbox(newest-sync.capacity())
assert(sync.read_outbox(newest)==newest_payload,"clearing stale sequence erased aliased current slot")
sync.clear_outbox(newest)
assert(sync.read_outbox(newest)==nil,"current ring slot did not clear")

local slot_keys=0
for key in pairs(values) do
    if string.find(key,"mcm_material_paint_outbox_slot_v3:",1,true)==1 then slot_keys=slot_keys+1 end
end
assert(slot_keys<=sync.capacity(),"transport created unbounded per-frame Global keys")

ew_enabled=false
assert(sync.publish_batch("water",false,1,{{1,1}})==false,"standalone mode wrote EW mailbox")
io.write("material_paint_transport=PASS bounded_ring=true validation=true standalone_noop=true\n")
