local root = assert(arg[1], "root required")
local native_dofile = dofile
local globals = {}
local world = { global_genome_relations_modifier = 0 }
local block_typed_write=false
local block_legacy_write=false

function GlobalsGetValue(key, fallback)
    local value = globals[key]
    if value == nil then return fallback end
    return value
end
function GlobalsSetValue(key, value) globals[key] = tostring(value) end
function GameGetWorldStateEntity() return 10 end
function EntityGetFirstComponentIncludingDisabled(entity, kind)
    if entity == 10 and kind == "WorldStateComponent" then return 20 end
    return 0
end
function ComponentGetValue2(component, field)
    assert(component == 20, "wrong world-state component")
    return world[field]
end
function ComponentSetValue2(component, field, value)
    assert(component == 20, "wrong world-state component")
    if block_typed_write then return end
    world[field] = value
end
function ComponentSetValue(component, field, value)
    assert(component == 20, "wrong world-state component")
    if block_legacy_write then return end
    world[field] = tonumber(value) or value
end

local stubs = {
    ["mods/metamorph_creative_menu/files/core/rule_math.lua"] = {
        same=function(a,b) return math.abs((tonumber(a) or 0) - (tonumber(b) or 0)) < 1e-9 end,
    },
}
dofile = function(path)
    if stubs[path] ~= nil then return stubs[path] end
    local prefix = "mods/metamorph_creative_menu/"
    if string.sub(path, 1, #prefix) == prefix then
        return native_dofile(root .. "/" .. string.sub(path, #prefix + 1))
    end
    return native_dofile(path)
end

METAMORPH_CREATIVE_MENU_WORLD_RULE_RECOVERY = nil
METAMORPH_CREATIVE_MENU_WORLD_STATE_RULE_ADAPTER = nil
_G.state = nil
local adapter = assert(native_dofile(root .. "/files/features/world_rules/world_state.lua"))
local rule = {
    id="relations", kind="field", field="global_genome_relations_modifier", integer=true,
}

local applied, reason = adapter.apply(rule, {value=100})
assert(applied == true and reason == "ok", "relations override failed")
assert(world.global_genome_relations_modifier == 100, "relations override did not reach WorldState")
assert(_G.state == nil, "adapter unexpectedly created/relied on global service state")

local restored, restore_reason = adapter.apply(rule, {native=true})
assert(restored == true and restore_reason == "ok", "NATIVE restore failed")
assert(world.global_genome_relations_modifier == 0, "NATIVE did not restore exact original relations")
assert(_G.state == nil, "NATIVE restore leaked service state into adapter")

-- A second NATIVE selection is idempotent and must not require an ownership record.
local again = adapter.apply(rule, {native=true})
assert(again == true, "idempotent NATIVE restore failed")

-- Capturing a baseline is not ownership. If both setters fail, a later RESET must
-- forget the record without overwriting a newer value written by another owner.
block_typed_write=true; block_legacy_write=true
local failed=adapter.apply(rule,{value=100})
assert(failed==false,"silent WorldState write failure reported success")
world.global_genome_relations_modifier=7 -- external owner after our failed attempt
block_typed_write=false; block_legacy_write=false
assert(adapter.reset_all()==true,"baseline-only WorldState record did not release cleanly")
assert(world.global_genome_relations_modifier==7,"RESET overwrote external value despite never acquiring ownership")

io.write("world_state_native_restore=PASS native_restore=0 external_preserved=7 adapter_state_isolated=true baseline_not_ownership=true\n")
