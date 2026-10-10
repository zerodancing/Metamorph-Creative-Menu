local root=assert(arg[1],"root required")
local native_dofile=dofile
local player=1
local nearby=true
local component={value=1.25,type="SpriteStainsComponent",owner=2}
function EntityGetIsAlive(entity) return entity==player or entity==2 end
function EntityGetTransform() return 0,0 end
function EntityGetInRadius() return nearby and {2} or {} end
function EntityGetComponentIncludingDisabled(entity,kind)
    if entity==2 and kind=="SpriteStainsComponent" then return {200} end
    return {}
end
function ComponentGetValue2(id,field) assert(id==200); return component.value end
function ComponentSetValue2(id,field,value) assert(id==200); component.value=value end
function ComponentGetTypeName(id) assert(id==200); return component.type end
function ComponentGetEntity(id) assert(id==200); return component.owner end
local stubs={
 ["mods/metamorph_creative_menu/files/core/rule_math.lua"]={same=function(a,b) return math.abs((tonumber(a)or 0)-(tonumber(b)or 0))<1e-9 end},
}
dofile=function(path)
 if stubs[path]~=nil then return stubs[path] end
 local prefix="mods/metamorph_creative_menu/"; if string.sub(path,1,#prefix)==prefix then return native_dofile(root.."/"..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end
METAMORPH_CREATIVE_MENU_WORLD_RULE_STAINS=nil
local stains=assert(native_dofile(root.."/files/features/world_rules/stains.lua"))

stains.apply(5,1,player)
assert(math.abs(component.value-5)<1e-9,"stain rule did not apply")
nearby=false
stains.cleanup_stale(2)
assert(math.abs(component.value-1.25)<1e-9,"stain rule did not restore entity leaving active area")
assert(stains.has_overrides()==false,"restored stain remained owned")

-- If another writer changes the field after us, cleanup must not overwrite it.
nearby=true
stains.apply(5,3,player)
component.value=7.5
nearby=false
stains.cleanup_stale(4)
assert(math.abs(component.value-7.5)<1e-9,"stain cleanup overwrote a newer external value")
assert(stains.has_overrides()==false,"external stain ownership was not relinquished")

io.write("world_rules_stain_ownership=PASS restore=true external_cas=true\n")
