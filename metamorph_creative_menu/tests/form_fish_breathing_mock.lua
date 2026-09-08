local root=assert(arg[1],"root required")
local native_dofile=dofile
local fish_ai,damage=10,20
local values={
 [fish_ai]={flock=true,avoid_predators=true},
 [damage]={air_needed=true,air_in_lungs_max=7,air_in_lungs=2,air_lack_of_damage=0.6},
}
local component_ops={
 valid=function(v)return v~=nil and v~=0 end,
 first=function(_,kind)if kind=="AdvancedFishAIComponent" then return fish_ai elseif kind=="DamageModelComponent" then return damage end end,
 ensure_controls=function()return 0 end,
 set_type_enabled=function()end,
 set_typed_scalar=function(c,f,v)
  local cur=values[c][f]
  if type(cur)=="boolean" then v=(v==true or v==1 or v=="1" or v=="true")
  elseif type(cur)=="number" then v=tonumber(v) end
  values[c][f]=v
  return true
 end,
}
local controls={direction=function()return 0,0,false end}
dofile=function(path)
 if path=="mods/metamorph_creative_menu/files/features/forms/component_ops.lua" then return component_ops end
 if path=="mods/metamorph_creative_menu/files/features/forms/controls.lua" then return controls end
 local prefix="mods/metamorph_creative_menu/"
 if string.sub(path,1,#prefix)==prefix then return native_dofile(root.."/"..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end
function ComponentSetValue2(c,f,a,b) values[c][f]=(b~=nil) and {a,b} or a end
function EntityGetTransform()return 0,0 end

local adapter=assert(native_dofile(root.."/files/features/forms/adapters/fish.lua"))
adapter.configure(1,{damage={air_needed="0",air_in_lungs_max="5",air_in_lungs="5",air_lack_of_damage="0.2"}})
assert(values[damage].air_needed==false,"fish retained player air_needed")
assert(values[damage].air_in_lungs_max==5,"fish max air was not restored")
assert(values[damage].air_in_lungs==5,"fish current air was not restored")
assert(math.abs(values[damage].air_lack_of_damage-0.2)<0.0001,"fish air damage was not restored")
assert(values[fish_ai].flock==false and values[fish_ai].avoid_predators==false,"fish AI playerization regressed")
print("form_fish_breathing=PASS authored_respiratory_profile=true")
