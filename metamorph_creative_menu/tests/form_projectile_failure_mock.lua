local root=assert(arg[1],"root required")
local native_dofile=dofile
local controls,animal,attack=10,20,30
local killed={}
local loads=0
local values={
 [controls]={mButtonDownFire2=true},
 [animal]={attack_ranged_entity_file="primary.xml"},
 [attack]={attack_ranged_entity_file="secondary.xml",attack_ranged_use_message=false,frames_between=30,frames_between_global=10,attack_ranged_entity_count_min=1,attack_ranged_entity_count_max=1,attack_ranged_action_frame=0,animation_name="",mNextFrameUsable=0,attack_ranged_offset_x=0,attack_ranged_offset_y=0,attack_ranged_root_offset_x=0,attack_ranged_root_offset_y=0},
}
local component_ops={
 valid=function(v) return v~=nil and v~=0 end,
 first=function(_,kind) if kind=="ControlsComponent" then return controls end end,
 get=function(c,f,d) local v=values[c] and values[c][f]; if v==nil then return d end return v end,
 boolean=function(v) return v==true or v==1 end,
 ensure_controls=function() return controls end,
 set_type_enabled=function() end,set_type_enabled_tree=function() end,
}
local tree={components=function(_,kind)
 if kind=="AnimalAIComponent" then return {animal} end
 if kind=="AIAttackComponent" then return {attack} end
 return {}
end}
local entity_tree={walk=function(e,fn) fn(e) end}
dofile=function(path)
 if path=="mods/metamorph_creative_menu/files/features/forms/component_ops.lua" then return component_ops end
 if path=="mods/metamorph_creative_menu/files/features/forms/entity_tree_cache.lua" then return tree end
 if path=="mods/metamorph_creative_menu/files/platform/noita/entity_tree.lua" then return entity_tree end
 local prefix="mods/metamorph_creative_menu/"; if string.sub(path,1,#prefix)==prefix then return native_dofile(root.."/"..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end
function ComponentGetEntity() return 1 end
function ComponentSetValue2(c,f,v) values[c]=values[c] or {}; values[c][f]=v end
function EntityGetRootEntity() return 1 end
function EntityGetTransform() return 0,0,0,1,1 end
function DEBUG_GetMouseWorld() return 100,0 end
function GameGetFrameNum() return 100 end
function ModDoesFileExist(path) return path=="secondary.xml" end
function EntityLoad() loads=loads+1; return 100+loads end
function EntityKill(e) killed[e]=true end
function GameShootProjectile() error("native shoot failed") end
function EntityGetComponentIncludingDisabled() return {} end
function GamePlayAnimation() end
local combat=assert(native_dofile(root.."/files/features/forms/combat.lua"))
local first=combat.update_secondary_attacks(1)
assert(first==false,"failed projectile launch reported successful attack")
assert(loads==1 and killed[101],"failed loaded projectile was not retired")
assert(values[attack].mNextFrameUsable==0,"failed projectile launch consumed native cooldown")
local second=combat.update_secondary_attacks(1)
assert(second==false and loads==2 and killed[102],"failed projectile launch could not retry in same frame")
io.write("form_projectile_failure=PASS projectile_retired=true cooldown_restored=true retry=true\n")
