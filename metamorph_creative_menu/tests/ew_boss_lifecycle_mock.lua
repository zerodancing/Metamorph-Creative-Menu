local root=assert(arg[1],"root required")
local test_root=(arg[0] or ""):match("^(.*)/tests/[^/]+$") or root
local native_dofile=dofile
local globals, entities, comps = {}, {}, {}
local tracked, storage, queue, deleted, released, packets = {}, {}, {}, {}, {}, {}
local next_comp, max_id, frame = 0, 0, 100
local inside_native, reject_notify, hold_update, fail_resolve = false,false,false,false
local during_native
local tag_queries=0
local stock_queue={}
local function component(e,t,v)
 next_comp=next_comp+1
 comps[next_comp]={entity=e,type=t,v=v or {},enabled=true}
 entities[e].components[#entities[e].components+1]=next_comp
 return next_comp
end
local function spawn(e,gid,opts)
 opts=opts or {}
 max_id=math.max(max_id,e)
 entities[e]={alive=true,tags=opts.tags or {ew_des=true},components={},children={},
  file=opts.file or "mods/example/entities/ancient_guardian.xml",x=100,y=200}
 component(e,"VariableStorageComponent",{name="ew_gid_lid",value_string=gid,value_bool=opts.owner~=false})
 local damage=component(e,"DamageModelComponent",{hp=opts.hp or 46,
  wait_for_kill_flag_on_death=opts.wait==true,kill_now=false})
 if opts.trait~=false then component(e,opts.trait or "BossHealthBarComponent",{}) end
 component(e,"LuaComponent",{script_death="custom_loot.lua",script_source_file="custom_phases.lua"})
 component(e,"ItemChestComponent",{})
 tracked[gid]=e; storage[gid]={entity=e,file=entities[e].file,owner=opts.owner~=false}
 return damage
end
function EntityGetIsAlive(e) return entities[e] and entities[e].alive or false end
function EntityHasTag(e,t) return entities[e] and entities[e].tags[t] or false end
function EntityGetRootEntity(e) return entities[e] and (entities[e].parent or e) or 0 end
function EntityGetAllChildren(e) return entities[e].children end
function EntityGetWithTag(t)
 tag_queries=tag_queries+1
 local out={}; for e in pairs(entities) do if EntityGetIsAlive(e) and EntityHasTag(e,t) then out[#out+1]=e end end
 return out
end
function EntityGetTransform(e) return entities[e].x,entities[e].y end
function EntityGetFilename(e) return entities[e] and entities[e].file or "" end
function EntityGetComponentIncludingDisabled(e,t)
 local out={}
 for _,id in ipairs((entities[e] or {}).components or {}) do
  if comps[id] and comps[id].type==t then out[#out+1]=id end
 end
 return out
end
function EntityGetFirstComponentIncludingDisabled(e,t) return EntityGetComponentIncludingDisabled(e,t)[1] end
function ComponentGetValue2(c,k) return assert(comps[c]).v[k] end
function ComponentSetValue2(c,k,v) assert(comps[c]).v[k]=v end
function EntitySetComponentIsEnabled(e,c,v) comps[c].enabled=v end
function EntityRemoveComponent(e,c) comps[c]=nil end
function EntityKill(e)
 entities[e].alive=false
 for _,child in ipairs(entities[e].children) do EntityKill(child) end
end
function GlobalsGetValue(k,d) return globals[k] or d end
function GlobalsSetValue(k,v) globals[k]=v end
function EntitiesGetMaxID() return max_id end
function GameGetFrameNum() return frame end
dofile=function(p)
 local rel=p:match("^mods/metamorph_creative_menu/(.*)$")
 return native_dofile(rel and root.."/"..rel or p)
end
dofile_once=dofile
ewext={}
function ewext.find_by_gid(gid)
 assert(not inside_native,"reentrant DES lookup")
 assert(type(gid)=="string","GID lost u64 precision")
 if fail_resolve then error("lookup failed") end
 return tracked[gid]
end
function ewext.des_death_notify(e,w,x,y,file,responsible)
 assert(not inside_native,"reentrant DES death notification")
 if reject_notify then error("notification failed") end
 queue[#queue+1]={e=e,wait=w,file=file,responsible=responsible}
end
function ewext.module_on_new_entity(arr,len) assert(len==#arr) end
-- Relevant actual EW order: pending_death_notify -> tracked !alive handling.
-- A missed callback leaves FullEntityData retained after global ReleaseAuthority.
function ewext.module_on_world_update()
 frame=frame+1
 if hold_update then return end
 inside_native=true
 for _,n in ipairs(queue) do
  for gid,e in pairs(tracked) do
   if e==n.e and storage[gid].owner then
    tracked[gid]=nil; storage[gid]=nil
    deleted[gid]=(deleted[gid] or 0)+1
    packets[#packets+1]={gid=gid,file=n.file,wait=n.wait,responsible=n.responsible,kind="KillEntity"}
   end
  end
 end
 queue={}
 for gid,e in pairs(tracked) do
  if storage[gid].owner and not EntityGetIsAlive(e) then tracked[gid]=nil; released[gid]=true end
 end
 if during_native then local f=during_native; during_native=nil; f() end
 inside_native=false
end
local function flush_stock()
 local q=stock_queue; stock_queue={}
 for _,n in ipairs(q) do ewext.des_death_notify(table.unpack(n)) end
end
local function stock_death(e,responsible)
 -- Independent entity VM; execute the supplied stock callback plus the real append.
 local env=setmetatable({}, {__index=_G})
 env.GetUpdatedEntityID=function() return e end
 env.CrossCall=function(name,...) assert(name=="ew_death_notify"); stock_queue[#stock_queue+1]={...} end
 assert(loadfile(test_root.."/tests/fixtures/ew163_death_notify.lua","t",env))()
 local append=loadfile(root.."/files/integrations/ew/boss_death_notify.lua","t",env)
 if append then append() end
 env.death(1,"lethal hit",responsible or 0,true)
end

-- Install the confirmed Kolmi guard together with the new guard, in production order.
assert(native_dofile(root.."/files/integrations/ew/kolmi_lifecycle.lua").install())
local general=loadfile(root.."/files/integrations/ew/boss_lifecycle.lua")
if general then local m=general(); assert(m.install()); assert(m.install()) end

-- TEST 31 regression: a generic mod boss with only a standard healthbar dies between
-- frames. Running this file against TEST 31 must fail here with retained FullEntityData.
spawn(100,"9007199254740992")
ewext.module_on_world_update()
EntityKill(100)
ewext.module_on_world_update()
assert(deleted["9007199254740992"]==1 and not released["9007199254740992"],
 "non-Kolmi boss was released and retained instead of permanently deleted")
assert(packets[#packets].file=="" and packets[#packets].kind=="KillEntity", "boss XML scheduled for death replay")

-- Standard callback + real entity-VM append preserves killer and handles a boss that
-- dies before observation. The stock callback still runs; it is not swallowed in Lua.
spawn(110,"110",{file="mods/unlisted_mod/monarch.xml"})
stock_death(110,77)
assert(#stock_queue==1,"append replaced rather than delegated the stock callback")
EntityKill(110)
flush_stock()
ewext.module_on_world_update()
assert(deleted["110"]==1 and packets[#packets].responsible==77,"early death mailbox lost identity/killer")
assert(packets[#packets].file=="","early callback retained a boss SpawnOnce filename")

-- The actual Koipi-style 40 x wait(3) delayed death must retain the original body,
-- scripts and loot until kill_now. Zero HP itself is not final, including custom mods.
local d=spawn(120,"120",{file="data/entities/animals/boss_limbs/boss_limbs.xml",wait=true,trait="LimbBossComponent"})
ewext.module_on_world_update()
ComponentSetValue2(d,"hp",0)
for i=1,120 do ewext.module_on_world_update() end
assert(tracked["120"]==120 and not deleted["120"],"delayed death animation was cut short")
ComponentSetValue2(d,"kill_now",true)
ewext.module_on_world_update()
assert(deleted["120"]==1 and EntityGetIsAlive(120),"final flag did not retire only the network record")
assert(EntityGetFirstComponentIncludingDisabled(120,"ItemChestComponent"),"original loot was stripped")
EntityKill(120)

-- Unknown mod: HP=0 and a death-like callback can be a phase transition. Wait-for-kill
-- is explicit; initialized=false has no Kolmi-specific meaning for this custom boss.
d=spawn(130,"130",{wait=true,trait=false,file="mods/multi_phase/a.xml"})
component(130,"VariableStorageComponent",{name="initialized",value_bool=false})
ewext.module_on_world_update()
ComponentSetValue2(d,"hp",0)
stock_death(130,88); flush_stock()
ewext.module_on_world_update()
assert(not deleted["130"] and tracked["130"],"phase transition treated as final death")
ComponentSetValue2(d,"hp",100)
ewext.module_on_world_update()
assert(not deleted["130"],"regenerated phase was killed")
tracked["130"]=nil; EntityKill(130) -- healthy transfer to a different owner
ewext.module_on_world_update()
assert(not deleted["130"],"healthy transfer was tombstoned by an earlier phase event")
spawn(131,"130",{wait=true,trait=false}) -- returned alive, same GID
ewext.module_on_world_update()
assert(tracked["130"]==131,"healthy authority reconstruction was blocked")

-- New boss and next phase at the same location and same filename, with adjacent u64
-- GID, remain independent. Only a confirmed dead exact GID is a stale reconstruction.
spawn(140,"9007199254740993")
ewext.module_on_world_update()
assert(tracked["9007199254740993"]==140,"fresh summon/phase confused with dead GID")
spawn(150,"9007199254740992")
entities[151]={alive=true,tags={},components={},children={},parent=150,x=100,y=200}
max_id=151
entities[150].children={151}
local child_death=component(151,"LuaComponent",{script_death="duplicate_reward.lua"})
component(151,"ItemChestComponent",{})
hold_update=true
ewext.module_on_world_update()
assert(EntityGetIsAlive(150) and storage["9007199254740992"],"copy killed before DES acknowledgement")
hold_update=false
ewext.module_on_world_update()
assert(not EntityGetIsAlive(150) and not storage["9007199254740992"],"same-GID copy survived")
assert(ComponentGetValue2(child_death,"script_death")=="" and not EntityGetFirstComponentIncludingDisabled(151,"ItemChestComponent"),
 "copy's child can duplicate death loot")

-- Boss with a custom HUD and only keepalive+damage; no vanilla name, tag or healthbar.
d=spawn(160,"160",{trait="StreamingKeepAliveComponent",file="mods/custom_hud/creature.xml"})
ewext.module_on_world_update()
ComponentSetValue2(d,"kill_now",true)
ewext.module_on_world_update()
assert(deleted["160"]==1,"custom HUD/global boss was missed")
EntityKill(160)

-- Discovery inside native update, including a boss whose healthbar was temporarily
-- hidden by the preexisting demotion wrapper at the initial discovery event.
d=spawn(170,"170")
ewext.module_on_new_entity({170},1)
local bar=EntityGetFirstComponentIncludingDisabled(170,"BossHealthBarComponent")
EntityRemoveComponent(170,bar)
ewext.module_on_world_update()
EntityKill(170)
ewext.module_on_world_update()
assert(deleted["170"]==1,"first-track demotion hid a known boss from lifecycle")
during_native=function() spawn(180,"180",{trait="BossDragonComponent"}) end
ewext.module_on_world_update()
EntityKill(180)
ewext.module_on_world_update()
assert(deleted["180"]==1,"native-created boss not observed after native update")

-- Callback while native DES is on the stack only writes a mailbox; it must not call
-- find_by_gid/des_death_notify reentrantly. Main-VM flush follows the real EW order.
during_native=function()
 spawn(190,"190")
 stock_death(190,91)
 EntityKill(190)
end
ewext.module_on_world_update()
flush_stock()
ewext.module_on_world_update()
assert(deleted["190"]==1 and packets[#packets].responsible==91,"native-stack callback was lost")

-- Native had already released before a late event could be read. Preserve the proven
-- dead GID, then reject its later authority replay; do not mistake release for commit.
spawn(200,"200")
stock_death(200,92)
EntityKill(200); tracked["200"]=nil; released["200"]=true
ewext.module_on_world_update()
spawn(201,"200")
ewext.module_on_world_update()
assert(not EntityGetIsAlive(201) and not storage["200"],"late event did not reject retained authority")
flush_stock(); ewext.module_on_world_update()

-- Foreign authority, polymorph/player avatars, EW death-replay corpses, ordinary
-- mobs and children keep their stock protocol. Kolmi still uses the unchanged guard.
spawn(210,"210",{owner=false})
spawn(211,"211",{tags={boss=true,player_unit=true}})
spawn(212,"212",{tags={boss=true,polymorphed_player=true}})
spawn(213,"213",{tags={boss=true,ew_peer=true}})
spawn(214,"214",{tags={boss=true,ew_no_enemy_sync=true}})
spawn(215,"215",{trait=false,tags={ew_des=true,enemy=true}})
for i=210,215 do
 ewext.module_on_world_update()
 local damage=EntityGetFirstComponentIncludingDisabled(i,"DamageModelComponent")
 ComponentSetValue2(damage,"kill_now",true)
end
ewext.module_on_world_update()
for i=210,215 do assert(not deleted[tostring(i)],"excluded entity modified: "..i) end
local prior=#queue
ewext.des_death_notify(215,false,100,200,"data/entities/animals/sheep.xml",33)
assert(#queue==prior+1 and queue[#queue].file=="data/entities/animals/sheep.xml", "ordinary death replay was changed")
queue={}
spawn(216,"216",{trait="LimbBossComponent",tags={ew_des=true,enemy=true}})
ewext.module_on_world_update()
prior=#queue
ewext.des_death_notify(216,false,100,200,"data/entities/animals/lukki/lukki.xml",33)
assert(#queue==prior+1 and queue[#queue].file=="data/entities/animals/lukki/lukki.xml",
 "ordinary lukki treated as a boss merely because of LimbBossComponent")
queue={}
-- Becoming a player after discovery must also release ownership of the callback.
spawn(220,"220")
ewext.module_on_world_update()
entities[220].tags.player_unit=true
prior=#queue
ewext.des_death_notify(220,false,100,200,"form.xml",33)
assert(#queue==prior+1,"cached boss record swallowed a player-form callback")
queue={}

d=spawn(230,"230",{tags={boss_centipede=true,boss=true},wait=true,
 file="data/entities/animals/boss_centipede/boss_centipede.xml"})
ewext.module_on_world_update()
ComponentSetValue2(d,"hp",0)
ewext.module_on_world_update()
assert(deleted["230"]==1 and EntityGetIsAlive(230),"confirmed Kolmi lethal-state fix regressed")
EntityKill(230)

-- Inherited vanilla tags do not make an unknown multi-phase mod boss vanilla Kolmi.
d=spawn(231,"231",{tags={boss_centipede=true,boss=true},wait=true})
ewext.module_on_world_update()
ComponentSetValue2(d,"hp",0)
ewext.module_on_world_update()
assert(not deleted["231"] and tracked["231"],"modded centipede phase used vanilla Kolmi's early-death rule")
ComponentSetValue2(d,"kill_now",true)
ewext.module_on_world_update()
assert(deleted["231"]==1,"modded centipede did not use generic final-death handling")
EntityKill(231)

-- Notification failure and failed acknowledgement never authorize a quiet kill.
d=spawn(240,"240")
ewext.module_on_world_update()
ComponentSetValue2(d,"kill_now",true)
reject_notify=true
ewext.module_on_world_update()
assert(EntityGetIsAlive(240) and tracked["240"],"failed notification discarded a boss")
reject_notify=false
ewext.module_on_world_update()
assert(deleted["240"]==1,"notification failure was not retried")
EntityKill(240)
spawn(241,"240")
hold_update=true
ewext.module_on_world_update()
hold_update=false; fail_resolve=true
ewext.module_on_world_update()
assert(EntityGetIsAlive(241),"lookup error was treated as an acknowledgement")
fail_resolve=false
ewext.module_on_world_update()
assert(not EntityGetIsAlive(241),"acknowledgement failure was not retried")

-- Custom boss HUD lives on a child; the parent is the actual EW synchronization root.
d=spawn(250,"250",{trait=false})
entities[251]={alive=true,tags={},components={},children={},parent=250,x=100,y=200}
max_id=251; entities[250].children={251}
component(251,"BossHealthBarComponent",{})
ewext.module_on_world_update()
EntityKill(250)
ewext.module_on_world_update()
assert(deleted["250"]==1,"boss HUD on a child did not protect the actual DES root")

-- An acknowledged old boss ID does not authorize deleting a player who took over
-- the local entity while the request was pending.
spawn(260,"250")
hold_update=true
ewext.module_on_world_update()
entities[260].tags.player_unit=true
hold_update=false
ewext.module_on_world_update()
assert(EntityGetIsAlive(260),"acknowledged reconstruction cleanup deleted a newly possessed player")

-- Inventory/living-entity population is not scanned each frame by the generic guard.
-- The only per-frame tag query here is from the unchanged Kolmi guard (twice/frame).
local queries=tag_queries
for i=1,20 do ewext.module_on_world_update() end
assert(tag_queries-queries<=44,"general guard performs a full tag sweep every frame")

-- Optional integration with the user's actual Noita data directory. The whole
-- authored Koipi script is loaded unchanged; its coroutine drives the final flag.
if arg[2] then
 local data_root=arg[2]
 d=spawn(300,"300",{wait=true,trait="BossHealthBarComponent",
  file="data/entities/animals/boss_limbs/boss_limbs.xml"})
 component(300,"LimbBossComponent",{})
 ewext.module_on_world_update()
 local flags, loot, actions, stats={},{},0,0
 local env=setmetatable({}, {__index=_G})
 env.dofile=function() end
 env.async_loop=function() end
 env.get_herd_id=function() return 1 end
 env.component_get_value_float=function() return 10 end
 env.GetUpdatedEntityID=function() return 300 end
 env.EntityGetFirstComponent=EntityGetFirstComponentIncludingDisabled
 env.EntitySetComponentsWithTagEnabled=function() end
 env.for_comps=function() end
 env.ComponentGetValueFloat=ComponentGetValue2
 env.ComponentSetValue=function(c,k,v)
  if k=="kill_now" then v=v=="1" else v=tonumber(v) or v end
  ComponentSetValue2(c,k,v)
 end
 env.SetRandomSeed=function() end
 env.Random=function(a,b) return a end
 env.GameScreenshake=function() end
 env.GameCreateParticle=function() end
 env.StatsLogPlayerKill=function(e) assert(e==300); stats=stats+1 end
 env.AddFlagPersistent=function(f) flags[f]=true end
 env.wait=function(n) coroutine.yield(n) end
 assert(loadfile(data_root.."/entities/animals/boss_limbs/boss_limbs_update.lua","t",env))()
 ComponentSetValue2(d,"hp",0)
 local co=coroutine.create(env.check_death)
 local waited=0
 while coroutine.status(co)~="dead" do
  local ok,n=coroutine.resume(co); assert(ok,n)
  if n then
   assert(n==3,"authored death changed its wait interval")
   for i=1,n do
    ewext.module_on_world_update(); waited=waited+1
    assert(tracked["300"]==300 and not deleted["300"],"actual Koipi coroutine lost its DES record mid-animation")
   end
  end
 end
 assert(waited==120 and stats==1 and flags.miniboss_limbs,"authored death sequence did not finish normally")
 assert(ComponentGetValue2(d,"kill_now"),"actual coroutine did not set kill_now")
 -- Its real death callback must still produce the original drops/unlock once.
 env.HasFlagPersistent=function(f) return flags[f] or false end
 env.check_parallel_pos=function() return 0 end
 env.EntityLoad=function(file) loot[#loot+1]=file; return 999 end
 env.CreateItemActionEntity=function() actions=actions+1 end
 assert(loadfile(data_root.."/entities/animals/boss_limbs/boss_limbs_death.lua","t",env))()
 env.death(1,"lethal hit",77,true)
 stock_death(300,77); EntityKill(300); flush_stock()
 ewext.module_on_world_update()
 assert(deleted["300"]==1 and #loot==3 and actions==4 and flags.card_unlocked_pyramid,
  "actual Koipi loot/unlock or final DES retirement changed")
 print("ew_boss_lifecycle_vanilla_koipi=PASS authored_wait_frames=120 authored_loot_entities=3 authored_actions=4 unlock=true")
end
print("ew_boss_lifecycle=PASS generic_traits=true phase_safe=true delayed_death=true native_callbacks=true u64=true ack=true mod_bosses=true kolmi_preserved=true")
