local root = assert(arg[1], "root required")
local native_dofile = dofile
local prefix = "mods/metamorph_creative_menu/"
dofile = function(path)
    if string.sub(path, 1, #prefix) == prefix then
        return native_dofile(root .. "/" .. string.sub(path, #prefix + 1))
    end
    return native_dofile(path)
end

local alive = {[1]=true,[2]=true,[3]=true}
local names = {[1]="player",[2]="inventory_quick",[3]="inventory_full"}
local parent = {[2]=1,[3]=1}
local children = {[1]={2,3},[2]={},[3]={}}
local comps = {[1]={101}}
local ctype = {[101]="Inventory2Component"}
local fields = {[101]={quick_inventory_slots=4,full_inventory_slots_x=16,full_inventory_slots_y=1}}
local transform = {[1]={100,200}}
local material = {}
local next_entity = 10
local loads = {}
local ew_calls = 0
local ew_enabled = true
local ew_fail = false
local pickup_calls = 0
local material_fail = false
local component_enable = {}

local function add_child(p, e)
    if parent[e] and children[parent[e]] then
        for i,v in ipairs(children[parent[e]]) do if v==e then table.remove(children[parent[e]],i); break end end
    end
    parent[e]=p
    children[p]=children[p] or {}
    children[p][#children[p]+1]=e
end
local function new_item(path,x,y)
    local e=next_entity; next_entity=next_entity+1
    alive[e]=true; names[e]="item"; transform[e]={x,y}; children[e]={}
    local c=10000+e
    comps[e]={c}; ctype[c]="ItemComponent"
    fields[c]={inventory_slot={0,0},is_pickable=true,auto_pickup=false,has_been_picked_by_player=false}
    loads[#loads+1]={entity=e,path=path,x=x,y=y}
    -- Deliberately make a child that EntityKill(root) alone would not clean up.
    local child=e*100
    alive[child]=true; names[child]="child"; children[child]={}; add_child(e,child)
    return e,child
end

function EntityGetIsAlive(e) return alive[e]==true end
function EntityGetAllChildren(e) local out={}; for _,v in ipairs(children[e] or {}) do if alive[v] then out[#out+1]=v end end; return out end
function EntityGetFirstComponentIncludingDisabled(e,t)
    for _,c in ipairs(comps[e] or {}) do if ctype[c]==t then return c end end
    return 0
end
function EntityGetComponentIncludingDisabled(e,t)
    local out={}; for _,c in ipairs(comps[e] or {}) do if ctype[c]==t then out[#out+1]=c end end; return out
end
function ComponentGetValue2(c,k)
    local v=fields[c] and fields[c][k]
    if type(v)=="table" then return unpack(v) end
    return v
end
function ComponentSetValue2(c,k,...)
    local a={...}; fields[c]=fields[c] or {}; fields[c][k]=#a>1 and a or a[1]; return true
end
function EntityGetName(e) return names[e] or "" end
function EntityGetParent(e) return parent[e] or 0 end
function EntityGetRootEntity(e) local cur=e; while parent[cur] do cur=parent[cur] end; return cur end
function EntityHasTag() return false end
function EntityGetTransform(e) local t=transform[e]; if not t then return nil,nil end; return t[1],t[2] end
function EntitySetTransform(e,x,y) transform[e]={x,y} end
function EntityRemoveFromParent(e)
    local p=parent[e]; if p and children[p] then for i,v in ipairs(children[p]) do if v==e then table.remove(children[p],i); break end end end
    parent[e]=nil
end
function EntityAddChild(p,e) EntityRemoveFromParent(e); add_child(p,e) end
function EntityKill(e) alive[e]=false; EntityRemoveFromParent(e) end
function EntitySetComponentsWithTagEnabled(e,tag,value)
    component_enable[e]=component_enable[e] or {}; component_enable[e][tag]=value
end
function EntityLoad(path,x,y)
    if path=="data/entities/items/bad_load.xml" then return 0 end
    return (new_item(path,x,y))
end
function ModDoesFileExist(path)
    return path=="data/entities/items/test.xml" or path=="data/entities/items/bad_load.xml"
        or path=="data/entities/items/pickup/potion_empty.xml"
end
function GamePickUpInventoryItem(player,e)
    pickup_calls=pickup_calls+1
    add_child(2,e)
end
function RemoveMaterialInventoryMaterial(e) material[e]=nil end
function AddMaterialInventoryMaterial(e,id,amount)
    if material_fail then error("material failure") end
    assert(amount==1000,"wrong liquid amount"); material[e]=id; return true
end
function ModIsEnabled(id) return id=="quant.ew" and ew_enabled end
function CrossCall(name,e)
    assert(name=="ew_thrown","wrong EW crosscall")
    ew_calls=ew_calls+1
    if ew_fail then error("EW down") end
    return true
end
local globals={}
function GlobalsGetValue(k,d) return globals[k] or d end
function GlobalsSetValue(k,v) if ew_fail then error("EW mailbox down") end; globals[k]=v end
function GameGetFrameNum() return 1 end
function GameHasFlagRun() return false end

for _,name in ipairs({"METAMORPH_CREATIVE_MENU_ITEM_SERVICE","METAMORPH_CREATIVE_MENU_EW_RUNTIME"}) do _G[name]=nil end
local service=assert(native_dofile(root.."/files/features/items/service.lua"))

-- Exact ordinary world drop: requested coordinates, world component state, one EW handoff.
local entity,reason=service.spawn_at("data/entities/items/test.xml",321.5,-77.25)
assert(entity~=0 and reason=="spawned_direct","exact item world spawn failed: "..tostring(reason))
local last=loads[#loads]
assert(last.entity==entity and last.x==321.5 and last.y==-77.25,"world coordinates were changed")
assert(component_enable[entity].enabled_in_world==true and component_enable[entity].enabled_in_inventory==false,"world component state not committed")
assert(ew_calls==1,"successful world item must perform exactly one EW handoff")

-- Exact filled bottle uses the same world transaction and keeps the requested liquid.
local before_ew=ew_calls
local ok,liquid_reason,flask=service.spawn_filled_flask_at("water",-12.5,44.75)
assert(ok and flask~=0 and liquid_reason=="spawned_direct","filled flask world drop failed")
last=loads[#loads]
assert(last.entity==flask and last.x==-12.5 and last.y==44.75,"filled flask ignored exact world coordinates")
assert(material[flask]=="water","filled flask lost selected material")
assert(ew_calls==before_ew+1,"filled flask did not perform exactly one EW handoff")

-- Invalid coordinates must not load anything.
local load_count=#loads
local invalid,invalid_reason=service.spawn_at("data/entities/items/test.xml",nil,10)
assert(invalid==0 and invalid_reason=="invalid" and #loads==load_count,"missing coordinates created an entity")
local bad_liquid,bad_liquid_reason=service.spawn_filled_flask_at("water",0,nil)
assert(not bad_liquid and bad_liquid_reason=="invalid" and #loads==load_count,"missing liquid coordinates created an entity")

-- XML load failure creates nothing.
local bad_load,bad_load_reason=service.spawn_at("data/entities/items/bad_load.xml",1,2)
assert(bad_load==0 and bad_load_reason=="load","XML load failure was not transactional")

-- Material fill failure recursively removes root and descendants.
material_fail=true
local material_ok,material_reason=service.spawn_filled_flask_at("oil",5,6)
material_fail=false
assert(not material_ok and material_reason=="material","material failure reason changed")
local failed_root=loads[#loads].entity
assert(not alive[failed_root] and not alive[failed_root*100],"material failure left a partial flask tree")

-- EW failure after a successful load/world-enable also rolls back the full tree.
ew_fail=true
local ew_entity,ew_reason=service.spawn_at("data/entities/items/test.xml",9,10)
ew_fail=false
assert(ew_entity==0 and ew_reason=="world_sync","EW failure was not reported")
failed_root=loads[#loads].entity
assert(not alive[failed_root] and not alive[failed_root*100],"EW failure left a world item or child behind")

-- The legacy short-click world path shares the same strict world commit.
ew_fail=true
local near_entity,near_reason=service.spawn_near(1,"data/entities/items/test.xml")
ew_fail=false
assert(near_entity==0 and near_reason=="world_sync","short-click EW failure left a nominal spawn")
failed_root=loads[#loads].entity
assert(not alive[failed_root] and not alive[failed_root*100],"short-click EW failure left partial entities")

-- Strict inventory release creates only on commit and rolls back when quick inventory is full.
for slot=0,3 do
    local e=40+slot; alive[e]=true; names[e]="occupied"; children[e]={}; add_child(2,e)
    local c=10000+e; comps[e]={c}; ctype[c]="ItemComponent"; fields[c]={inventory_slot={slot,0},is_pickable=true,auto_pickup=false}
end
local ew_before_inventory=ew_calls
local inv_ok,inv_reason,inv_entity=service.give_strict(1,"data/entities/items/test.xml",true)
assert(not inv_ok and inv_reason=="full" and inv_entity==0,"full inventory did not reject strict drop: ok="..tostring(inv_ok).." reason="..tostring(inv_reason).." entity="..tostring(inv_entity))
failed_root=loads[#loads].entity
assert(not alive[failed_root] and not alive[failed_root*100],"failed inventory drop left partial entities")
assert(ew_calls==ew_before_inventory,"failed inventory drop must not perform an EW world handoff")
local liquid_inv_ok,liquid_inv_reason,liquid_inv_entity=service.give_filled_flask_strict(1,"water")
assert(not liquid_inv_ok and liquid_inv_reason=="full" and liquid_inv_entity==0,"full inventory accepted strict liquid drop")
failed_root=loads[#loads].entity
assert(not alive[failed_root] and not alive[failed_root*100],"failed liquid inventory drop left partial entities")
assert(ew_calls==ew_before_inventory,"failed liquid inventory drop incorrectly used EW")

-- Free one slot and verify a strict inventory commit succeeds without a world handoff.
EntityKill(43)
local inv_ok2,inv_reason2,inv_entity2=service.give_strict(1,"data/entities/items/test.xml",true)
assert(inv_ok2 and inv_reason2=="picked" and inv_entity2~=0,"strict inventory commit failed")
assert(EntityGetParent(inv_entity2)==2,"strict inventory item did not end in quick inventory")
assert(ew_calls==ew_before_inventory,"inventory commit incorrectly used EW world handoff")

-- Single-player world spawning does not require EW/CrossCall at all.
ew_enabled=false
local ew_before_single=ew_calls
local solo,solo_reason=service.spawn_at("data/entities/items/test.xml",7,8)
assert(solo~=0 and solo_reason=="spawned_singleplayer","single-player world spawn became EW-dependent")
assert(ew_calls==ew_before_single,"single-player world spawn called EW")

print("item_drag_transaction=PASS exact_world=true liquid=true strict_inventory=true rollback=true ew_once=true singleplayer=true")
