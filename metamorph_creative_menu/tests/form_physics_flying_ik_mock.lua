local root=assert(arg[1],"root required")
local native_dofile=dofile
local gravity_calls={}
local forces={}
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
  boolean=function(v) return v==true or v==1 end,
  ensure_controls=function() return 20 end,
  set_type_enabled=function() end,
 },
 ["mods/metamorph_creative_menu/files/features/forms/entity_tree_cache.lua"]={components=function(entity,ctype)
   local out={};for _,id in ipairs(entity_components[entity] or {}) do if components[id].type==ctype then out[#out+1]=id end end;return out end},
 ["mods/metamorph_creative_menu/files/features/forms/controls.lua"]={direction=function() return 0,-1,true end},
}
dofile=function(path) if stubs[path] then return stubs[path] end return native_dofile(path) end
function PhysicsSetStatic() end
function PhysicsBodyIDGetFromEntity() return {99} end
function PhysicsBodyIDSetGravityScale(body,scale) gravity_calls[#gravity_calls+1]={body,scale} end
function EntityGetComponentIncludingDisabled() return {} end
function EntityGetTransform() return 100,200,0 end
function ComponentSetValue2(id,key,value) values[id]=values[id] or {};values[id][key]=value end
function PhysicsGetComponentVelocity() return 0,0 end
function PhysicsGetComponentAngularVelocity() return 0 end
function PhysicsApplyForce(entity,x,y) forces[#forces+1]={x,y} end
function PhysicsApplyTorque() end
local adapter=assert(native_dofile(root.."/files/features/forms/adapters/physics.lua"))
local profile={pure_flyer=true,physics_ai={target_vec_max_len=15,force_coeff=10,force_balancing_coeff=0.8,force_max=100}}
adapter.configure(1,profile,true)
assert(#gravity_calls==1 and gravity_calls[1][2]==0,'flying IK boss had gravity forced on')
adapter.update(1,profile,true)
assert(#forces==1 and forces[1][2]<0,'UP input did not produce upward force for flying IK boss')
assert(values[12] and values[12].state==4 and values[12].mMoveToPositionY==104,
    'LimbBoss flight target did not accept upward player input')
dofile=native_dofile
print('form_physics_flying_ik=PASS gravity_zero=true upward_force=true limbboss_up=true')
