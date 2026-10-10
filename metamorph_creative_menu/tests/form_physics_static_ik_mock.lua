local root=assert(arg[1],"root required")
local native_dofile=dofile
local static_calls={}
local values={}
local components={
 [10]={type="PhysicsAIComponent"},
 [11]={type="PhysicsBodyComponent"},
 [12]={type="LimbBossComponent"},
}
local entity_components={[1]={10,11,12}}
local stubs={
 ["mods/metamorph_creative_menu/files/platform/noita/entity_tree.lua"]={walk=function(entity,fn) fn(entity) end},
 ["mods/metamorph_creative_menu/files/features/forms/component_ops.lua"]={
  valid=function(v) return v~=nil and v~=0 end,
  first=function(entity,ctype) for _,id in ipairs(entity_components[entity] or {}) do if components[id].type==ctype then return id end end end,
  get=function(id,key,default) return values[id] and values[id][key] or default end,
  boolean=function(v) return v==true end,
  ensure_controls=function() return 20 end,
  set_type_enabled=function() end,
 },
 ["mods/metamorph_creative_menu/files/features/forms/entity_tree_cache.lua"]={components=function(entity,ctype)
   local out={};for _,id in ipairs(entity_components[entity] or {}) do if components[id].type==ctype then out[#out+1]=id end end;return out end},
 ["mods/metamorph_creative_menu/files/features/forms/controls.lua"]={direction=function() return 1,0,true end},
}
dofile=function(path) if stubs[path] then return stubs[path] end return native_dofile(path) end
function PhysicsSetStatic(e,v) static_calls[#static_calls+1]={e,v} end
function PhysicsBodyIDGetFromEntity() return {} end
function EntityGetComponentIncludingDisabled() return {} end
function EntityGetTransform() return 100,200,0 end
function ComponentSetValue2(id,key,value) values[id]=values[id] or {};values[id][key]=value end
function PhysicsGetComponentVelocity() return 0,0 end
function PhysicsGetComponentAngularVelocity() return 0 end
function PhysicsApplyForce() end
function PhysicsApplyTorque() end
local adapter=assert(native_dofile(root.."/files/features/forms/adapters/physics.lua"))
adapter.configure(1,{physics_ai={}},true)
assert(#static_calls==1 and static_calls[1][1]==1 and static_calls[1][2]==false,"physics/IK form root remained static")
adapter.update(1,{physics_ai={}},true)
assert(values[12] and values[12].state==4,"LimbBoss player form was not placed into MoveTo state")
assert(values[12].mMoveToPositionX==196 and values[12].mMoveToPositionY==200,"LimbBoss MoveTo target not driven by player input")
dofile=native_dofile
print("form_physics_static_ik=PASS root_unstatic=true limbboss_move_to=true")
