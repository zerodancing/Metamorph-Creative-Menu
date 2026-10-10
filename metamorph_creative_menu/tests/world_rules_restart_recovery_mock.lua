local root=assert(arg[1],"root required")
local native_dofile=dofile
local globals={}
local player=1
local world_entity=10
local world_comp=20
local components={
    [101]={type="CharacterDataComponent",owner=player,gravity=0},
    [102]={type="CharacterPlatformingComponent",owner=player,pixel_gravity=0},
}
local world={global_genome_relations_modifier=100, perk_gold_is_forever=true}
local dirty_calls=0
local network_updates=0
local diagnostics=0
local gold_lifetime_repairs=0

function GlobalsGetValue(key,fallback) local v=globals[key]; if v==nil then return fallback end; return v end
function GlobalsSetValue(key,value) globals[key]=tostring(value) end
function GameGetFrameNum() return 10 end
function GameGetWorldStateEntity() return world_entity end
function EntityGetFirstComponentIncludingDisabled(entity,kind)
    if entity==world_entity and kind=="WorldStateComponent" then return world_comp end
    local list=EntityGetComponentIncludingDisabled(entity,kind); return list[1]
end
function EntityGetComponentIncludingDisabled(entity,kind)
    if entity~=player then return {} end
    if kind=="CharacterDataComponent" then return {101} end
    if kind=="CharacterPlatformingComponent" then return {102} end
    return {}
end
function ComponentGetValue2(comp,field)
    if comp==world_comp then return world[field] end
    return components[comp] and components[comp][field]
end
function ComponentSetValue2(comp,field,value)
    if comp==world_comp then world[field]=value; return end
    assert(components[comp],"unknown component")
    components[comp][field]=value
end
function ComponentSetValue(comp,field,value)
    if comp==world_comp then world[field]=tonumber(value) or value; return end
    components[comp][field]=tonumber(value) or value
end
function ComponentGetTypeName(comp) return components[comp] and components[comp].type end
function ComponentGetEntity(comp) return components[comp] and components[comp].owner end
function EntityGetIsAlive(entity) return entity==player or entity==world_entity end
function EntityGetFilename(entity) return entity==player and "data/entities/player.xml" or "" end
function EntityGetTransform() return 0,0 end
function EntityGetInRadius() return {} end
function PhysicsBodyIDQueryBodies() return {} end
function PhysicsBodyIDSetGravityScale() end
function PhysicsBodyIDGetGravityScale() return 1 end
function PhysicsBodyIDSetDamping() end
function PhysicsBodyIDGetDamping() return 0,0 end
function ModIsEnabled() return false end
function GameHasFlagRun() return false end
function print() end
METAMORPH_CREATIVE_MENU_DIAGNOSTICS_CAPTURE=function(kind)
    if kind=="world_rules.startup_recovery" then diagnostics=diagnostics+1 end
end

local rules={
    {id="relations",kind="field",field="global_genome_relations_modifier",integer=true,choices={{native=true,label="NATIVE"},{value=100,label="FRIENDLY"}}},
    {id="gold_forever",kind="field",field="perk_gold_is_forever",choices={{native=true,label="NATIVE"},{value=true,label="ON"}}},
    {id="physics_gravity",kind="physics_gravity",choices={{native=true,label="NATIVE"},{value=0,label="ZERO"}}},
}
local sync={
    can_edit=function() return true,"singleplayer" end,
    mark_dirty=function() dirty_calls=dirty_calls+1 end,
    update=function(_,callbacks) network_updates=network_updates+1; callbacks.set_remote_authoritative(false) end,
}
local stain={supported=function() return true end,apply=function() end,cleanup_stale=function() end,restore_all=function() return true end,has_overrides=function() return false end}
local magic={
    supported=function() return true end,apply=function() return true end,restore=function() return true end,reset_all=function() return true end,
    owns=function() return false end,has_overrides=function() return false end,
    has_persisted_recovery=function() return false end,recover_persisted=function() return true end,
}
local stubs={
    ["mods/metamorph_creative_menu/files/platform/noita/player_locator.lua"]={get=function() return player end},
    ["mods/metamorph_creative_menu/files/platform/noita/input_guard.lua"]={heavy_updates_allowed=function() return true end},
    ["mods/metamorph_creative_menu/files/features/world_rules/gold_lifetime.lua"]={restore_missing_lifetimes=function() gold_lifetime_repairs=gold_lifetime_repairs+1; return 2 end},
    ["mods/metamorph_creative_menu/files/features/world_rules/definitions.lua"]=rules,
    ["mods/metamorph_creative_menu/files/integrations/ew/world_rules_sync.lua"]=sync,
    ["mods/metamorph_creative_menu/files/features/world_rules/stains.lua"]=stain,
    ["mods/metamorph_creative_menu/files/features/world_rules/magic_numbers.lua"]=magic,
    ["mods/metamorph_creative_menu/files/platform/noita/patcher_bridge.lua"]={get=function() return nil end},
}
dofile=function(path)
    if stubs[path] ~= nil then return stubs[path] end
    local prefix="mods/metamorph_creative_menu/"; if string.sub(path,1,#prefix)==prefix then return native_dofile(root.."/"..string.sub(path,#prefix+1)) end
    return native_dofile(path)
end

-- Simulate a previous process that closed while its Rules overrides were still saved.
METAMORPH_CREATIVE_MENU_WORLD_RULE_RECOVERY=nil
local recovery=assert(native_dofile(root.."/files/features/world_rules/recovery.lua"))
assert(recovery.capture("world","global_genome_relations_modifier",0))
assert(recovery.update_last("world","global_genome_relations_modifier",100))
assert(recovery.capture("world","perk_gold_is_forever",false))
assert(recovery.update_last("world","perk_gold_is_forever",true))
assert(recovery.capture("player_gravity","CharacterDataComponent|gravity|1",100,"data/entities/player.xml"))
assert(recovery.update_last("player_gravity","CharacterDataComponent|gravity|1",0))
assert(recovery.capture("player_gravity","CharacterPlatformingComponent|pixel_gravity|1",350,"data/entities/player.xml"))
assert(recovery.update_last("player_gravity","CharacterPlatformingComponent|pixel_gravity|1",0))

-- Fresh Lua VM/service: no in-memory ownership survives, only the persisted recovery journal.
METAMORPH_CREATIVE_MENU_WORLD_STATE_RULE_ADAPTER=nil
METAMORPH_CREATIVE_MENU_WORLD_RULE_PHYSICS=nil
METAMORPH_CREATIVE_MENU_WORLD_RULE_SERVICE=nil
METAMORPH_CREATIVE_MENU_WORLD_RULES_EDITOR=nil
local service=assert(native_dofile(root.."/files/features/world_rules/service.lua"))
assert(world.global_genome_relations_modifier==100 and world.perk_gold_is_forever==true and components[102].pixel_gravity==0,"restart fixture was not stale")

service.update()
assert(world.global_genome_relations_modifier==0,"restart recovery left mobs globally friendly")
assert(world.perk_gold_is_forever==false,"restart recovery left Gold Forever enabled")
assert(gold_lifetime_repairs==1,"restart recovery did not restore missing lifetimes on loaded gold")
assert(components[101].gravity==100,"restart recovery left CharacterData gravity modified")
assert(components[102].pixel_gravity==350,"restart recovery left player pixel gravity modified")
assert(recovery.has("world")==false and recovery.has("player_gravity")==false,"restart recovery journal was not cleared")
assert(service.choice_index(service.rules()[1])==1 and service.choice_index(service.rules()[2])==1 and service.choice_index(service.rules()[3])==1,"restart recovery did not return Rules UI to NATIVE")
assert(service.has_overrides()==false,"restart recovery left in-memory rule ownership")
assert(dirty_calls==0,"startup recovery was incorrectly published as a user Rules edit")
assert(network_updates==1,"normal network sync did not continue after recovery")
assert(diagnostics==1,"restart recovery was not visible to diagnostics")

io.write("world_rules_restart_recovery=PASS relations=0 pixel_gravity=350 recovery_clean=true\n")
