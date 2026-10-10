local root=assert(arg[1])
local native_dofile=dofile
dofile=function(path)
 local prefix="mods/metamorph_creative_menu/"
 if string.sub(path,1,#prefix)==prefix then return native_dofile(root.."/"..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end
local alive={[1]=true,[2]=true,[3]=true}
local parent={[1]=0,[2]=1,[3]=2}
local children={[1]={2},[2]={3},[3]={}}
local comp_owner={[11]=1,[21]=2,[31]=3}
local comp_type={[11]="Inventory2Component",[21]="AbilityComponent",[31]="ItemActionComponent"}
local fields={[11]={mActualActiveItem=2,mActiveItem=2},[21]={use_gun_script=true,mana_max=100,mana_charge_speed=10},[31]={}}
local objects={[21]={gun_config={deck_capacity=3}}}
local block_mana_max_restore=false
GlobalsGetValue=function(_,d) return d end; GlobalsSetValue=function() end
GameHasFlagRun=function() return false end; GameAddFlagRun=function() end; GameRemoveFlagRun=function() end
EntityGetIsAlive=function(e) return alive[e]==true end
EntityGetParent=function(e) return parent[e] or 0 end
EntityGetRootEntity=function(e) while parent[e] and parent[e]~=0 do e=parent[e] end; return e end
EntityGetAllChildren=function(e) local r={}; for _,c in ipairs(children[e] or {}) do if alive[c] then r[#r+1]=c end end; return r end
EntityGetAllComponents=function(e) local r={}; for c,o in pairs(comp_owner) do if o==e then r[#r+1]=c end end; return r end
EntityGetFirstComponentIncludingDisabled=function(e,t) for c,o in pairs(comp_owner) do if o==e and comp_type[c]==t then return c end end end
ComponentGetTypeName=function(c) return comp_type[c] end
ComponentGetEntity=function(c) return comp_owner[c] end
ComponentGetMembers=function() return {} end
ComponentGetValue=function(c,f) local v=fields[c] and fields[c][f]; return v==nil and "" or tostring(v) end
ComponentGetValue2=function(c,f) return fields[c] and fields[c][f] end
ComponentSetValue2=function(c,f,v)
 if block_mana_max_restore and c==21 and f=="mana_max" and tonumber(v)==200 then return end
 fields[c][f]=v
end
ComponentGetIsEnabled=function() return true end
EntitySetComponentIsEnabled=function() end
ComponentObjectGetValue2=function(c,o,f) return objects[c] and objects[c][o] and objects[c][o][f] end
ComponentObjectSetValue2=function(c,o,f,v) objects[c][o][f]=v end
GameGetWorldStateEntity=function() return 0 end
EntityAddChild=function(p,c)
 local old=parent[c] or 0; if old~=0 then for i=#children[old],1,-1 do if children[old][i]==c then table.remove(children[old],i) end end end
 parent[c]=p; children[p]=children[p] or {}; children[p][#children[p]+1]=c
end
EntityRemoveFromParent=function(c) parent[c]=0 end
EntityKill=function(e) alive[e]=false end
local tx=assert(loadfile(root.."/files/features/perks/transactions.lua"))()
local token=assert(tx.begin(1,"EXTRA_MANA"))
-- Vanilla-like owned changes: additive wand stats, action detached but alive at commit.
objects[21].gun_config.deck_capacity=4; fields[21].mana_max=150; fields[21].mana_charge_speed=15
parent[3]=0; children[2]={}
local ok,reason=tx.commit(token); assert(ok,reason)
-- Later wand use consumes/deletes the detached action. This used to make removal impossible forever.
alive[3]=false
-- Later independent additive edit should compose with inverse.
objects[21].gun_config.deck_capacity=6; fields[21].mana_max=250; fields[21].mana_charge_speed=25
local rok,rreason=tx.revert("EXTRA_MANA",1); assert(rok,rreason)
assert(objects[21].gun_config.deck_capacity==5,"deck="..tostring(objects[21].gun_config.deck_capacity))
assert(fields[21].mana_max==200,"max="..tostring(fields[21].mana_max))
assert(fields[21].mana_charge_speed==20,"charge="..tostring(fields[21].mana_charge_speed))
assert(not tx.has("EXTRA_MANA",1),"transaction not popped")

-- A partial scalar failure must be retryable without applying the already-restored
-- deck inverse twice.
local token2=assert(tx.begin(1,"EXTRA_MANA"))
objects[21].gun_config.deck_capacity=6; fields[21].mana_max=250; fields[21].mana_charge_speed=25
local ok2,reason2=tx.commit(token2); assert(ok2,reason2)
block_mana_max_restore=true
local fail,fail_reason=tx.revert("EXTRA_MANA",1)
assert(fail==false and fail_reason=="extra_mana_mana_max_restore","silent mana restore failure reported success")
assert(objects[21].gun_config.deck_capacity==5,"deck inverse did not commit before later scalar failure")
assert(fields[21].mana_max==250 and tx.has("EXTRA_MANA",1),"failed scalar restore lost transaction ownership")
block_mana_max_restore=false
local retry,retry_reason=tx.revert("EXTRA_MANA",1); assert(retry,retry_reason)
assert(objects[21].gun_config.deck_capacity==5,"retry applied deck inverse twice")
assert(fields[21].mana_max==200 and fields[21].mana_charge_speed==20,"retry did not finish mana scalar restore")
assert(not tx.has("EXTRA_MANA",1),"retry did not pop completed transaction")
print("extra_mana_missing_action_inverse=PASS reason="..tostring(rreason).." verified_retry=true deck=5 max=200 charge=20")
