-- TEST 25: verify that the authored Kolmisilma combat LuaComponent actually entered its
-- coroutine after the stock Sampo pickup transition.  This is deliberately a watchdog for
-- *startup only*: it never implements attacks/phases/death itself.  If the disabled authored
-- component failed to execute after being enabled, replace it once with the exact same vanilla
-- script in a fresh ONE_PER_COMPONENT_INSTANCE VM.  The VFS still supplies vanilla + EW append.
local controller = GetUpdatedEntityID()
local UPDATE = "data/entities/animals/boss_centipede/boss_centipede_update.lua"
local STATUS = "mcm25_kolmi_combat_status_v1"
local START_VAR = "mcm_kolmi_verify_start_frame_v1"
local RESTART_VAR = "mcm_kolmi_verify_restart_frame_v1"
local GRACE_FRAMES = 8
local RESTART_GRACE_FRAMES = 12

local function storage_value_int(entity, name)
    for _, storage in ipairs(EntityGetComponentIncludingDisabled(entity, "VariableStorageComponent") or {}) do
        if ComponentGetValue2(storage, "name") == name then
            return tonumber(ComponentGetValue2(storage, "value_int")) or 0, storage
        end
    end
    return 0, nil
end

local function set_storage_int(entity, name, value)
    local _, storage = storage_value_int(entity, name)
    if storage ~= nil then
        pcall(ComponentSetValue2, storage, "value_int", tonumber(value) or 0)
        return storage
    end
    if type(EntityAddComponent2) ~= "function" then return nil end
    local ok, created = pcall(EntityAddComponent2, entity, "VariableStorageComponent", {
        name = name,
        value_int = tonumber(value) or 0,
    })
    return ok and created or nil
end

local function controller_boss()
    local value = storage_value_int(controller, "mcm_kolmi_boss_id_v3")
    return tonumber(value) or 0
end

local function initialized(boss)
    for _, storage in ipairs(EntityGetComponentIncludingDisabled(boss, "VariableStorageComponent") or {}) do
        if ComponentGetValue2(storage, "name") == "initialized" then
            return ComponentGetValue2(storage, "value_bool") == true
        end
    end
    return false
end

local function update_components(boss)
    local out = {}
    for _, lua in ipairs(EntityGetComponentIncludingDisabled(boss, "LuaComponent") or {}) do
        local ok, source = pcall(ComponentGetValue2, lua, "script_source_file")
        if ok and tostring(source or "") == UPDATE then out[#out + 1] = lua end
    end
    return out
end

local function publish(value)
    if type(GlobalsSetValue) == "function" then pcall(GlobalsSetValue, STATUS, tostring(value)) end
end

local function finish(value)
    publish(value)
    if type(EntityKill) == "function" then pcall(EntityKill, controller) end
end

local boss = controller_boss()
if boss == 0 or EntityGetIsAlive(boss) ~= true then
    finish("failed:missing_boss")
    return
end

local frame = tonumber(GameGetFrameNum()) or 0
local start = storage_value_int(controller, START_VAR)
if start == 0 then
    start = frame
    set_storage_int(controller, START_VAR, start)
end

if initialized(boss) then
    finish("initialized_stock")
    return
end

if frame - start < GRACE_FRAMES then return end

local restart_frame = storage_value_int(controller, RESTART_VAR)
if restart_frame == 0 then
    -- The authored component was enabled by stock sampo_pickup.lua but never reached init_boss().
    -- Recreate only that authored VM.  Do not copy or emulate any phase code.
    for _, lua in ipairs(update_components(boss)) do pcall(EntityRemoveComponent, boss, lua) end

    local values = {
        _tags = "disabled_at_start",
        script_source_file = UPDATE,
        vm_type = "ONE_PER_COMPONENT_INSTANCE",
        enable_coroutines = true,
        execute_on_added = true,
        execute_every_n_frame = -1,
        execute_times = 1,
    }
    local ok, fresh = pcall(EntityAddComponent2, boss, "LuaComponent", values)
    if not ok or fresh == nil or fresh == 0 then
        finish("restart_failed:add_component")
        return
    end
    pcall(EntitySetComponentIsEnabled, boss, fresh, true)
    set_storage_int(controller, RESTART_VAR, frame)
    publish("restarted_component")
    return
end

if initialized(boss) then
    finish("initialized_after_restart")
    return
end
if frame - restart_frame >= RESTART_GRACE_FRAMES then
    finish("restart_failed:not_initialized")
end
