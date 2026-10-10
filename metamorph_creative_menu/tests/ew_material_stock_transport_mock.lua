local root=assert(arg[1],"root required")
local native_dofile,native_require=dofile,require
local frame,globals,newest,ack=1,{},0,0
local slots={}
local unavailable_chunk_x=nil

function GlobalsGetValue(key,default) return globals[key] or default end
function GlobalsSetValue(key,value) globals[key]=tostring(value) end
function GameGetFrameNum() return frame end
function DoesWorldExistAt(x1) return x1~=unavailable_chunk_x end
function CellFactory_GetType(name) return name=="water" and 1 or (name=="rock_static" and 7 or -1) end

local decoded={
 dynamic={material_name="water",solid=false,brush_index=3,points={{130,10},{132,10}}},
 solid={material_name="rock_static",solid=true,brush_index=2,points={{10,20},{14,20}}},
 repeat_solid={material_name="rock_static",solid=true,brush_index=2,points={{18,20}}},
 far={material_name="rock_static",solid=true,brush_index=2,points={{385,20}}},
 other={material_name="rock_static",solid=true,brush_index=2,points={{650,20}}},
}
local transport={
 ack_sequence=function() return ack end,
 first_available_sequence=function(after) return after+1,newest end,
 read_outbox=function(sequence) return slots[sequence] end,
 clear_outbox=function(sequence) slots[sequence]=nil end,
 mark_ack=function(sequence) ack=math.max(ack,sequence) end,
 decode_batch=function(payload) return decoded[payload] end,
}

local encoded_calls={}
local area={payload="native-ew-world-frame"}
local world={
 EncodedArea=function() return area end,
 encode_area=function(x1,y1,x2,y2,buffer)
  assert(buffer==area and x1%128==0 and y1%128==0 and x2-x1==128 and y2-y1==128,
   "unsafe native world frame")
  encoded_calls[#encoded_calls+1]={x1,y1,x2,y2}; return area
 end,
 encoded_size=function(buffer) return #buffer.payload end,
}
local ffi_stub={string=function(buffer,size) assert(size==#buffer.payload); return buffer.payload end}
require=function(name) if name=="ffi" then return ffi_stub end return native_require(name) end
dofile=function(path)
 if path=="mods/metamorph_creative_menu/files/integrations/ew/material_paint_sync.lua" then return transport end
 return native_dofile(path)
end
dofile_once=function(path)
 if path=="mods/quant.ew/files/system/world_sync/world.lua" then return world end
 error("unexpected dofile_once "..tostring(path))
end

local binary,proxy={},{}
local fail_world_end_once=true
net={
 proxy_bin_send=function(key,payload)
  if key==1 and fail_world_end_once then fail_world_end_once=false; error("temporary world-end failure") end
  binary[#binary+1]={key=key,payload=payload}
 end,
 proxy_send=function(command,payload) proxy[#proxy+1]={command=command,payload=payload} end,
}
ctx={proxy_opt={world_num=3}}

local next_entity,entities,uploaded=100,{},{}
function EntityCreateNew(name) next_entity=next_entity+1; entities[next_entity]={name=name,components={},children={},alive=true}; return next_entity end
function EntitySetTransform(entity,x,y) entities[entity].x=x; entities[entity].y=y end
function EntityAddTag(entity,tag) entities[entity].tag=tag end
function EntityAddChild(parent,child)
 entities[child].parent=parent
 entities[child].relative_x=(entities[child].x or 0)-(entities[parent].x or 0)
 entities[child].relative_y=(entities[child].y or 0)-(entities[parent].y or 0)
 entities[parent].children[#entities[parent].children+1]=child
end
function EntityAddComponent2(entity,name,values)
 entities[entity].components[#entities[entity].components+1]={name=name,values=values}
 return #entities[entity].components
end
function EntityKill(entity) if entities[entity] then entities[entity].alive=false end end
ewext={des_item_thrown=function(entity) uploaded[#uploaded+1]=entity end}

local registered={}
local rpc=setmetatable({opts_reliable=function() end,opts_everywhere=function() end},{
 __newindex=function(t,key,value) rawset(t,key,value); if type(value)=="function" then registered[#registered+1]=key end end,
})
local errors={}
local common={clean=tostring,report_error=function(scope,detail) errors[#errors+1]=scope..":"..tostring(detail) end}
local bridge=assert(loadfile(root.."/files/integrations/ew/bridge/materials.lua"))()
bridge.register(rpc,common)
assert(registered[1]=="sync_material_paint","reserved material RPC slot moved")

slots[1]="dynamic"; newest=1; bridge.update()
assert(ack==1 and #encoded_calls==1 and #binary==1 and #uploaded==0,
 "batch did not enter an ordered native chunk transaction")
frame=2; bridge.update()
assert(#binary==2 and binary[2].key==1 and #uploaded==1,
 "failed world end was not retried before releasing relay")
assert(#proxy==0,"painting used EW's destructive cut-through-world command")

local dynamic=entities[uploaded[1]]
assert(dynamic.name=="mcm_material_relay" and #dynamic.children==2,"dynamic relay lost brush points")
for _,child in ipairs(dynamic.children) do
 local converter,emitter=false,false
 for _,component in ipairs(entities[child].components) do
  if component.name=="MagicConvertMaterialComponent" then
   converter=component.values.to_material==1 and component.values.min_radius==0
  elseif component.name=="ParticleEmitterComponent" then
   emitter=component.values.emitted_material_name=="water" and component.values.create_real_particles==true
  end
 end
 assert(converter and emitter,"stock relay lacks converter or real material seed")
end

frame=3; slots[2]="solid"; newest=2; bridge.update()
assert(ack==2 and #encoded_calls==2 and encoded_calls[2][1]==0 and #uploaded==2,
 "solid paint did not seed and relay its exact chunk")

-- The same chunk is no longer cached forever. It is coalesced during a short cooldown
-- and then re-sent, which keeps continuous moving strokes authoritative without 60
-- full chunk frames per second.
frame=4; slots[3]="repeat_solid"; newest=3; bridge.update()
assert(ack==3 and #encoded_calls==2 and #uploaded==2,"chunk resend cooldown was ignored")
for next_frame=5,8 do frame=next_frame; bridge.update() end
assert(#encoded_calls==2 and #uploaded==2,"cooldown released too early")
frame=9; bridge.update()
assert(#encoded_calls==3 and encoded_calls[3][1]==0 and #uploaded==3,
 "painted chunk was permanently cached instead of being refreshed")

-- An unloaded fringe cannot block a later loaded chunk while the player moves.
unavailable_chunk_x=384
frame=10; slots[4]="far"; newest=4; bridge.update()
assert(ack==4 and #uploaded==3,"unloaded paint escaped before its chunk existed")
frame=11; slots[5]="other"; newest=5; bridge.update()
assert(ack==5 and encoded_calls[#encoded_calls][1]==640 and #uploaded==4,
 "unloaded fringe blocked a loaded moving stroke")
unavailable_chunk_x=nil
frame=12; bridge.update()
assert(encoded_calls[#encoded_calls][1]==384 and #uploaded==5,
 "fringe paint was not released after streaming completed")

local converters,emitters=0,0
for _,entity in pairs(entities) do
 for _,component in ipairs(entity.components) do
  assert(component.name~="LuaComponent","relay introduced a receiver-side MCM script")
  if component.name=="MagicConvertMaterialComponent" then converters=converters+1 end
  if component.name=="ParticleEmitterComponent" then emitters=emitters+1 end
 end
end
assert(converters==emitters and converters>0,"material classes do not share the stock relay path")
assert(#proxy==0,"destructive proxy terrain transport returned")
assert(#errors==1 and string.find(errors[1],"material_paint_world_end",1,true),
 "temporary native transport failure was not isolated")

require=native_require; dofile=native_dofile
io.write("ew_material_stock_transport=PASS refreshed_chunks=true stock_relay=true no_cut_command=true\n")
