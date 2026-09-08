local root = assert(arg[1], "root required")
local native_dofile = dofile
local frame = 10
local alive = {[1]=true, [10]=true, [11]=true}
local children = {[1]={11}}
local tags = {}
local frames = {[100]=-1, [101]=-1, [110]=900}
local filenames = {
    [10]="data/entities/misc/effect_trip_00.xml",
    [11]="data/entities/misc/effect_trip_01.xml",
}
local effect_entry = {
    kind="game_effect",
    id="TRIP",
    path="data/entities/misc/effect_trip_00.xml",
    icon="data/ui_gfx/status_indicators/trip.png",
    display_name="Light trip",
    display_description="",
    game_effect="CUSTOM",
    custom_effect_id="TRIP_00",
}
local stronger_entry = {
    kind="game_effect",
    id="TRIP",
    path="data/entities/misc/effect_trip_01.xml",
    icon=effect_entry.icon,
    display_name="Medium trip",
    display_description="",
    game_effect="CUSTOM",
    custom_effect_id="TRIP_00",
}
local family_entry = {
    kind="game_effect", id="TRIP", path=effect_entry.path, icon=effect_entry.icon,
    display_name="Trip", display_description="", game_effect="CUSTOM", custom_effect_id="TRIP_00",
    variants={effect_entry,stronger_entry},
}

local catalog_stub = {
    entries=function() return {effect_entry,stronger_entry} end,
    status_entries=function() return {} end,
    reserved_effects=function() return {POLYMORPH=true} end,
}

dofile = function(path)
    if path == "mods/metamorph_creative_menu/files/features/effects/catalog.lua" then return catalog_stub end
    local prefix = "mods/metamorph_creative_menu/"
    if string.sub(path, 1, #prefix) == prefix then
        return native_dofile(root .. "/" .. string.sub(path, #prefix + 1))
    end
    return native_dofile(path)
end

function EntityGetIsAlive(entity) return alive[entity] == true end
function ModDoesFileExist(path) return path == effect_entry.path or path == stronger_entry.path or path == effect_entry.icon end
function LoadGameEffectEntityTo(player, path)
    assert(player == 1 and path == effect_entry.path, "effect attached to wrong target")
    children[1][#children[1]+1]=10
    return 10
end
function EntityAddTag(entity, tag)
    tags[entity] = tags[entity] or {}
    tags[entity][tag] = true
end
function EntityHasTag(entity, tag) return tags[entity] ~= nil and tags[entity][tag] == true end
function EntityGetAllChildren(entity)
    local result={}
    for _,child in ipairs(children[entity] or {}) do if alive[child] then result[#result+1]=child end end
    return result
end
function EntityGetFilename(entity) return filenames[entity] or "" end
function EntityGetComponentIncludingDisabled(entity, component_type)
    if entity == 10 and component_type == "GameEffectComponent" then return {100,101} end
    if entity == 11 and component_type == "GameEffectComponent" then return {110} end
    return {}
end
function EntityGetFirstComponentIncludingDisabled(entity, component_type)
    local values=EntityGetComponentIncludingDisabled(entity,component_type)
    if #values>0 then return values[1] end
    if (entity == 10 or entity == 11) and component_type == "UIIconComponent" then return 0 end
    if entity == 1 and component_type == "StatusEffectDataComponent" then return 0 end
    return 0
end
function EntityAddComponent2(entity, component_type, values)
    assert((entity == 10 or entity == 11) and component_type == "UIIconComponent", "unexpected component creation")
    assert(values.display_in_hud == true and values.is_perk == false, "effect HUD ownership changed")
    return 200 + entity
end
function ComponentGetValue2(component, field)
    if component == 100 or component == 101 or component == 110 then
        if field == "effect" then return "CUSTOM" end
        if field == "custom_effect_id" then return "TRIP_00" end
        if field == "frames" then return frames[component] end
    end
    return nil
end
function ComponentSetValue2(component, field, value)
    if (component == 100 or component == 101 or component == 110) and field == "frames" then frames[component] = value end
end
function GameGetFrameNum() return frame end
function EntityKill(entity) alive[entity] = false end

METAMORPH_CREATIVE_MENU_EFFECT_SERVICE = nil
METAMORPH_CREATIVE_MENU_EFFECT_EDITOR = nil
local effects = assert(native_dofile(root .. "/files/features/effects/service.lua"))

-- A stronger variant with the same CUSTOM id already exists. Exact-path ownership means
-- it must not make the light variant active or absorb/remove light-variant operations.
local snapshot=effects.active_snapshot(1)
assert(effects.is_active(1,effect_entry,snapshot)==false,"shared custom id incorrectly activated another variant")
assert(effects.is_active(1,stronger_entry,snapshot)==true,"exact stronger variant not reported active")

assert(effects.active_variant_index(1,family_entry,snapshot)==2,"editor did not select the currently active authored stage")
local added, reason = effects.set_variant(1, family_entry, 1, 600)
assert(added == true and reason == "TRIP_00", "family editor did not apply selected stage")
assert(frames[110] == 1, "changing stage did not retire the previously active sibling stage")
assert(frames[100] == 600 and frames[101] == 600, "selected duration was not applied to every component")
assert(EntityHasTag(10, "metamorph_creative_menu_effect"), "effect service did not mark ownership")
assert(#EntityGetAllChildren(1)==2,"first apply produced unexpected child count")

-- Reapply exact variant: extend the existing entity instead of creating a second HUD row.
local stacked,stack_reason=effects.add(1,effect_entry,600)
assert(stacked==true and stack_reason=="stacked","same variant did not stack duration")
assert(frames[100]==1200 and frames[101]==1200,"stacking did not extend duration")
assert(#EntityGetAllChildren(1)==2,"stacking cloned the effect entity")
assert(effects.residue_count(1,effect_entry)==1,"stacked effect became duplicate residues")

frames[110]=900 -- simulate an independently reintroduced stronger stage
local removed = effects.remove(1, effect_entry)
assert(removed == 1 and frames[100] == 1 and frames[101] == 1, "remove did not expire every component")
assert(frames[110]==900,"removing light trip touched stronger same-id variant")
frame = frame + 5
effects.update()
assert(alive[10] == false, "owned persistent effect was not retired after bounded expiry window")
assert(alive[11] == true,"variant-specific cleanup killed the wrong effect")

print("effect_lifecycle=PASS variants_exact=true active_stage_detected=true stage_replace=true stack_extends=true single_hud_entity=true multi_component_duration=true remove_exact=true bounded_cleanup=true")
