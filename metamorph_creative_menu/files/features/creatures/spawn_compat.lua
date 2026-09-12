local spawn_compat = {}

local KOLMI = "data/entities/animals/boss_centipede/boss_centipede.xml"
local REF_PATH = "data/entities/animals/boss_centipede/reference_point.xml"
local CREATIVE_REF_VAR = "mcm_creative_kolmi_reference_v3"
local CREATIVE_REF_ID_VAR = "mcm_creative_kolmi_reference_id_v3"
local CREATIVE_MARKER = "mcm_creative_kolmi_v3"
local CREATIVE_REF_TAG = "mcm_creative_kolmi_reference_v3"
local BOOTSTRAP = "mods/metamorph_creative_menu/files/features/creatures/kolmi_creative_bootstrap.lua"
local CONTROLLER = "mods/metamorph_creative_menu/files/features/creatures/kolmi_encounter_start.lua"

-- The final-boss arena already contains an authored Kolmisilma and reference point.
-- Reuse or retire that root before creating a creative replacement so the encounter never
-- starts with two nearly coincident boss authorities.
local ARENA_BOSS_RADIUS_SQ = 192 * 192
local ARENA_REFERENCE_RADIUS_SQ = 768 * 768
local REPLACED_COUNT = "mcm30_kolmi_existing_arena_root_replaced_v1"
local REUSED_REMOTE_COUNT = "mcm30_kolmi_existing_remote_root_reused_v1"
local REUSED_REFERENCE_COUNT = "mcm30_kolmi_existing_reference_reused_v1"

local function bump(key)
    if type(GlobalsGetValue) ~= "function" or type(GlobalsSetValue) ~= "function" then return end
    local ok, value = pcall(GlobalsGetValue, key, "0")
    value = ok and (tonumber(value) or 0) or 0
    pcall(GlobalsSetValue, key, tostring(value + 1))
end

local function alive(entity)
    entity = tonumber(entity) or 0
    return entity ~= 0 and type(EntityGetIsAlive) == "function" and EntityGetIsAlive(entity) == true
end

local function has_tag(entity, tag)
    if type(EntityHasTag) ~= "function" then return false end
    local ok, value = pcall(EntityHasTag, entity, tag)
    return ok and value == true
end

local function position(entity)
    if type(EntityGetTransform) ~= "function" then return 0, 0 end
    local ok, x, y = pcall(EntityGetTransform, entity)
    if not ok then return 0, 0 end
    return tonumber(x) or 0, tonumber(y) or 0
end

local function distance_sq(entity, x, y)
    local ex, ey = position(entity)
    local dx, dy = ex - (tonumber(x) or 0), ey - (tonumber(y) or 0)
    return dx * dx + dy * dy
end

local function find_named_var(entity, name)
    if type(EntityGetComponentIncludingDisabled) ~= "function" then return nil end
    for _, component in ipairs(EntityGetComponentIncludingDisabled(entity, "VariableStorageComponent") or {}) do
        local ok_name, current = pcall(ComponentGetValue2, component, "name")
        if ok_name and tostring(current or "") == name then return component end
    end
    return nil
end

local function gid_state(entity)
    local storage = find_named_var(entity, "ew_gid_lid")
    if storage == nil or type(ComponentGetValue2) ~= "function" then return nil, nil end
    local ok_gid, gid = pcall(ComponentGetValue2, storage, "value_string")
    local ok_owner, owner = pcall(ComponentGetValue2, storage, "value_bool")
    gid = ok_gid and tostring(gid or "") or ""
    if gid == "" then gid = nil end
    return gid, ok_owner and owner == true
end

local function add_var(entity, name, fields, tags)
    local existing = find_named_var(entity, name)
    if existing ~= nil then
        for key, value in pairs(fields or {}) do pcall(ComponentSetValue2, existing, key, value) end
        if type(ComponentAddTag) == "function" then
            for tag in string.gmatch(tostring(tags or ""), "[^,]+") do pcall(ComponentAddTag, existing, tag) end
        end
        return existing
    end
    if type(EntityAddComponent2) ~= "function" then return nil end
    local values = { name = name }
    for key, value in pairs(fields or {}) do values[key] = value end
    if tags ~= nil and tags ~= "" then values._tags = tags end
    local ok, component = pcall(EntityAddComponent2, entity, "VariableStorageComponent", values)
    return ok and component or nil
end

local function add_synced_reference(entity, x, y)
    local value = string.format("%.17g,%.17g", tonumber(x) or 0, tonumber(y) or 0)
    return add_var(entity, CREATIVE_REF_VAR, { value_string = value }, "ew_synced_var")
end

local function remember_reference_id(entity, reference)
    return add_var(entity, CREATIVE_REF_ID_VAR, { value_int = tonumber(reference) or 0 }, "ew_remove_on_send")
end

local function nearest_tagged(tag, x, y, max_distance_sq, predicate)
    if type(EntityGetWithTag) ~= "function" then return 0 end
    local ok, entities = pcall(EntityGetWithTag, tag)
    if not ok or type(entities) ~= "table" then return 0 end
    local best, best_d = 0, max_distance_sq
    for _, raw in ipairs(entities) do
        local entity = tonumber(raw) or 0
        if alive(entity) and (predicate == nil or predicate(entity)) then
            local d = distance_sq(entity, x, y)
            if d <= best_d then best, best_d = entity, d end
        end
    end
    return best
end

local function nearest_reference(x, y)
    return nearest_tagged("reference", x, y, ARENA_REFERENCE_RADIUS_SQ)
end

local function existing_authored_kolmi(x, y)
    return nearest_tagged("boss_centipede", x, y, ARENA_BOSS_RADIUS_SQ, function(entity)
        -- Never confuse a player form, a replay corpse or a Kolmi already spawned by MCM
        -- with the authored arena root we are trying to deduplicate.
        return not has_tag(entity, "player_unit")
            and not has_tag(entity, "polymorphed_player")
            and not has_tag(entity, "ew_no_enemy_sync")
            and not has_tag(entity, CREATIVE_MARKER)
    end)
end

local function quiet_retire_existing(entity)
    if not alive(entity) then return true end

    -- MCM's menu VM has no ewext. Hand the exact GID to the EW module, which keeps the
    -- body alive until native DES has actually removed its record. A queued notification
    -- is not an acknowledgement, and EntityKill alone leaves global authority behind.
    local gid, owner = gid_state(entity)
    if gid ~= nil and owner == false then
        return false, "remote_authority"
    end
    if gid ~= nil then
        if type(GlobalsGetValue) ~= "function" or type(GlobalsSetValue) ~= "function"
            or GlobalsGetValue("mcm31_kolmi_lifecycle_ready_v1", "") ~= "1"
        then return false, "des_retire_unavailable" end
        local ok = pcall(GlobalsSetValue, "mcm31_kolmi_retire_request_v1_" .. tostring(entity), gid)
        if not ok then return false, "des_retire_failed" end
        return true, "retire_queued"
    end

    if type(EntityAddTag) == "function" then pcall(EntityAddTag, entity, "mcm30_replaced_authored_kolmi_v1") end

    if type(EntityGetComponentIncludingDisabled) == "function" then
        for _, lua in ipairs(EntityGetComponentIncludingDisabled(entity, "LuaComponent") or {}) do
            if type(ComponentSetValue2) == "function" then
                pcall(ComponentSetValue2, lua, "script_death", "")
                pcall(ComponentSetValue2, lua, "script_damage_received", "")
                pcall(ComponentSetValue2, lua, "script_damage_about_to_be_received", "")
            end
            if type(EntitySetComponentIsEnabled) == "function" then
                pcall(EntitySetComponentIsEnabled, entity, lua, false)
            end
        end
        for _, chest in ipairs(EntityGetComponentIncludingDisabled(entity, "ItemChestComponent") or {}) do
            if type(EntityRemoveComponent) == "function" then pcall(EntityRemoveComponent, entity, chest) end
        end
    end
    if type(EntityGetFirstComponentIncludingDisabled) == "function" and type(ComponentSetValue2) == "function" then
        local damage = EntityGetFirstComponentIncludingDisabled(entity, "DamageModelComponent")
        if damage ~= nil then
            pcall(ComponentSetValue2, damage, "wait_for_kill_flag_on_death", false)
            pcall(ComponentSetValue2, damage, "kill_now", true)
        end
    end
    if type(EntityKill) == "function" then pcall(EntityKill, entity) end
    return true, "retired"
end

local function publish_reference(reference)
    reference = tonumber(reference) or 0
    if reference ~= 0 and type(EntityAddTag) == "function" then
        pcall(EntityAddTag, reference, CREATIVE_REF_TAG)
        pcall(EntityAddTag, reference, "ew_synced")
    end
    return reference
end

local function spawn_reference(x, y)
    if type(EntityLoad) ~= "function" then return 0 end
    local ok, reference = pcall(EntityLoad, REF_PATH, tonumber(x) or 0, tonumber(y) or 0)
    reference = ok and (tonumber(reference) or 0) or 0
    return publish_reference(reference)
end

local function add_bootstrap(entity)
    if type(EntityAddComponent2) ~= "function" then return nil end
    local ok, component = pcall(EntityAddComponent2, entity, "LuaComponent", {
        _tags = "mcm_creative_kolmi_bootstrap,ew_remove_on_send",
        script_source_file = BOOTSTRAP,
        execute_every_n_frame = 1,
        execute_on_added = false,
        remove_after_executed = false,
    })
    return ok and component or nil
end

-- Runs before EntityLoad. If the user clicks Kolmisilma while standing in the real final
-- boss arena, retire the authored dormant root first and reuse its authored reference point.
-- A remote-owned root cannot be safely deleted by this peer; in that case reuse it instead
-- of creating a second final boss.
function spawn_compat.before_spawn(path, x, y)
    if tostring(path or "") ~= KOLMI then return { kind = "ordinary" } end
    local reference = nearest_reference(x, y)
    local existing = existing_authored_kolmi(x, y)
    if existing == 0 then
        if reference ~= 0 then bump(REUSED_REFERENCE_COUNT) end
        return { kind = "kolmi", reference_id = reference }
    end

    local retired, reason = quiet_retire_existing(existing)
    if retired then
        bump(REPLACED_COUNT)
        if reference ~= 0 then bump(REUSED_REFERENCE_COUNT) end
        return { kind = "kolmi", reference_id = reference, replaced_entity = existing }
    end

    if reason == "remote_authority" then
        bump(REUSED_REMOTE_COUNT)
        return { kind = "reuse", entity = existing, reference_id = reference, reason = reason }
    end
    -- A failed retirement must not create another root on top of the retained one.
    return { kind = "reuse", entity = existing, reference_id = reference, reason = reason }
end

local function prepare_creative_kolmi(entity, x, y, context)
    if not alive(entity) then return false, "invalid" end

    local reference = type(context) == "table" and tonumber(context.reference_id) or 0
    if reference == nil then reference = 0 end
    if not alive(reference) then reference = spawn_reference(x, y)
    else reference = publish_reference(reference) end
    if reference == 0 then return false, "reference" end

    if add_synced_reference(entity, x, y) == nil then return false, "reference_var" end
    if remember_reference_id(entity, reference) == nil then return false, "reference_id_var" end
    if type(EntityAddTag) == "function" then pcall(EntityAddTag, entity, CREATIVE_MARKER) end

    local bootstrap = add_bootstrap(entity)
    if bootstrap == nil then return false, "bootstrap_component" end
    return true, "creative_kolmi_prepared"
end

function spawn_compat.after_spawn(path, entity, x, y, context)
    if tostring(path or "") ~= KOLMI then return true, "ordinary" end
    return prepare_creative_kolmi(tonumber(entity) or 0, tonumber(x) or 0, tonumber(y) or 0, context)
end

spawn_compat.KOLMI_PATH = KOLMI
spawn_compat.REF_PATH = REF_PATH
spawn_compat.CREATIVE_REF_VAR = CREATIVE_REF_VAR
spawn_compat.CREATIVE_REF_ID_VAR = CREATIVE_REF_ID_VAR
spawn_compat.CREATIVE_MARKER = CREATIVE_MARKER
spawn_compat.CREATIVE_REF_TAG = CREATIVE_REF_TAG
spawn_compat.BOOTSTRAP = BOOTSTRAP
spawn_compat.CONTROLLER = CONTROLLER
return spawn_compat
