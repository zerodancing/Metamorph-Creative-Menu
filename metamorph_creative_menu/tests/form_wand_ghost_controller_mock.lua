local root=assert(arg[1],"root required")
local native_dofile=dofile
local values,enabled,owners,components,alive,transforms,tags,inventories={},{},{},{},{},{},{},{}
local next_component,next_entity=1000,2000
local frame=100
local mouse_x,mouse_y=150,40
local loads,use_calls={},{ }

local function add(entity,kind,id,data)
 components[entity]=components[entity] or {}; components[entity][kind]=components[entity][kind] or {}
 table.insert(components[entity][kind],id); values[id]=data or {}; enabled[id]=values[id]._enabled~=false; owners[id]=entity
 alive[entity]=true; transforms[entity]=transforms[entity] or {0,0,0,1,1}; return id
end
local component_ops={}
function component_ops.valid(v)return v~=nil and v~=0 end
function component_ops.get(c,f,d)local v=values[c] and values[c][f];if v==nil then return d end return v end
function component_ops.ensure_controls(entity)local x=components[entity] and components[entity].ControlsComponent;return x and x[1] or nil end
local gameplay_input={}
function gameplay_input.require_release() end
function gameplay_input.down(controls,surface) return surface=="primary" and values[controls].mButtonDownFire==true end
local bridge={}
function bridge.UseItem(entity,wand,a,b,c,x,y,tx,ty)
 use_calls[#use_calls+1]={entity=entity,wand=wand,x=x,y=y,tx=tx,ty=ty}
 return true
end
local patcher_bridge={}
function patcher_bridge.get(options)
 assert(options and options.capability=="UseItem","wand controller requested wrong patcher capability")
 return bridge
end
local stubs={
 ["mods/metamorph_creative_menu/files/features/forms/component_ops.lua"]=component_ops,
 ["mods/metamorph_creative_menu/files/platform/noita/gameplay_input.lua"]=gameplay_input,
 ["mods/metamorph_creative_menu/files/platform/noita/patcher_bridge.lua"]=patcher_bridge,
}
dofile=function(path)
 if stubs[path] then return stubs[path] end
 local prefix="mods/metamorph_creative_menu/"
 if string.sub(path,1,#prefix)==prefix then return native_dofile(root.."/"..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end
function ComponentGetValue2(c,f)local v=values[c] and values[c][f];if type(v)=="table" and #v>=2 then return v[1],v[2] end return v end
function ComponentSetValue2(c,f,a,b) values[c]=values[c] or {};if b~=nil then values[c][f]={a,b}else values[c][f]=a end end
function ComponentGetEntity(c)return owners[c] or 0 end
function EntitySetComponentIsEnabled(_,c,v)enabled[c]=v==true end
function EntityGetComponentIncludingDisabled(entity,kind)return (components[entity] and components[entity][kind]) or {} end
function EntityGetFirstComponentIncludingDisabled(entity,kind)local x=EntityGetComponentIncludingDisabled(entity,kind);return x[1] end
function EntityGetTransform(entity)local t=transforms[entity] or {0,0,0,1,1};return t[1],t[2],t[3],t[4],t[5] end
function EntitySetTransform(entity,x,y,r,sx,sy)transforms[entity]={x,y,r or 0,sx or 1,sy or 1} end
function EntityGetIsAlive(entity)return alive[entity]~=false end
function EntityKill(entity)alive[entity]=false end
function EntityAddTag(entity,tag)tags[entity]=tags[entity] or {};tags[entity][tag]=true end
function EntityRemoveTag(entity,tag)if tags[entity] then tags[entity][tag]=nil end end
function EntityHasTag(entity,tag)return tags[entity] and tags[entity][tag]==true or false end
function DEBUG_GetMouseWorld()return mouse_x,mouse_y end
function GameGetFrameNum()return frame end
function GameGetAllInventoryItems(entity)return inventories[entity] end

local helper_count=0
function EntityLoad(path,x,y)
 next_entity=next_entity+1;local e=next_entity;alive[e]=true;transforms[e]={x,y,0,1,1};loads[#loads+1]={entity=e,path=path,x=x,y=y}
 if path=="data/entities/animals/wand_ghost.xml" then
  helper_count=helper_count+1
  tags[e]={mortal=true,hittable=true,homing_target=true,enemy=true,wand_ghost=true}
  add(e,"AnimalAIComponent",e*10+1,{_enabled=true,ai_state=10,attack_ranged_enabled=true,attack_ranged_entity_file="data/entities/projectiles/orb_pink.xml"})
  add(e,"ItemPickUpperComponent",e*10+2,{_enabled=true,is_in_npc=true,drop_items_on_death=true})
  add(e,"DamageModelComponent",e*10+3,{_enabled=true})
  add(e,"HitboxComponent",e*10+4,{_enabled=true})
  add(e,"PhysicsAIComponent",e*10+5,{_enabled=true})
  -- Simulate the result of the untouched vanilla one-shot wand_ghost.lua. Different
  -- proxy seed positions produce different actual item sprites/decks.
  next_entity=next_entity+1;local wand=next_entity;alive[wand]=true;transforms[wand]={x,y,0,1,1};tags[wand]={wand=true,item=true}
  local sprite_path=helper_count==1 and "data/items_gfx/wands/wand_0240.png" or (helper_count==2 and "data/items_gfx/wands/wand_0777.png" or "data/items_gfx/wands/wand_0111.png")
  add(wand,"SpriteComponent",wand*10+1,{_enabled=true,_tags="item,enabled_in_hand",image_file=sprite_path,visible=true})
  add(wand,"AbilityComponent",wand*10+2,{use_gun_script=true,mReloadFramesLeft=0,mNextFrameUsable=0})
  inventories[e]={wand}
 end
 return e
end

local ghost=1
add(ghost,"ControlsComponent",12,{mButtonDownFire=false,polymorph_hax=true})
transforms[ghost]={10,20,0,1,1}
local controller=assert(native_dofile(root.."/files/features/forms/held_wand_forms/controller.lua"))
local paths={"data/entities/animals/wand_ghost.xml","data/entities/animals/wand_ghost_charmed.xml","data/entities/animals/wand_ghost_with_sampo.xml"}
local seed_positions={}
for i,path in ipairs(paths) do
 assert(controller.configure(ghost,path)==true,"held-wand ghost path was not claimed: "..path)
 assert(controller.owns_primary()==true,"wand ghost did not own primary fire")
 local helper=loads[#loads].entity
 assert(loads[#loads].path=="data/entities/animals/wand_ghost.xml","held-wand form did not use a vanilla proxy ghost")
 seed_positions[#seed_positions+1]={loads[#loads].x,loads[#loads].y}
 local ai=components[helper].AnimalAIComponent[1]
 local pickup=components[helper].ItemPickUpperComponent[1]
 assert(enabled[ai]==false and enabled[components[helper].PhysicsAIComponent[1]]==false,"proxy retained autonomous AI")
 assert(enabled[components[helper].DamageModelComponent[1]]==false and enabled[components[helper].HitboxComponent[1]]==false,"proxy remained damageable")
 assert(values[pickup].drop_items_on_death==false,"proxy could drop implementation wand")
 assert(not EntityHasTag(helper,"hittable") and not EntityHasTag(helper,"enemy"),"proxy retained world-enemy tags")

 -- Update discovers the real vanilla-held item and attaches the invisible proxy to the
 -- player body. The item's own SpriteComponent remains enabled; no MCM sprite copy can
 -- independently become invisible.
 values[12].mButtonDownFire=false;frame=frame+1;controller.update(ghost)
 local wand=GameGetAllInventoryItems(helper)[1]
 local wand_sprite=components[wand].SpriteComponent[1]
 assert(enabled[wand_sprite]==true and values[wand_sprite].image_file~="","real procedural wand renderer was disabled")
 assert(math.abs(transforms[helper][1]-10)<0.001 and math.abs(transforms[helper][2]-20)<0.001,"ready proxy was not attached to player form")

 values[12].mButtonDownFire=true;frame=frame+1;controller.update(ghost)
 local use=use_calls[#use_calls]
 assert(use and use.entity==helper and use.wand==wand,"primary fire did not cast the actual proxy-held wand")
 assert(use.tx==mouse_x and use.ty==mouse_y,"real wand cast did not use cursor target")
 assert(enabled[ai]==false and values[ai].attack_ranged_entity_file=="data/entities/projectiles/orb_pink.xml","MCM fell back to AnimalAI orb_pink ownership")
 assert(not EntityHasTag(helper,"player_unit"),"temporary UseItem player tag leaked after cast")

 -- Ability cooldown is authoritative: an unavailable wand must not be forcibly used.
 local ability=components[wand].AbilityComponent[1]
 values[ability].mNextFrameUsable=frame+10
 local uses_before=#use_calls;frame=frame+1;controller.update(ghost)
 assert(#use_calls==uses_before,"wand controller bypassed real AbilityComponent cooldown")
 values[12].mButtonDownFire=false
 controller.reset()
 assert(alive[helper]==false and alive[wand]==false,"wand proxy/helper leaked after controller reset")
end
assert(seed_positions[1][1]~=seed_positions[2][1] or seed_positions[1][2]~=seed_positions[2][2],"proxy generation reused identical procedural seed coordinates")
print("form_wand_ghost_controller=PASS paths=3 vanilla_proxy=true native_item_renderer=true procedural_seed_varies=true patcher_use_item=true ability_cooldown=true no_ai_fallback=true")
