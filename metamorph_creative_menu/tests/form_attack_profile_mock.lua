local root=assert(arg[1],"root required")
local profile=dofile(root.."/files/features/forms/attack_profile.lua")

local shotgun=profile.normalize({
    source_kind="animal", component=20,
    path="data/entities/projectiles/buckshot.xml",
    frames=100, global_frames=0,
    count_min=3, count_max=4,
    action_frame=4, animation="attack_ranged",
    min_distance=0, max_distance=180,
    offset_x=0, offset_y=-7,
})
assert(shotgun.path=="data/entities/projectiles/buckshot.xml","projectile path changed")
assert(shotgun.count_min==3 and shotgun.count_max==4,"shotgun count range lost")
assert(shotgun.frames==100 and shotgun.global_frames==0,"cooldowns changed")
assert(shotgun.action_frame==4 and shotgun.animation=="attack_ranged","authored action timing lost")

local count=profile.projectile_count(shotgun,function(a,b) assert(a==3 and b==4); return 4 end)
assert(count==4,"projectile count did not use authored random range")
assert(profile.animation_delay_frames(shotgun,0.15,60)==36,"animation frame timing was treated as game frames")

local close=profile.normalize({source_kind="ai_attack",component=31,path="same.xml",min_distance=0,max_distance=40,use_probability=100,frames=80,global_frames=0,count_min=1,count_max=1,root_offset_x=2,root_offset_y=3})
local far=profile.normalize({source_kind="ai_attack",component=32,path="same.xml",min_distance=100,max_distance=300,use_probability=100,frames=50,global_frames=50,count_min=2,count_max=2,root_offset_x=7,root_offset_y=9})
assert(close.component~=far.component and close.path==far.path,"profiles with same projectile must remain distinct")
assert(close.root_offset_x==2 and far.root_offset_x==7,"root offsets lost")
local selected_close=profile.select_primary({close,far},20,function() return 1 end)
local selected_far=profile.select_primary({close,far},180,function() return 1 end)
assert(selected_close==close,"close-range authored attack not selected")
assert(selected_far==far,"far-range authored attack not selected")

-- Player input is not target acquisition: outside every authored AI interval, use the
-- nearest authored attack profile instead of dropping the click. The actual shot target
-- remains the cursor and is not clamped to the profile range.
local fallback=profile.select_primary({close,far},70,function() return 1 end)
assert(fallback==close,"gap-range player input did not choose a nearest authored attack")
local very_far=profile.select_primary({close,far},1000,function() return 1 end)
assert(very_far==far,"far cursor was still blocked by the AI max-distance radius")
local min_only=profile.normalize({source_kind="ai_attack",component=39,path="minimum.xml",min_distance=30,max_distance=220,use_probability=100})
assert(profile.select_primary({min_only},0,function() return 1 end)==min_only,"near cursor was blocked by the AI min-distance radius")


local probabilistic=profile.normalize({source_kind="ai_attack",component=34,path="chance.xml",min_distance=0,max_distance=100,use_probability=70})
local calls={}
local declined=profile.select_primary({probabilistic},10,function(a,b) calls[#calls+1]={a,b}; return 71 end)
assert(declined==nil,"use_probability was treated as a weight instead of a probability gate")
assert(#calls==1 and calls[1][1]==1 and calls[1][2]==100,"single probabilistic attack used the wrong probability roll")
local accepted=profile.select_primary({probabilistic},10,function(a,b) return 70 end)
assert(accepted==probabilistic,"authored probability gate rejected its inclusive boundary")

local always_a=profile.normalize({source_kind="ai_attack",component=35,path="a.xml",min_distance=0,max_distance=100,use_probability=100})
local always_b=profile.normalize({source_kind="ai_attack",component=36,path="b.xml",min_distance=0,max_distance=100,use_probability=100})
local picked_second=profile.select_primary({always_a,always_b},10,function(a,b) assert(a==1 and b==2); return 2 end)
assert(picked_second==always_b,"100-percent attacks no longer use a normal candidate choice")

local guaranteed=profile.normalize({source_kind="ai_attack",component=37,path="guaranteed.xml",min_distance=0,max_distance=100,use_probability=100})
local optional=profile.normalize({source_kind="ai_attack",component=38,path="optional.xml",min_distance=0,max_distance=100,use_probability=70})
local rolls={71}
local idx=0
local keep_guaranteed=profile.select_primary({guaranteed,optional},10,function(a,b)
 idx=idx+1
 local v=rolls[idx]
 assert(v~=nil,"unexpected RNG call while gating mixed probabilities")
 return v
end)
assert(keep_guaranteed==guaranteed,"declined optional attack suppressed an otherwise guaranteed attack")

local rolls2={70,2}
idx=0
local optional_selected=profile.select_primary({guaranteed,optional},10,function(a,b)
 idx=idx+1
 local v=rolls2[idx]
 assert(v~=nil,"unexpected RNG call while selecting passed mixed probabilities")
 return v
end)
assert(optional_selected==optional,"passed optional attack did not participate in candidate selection")

local zero_prob=profile.normalize({source_kind="ai_attack",component=33,path="never.xml",min_distance=0,max_distance=100,use_probability=0})
assert(profile.select_primary({zero_prob},10,function() return 1 end)==nil,"zero-probability attack became primary")
print("form_attack_profile=PASS count=true timing=true multi=true same_path_distinct=true range_select=true probability_gate=true")
