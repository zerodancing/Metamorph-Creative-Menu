-- TEST 24: wait until the creative Kolmisilma is actually owned by this DES peer, then
-- hand encounter activation to a *separate* one-shot Lua VM. Vanilla starts Kolmi from
-- Sampo's item_pickup LuaComponent, not from a LuaComponent on the boss itself. Starting
-- the enable_coroutines combat component from the boss' own update was the last semantic
-- difference in TEST 22/23 and can leave the authored coroutine half-started.
local entity = GetUpdatedEntityID()
local component = GetUpdatedComponentID()
local REF_ID_VAR = "mcm_creative_kolmi_reference_id_v3"
local START_VAR = "mcm_creative_kolmi_bootstrap_frame_v3"
local CONTROLLER = "mods/metamorph_creative_menu/files/features/creatures/kolmi_encounter_start.lua"
local ew_runtime = dofile("mods/metamorph_creative_menu/files/integrations/ew/runtime.lua")

local function get_var(name)
    for _, storage in ipairs(EntityGetComponentIncludingDisabled(entity, "VariableStorageComponent") or {}) do
        if ComponentGetValue2(storage, "name") == name then return storage end
    end
    return nil
end

local function get_or_create_start_frame()
    local storage = get_var(START_VAR)
    if storage ~= nil then return tonumber(ComponentGetValue2(storage, "value_int")) or GameGetFrameNum() end
    storage = EntityAddComponent2(entity, "VariableStorageComponent", {
        _tags = "ew_remove_on_send",
        name = START_VAR,
        value_int = GameGetFrameNum(),
    })
    return storage ~= nil and (tonumber(ComponentGetValue2(storage, "value_int")) or GameGetFrameNum()) or GameGetFrameNum()
end

local function gid_owner_state()
    local storage = get_var("ew_gid_lid")
    if storage == nil then return false, false end
    return true, ComponentGetValue2(storage, "value_bool") == true
end

local function ew_enabled()
    return type(ew_runtime) == "table" and type(ew_runtime.enabled) == "function" and ew_runtime.enabled() == true
end

local function reference_id()
    local storage = get_var(REF_ID_VAR)
    return storage ~= nil and (tonumber(ComponentGetValue2(storage, "value_int")) or 0) or 0
end

local function add_controller_var(controller, name, value)
    return EntityAddComponent2(controller, "VariableStorageComponent", {
        name = name,
        value_int = tonumber(value) or 0,
    })
end

local function spawn_controller(reference)
    if type(EntityCreateNew) ~= "function" or type(EntityAddComponent2) ~= "function" then return 0 end
    local x, y = EntityGetTransform(entity)
    local controller = EntityCreateNew("mcm_creative_kolmi_encounter_controller") or 0
    controller = tonumber(controller) or 0
    if controller == 0 then return 0 end
    EntitySetTransform(controller, tonumber(x) or 0, (tonumber(y) or 0) + 80)
    if type(EntityAddTag) == "function" then EntityAddTag(controller, "ew_no_enemy_sync") end
    add_controller_var(controller, "mcm_kolmi_boss_id_v3", entity)
    add_controller_var(controller, "mcm_kolmi_reference_id_v3", reference)
    EntityAddComponent2(controller, "LuaComponent", {
        script_source_file = CONTROLLER,
        -- Do not execute synchronously from the boss bootstrap call stack. Vanilla Sampo
        -- pickup is an external engine event; yielding to the next world frame ensures the
        -- boss' enable_coroutines LuaComponent is enabled from a separate entity update.
        execute_on_added = false,
        execute_every_n_frame = 1,
        remove_after_executed = true,
    })
    return controller
end

if not EntityGetIsAlive(entity) then return end
local started = get_or_create_start_frame()
local has_gid, is_owner = gid_owner_state()

if ew_enabled() then
    -- Never start a global final-boss encounter from a remote replica. The creative root
    -- is born locally, so this normally resolves in one DES update; if authority moved,
    -- the new owner (with MCM) can recreate/start its own controller later.
    if not has_gid or not is_owner then return end
else
    -- Singleplayer has no ew_gid_lid. Yield one frame so all authored execute_on_added
    -- initialization from EntityLoad has completed before the external pickup transition.
    if GameGetFrameNum() <= started then return end
end

local reference = reference_id()
if reference == 0 or not EntityGetIsAlive(reference) then
    -- The spawn path creates the authored reference first. Failing closed here is safer
    -- than starting a final-boss coroutine without the anchor it requires for phases/death.
    return
end

local controller = spawn_controller(reference)
if controller == 0 then return end
if type(EntityAddTag) == "function" then EntityAddTag(entity, "mcm_creative_kolmi_activation_queued_v3") end
if component ~= nil and component ~= 0 then EntityRemoveComponent(entity, component) end
