local root=assert(arg[1],'root required')
local globals={}
local tags={[50]={polymorphed_player=true,metamorph_creative_menu_network_form=true}}
local pose_calls=0
ctx={my_player={entity=50},my_id='me'}
ewext=setmetatable({}, {__index=function(_,key) error('unexpected ewext access: '..tostring(key)) end})
function EntityGetIsAlive(e) return e==50 end
function EntityHasTag(e,t) return tags[e] and tags[e][t] or false end
function EntityAddTag(e,t) tags[e]=tags[e] or {}; tags[e][t]=true end
function EntityGetTransform() return 100,200,0,1,1 end
function EntityGetComponentIncludingDisabled(e,typ)
  if typ=='VariableStorageComponent' then return {} end
  return {}
end
function EntityGetFirstComponentIncludingDisabled(e,typ)
  if typ=='WormPlayerComponent' then return 701 end
  if typ=='WormComponent' then return 702 end
  return nil
end
function ComponentGetValue2(c,f)
  if c==701 and f=='mDirection' then return 1,0 end
  if c==702 and (f=='mTargetSpeed' or f=='speed') then return 20 end
  return 0
end
function ComponentSetValue2() end
function GlobalsGetValue(k,d) return globals[k] or d end
function GlobalsSetValue(k,v) globals[k]=tostring(v) end
function GameGetFrameNum() return tonumber(globals.frame or '0') end
function EntityGetAllChildren() return {} end
util={}
local rpc={opts_reliable=function() end,opts_everywhere=function() end}
local forms=assert(dofile(root..'/files/integrations/ew/bridge/forms.lua'))
forms.register_pose(rpc,{})
rpc.sync_form_pose=function(...) pose_calls=pose_calls+1 end

globals.frame='0'; forms.update(0)
assert(tags[50].ew_no_enemy_sync==true,'MCM player-form was not explicitly excluded from DES')
assert(pose_calls==1,'first articulated pose was not sent')
globals.frame='3'; forms.update(3)
assert(pose_calls==1,'articulated pose still uses old 20Hz cadence')
globals.frame='6'; forms.update(6)
assert(pose_calls==2,'articulated 10Hz correction did not send at six frames')
globals.mcm_ew_boss_death_pressure_until_v1='20'
globals.frame='12'; forms.update(12)
assert(pose_calls==2,'pose traffic ignored boss death pressure window')
print('form_network_pressure=PASS early_des_exclusion=true native_poly_exclusion=true articulated_10hz=true death_priority=true')
