local root=assert(arg[1],"root required")
local BOSS="data/entities/animals/boss_centipede/boss_centipede.xml"
local globals, entities, components = {}, {}, {}
local tracked, storage, queue, released, deleted, packets = {}, {}, {}, {}, {}, {}
local next_component=0
local reject_notify, hold_update, fail_resolve=false,false,false
local inside_native=false
local load_inside_native
local function add_component(entity, kind, values)
 next_component=next_component+1
 components[next_component]={kind=kind, values=values, enabled=true, entity=entity}
 entities[entity].components[#entities[entity].components+1]=next_component
 return next_component
end
local function spawn(entity,gid,owner,hp,tags)
 entities[entity]={alive=true,tags=tags or {boss_centipede=true},components={},x=100,y=200}
 add_component(entity,"VariableStorageComponent",{name="ew_gid_lid",value_string=gid,value_bool=owner})
 local damage=add_component(entity,"DamageModelComponent",{hp=hp,wait_for_kill_flag_on_death=true,kill_now=false})
 add_component(entity,"LuaComponent",{script_source_file="authored_combat.lua",script_death="death.lua"})
 add_component(entity,"ItemChestComponent",{})
 tracked[gid]=entity
 storage[gid]={filename=BOSS,hp=hp,global=true,owner=owner}
 return damage
end
function EntityGetIsAlive(entity) return entities[entity] and entities[entity].alive or false end
function EntityGetFilename(entity) return BOSS end
function EntityHasTag(entity,tag) return entities[entity] and entities[entity].tags[tag] or false end
function EntityGetRootEntity(entity) return entity end
function EntityGetWithTag(tag)
 local found={}
 for entity in pairs(entities) do
  if EntityGetIsAlive(entity) and EntityHasTag(entity,tag) then found[#found+1]=entity end
 end
 return found
end
function EntityGetTransform(entity) return entities[entity].x,entities[entity].y end
function EntityGetComponentIncludingDisabled(entity,kind)
 local found={}
 for _,id in ipairs(entities[entity].components) do
  if components[id] and components[id].kind==kind then found[#found+1]=id end
 end
 return found
end
function EntityGetFirstComponentIncludingDisabled(entity,kind)
 return EntityGetComponentIncludingDisabled(entity,kind)[1]
end
function ComponentGetValue2(id,key) return assert(components[id]).values[key] end
function ComponentSetValue2(id,key,value) assert(components[id]).values[key]=value end
function EntitySetComponentIsEnabled(entity,id,enabled) components[id].enabled=enabled end
function EntityRemoveComponent(entity,id) components[id]=nil end
function EntityKill(entity) entities[entity].alive=false end
function GlobalsGetValue(key,default) return globals[key] or default end
function GlobalsSetValue(key,value) globals[key]=value end
ewext={}
function ewext.find_by_gid(gid)
 assert(not inside_native,"ewext called reentrantly from the native update")
 assert(type(gid)=="string","u64 GID converted to a lossy Lua number")
 if fail_resolve then error("find_by_gid temporarily unavailable") end
 return tracked[gid]
end
function ewext.des_death_notify(entity,wait,x,y,file,responsible)
 assert(not inside_native,"death notify called reentrantly")
 if reject_notify then error("notify temporarily unavailable") end
 queue[#queue+1]={entity=entity,wait=wait,file=file,responsible=responsible}
end
-- Model the relevant v1.6.3 Rust ordering, not a mock where notify immediately deletes:
-- diff_model.rs update_tracked_entities drains pending_death_notify, then update_entity
-- releases a global !alive body. ReleaseAuthority retains proxy FullEntityData; a later
-- RequestAuthority can reload it. DeleteEntity removes it. Remote KillEntity is the
-- stock protocol and requires no MCM on the recipient.
function ewext.module_on_world_update()
 if hold_update then return end
 inside_native=true
 for _,notification in ipairs(queue) do
  for gid,entity in pairs(tracked) do
   if entity==notification.entity and storage[gid].owner then
    tracked[gid]=nil
    storage[gid]=nil
    deleted[gid]=(deleted[gid] or 0)+1
    packets[#packets+1]={kind="KillEntity",gid=gid,wait=notification.wait,file=notification.file}
   end
  end
 end
 queue={}
 for gid,entity in pairs(tracked) do
  if storage[gid].owner and (not EntityGetIsAlive(entity) or entities[entity].beyond_authority) then
   tracked[gid]=nil
   released[gid]=true -- FullEntityData remains in storage!
   EntityKill(entity)
  end
 end
 if load_inside_native then
  local f=load_inside_native; load_inside_native=nil; f()
 end
 inside_native=false
end

-- Establish the native failure without a guard: a previously tracked global Kolmi
-- disappears before EW's post-update callback. The proxy retains her spawn data.
spawn(1,"100",true,0)
EntityKill(1)
ewext.module_on_world_update()
assert(released["100"] and storage["100"],"fixture failed to reproduce retained authority")
storage["100"]=nil; released["100"]=nil

local module=assert(loadfile(root.."/files/integrations/ew/kolmi_lifecycle.lua"))()
assert(module.install())
assert(module.install(),"installation must be idempotent")

-- Lethal state must beat transfer. Preserve the original delayed-death body/coroutine
-- and chest; only its network record is retired. A peer with stock EW gets KillEntity.
local damage=spawn(10,"9007199254740992",true,46)
ewext.module_on_world_update()
ComponentSetValue2(damage,"hp",0)
entities[10].beyond_authority=true
ewext.module_on_world_update()
assert(not storage["9007199254740992"] and not released["9007199254740992"],"dying Kolmi was released instead of deleted")
assert(EntityGetIsAlive(10),"guard skipped the original authored death animation")
assert(EntityGetFirstComponentIncludingDisabled(10,"ItemChestComponent"),"original loot was stripped")
assert(not ComponentGetValue2(damage,"kill_now"),"guard forced the original death animation to finish")
assert(packets[#packets].kind=="KillEntity" and packets[#packets].wait and packets[#packets].file=="",
 "native replica death or distant replay suppression is missing")
-- Late stock callback must not create another packet or resurrect an untracked root.
ewext.des_death_notify(10,true,100,200,BOSS,2)
EntityKill(10)
ewext.module_on_world_update()
assert(deleted["9007199254740992"]==1,"late callback retired a boss twice")

-- A different u64 GID, including the adjacent value above 2^53, is a new legitimate
-- boss at the exact same position. No spatial tombstone may delete it.
spawn(11,"9007199254740993",true,46)
ewext.module_on_world_update()
assert(storage["9007199254740993"] and EntityGetIsAlive(11),"new nearby boss was mistaken for a replay")

-- A real same-GID authority reconstruction is retired through DES, then quietly
-- disposed of, with no second script/loot/death animation. No MCM marker is required.
spawn(12,"9007199254740992",true,46)
hold_update=true
ewext.module_on_world_update()
assert(EntityGetIsAlive(12),"reconstructed body killed before native acknowledgement")
hold_update=false
ewext.module_on_world_update()
assert(not EntityGetIsAlive(12) and not storage["9007199254740992"],"same-GID reconstruction survived")
assert(not EntityGetFirstComponentIncludingDisabled(12,"ItemChestComponent"),"reconstruction can duplicate loot")

-- Body removed between frames: use the last authoritative snapshot BEFORE native
-- !alive handling, rather than waiting for a late stock death callback.
spawn(20,"200",true,46)
ewext.module_on_world_update()
EntityKill(20)
ewext.module_on_world_update()
assert(deleted["200"]==1 and not released["200"],"late-callback resurrection window remains")

-- Discover a boss first tracked inside native update, then killed before the next one.
load_inside_native=function() spawn(21,"201",true,46) end
ewext.module_on_world_update()
EntityKill(21)
ewext.module_on_world_update()
assert(deleted["201"]==1 and not released["201"],"native-created root was not observed after update")

-- EW can load a Filename with saved HP=0 and is_charmed=false. There is no combat
-- coroutine on that passive copy to finish kill_now. It must not remain as an inert,
-- immortal body after its network record was removed.
load_inside_native=function()
 spawn(22,"202",true,0)
 add_component(22,"VariableStorageComponent",{name="initialized",value_bool=false})
end
ewext.module_on_world_update()
ewext.module_on_world_update()
assert(deleted["202"]==1 and not EntityGetIsAlive(22),"zero-HP passive reconstruction remained after DES retirement")

-- Arena request from the separate menu VM: notification acceptance is not commit.
spawn(30,"300",true,46)
globals.mcm31_kolmi_retire_request_v1_30="300"
hold_update=true
ewext.module_on_world_update()
assert(EntityGetIsAlive(30) and storage["300"],"arena root killed before DES processed its queue")
hold_update=false
ewext.module_on_world_update()
assert(not EntityGetIsAlive(30) and deleted["300"]==1,"arena GID/body did not retire together")
assert(globals.mcm31_kolmi_retire_request_v1_30=="","arena request was not consumed")

-- Remote authority, player forms, ordinary bosses, and healthy ownership transfer
-- must keep the stock lifecycle. Merely seeing zero HP on a replica is not authority.
spawn(40,"400",false,0)
spawn(41,"401",true,0,{boss_centipede=true,player_unit=true})
spawn(42,"402",true,0,{boss_centipede=true,polymorphed_player=true})
spawn(43,"403",true,0,{boss_centipede=true,ew_no_enemy_sync=true})
spawn(44,"404",true,0,{boss_alchemist=true})
ewext.module_on_world_update()
for _,gid in ipairs({"400","401","402","403","404"}) do
 assert(not deleted[gid] and storage[gid],"guard modified excluded entity "..gid)
end
spawn(45,"405",true,46)
ewext.module_on_world_update()
tracked["405"]=nil; EntityKill(45) -- stock healthy transfer has already relinquished it
ewext.module_on_world_update()
assert(not deleted["405"],"healthy transfer was interpreted as a death")

-- Transient API failures neither authorize a quiet kill nor discard a pending death.
spawn(50,"500",true,0)
reject_notify=true
ewext.module_on_world_update()
assert(EntityGetIsAlive(50) and storage["500"],"failed notify discarded a body")
reject_notify=false
ewext.module_on_world_update()
assert(deleted["500"]==1,"failed notify was not retried")
spawn(51,"501",true,46)
globals.mcm31_kolmi_retire_request_v1_51="501"
hold_update=true
ewext.module_on_world_update()
fail_resolve=true; hold_update=false
ewext.module_on_world_update()
assert(EntityGetIsAlive(51),"find_by_gid failure treated as acknowledgement")
fail_resolve=false
ewext.module_on_world_update()
assert(not EntityGetIsAlive(51),"acknowledgement was not retried")
print("ew_kolmi_lifecycle=PASS native_queue_order=true separate_vm_ack=true delayed_death=true u64=true transfer=true replay=true exclusions=true retries=true")
