if type(METAMORPH_CREATIVE_MENU_QA_BASELINES) == "table" then return METAMORPH_CREATIVE_MENU_QA_BASELINES end

local baselines = {}
local world_rules = dofile("mods/metamorph_creative_menu/files/features/world_rules/service.lua")
local weather = dofile("mods/metamorph_creative_menu/files/features/weather/service.lua")
local perk_root_companions = dofile("mods/metamorph_creative_menu/files/features/perks/root_companions.lua")
local perk_service = dofile("mods/metamorph_creative_menu/files/features/perks/service.lua")

local function valid(entity)
    return entity ~= nil and entity ~= 0 and EntityGetIsAlive(entity)
end

local function snapshot_world_controls()
    local rules={}
    for _,r in ipairs(world_rules.rules() or {}) do rules[r.id]=world_rules.choice_index(r) end
    local w={locked=weather.is_locked(), fields={}}
    for _,field in ipairs(weather.fields() or {}) do local ok,v=pcall(weather.get,field); if ok then w.fields[field.id]=v end end
    w.time=weather.get_time()
    return {rules=rules,weather=w}
end

local function restore_world_controls(snapshot)
    snapshot=snapshot or {}
    local can_rules=select(1,world_rules.can_edit())
    local can_weather=select(1,weather.can_edit())
    local ok_all=true
    if can_rules then local ok,res=pcall(world_rules.reset); if not ok or res~=true then ok_all=false end end
    local desired=snapshot.rules or {}
    if can_rules then
        for _,r in ipairs(world_rules.rules() or {}) do
            local target=tonumber(desired[r.id]) or 1
            if target>1 and world_rules.supported(r) then
                for _=2,target do local ok,res=pcall(world_rules.step,r,1); if not ok or res~=true then ok_all=false end end
            end
        end
    end
    local w=snapshot.weather or {}
    if can_weather and w.locked then
        for _,field in ipairs(weather.fields() or {}) do
            local v=w.fields and w.fields[field.id] or nil
            if v~=nil then pcall(weather.set,field,v) end
        end
    elseif can_weather then
        local ok,res=pcall(weather.release); if not ok or res~=true then ok_all=false end
    end
    return ok_all
end

local function world_controls_match(snapshot)
    snapshot=snapshot or {}
    for _,r in ipairs(world_rules.rules() or {}) do
        local wanted=tonumber((snapshot.rules or {})[r.id]) or 1
        if world_rules.choice_index(r)~=wanted then return false,"rule:"..tostring(r.id) end
    end
    local w=snapshot.weather or {}
    if weather.is_locked()~=(w.locked==true) then return false,"weather_lock" end
    return true,"ok"
end

local function restore_player_baseline(p, baseline, restore_health)
    if p==0 or not valid(p) or type(baseline)~="table" then return end
    if baseline.x~=nil and baseline.y~=nil then pcall(EntitySetTransform,p,baseline.x,baseline.y) end
    local data=EntityGetFirstComponentIncludingDisabled(p,"CharacterDataComponent")
    if data~=nil and data~=0 then pcall(ComponentSetValue2,data,"mVelocity",0,0) end
    if restore_health then
        local d=EntityGetFirstComponentIncludingDisabled(p,"DamageModelComponent")
        if d~=nil and d~=0 then
            if baseline.maxhp~=nil then pcall(ComponentSetValue2,d,"max_hp",baseline.maxhp) end
            if baseline.cap~=nil then pcall(ComponentSetValue2,d,"max_hp_cap",baseline.cap) end
            if baseline.hp~=nil then pcall(ComponentSetValue2,d,"hp",baseline.hp) end
        end
    end
end

local function snapshot_player(p)
    local x,y = EntityGetTransform(p)
    local d = EntityGetFirstComponentIncludingDisabled(p, "DamageModelComponent")
    local hp,maxhp,cap = nil,nil,nil
    if d ~= nil and d ~= 0 then
        hp,maxhp,cap = ComponentGetValue2(d,"hp"),ComponentGetValue2(d,"max_hp"),ComponentGetValue2(d,"max_hp_cap")
    end
    return {x=x,y=y,hp=hp,maxhp=maxhp,cap=cap}
end

local function meta_number(component, field)
    if type(ComponentGetMetaCustom) ~= "function" then return nil end
    local ok, value = pcall(ComponentGetMetaCustom, component, field)
    return ok and tonumber(value) or nil
end

local TRANSIENT_GUARD_EFFECTS = { WET=true, ON_FIRE=true, RADIOACTIVE=true, BLOODY=true }
local function relevant_perk_descendant(entity)
    if EntityHasTag(entity, "perk_entity") or EntityHasTag(entity, "hungry_ghost") then return true end
    local filename = string.lower(tostring(EntityGetFilename(entity) or ""))
    if string.find(filename, "/misc/perks/", 1, true) then return true end
    local ge = EntityGetFirstComponentIncludingDisabled(entity, "GameEffectComponent")
    if ge == nil or ge == 0 then return false end
    local ok, effect = pcall(ComponentGetValue2, ge, "effect")
    if ok and TRANSIENT_GUARD_EFFECTS[tostring(effect or "")] then return false end
    return true
end

local function perk_entity_signature(entity)
    local filename = tostring(EntityGetFilename(entity) or "")
    local name = tostring(EntityGetName(entity) or "")
    local effect = ""
    local ge = EntityGetFirstComponentIncludingDisabled(entity, "GameEffectComponent")
    if ge ~= nil and ge ~= 0 then
        local ok, value = pcall(ComponentGetValue2, ge, "effect")
        if ok then effect = tostring(value or "") end
        if effect == "CUSTOM" then local ok2,v2=pcall(ComponentGetValue2,ge,"custom_effect_id"); if ok2 then effect=effect..":"..tostring(v2 or "") end end
    end
    return filename .. "|" .. name .. "|" .. effect
end

local PERK_GUARD_GLOBALS = {
    "PLAYER_LUKKINESS_LEVEL", "LUKKI_PERK_TOTAL_COUNT",
    "PLAYER_GHOSTNESS_LEVEL", "PLAYER_RATTINESS_LEVEL", "PLAYER_FUNGAL_LEVEL", "PLAYER_HALO_LEVEL",
    "FUNGI_PERK_TOTAL_COUNT", "PERK_SHIELD_COUNT",
    "TEMPLE_PERK_COUNT", "TEMPLE_SHOP_ITEM_COUNT", "TEMPLE_PEACE_WITH_GODS", "TEMPLE_SPAWN_GUARDIAN",
}
local DAMAGE_MULTIPLIER_FIELDS = {
    "projectile", "explosion", "electricity", "fire", "drill", "slice", "ice", "healing",
    "physics_hit", "radioactive", "poison", "melee", "holy", "curse",
}
local CHARACTER_DATA_FIELDS = {
    "fly_recharge_spd", "fly_recharge_spd_ground", "fly_speed_max_up", "fly_speed_max_down",
}
local DAMAGE_MODEL_FIELDS = {
    "air_in_lungs_max", "blood_multiplier", "falling_damages", "materials_damage",
}
local WORLD_STATE_FIELDS = {
    "global_genome_relations_modifier", "perk_gold_is_forever",
}

local function component_field_snapshot(component, fields)
    local result={}
    if component==nil or component==0 then return result end
    for _,field in ipairs(fields or {}) do
        local ok,value=pcall(ComponentGetValue2,component,field)
        if not ok then ok,value=pcall(ComponentGetValue,component,field) end
        if ok and value~=nil then result[field]=value end
    end
    return result
end

local function object_field_snapshot(component, object_name, fields)
    local result={}
    if component==nil or component==0 then return result end
    for _,field in ipairs(fields or {}) do
        local ok,value=false,nil
        if type(ComponentObjectGetValue2)=="function" then ok,value=pcall(ComponentObjectGetValue2,component,object_name,field) end
        if (not ok or value==nil) and type(ComponentObjectGetValue)=="function" then ok,value=pcall(ComponentObjectGetValue,component,object_name,field) end
        if ok and value~=nil then result[field]=value end
    end
    return result
end

local function perk_guard_snapshot(p)
    local result={
        ids={},counts={},by_sig={},platform={},external={homunculus=0,lukki_minion=0},
        owned_roots={},globals={},character_data={},damage_model={},damage_multipliers={},world_state={},
        ownership={transactions=0,mutations=0,global_owners=0,run_flag_owners=0},
    }
    if type(perk_root_companions.owned_counts)=="function" then
        local ok_owned, owned_counts=pcall(perk_root_companions.owned_counts)
        if ok_owned and type(owned_counts)=="table" then result.owned_roots=owned_counts end
    end
    if type(perk_service.debug_ownership_state)=="function" then
        local ok_state, ownership=pcall(perk_service.debug_ownership_state)
        if ok_state and type(ownership)=="table" then result.ownership=ownership end
    end
    if type(EntityGetWithTag)=="function" then
        local seen={homunculus={},lukki_minion={}}
        for _, tag in ipairs({"homunculus","lukki_minion","perk_lukki_minion","lukki_minion_friend"}) do
            local ok, values=pcall(EntityGetWithTag,tag)
            if ok and type(values)=="table" then
                local key=tag=="homunculus" and "homunculus" or "lukki_minion"
                for _,e in ipairs(values) do
                    if valid(e) and not seen[key][e] then seen[key][e]=true; result.external[key]=result.external[key]+1 end
                end
            end
        end
    end
    local queue,index={p},1
    while index<=#queue do
        local e=queue[index]; index=index+1
        for _,child in ipairs(EntityGetAllChildren(e) or {}) do
            queue[#queue+1]=child
            if relevant_perk_descendant(child) then
                result.ids[child]=true
                local sig=perk_entity_signature(child)
                result.counts[sig]=(result.counts[sig] or 0)+1
                result.by_sig[sig]=result.by_sig[sig] or {}
                result.by_sig[sig][#result.by_sig[sig]+1]=child
            end
        end
    end
    for _,c in ipairs(EntityGetComponentIncludingDisabled(p,"CharacterPlatformingComponent") or {}) do
        local okg,g=pcall(ComponentGetValue2,c,"pixel_gravity")
        -- mFramesNotSwimming is a live engine counter and changes every frame even
        -- when no perk touches locomotion. Treating it as persistent state produced
        -- false FAILs and harmful emergency writes after ordinary perk removal.
        result.platform[#result.platform+1]={component=c,pixel_gravity=okg and tonumber(g) or nil,
            run=meta_number(c,"run_velocity"),minx=meta_number(c,"velocity_min_x"),maxx=meta_number(c,"velocity_max_x")}
    end
    for _,c in ipairs(EntityGetComponentIncludingDisabled(p,"CharacterDataComponent") or {}) do
        result.character_data[#result.character_data+1]=component_field_snapshot(c,CHARACTER_DATA_FIELDS)
    end
    for _,c in ipairs(EntityGetComponentIncludingDisabled(p,"DamageModelComponent") or {}) do
        result.damage_model[#result.damage_model+1]=component_field_snapshot(c,DAMAGE_MODEL_FIELDS)
        result.damage_multipliers[#result.damage_multipliers+1]=object_field_snapshot(c,"damage_multipliers",DAMAGE_MULTIPLIER_FIELDS)
    end
    if type(GlobalsGetValue)=="function" then
        for _,name in ipairs(PERK_GUARD_GLOBALS) do result.globals[name]=tostring(GlobalsGetValue(name,"")) end
    end
    if type(GameGetWorldStateEntity)=="function" then
        local ok_world,world_entity=pcall(GameGetWorldStateEntity)
        if ok_world and world_entity~=nil and world_entity~=0 then
            local component=EntityGetFirstComponentIncludingDisabled(world_entity,"WorldStateComponent")
            result.world_state=component_field_snapshot(component,WORLD_STATE_FIELDS)
        end
    end
    return result
end

local function near(a,b)
    if a==nil or b==nil then return a==b end
    return math.abs((tonumber(a) or 0)-(tonumber(b) or 0))<0.0001
end

local function compare_named_values(issues, prefix, before_values, after_values)
    local keys={}
    for key in pairs(before_values or {}) do keys[key]=true end
    for key in pairs(after_values or {}) do keys[key]=true end
    for key in pairs(keys) do
        local left=(before_values or {})[key]
        local right=(after_values or {})[key]
        if not near(left,right) and tostring(left or "")~=tostring(right or "") then
            issues[#issues+1]=prefix.."."..tostring(key)..":"..tostring(left).."->"..tostring(right)
        end
    end
end

local function compare_component_rows(issues, prefix, before_rows, after_rows)
    local count=math.max(#(before_rows or {}),#(after_rows or {}))
    for index=1,count do
        local left=(before_rows or {})[index]
        local right=(after_rows or {})[index]
        if left==nil or right==nil then issues[#issues+1]=prefix.."_count"
        else compare_named_values(issues,prefix.."["..tostring(index).."]",left,right) end
    end
end

local function perk_guard_diff(before, after)
    local issues={}
    before=before or {counts={},platform={}}; after=after or {counts={},platform={}}
    local keys={}
    for k in pairs(before.counts or {}) do keys[k]=true end
    for k in pairs(after.counts or {}) do keys[k]=true end
    for k in pairs(keys) do
        local a=(before.counts or {})[k] or 0; local b=(after.counts or {})[k] or 0
        -- QA is a residue detector, not a freeze-frame of all transient perk entities.
        -- A baseline effect may legitimately expire while another perk is being tested;
        -- only newly leaked/excess entities make the test dirty.
        if b>a then issues[#issues+1]="entity_excess:"..k..":"..a.."->"..b end
    end
    for _, key in ipairs({"homunculus","lukki_minion"}) do
        local a=tonumber(before.external and before.external[key]) or 0
        local b=tonumber(after.external and after.external[key]) or 0
        if b>a then issues[#issues+1]="external_excess."..key..":"..a.."->"..b end
    end
    local owned_keys={}
    for key in pairs(before.owned_roots or {}) do owned_keys[key]=true end
    for key in pairs(after.owned_roots or {}) do owned_keys[key]=true end
    for key in pairs(owned_keys) do
        local a=tonumber(before.owned_roots and before.owned_roots[key]) or 0
        local b=tonumber(after.owned_roots and after.owned_roots[key]) or 0
        if b>a then issues[#issues+1]="owned_root_excess."..tostring(key)..":"..a.."->"..b end
    end
    local n=math.max(#(before.platform or {}),#(after.platform or {}))
    for i=1,n do
        local a=(before.platform or {})[i]; local b=(after.platform or {})[i]
        if a==nil or b==nil then issues[#issues+1]="platform_count"
        else
            for _,field in ipairs({"pixel_gravity","run","minx","maxx"}) do
                if not near(a[field],b[field]) then issues[#issues+1]="platform."..field..":"..tostring(a[field]).."->"..tostring(b[field]) end
            end
        end
    end
    compare_component_rows(issues,"character_data",before.character_data,after.character_data)
    compare_component_rows(issues,"damage_model",before.damage_model,after.damage_model)
    compare_component_rows(issues,"damage_multiplier",before.damage_multipliers,after.damage_multipliers)
    compare_named_values(issues,"global",before.globals,after.globals)
    compare_named_values(issues,"world_state",before.world_state,after.world_state)
    for _,key in ipairs({"transactions","mutations","global_owners","run_flag_owners"}) do
        local a=tonumber(before.ownership and before.ownership[key]) or 0
        local b=tonumber(after.ownership and after.ownership[key]) or 0
        if b>a then issues[#issues+1]="ownership_excess."..key..":"..a.."->"..b end
    end
    local cleanup_before = type(before.ownership) == "table" and before.ownership.cleanup or nil
    local cleanup_after = type(after.ownership) == "table" and after.ownership.cleanup or nil
    local failed_before = tonumber(type(cleanup_before)=="table" and cleanup_before.failed) or 0
    local failed_after = tonumber(type(cleanup_after)=="table" and cleanup_after.failed) or 0
    if failed_after > failed_before then
        issues[#issues+1]="ownership_excess.cleanup_failed:"..failed_before.."->"..failed_after
    end
    return issues
end

local function repair_perk_guard(p, before)
    local after=perk_guard_snapshot(p)
    -- Remove only signature counts created beyond baseline. This remains safe after a
    -- polymorph roundtrip where baseline perk entities may have new runtime entity IDs.
    for sig, ids in pairs(after.by_sig or {}) do
        local excess=#ids-((before.counts or {})[sig] or 0)
        for i=#ids,math.max(1,#ids-excess+1),-1 do
            if excess<=0 then break end
            local entity=ids[i]
            if valid(entity) then
                for _,lua in ipairs(EntityGetComponentIncludingDisabled(entity,"LuaComponent") or {}) do pcall(EntitySetComponentIsEnabled,entity,lua,false) end
                pcall(EntityKill,entity)
            end
            excess=excess-1
        end
    end
    -- Root companions are intentionally not repaired by broad tag deletion here.
    -- Production removal owns exact post-pickup roots; if one leaks, QA must leave the
    -- residue visible and fail rather than risk deleting a natural/foreign companion.
    local current=EntityGetComponentIncludingDisabled(p,"CharacterPlatformingComponent") or {}
    for i,record in ipairs(before.platform or {}) do
        local c=current[i]
        if c~=nil and c~=0 then
            if record.pixel_gravity~=nil then pcall(ComponentSetValue2,c,"pixel_gravity",record.pixel_gravity) end
            if type(ComponentSetMetaCustom)=="function" then
                if record.run~=nil then pcall(ComponentSetMetaCustom,c,"run_velocity",record.run) end
                if record.minx~=nil then pcall(ComponentSetMetaCustom,c,"velocity_min_x",record.minx) end
                if record.maxx~=nil then pcall(ComponentSetMetaCustom,c,"velocity_max_x",record.maxx) end
            end
        end
    end
    return #perk_guard_diff(before,perk_guard_snapshot(p))==0
end

local function compact_issues(values)
    local out={}
    for i=1,math.min(3,#(values or {})) do out[#out+1]=values[i] end
    return table.concat(out,";")
end


baselines.snapshot_world_controls = snapshot_world_controls
baselines.restore_world_controls = restore_world_controls
baselines.world_controls_match = world_controls_match
baselines.restore_player = restore_player_baseline
baselines.snapshot_player = snapshot_player
baselines.perk_guard_snapshot = perk_guard_snapshot
baselines.perk_guard_diff = perk_guard_diff
baselines.repair_perk_guard = repair_perk_guard
baselines.compact_issues = compact_issues

METAMORPH_CREATIVE_MENU_QA_BASELINES = baselines
return baselines
