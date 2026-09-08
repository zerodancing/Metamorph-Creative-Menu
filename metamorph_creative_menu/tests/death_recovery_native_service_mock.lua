local root=assert(arg[1])
local native_dofile=dofile
local frame=0
local alive={[1]=true,[2]=false,[3]=false}
local authoritative=1
local positions={[1]={12,34},[2]={0,0},[3]={0,0}}
local values={[101]={hp=4,max_hp=4,kill_now=false,invincibility_frames=0},[201]={hp=0,max_hp=5,kill_now=true,invincibility_frames=0},[301]={hp=0,max_hp=6,kill_now=true,invincibility_frames=0}}
local native_requested=false
local gameover_active=false
local serialize_count=0
local deserialize_count=0
local kill_count=0
local events={}

GameGetFrameNum=function() return frame end
EntityGetIsAlive=function(e) return alive[e]==true end
EntityGetTransform=function(e) local p=positions[e] or {0,0}; return p[1],p[2] end
EntityGetWithTag=function(tag) if tag=='player_unit' and authoritative~=0 and alive[authoritative] then return {authoritative} end return {} end
EntityHasTag=function() return false end
EntityGetFirstComponentIncludingDisabled=function(e,t)
 if t=='DamageModelComponent' then return e==1 and 101 or e==2 and 201 or e==3 and 301 or 0 end
 return 0
end
ComponentGetValue2=function(c,k) return values[c] and values[c][k] end
ComponentSetValue2=function(c,k,v) values[c]=values[c] or {}; values[c][k]=v end
local next_entity=2
EntityCreateNew=function(name) assert(name=='mcm_death_recovery_player'); local e=next_entity; next_entity=next_entity+1; alive[e]=true; return e end
EntityLoad=function(path,x,y) error('fresh fallback should not be needed') end
EntityKill=function(e) kill_count=kill_count+1; alive[e]=false end

local bridge={}
bridge.SerializeEntity=function(e) serialize_count=serialize_count+1; events[#events+1]='serialize:'..e; return 'snapshot:'..tostring(e)..':'..tostring(frame) end
bridge.DeserializeEntity=function(e,data,x,y)
 deserialize_count=deserialize_count+1; events[#events+1]='deserialize:'..e
 assert(data:match('^snapshot:1:'),'wrong rolling snapshot')
 positions[e]={x,y}
 local c=e==2 and 201 or 301
 values[c].hp=0; values[c].kill_now=true
end
bridge.SetPlayerEntity=function(e) events[#events+1]='authority:'..e; authoritative=e end
bridge.GetPlayerEntity=function() return authoritative end
bridge.RegisterPlayerEntityId=function(e) authoritative=e end

local native_patch={
 install=function() return true,'profile' end,
 is_installed=function() return true end,
 has_revive_request=function() return native_requested end,
 clear_revive_request=function() local had=native_requested; native_requested=false; events[#events+1]='request_clear'; return had end,
 is_game_over_active=function() return gameover_active,'ok' end,
 cancel_game_over_state=function() events[#events+1]='gameover_clear'; gameover_active=false; return true,'cleared' end,
 cleanup_post_revive=function() events[#events+1]='post_revive_cleanup'; return true,'post_revive_cleaned' end,
 status=function() return {installed=true,game_over_active=gameover_active} end,
}

local mocks={
 ['mods/metamorph_creative_menu/files/platform/noita/player_locator.lua']={get_human=function() return authoritative~=0 and alive[authoritative] and authoritative or 0 end},
 ['mods/metamorph_creative_menu/files/platform/noita/patcher_bridge.lua']={get=function() return bridge end},
 ['mods/metamorph_creative_menu/files/platform/noita/native_gameover_patch.lua']=native_patch,
 ['mods/metamorph_creative_menu/files/integrations/ew/runtime.lua']={enabled=function() return false end},
 ['mods/metamorph_creative_menu/files/features/death_recovery/post_revive_cleanup.lua']={
   apply=function() return native_patch.cleanup_post_revive() end,
   status=function() return {attempts=1,successes=1,last_reason='post_revive_cleaned'} end,
 },
 ['mods/metamorph_creative_menu/files/features/forms/human_restore.lua']={
   restore_controls=function() return true end,
   protect_player=function(e,frames)
     local c=e==1 and 101 or e==2 and 201 or 301
     values[c].invincibility_frames=math.max(values[c].invincibility_frames or 0,frames or 0)
     values[c].kill_now=false
   end,
 },
}
dofile=function(path) if mocks[path] then return mocks[path] end return native_dofile(path) end

local service=assert(loadfile(root..'/files/features/death_recovery/service.lua'))()
assert(service.install()==true)

-- Rolling backup is created during an ordinary live world frame, not from OnPlayerDied.
service.update()
assert(serialize_count==1 and deserialize_count==0)

-- Position tracking remains current even when serialization is throttled.
frame=5; positions[1]={77,88}; service.update()
assert(serialize_count==1,'rolling backup ignored throttle')

-- Model a completely vanilla death. MCM is not called at the death boundary at all.
alive[1]=false; authoritative=0; gameover_active=true
assert(deserialize_count==0 and kill_count==0)

-- Stock fourth button writes only request=1. The later OnWorldPreUpdate restores player,
-- establishes authority, and only then releases stock Game Over.
native_requested=true
local handled,source,entity=service.update()
assert(handled==true and source=='snapshot' and entity==2)
assert(authoritative==2 and alive[2])
assert(positions[2][1]==77 and positions[2][2]==88,'recovery did not use latest tracked position')
assert(values[201].hp==5 and values[201].kill_now==false)
assert(values[201].invincibility_frames==1800)
assert(gameover_active==false and native_requested==false)
assert(deserialize_count==1 and kill_count==0)
local authority_i, clear_i, cleanup_i
for i,v in ipairs(events) do
 if v=='authority:2' then authority_i=i elseif v=='gameover_clear' then clear_i=i elseif v=='post_revive_cleanup' then cleanup_i=i end
end
assert(authority_i and clear_i and authority_i<clear_i,'Game Over released before player authority')
assert(cleanup_i and clear_i<cleanup_i,'post-revive cleanup ran before Game Over release')

print('death_recovery_native_service=PASS rolling_snapshot=true death_boundary_idle=true authority_before_release=true post_cleanup=true invincibility=1800')
