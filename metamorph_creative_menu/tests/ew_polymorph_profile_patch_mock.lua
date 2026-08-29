local root = assert(arg[1], "root required")
local patches = assert(dofile(root .. "/files/integrations/ew/resilience_patches.lua"))

local source = [[
local rpc = { change_entity = function(value) LAST_SENT = value end }
local module = {}
ctx = { my_player = { entity = 7 } }
util = {
    serialize_entity = function(entity) assert(entity == 7); return "payload123" end,
    deserialize_entity = function(data) assert(data == "payload123"); return 8 end,
    get_ent_health = function() return 1,1,true end,
}
local gameover_requested = false
function module.on_world_update()
    if ctx.my_player.currently_polymorphed then
        local hp, _, has_hp_component = util.get_ent_health(ctx.my_player.entity)
        if has_hp_component and hp <= 0 and not gameover_requested then
            ctx.cap.health.on_poly_death()
            gameover_requested = true
        end
    else
        gameover_requested = false
    end
end
local function send_poly()
        rpc.change_entity({ data = util.serialize_entity(ctx.my_player.entity) })
end
local function apply_seri_ent(player_data, seri_ent)
    if seri_ent ~= nil then
        local ent = util.deserialize_entity(seri_ent.data)
        LAST_RECEIVED = ent
    end
end
module.send_poly = send_poly
module.apply_seri_ent = apply_seri_ent
return module
]]

local patched, count = patches.patch_polymorph_profile_source(source)
assert(count == 1, "polymorph profiler patch did not apply")
assert(string.find(patched, "mcm_poly_profile_v1", 1, true), "profiler marker missing")
assert(string.find(patched, "mcm_ew_poly_serialize", 1, true), "serialize metric missing")
assert(string.find(patched, "mcm_ew_poly_deserialize", 1, true), "deserialize metric missing")
local again, again_count = patches.patch_polymorph_profile_source(patched)
assert(again_count == 0 and again == patched, "profiler patch was not idempotent")
local unchanged, missing_count = patches.patch_polymorph_profile_source("local module = {}\nreturn module")
assert(missing_count == 0 and unchanged == "local module = {}\nreturn module", "partial anchor match modified source")

local globals = {}
local clock = {1.000, 1.025, 2.000, 2.150}
local clock_i = 0
GameGetRealWorldTimeSinceStarted = function()
    clock_i = clock_i + 1
    return clock[clock_i]
end
GameGetFrameNum = function() return 77 end
GlobalsSetValue = function(key, value) globals[key] = tostring(value) end
EntityGetComponentIncludingDisabled = function(entity, component_type)
    if component_type == "VariableStorageComponent" then return {91} end
    return {}
end
ComponentGetValue2 = function(component, field)
    assert(component == 91)
    if field == "name" then return "metamorph_creative_menu_network_source" end
    if field == "value_string" then return "data/entities/animals/boss_dragon.xml" end
end
EntityGetFilename = function(entity) return entity == 7 and "sender.xml" or "receiver.xml" end
EntityHasTag = function(entity, tag) return tag == "metamorph_creative_menu_network_form" end
EntityGetFirstComponentIncludingDisabled = function(entity, component_type)
    if component_type == "BossDragonComponent" then return 123 end
    return nil
end

local chunk, err = load(patched, "patched_polymorph", "t", _G)
assert(chunk, err)
local module = assert(chunk())
module.send_poly()
assert(LAST_SENT and LAST_SENT.data == "payload123", "serialized payload changed")
module.apply_seri_ent({}, {data="payload123"})
assert(LAST_RECEIVED == 8, "deserialized entity changed")
assert(globals.mcm_ew_poly_serialize_bytes_v1 == "10", "serialize bytes metric wrong")
assert(globals.mcm_ew_poly_deserialize_bytes_v1 == "10", "deserialize bytes metric wrong")
assert(tonumber(globals.mcm_ew_poly_serialize_ms_v1) == 25, "serialize timing metric wrong")
assert(tonumber(globals.mcm_ew_poly_deserialize_ms_v1) == 150, "deserialize timing metric wrong")
assert(globals.mcm_ew_poly_serialize_kind_v1 == "boss_dragon", "serialize kind missing")
assert(globals.mcm_ew_poly_deserialize_kind_v1 == "boss_dragon", "deserialize kind missing")
assert(globals.mcm_ew_poly_deserialize_source_v1 == "data/entities/animals/boss_dragon.xml", "source identity missing")
assert(globals.mcm_ew_poly_deserialize_frame_v1 == "77", "profile frame missing")
print("ew_polymorph_profile_patch=PASS payload_unchanged=true isolated_poly_path=true")
