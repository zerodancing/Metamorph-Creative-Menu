local root=tostring(arg[1] or ".")
local old_dofile=dofile
local prefix="mods/metamorph_creative_menu/"
dofile=function(path) if string.sub(path,1,#prefix)==prefix then return old_dofile(root.."/"..string.sub(path,#prefix+1)) end return old_dofile(path) end

local player=1
local alive={[1]=true,[10]=true,[11]=true,[12]=true,[13]=true}
local parent={[10]=1,[11]=1,[12]=1,[13]=1}
local tags={[10]={essence_effect=true},[11]={essence_effect=true},[12]={essence_effect=true},[13]={greed_curse=true}}
local filenames={[10]="data/entities/misc/essences/fire.xml",[12]="data/entities/misc/essences/air.xml"}
local icons={[11]="$item_essence_fire"}
local globals={ESSENCE_FIRE_PICKUP_COUNT="2",ESSENCE_AIR_PICKUP_COUNT="1"}
local flags={essence_fire=true,essence_air=true,greed_curse=true}
local damage={projectile=1.69,explosion=3.38}

function EntityGetIsAlive(e) return alive[e]==true end
function EntityGetAllChildren(e) local r={} for child,p in pairs(parent) do if p==e and alive[child] then r[#r+1]=child end end return r end
function EntityHasTag(e,t) return tags[e] and tags[e][t] or false end
function EntityGetFilename(e) return filenames[e] or "" end
function EntityGetFirstComponentIncludingDisabled(e,t) if t=="UIIconComponent" and icons[e] then return e+100 end end
function ComponentGetValue2(c,f) if f=="name" then return icons[c-100] end end
function EntityRemoveFromParent(e) parent[e]=nil end
function EntityKill(e) alive[e]=false end
function GlobalsGetValue(k,d) return globals[k] or d end
function GlobalsSetValue(k,v) globals[k]=v end
function GameHasFlagRun(k) return flags[k]==true end
function GameRemoveFlagRun(k) flags[k]=nil end
function GameAddFlagRun(k) flags[k]=true end
function EntityGetComponent(e,t) if e==player and t=="DamageModelComponent" then return {200} end return {} end
function ComponentObjectGetValue(c,o,f) return tostring(damage[f]) end
function ComponentObjectSetValue(c,o,f,v) damage[f]=tonumber(v) end

local service=dofile("mods/metamorph_creative_menu/files/features/perks/non_perk_states.lua")
local listed=service.list(player)
assert(#listed==3,"expected fire, air and greed")
local ok,reason=service.remove(player,"essence_fire"); assert(ok,tostring(reason))
assert(globals.ESSENCE_FIRE_PICKUP_COUNT=="0" and not flags.essence_fire,"fire state remained")
assert(not alive[10] and not alive[11],"fire children remained")
assert(math.abs(damage.projectile-1.0)<0.000001,"fire projectile multiplier not reversed")
assert(math.abs(damage.explosion-2.0)<0.000001,"fire explosion multiplier not reversed")
assert(alive[12],"removing fire killed another essence")
ok,reason=service.remove(player,"greed_curse"); assert(ok,tostring(reason))
assert(not alive[13] and not flags.greed_curse and flags.greed_curse_gone,"greed runtime state remained")
assert(globals.ESSENCE_AIR_PICKUP_COUNT=="1" and flags.essence_air,"unrelated essence changed")
print("non_perk_states=PASS selective=true fire_inverse=true greed=true")

-- Standard grid semantics: one copy with LMB, all remaining copies with RMB,
-- for every vanilla essence (including the earth essence with internal id "air").
function RemoveFlagPersistent() error("active-state removal must preserve progression") end
for index,id in ipairs({"laser","fire","water","air","alcohol"}) do
    service.remove(player,"essence_"..id)
    local key="ESSENCE_"..string.upper(id).."_PICKUP_COUNT"
    globals[key]="2"; flags["essence_"..id]=true
    if id=="fire" then damage.projectile=1.69; damage.explosion=3.38 end
    local owned={}
    for copy=1,2 do
        local effect=1000+index*10+copy*2
        local icon=effect+1
        owned[#owned+1]=effect; owned[#owned+1]=icon
        for _,child in ipairs({effect,icon}) do
            alive[child]=true; parent[child]=player; tags[child]={essence_effect=true}
        end
        filenames[effect]="data/entities/misc/essences/"..id..".xml"
        icons[icon]="$item_essence_"..id
    end
    assert(service.remove_one(player,"essence_"..id))
    assert(globals[key]=="1" and flags["essence_"..id],"single copy did not preserve remaining state: "..id)
    local remaining=0
    for _,child in ipairs(owned) do if alive[child] then remaining=remaining+1 end end
    assert(remaining==2,"single copy did not remove one effect and one icon")
    if id=="fire" then assert(math.abs(damage.projectile-1.3)<0.000001,"single fire inverse wrong") end
    assert(service.remove(player,"essence_"..id))
    assert(globals[key]=="0" and not flags["essence_"..id],"remove-all state remained: "..id)
    for _,child in ipairs(owned) do assert(not alive[child],"remove-all child remained") end
    if id=="fire" then
        assert(math.abs(damage.projectile-1)<0.000001 and math.abs(damage.explosion-2)<0.000001,"stacked fire inverse wrong")
    end
end
print("non_perk_states_stacks=PASS essences=5 one=true all=true fire_inverse=true progression_preserved=true")
