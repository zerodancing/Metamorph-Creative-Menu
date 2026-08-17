local root = assert(arg[1], "root required")
local native_dofile = dofile
local frame = 10
local alive = {[1]=true, [10]=true}
local children = {[1]={10}}
local tags = {}
local frames = {[100]=-1}
local filenames = {[10]="data/entities/misc/effect_test.xml"}
local effect_entry = {
    kind="game_effect",
    id="TEST_EFFECT",
    path="data/entities/misc/effect_test.xml",
    icon="data/ui_gfx/status_indicators/test.png",
    display_name="Test effect",
    display_description="",
    game_effect="TEST_EFFECT",
}

local catalog_stub = {
    entries=function() return {effect_entry} end,
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
function ModDoesFileExist(path) return path == effect_entry.path or path == effect_entry.icon end
function LoadGameEffectEntityTo(player, path)
    assert(player == 1 and path == effect_entry.path, "effect attached to wrong target")
    return 10
end
function EntityAddTag(entity, tag)
    tags[entity] = tags[entity] or {}
    tags[entity][tag] = true
end
function EntityHasTag(entity, tag) return tags[entity] ~= nil and tags[entity][tag] == true end
function EntityGetAllChildren(entity) return children[entity] or {} end
function EntityGetFilename(entity) return filenames[entity] or "" end
function EntityGetFirstComponentIncludingDisabled(entity, component_type)
    if entity == 10 and component_type == "GameEffectComponent" then return 100 end
    if entity == 10 and component_type == "UIIconComponent" then return 0 end
    if entity == 1 and component_type == "StatusEffectDataComponent" then return 0 end
    return 0
end
function EntityAddComponent2(entity, component_type, values)
    assert(entity == 10 and component_type == "UIIconComponent", "unexpected component creation")
    assert(values.display_in_hud == true and values.is_perk == false, "effect HUD ownership changed")
    return 200
end
function ComponentGetValue2(component, field)
    if component == 100 and field == "effect" then return "TEST_EFFECT" end
    if component == 100 and field == "custom_effect_id" then return "" end
    if component == 100 and field == "frames" then return frames[100] end
    return nil
end
function ComponentSetValue2(component, field, value)
    if component == 100 and field == "frames" then frames[100] = value end
end
function GameGetFrameNum() return frame end
function EntityKill(entity) alive[entity] = false end

METAMORPH_CREATIVE_MENU_EFFECT_SERVICE = nil
METAMORPH_CREATIVE_MENU_EFFECT_EDITOR = nil
local effects = assert(native_dofile(root .. "/files/features/effects/service.lua"))

local added, reason = effects.add(1, effect_entry, 600)
assert(added == true and reason == "TEST_EFFECT", "game effect was not applied")
assert(frames[100] == 600, "selected duration was not applied")
assert(EntityHasTag(10, "metamorph_creative_menu_effect"), "effect service did not mark ownership")
assert(effects.is_active(1, effect_entry) == true, "new effect is not reported active")
assert(effects.residue_count(1, effect_entry) == 1, "active effect residue count changed")

local removed = effects.remove(1, effect_entry)
assert(removed == 1 and frames[100] == 1, "remove did not request normal Noita expiry")
frame = frame + 5
effects.update()
assert(alive[10] == false, "owned persistent effect was not retired after bounded expiry window")

print("effect_lifecycle=PASS apply=true active=true remove=true bounded_cleanup=true")
