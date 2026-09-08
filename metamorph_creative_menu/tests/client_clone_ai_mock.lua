local root=assert(arg[1])
local frame=1
local owned=true
local velocity={0,0}
local vars={
 [201]={name='mcm_companion_owner',value_int=1},
 [202]={name='mcm_companion_target',value_int=0},
 [203]={name='ew_gid_lid',value_bool=true},
}
local function comp_by_tag(tag) if tag=='mcm_companion_owner' then return 201 elseif tag=='mcm_companion_target' then return 202 end return 0 end
function GetUpdatedEntityID() return 10 end
function EntityGetIsAlive(e) return e==10 or e==1 end
function EntityGetFirstComponentIncludingDisabled(e,k,tag)
 if e~=10 then return 0 end
 if k=='ControlsComponent' then return 100 elseif k=='Inventory2Component' then return 101 elseif k=='CharacterDataComponent' then return 102 elseif k=='VariableStorageComponent' then return comp_by_tag(tag) end
 return 0
end
function EntityGetComponentIncludingDisabled(e,k) if e==10 and k=='VariableStorageComponent' then return {201,202,203} end return {} end
function ComponentGetValue2(c,f)
 if vars[c] then if c==203 and f=='value_bool' then return owned end return vars[c][f] end
 if c==101 and (f=='mActualActiveItem' or f=='mActiveItem') then return 0 end
 if c==102 and f=='mVelocity' then return velocity[1],velocity[2] end
 return 0
end
function ComponentSetValue2(c,f,a,b) if vars[c] then vars[c][f]=a elseif c==102 and f=='mVelocity' then velocity={a,b} end end
function ModIsEnabled(name) return name=='quant.ew' end
function EntityHasTag(e,t) if e==1 and t=='player_unit' then return true end if e==10 and t=='metamorph_creative_menu_companion' then return true end return false end
function EntityGetWithTag() return {} end
function EntityGetTransform(e) if e==10 then return 0,0 elseif e==1 then return 100,0 end return 0,0 end
function EntityGetFirstHitboxCenter(e) return EntityGetTransform(e) end
function EntityGetInRadiusWithTag() return {} end
function GameGetFrameNum() return frame end
function RaytracePlatforms() return false end
function ModDoesFileExist() return false end
owned=true; velocity={0,0}; frame=1
assert(loadfile(root..'/files/features/companion/ai.lua'))()
assert(velocity[1]>0,'EW client-owned clone returned before running AI')
owned=false; velocity={0,0}; frame=2
assert(loadfile(root..'/files/features/companion/ai.lua'))()
assert(velocity[1]==0 and velocity[2]==0,'remote EW replica ran local AI')
print('client_clone_ai=PASS client_owner_runs=true remote_replica_passive=true')
