local root = assert(arg[1], "root required")
local native_dofile = dofile

local next_component = 1000
local next_entity = 5000
local components_by_entity = {}
local values = {}
local enabled = {}
local alive = {}
local transforms = {}
local frame = 90
local mouse_x, mouse_y = 100, 0
local raw_mouse = {[1]=false,[2]=false}
local animation_calls = {}
local loaded = {}
local shot = {}
local tags = {}
local owners = {}

local function add(entity, kind, id, data)
    components_by_entity[entity] = components_by_entity[entity] or {}
    components_by_entity[entity][kind] = components_by_entity[entity][kind] or {}
    table.insert(components_by_entity[entity][kind], id)
    values[id] = data or {}
    owners[id] = entity
    enabled[id] = values[id]._enabled ~= false
    alive[entity] = true
    transforms[entity] = transforms[entity] or {0,0,0,1,1}
    return id
end

local entity_tree = { walk=function(entity, fn) return fn(entity) end }
local component_ops = {}
function component_ops.valid(v) return v ~= nil and v ~= 0 end
function component_ops.get(c, f, fallback)
    local t=values[c]
    if t==nil or t[f]==nil then return fallback end
    return t[f]
end
function component_ops.boolean(v)
    if type(v)=="number" then return v~=0 end
    if type(v)=="string" then return v=="1" or v=="true" end
    return v==true
end
function component_ops.ensure_controls(entity)
    local list=components_by_entity[entity] and components_by_entity[entity].ControlsComponent or nil
    if list and list[1] then return list[1] end
    next_component=next_component+1
    return add(entity,"ControlsComponent",next_component,{mButtonDownFire=false,mButtonDownFire2=false,polymorph_hax=true})
end

local stubs = {
    ["mods/metamorph_creative_menu/files/platform/noita/entity_tree.lua"] = entity_tree,
    ["mods/metamorph_creative_menu/files/features/forms/component_ops.lua"] = component_ops,
}
dofile=function(path)
    if stubs[path] then return stubs[path] end
    local prefix="mods/metamorph_creative_menu/"
    if string.sub(path,1,#prefix)==prefix then return native_dofile(root.."/"..string.sub(path,#prefix+1)) end
    return native_dofile(path)
end

function GameGetFrameNum() return frame end
function GameIsInventoryOpen() return false end
function InputIsMouseButtonDown(code) return raw_mouse[code] == true end
function ComponentGetIsEnabled(c) return enabled[c] ~= false end
function ComponentGetValue2(c,f)
    local v=values[c] and values[c][f]
    if type(v)=="table" and #v>=2 then return v[1],v[2] end
    return v
end
function ComponentGetEntity(c) return owners[c] or 0 end
function ComponentSetValue2(c,f,a,b)
    values[c]=values[c] or {}
    if b~=nil then values[c][f]={a,b} else values[c][f]=a end
end
function EntitySetComponentIsEnabled(_,c,v) enabled[c]=v==true end
function EntityGetComponentIncludingDisabled(entity,kind)
    return (components_by_entity[entity] and components_by_entity[entity][kind]) or {}
end
function EntityGetFirstComponentIncludingDisabled(entity,kind)
    local list=EntityGetComponentIncludingDisabled(entity,kind); return list[1]
end
function EntityGetTransform(entity)
    local t=transforms[entity] or {0,0,0,1,1}; return t[1],t[2],t[3],t[4],t[5]
end
function EntitySetTransform(entity,x,y,r,sx,sy) transforms[entity]={x,y,r or 0,sx or 1,sy or 1} end
function EntityGetRootEntity(entity) return entity end
function EntityGetIsAlive(entity) return alive[entity] ~= false end
function EntityGetInRadiusWithTag() return {} end
function DEBUG_GetMouseWorld() return mouse_x,mouse_y end
function ModTextFileGetContent(path)
    if path=="data/enemies_gfx/chest_mimic.xml" then
        return '<Sprite><RectAnimation name="stand" frame_count="1" frame_wait="0.23" loop="1"></RectAnimation><RectAnimation name="attack" frame_count="7" frame_wait="0.07" loop="0"></RectAnimation></Sprite>'
    end
    return ""
end
function GamePlayAnimation(entity,name) animation_calls[#animation_calls+1]={entity,name} end
function EntityInflictDamage(...) return true end
function SetRandomSeed() end
function Random(a,b) return a end
function EntityLoad(path,x,y)
    local id=2000+#loaded+1; loaded[#loaded+1]={id=id,path=path,x=x,y=y}; alive[id]=true; transforms[id]={x,y,0,1,1}
    add(id,"VelocityComponent",id*10+1,{mVelocity={0,0}})
    add(id,"ProjectileComponent",id*10+2,{damage=0.1})
    return id
end
function GameShootProjectile(shooter,sx,sy,tx,ty,projectile,network)
    shot[#shot+1]={shooter=shooter,projectile=projectile,tx=tx,ty=ty,network=network}; return true
end
function EntityKill(entity) alive[entity]=false end
function EntityCreateNew() next_entity=next_entity+1; alive[next_entity]=true; transforms[next_entity]={0,0,0,1,1}; return next_entity end
function EntityAddTag(entity,tag) tags[entity]=tags[entity] or {}; tags[entity][tag]=true end
function EntityAddComponent2(entity,kind,data)
    next_component=next_component+1
    return add(entity,kind,next_component,data or {})
end
function EntityRefreshSprite() end

-- Dash support is intentionally absent. Player-controlled forms keep secondary fire
-- available to the normal combat system and no manual action module owns RMB.
local wolf=1
add(wolf,"ControlsComponent",11,{mButtonDownFire=false,mButtonDownFire2=false,polymorph_hax=true})
add(wolf,"AnimalAIComponent",12,{_enabled=false,attack_dash_enabled=true,attack_dash_speed=800,attack_dash_distance=50})
transforms[wolf]={0,0,0,1,1}
local actions=assert(native_dofile(root.."/files/features/forms/adapters/manual_actions.lua"))
actions.configure(wolf,"data/entities/animals/wolf.xml",{can_fly=false,platforming={run_velocity=80}})
assert(actions.owns_secondary()==false and actions.owns_primary()==false,"removed dash still owns an input surface")
frame=100; raw_mouse[2]=true; actions.update(wolf)
assert(enabled[12]==false,"removed dash feature re-enabled AnimalAI")
raw_mouse[2]=false

-- All four vanilla tooth-mimic bodies expose the same melee contract.
local mimic_paths={
    "data/entities/animals/chest_mimic.xml",
    "data/entities/animals/chest_leggy.xml",
    "data/entities/animals/illusions/dark_alchemist.xml",
    "data/entities/animals/illusions/shaman_wind.xml",
}
for index,path in ipairs(mimic_paths) do
    local entity=10+index
    local controls=entity*10+1
    add(entity,"ControlsComponent",controls,{mButtonDownFire=false,mButtonDownFire2=false,polymorph_hax=true})
    add(entity,"AnimalAIComponent",entity*10+2,{_enabled=false,attack_melee_enabled=true,attack_melee_damage_min=0.6,attack_melee_damage_max=1.0,attack_melee_max_distance=15,attack_melee_action_frame=5,attack_melee_frames_between=10})
    add(entity,"CharacterDataComponent",entity*10+3,{mVelocity={0,0}})
    local sprite=add(entity,"SpriteComponent",entity*10+4,{image_file="data/enemies_gfx/chest_mimic.xml",rect_animation="stand",next_rect_animation="stand"})
    local animator=add(entity,"SpriteAnimatorComponent",entity*10+5,{_enabled=true})
    actions.configure(entity,path,{can_fly=false,platforming={run_velocity=0}})
    assert(actions.owns_primary()==true,"mimic bite did not own primary input: "..path)
    frame=200+index*10; values[controls].mButtonDownFire=false; raw_mouse[1]=false; actions.update(entity)
    values[controls].mButtonDownFire=true; frame=frame+1; actions.update(entity)
    local last=animation_calls[#animation_calls]
    assert(last and last[1]==entity and last[2]=="attack","mimic did not play tooth attack animation: "..path)
    assert(values[sprite].rect_animation=="attack" and values[sprite].next_rect_animation=="stand","mimic root sprite did not enter authored bite animation: "..path)
    assert(enabled[animator]==false,"mimic SpriteAnimator was allowed to overwrite bite animation: "..path)
    frame=frame+40; values[controls].mButtonDownFire=false; actions.update(entity)
    assert(enabled[animator]==true,"mimic SpriteAnimator was not restored after bite: "..path)
end
raw_mouse[1]=false

-- Physics crystals use their authored AnimalAI projectile even though PhysicsAI owns locomotion.
local crystal=30
add(crystal,"ControlsComponent",301,{mButtonDownFire=false,mButtonDownFire2=false,polymorph_hax=true})
add(crystal,"AnimalAIComponent",302,{_enabled=false,attack_ranged_enabled=true,attack_ranged_entity_file="data/entities/projectiles/orb_pink.xml",attack_ranged_frames_between=10,attack_ranged_action_frame=3,attack_ranged_offset_x=0,attack_ranged_offset_y=-5})
add(crystal,"PhysicsAIComponent",303,{})
transforms[crystal]={20,30,0,1,1}
actions.configure(crystal,"data/entities/animals/crystal_physics.xml",{})
assert(actions.owns_primary()==true,"crystal manual projectile did not own primary")
frame=300; values[301].mButtonDownFire=false; actions.update(crystal)
frame=301; values[301].mButtonDownFire=true; actions.update(crystal)
frame=304; actions.update(crystal)
assert(loaded[#loaded] and loaded[#loaded].path=="data/entities/projectiles/orb_pink.xml","crystal did not fire authored orb_pink projectile")
assert(shot[#shot] and shot[#shot].shooter==crystal,"crystal projectile ownership wrong")

-- Blood crystal does not use AnimalAI ranged fire at all. Its vanilla collision script
-- emits twelve orb_pink projectiles around the body; player primary fire must replay the
-- same radial attack while suppressing the automatic collision script.
local blood=35
add(blood,"ControlsComponent",351,{mButtonDownFire=false,mButtonDownFire2=false,polymorph_hax=true})
local blood_lua=add(blood,"LuaComponent",352,{_enabled=true,script_collision_trigger_hit="data/scripts/animals/bloodcrystal_explosion.lua"})
transforms[blood]={50,60,0,1,1}
actions.configure(blood,"data/entities/animals/the_end/bloodcrystal_physics.xml",{})
assert(actions.owns_primary()==true and enabled[blood_lua]==false,"blood crystal collision attack was not manually owned/suppressed")
local before=#loaded
frame=350; values[351].mButtonDownFire=false; raw_mouse[1]=false; actions.update(blood)
frame=351; values[351].mButtonDownFire=true; actions.update(blood)
assert(#loaded-before==12,"blood crystal did not reproduce the vanilla 12-orb radial attack")
for i=before+1,#loaded do assert(loaded[i].path=="data/entities/projectiles/orb_pink.xml","blood crystal radial attack used wrong projectile") end
-- Vanilla bloodcrystal_explosion.lua uses script_wait_frames(entity, 10). Holding fire
-- therefore repeats quickly but must never emit another volley before ten frames.
frame=359; actions.update(blood)
assert(#loaded-before==12,"blood crystal fired before its vanilla 10-frame gate")
frame=361; actions.update(blood)
assert(#loaded-before==24,"blood crystal did not repeat at the vanilla 10-frame cadence")
actions.reset()
assert(enabled[blood_lua]==true,"blood crystal collision script enable state was not restored on reset")
values[351].mButtonDownFire=false; raw_mouse[1]=false

-- Boss Pit wand is a projectile-form, not a manual creature action. It renders through a
-- dedicated presentation entity and chooses a non-stale vanilla Boss Pit payload.
local wand=40
add(wand,"ControlsComponent",401,{mButtonDownFire=false,mButtonDownFire2=false,mButtonDownRight=false,mButtonDownLeft=false,mButtonDownUp=false,mButtonDownDown=false,mButtonDownFly=false,polymorph_hax=true})
add(wand,"VelocityComponent",402,{mVelocity={0,0}})
add(wand,"ProjectileComponent",403,{on_death_explode=true,on_lifetime_out_explode=true})
add(wand,"SpriteComponent",404,{image_file="data/entities/animals/boss_pit/wand_0$[1-9].png",alpha=1})
add(wand,"LuaComponent",405,{script_source_file="data/entities/animals/boss_pit/wand.lua"})
add(wand,"LuaComponent",406,{script_source_file="data/entities/animals/boss_pit/wand_rotate.lua"})
add(wand,"VariableStorageComponent",407,{name="memory",value_string="data/entities/projectiles/enlightened_laser_darkbeam.xml"})
transforms[wand]={10,20,0,1,1}
local projectile_forms=assert(native_dofile(root.."/files/features/forms/projectile_forms/controller.lua"))
assert(projectile_forms.configure(wand,"data/entities/animals/boss_pit/wand.xml",{})==true,"wand projectile-form not claimed")
assert(enabled[403]==false and enabled[404]==true and enabled[405]==false and enabled[406]==false,"wand lifecycle suppression/root presentation state wrong")
assert(values[404].image_file=="data/entities/animals/boss_pit/wand_01.png" and values[404].alpha==1,"wand root did not retain a concrete peer-visible sprite")
assert(values[407].value_string=="data/entities/projectiles/deck/rocket.xml","wand did not choose vanilla Boss Pit payload")
local visual1=nil
for e,kinds in pairs(components_by_entity) do
    for _,sprite in ipairs(kinds.SpriteComponent or {}) do
        if values[sprite] and values[sprite].image_file=="data/entities/animals/boss_pit/wand_01.png" and e~=wand then visual1=sprite end
    end
end
assert(visual1,"wand did not create a concrete visible presentation sprite")
frame=400; values[401].mButtonDownFire=false; projectile_forms.update(wand)
frame=401; values[401].mButtonDownFire=true; mouse_x=110; mouse_y=20; projectile_forms.update(wand)
assert(loaded[#loaded] and loaded[#loaded].path=="data/entities/projectiles/deck/rocket.xml","wand fired wrong projectile")
local wand_projectile=loaded[#loaded].id
local pv=values[wand_projectile*10+1].mVelocity
assert(math.abs(pv[1]-250)<0.001 and math.abs(pv[2])<0.001,"rocket wand did not preserve vanilla 500*0.5 launch speed")
assert(math.abs(values[wand_projectile*10+2].damage-0.3)<0.0001,"wand.lua +0.2 projectile damage was not preserved")

local wand2=41
add(wand2,"ControlsComponent",411,{mButtonDownFire=false,mButtonDownFire2=false,polymorph_hax=true})
add(wand2,"VelocityComponent",412,{mVelocity={0,0}})
add(wand2,"ProjectileComponent",413,{})
add(wand2,"SpriteComponent",414,{image_file="data/entities/animals/boss_pit/wand_0$[1-9].png"})
add(wand2,"VariableStorageComponent",417,{name="memory",value_string="data/entities/projectiles/enlightened_laser_darkbeam.xml"})
transforms[wand2]={11,21,0,1,1}
projectile_forms.configure(wand2,"data/entities/animals/boss_pit/wand.xml",{})
assert(values[417].value_string=="data/entities/projectiles/deck/rocket_tier_2.xml","consecutive wand transform reused one deterministic attack variant")

print("form_manual_actions=PASS dash_removed=true mimic_bites=4 chest_leggy_sprite=true crystals=true blood_crystal_radial=true blood_crystal_cooldown=10 projectile_wand_visual=true wand_variant_nonrepeat=true")
