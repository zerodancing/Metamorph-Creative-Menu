local root=assert(arg[1],"root required")
local native_dofile=dofile
local native_require=require
local globals={}
local frame=1
local newest=100
local ack=0
local slots={}
for i=1,newest do slots[i]="solid" end

function GlobalsGetValue(key,default) return globals[key] or default end
function GlobalsSetValue(key,value) globals[key]=tostring(value) end
function GameGetFrameNum() return frame end
function CellFactory_GetType(name) return name=="rock_static" and 7 or -1 end
function DoesWorldExistAt() return true end

local points={}
for i=1,24 do points[i]={i,20} end
local transport={
    ack_sequence=function() return ack end,
    first_available_sequence=function(after) return after+1,newest end,
    read_outbox=function(sequence) return slots[sequence] end,
    clear_outbox=function(sequence) slots[sequence]=nil end,
    mark_ack=function(sequence) if sequence>ack then ack=sequence end end,
    decode_batch=function(payload)
        if payload~="solid" then return nil end
        return {material_name="rock_static",solid=true,brush_index=3,points=points}
    end,
}

local area={payload="solid-seed-frame"}
local ffi_stub={string=function(buffer,size)
    assert(buffer==area and size==#area.payload,"bad encoded solid seed")
    return area.payload
end}
local world={
    EncodedArea=function() return area end,
    encode_area=function(_,_,_,_,buffer) assert(buffer==area); return area end,
    encoded_size=function(buffer) assert(buffer==area); return #buffer.payload end,
}
require=function(name)
    if name=="ffi" then return ffi_stub end
    return native_require(name)
end
dofile=function(path)
    if path=="mods/metamorph_creative_menu/files/integrations/ew/material_paint_sync.lua" then return transport end
    return native_dofile(path)
end
dofile_once=function(path)
    if path=="mods/quant.ew/files/system/world_sync/world.lua" then return world end
    error("unexpected dofile_once "..tostring(path))
end

local network_fails=true
net={
    proxy_send=function() if network_fails then error("proxy offline") end end,
    proxy_bin_send=function() if network_fails then error("proxy offline") end end,
}
ctx={proxy_opt={world_num=0}}
local next_entity=0
function EntityCreateNew() next_entity=next_entity+1; return next_entity end
function EntitySetTransform() end
function EntityAddTag() end
function EntityAddChild() end
function EntityAddComponent2() return 1 end
function EntityKill() end
ewext={des_item_thrown=function() if network_fails then error("entity transport offline") end end}

local errors=0
local rpc={opts_reliable=function() end,opts_everywhere=function() end}
local common={clean=tostring,report_error=function() errors=errors+1 end}
local bridge=assert(loadfile(root.."/files/integrations/ew/bridge/materials.lua"))()
bridge.set_metrics_enabled(true)
bridge.register(rpc,common)

for i=1,5 do frame=i; bridge.update() end
assert(ack==16,"bounded bridge did not stop acknowledging at relay capacity: "..tostring(ack))
assert(slots[17]=="solid","backpressured batch was cleared instead of retained")
frame=60; bridge.update()
assert(globals.mcm_material_sync_backlog_v1=="2:16",
    "bounded backlog changed: "..tostring(globals.mcm_material_sync_backlog_v1))
assert(errors>0,"network failures were not surfaced")

-- Remove work that the mailbox has not accepted, restore both stock EW transports and
-- prove the fixed queues can drain without a restart.
newest=ack
network_fails=false
for i=61,120 do frame=i; bridge.update() end
assert(globals.mcm_material_sync_backlog_v1=="0:0","bridge did not recover after transport returned")
assert(ack==16,"recovery corrupted mailbox acknowledgement")

require=native_require; dofile=native_dofile
io.write("ew_material_backpressure=PASS bounded=true atomic_ack=true recovery=true\n")
