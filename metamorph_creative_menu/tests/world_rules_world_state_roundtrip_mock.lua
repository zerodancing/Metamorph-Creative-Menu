local root=assert(arg[1],"root required")
local native_dofile=dofile
local globals={}
local world={
 global_genome_relations_modifier=0,
 perk_gold_is_forever=false,
 perk_infinite_spells=false,
 consume_actions=true,
 open_fog_of_war_everywhere=false,
 perk_trick_kills_blood_money=false,
 perk_hp_drop_chance=5,
 perk_rats_player_friendly=false,
 gore_multiplier=1,
 trick_kill_gold_multiplier=1,
 damage_flash_multiplier=1,
}
local baseline={}; for k,v in pairs(world) do baseline[k]=v end
function GlobalsGetValue(k,d) local v=globals[k]; if v==nil then return d end; return v end
function GlobalsSetValue(k,v) globals[k]=tostring(v) end
function GameGetWorldStateEntity() return 10 end
function EntityGetFirstComponentIncludingDisabled(e,k) if e==10 and k=="WorldStateComponent" then return 20 end return 0 end
function ComponentGetValue2(c,f) assert(c==20); return world[f] end
function ComponentSetValue2(c,f,v) assert(c==20); world[f]=v end
function ComponentSetValue(c,f,v) assert(c==20); local n=tonumber(v); world[f]=n~=nil and n or v end
local stubs={
 ["mods/metamorph_creative_menu/files/core/rule_math.lua"]={same=function(a,b)
  if type(a)=="number" or type(b)=="number" then return math.abs((tonumber(a)or 0)-(tonumber(b)or 0))<1e-9 end
  return a==b
 end},
}
dofile=function(path)
 if stubs[path]~=nil then return stubs[path] end
 local prefix="mods/metamorph_creative_menu/"; if string.sub(path,1,#prefix)==prefix then return native_dofile(root.."/"..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end
METAMORPH_CREATIVE_MENU_WORLD_RULE_DEFINITIONS=nil
METAMORPH_CREATIVE_MENU_WORLD_RULE_RECOVERY=nil
METAMORPH_CREATIVE_MENU_WORLD_STATE_RULE_ADAPTER=nil
local rules=assert(native_dofile(root.."/files/features/world_rules/definitions.lua"))
local adapter=assert(native_dofile(root.."/files/features/world_rules/world_state.lua"))
local tested=0
for _,rule in ipairs(rules) do
 if rule.kind=="field" or rule.kind=="infinite_spells" then
  for index=2,#(rule.choices or {}) do
   local ok,reason=adapter.apply(rule,rule.choices[index])
   assert(ok==true,"apply failed for "..rule.id.." choice "..index..":"..tostring(reason))
   local reset,reset_reason=adapter.apply(rule,rule.choices[1])
   assert(reset==true,"NATIVE failed for "..rule.id..":"..tostring(reset_reason))
   for field,expected in pairs(baseline) do
    local actual=world[field]
    if type(expected)=="number" then assert(math.abs((tonumber(actual)or 1e30)-expected)<1e-9,rule.id.." changed unrelated/failed field "..field)
    else assert(actual==expected,rule.id.." changed unrelated/failed field "..field) end
   end
   assert(adapter.has_overrides()==false,"ownership leaked after NATIVE for "..rule.id)
   tested=tested+1
  end
 end
end
assert(tested>0,"no WorldState choices exercised")
io.write("world_rules_world_state_roundtrip=PASS choices="..tested.." exact_native=true\n")
