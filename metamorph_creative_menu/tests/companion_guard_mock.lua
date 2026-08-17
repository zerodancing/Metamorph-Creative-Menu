local root=assert(arg[1])
local frame=10
local alive={[1]=true}
local comps={state=11,damage=12,lua=13}
local values={
  [11]={value_float=4.5,value_int=10,value_bool=false},
  [12]={max_hp=1,hp=1,max_hp_cap=0},
}
EntityGetIsAlive=function(e) return alive[e]==true end
EntityGetFirstComponentIncludingDisabled=function(e,t,tag)
  if t=="VariableStorageComponent" and tag=="mcm_companion_health_target" then return comps.state end
  if t=="DamageModelComponent" then return comps.damage end
  return nil
end
ComponentGetValue2=function(c,k) return values[c] and values[c][k] end
ComponentSetValue2=function(c,k,v) values[c][k]=v end
GameGetFrameNum=function() return frame end
EntitySetComponentIsEnabled=function(e,c,on) assert(e==1 and c==13 and on==false); _G.disabled=true end
GetUpdatedEntityID=function() return 1 end
GetUpdatedComponentID=function() return 13 end

-- The shared service repairs the first late 1/1 clamp.
local health=assert(loadfile(root.."/files/features/companion/health.lua"))()
local changed,finished=health.repair(1)
assert(changed and not finished)
assert(math.abs(values[12].max_hp-4.5)<0.001 and math.abs(values[12].hp-4.5)<0.001)
assert(values[11].value_bool==true)

-- Combat damage after the first repair must never be healed. A later max_hp clamp may be
-- corrected, but hp remains the combat value because repaired=true.
values[12].hp=2
values[12].max_hp=1
frame=20
health.repair(1)
assert(math.abs(values[12].max_hp-4.5)<0.001 and math.abs(values[12].hp-2)<0.001)

-- Per-entity fallback calls the same service and disables itself after the window.
frame=41
assert(loadfile(root.."/files/features/companion/spawn_guard.lua"))()
assert(_G.disabled==true)
assert(math.abs(values[12].hp-2)<0.001)
print("companion_spawn_guard=PASS max=4.5 combat_hp=2 disabled=true shared_service=true")
