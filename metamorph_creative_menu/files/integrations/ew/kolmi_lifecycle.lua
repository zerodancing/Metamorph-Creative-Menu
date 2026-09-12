-- EW 1.6.3 drains pending_death_notify BEFORE updating/transferring local entities.
-- Submit in this VM, before module_on_world_update, including deaths whose body has
-- already disappeared. A successful des_death_notify call only enqueues work: confirm
-- removal with find_by_gid after the native update before disposing of replacement roots.
local lifecycle = {}
local BOSS = "data/entities/animals/boss_centipede/boss_centipede.xml"
local READY = "mcm31_kolmi_lifecycle_ready_v1"
local REQUEST = "mcm31_kolmi_retire_request_v1_"
local observed, pending, retired = {}, {}, {}
local installed = false
local native_notify

local function alive(entity)
    return EntityGetIsAlive(entity) == true
end

local function boss_root(entity)
    return alive(entity) and EntityHasTag(entity, "boss_centipede")
        -- A mod may inherit this tag but implement different phases/death semantics.
        -- The proven early-HP policy belongs to the vanilla encounter, not its tag.
        and EntityGetFilename(entity) == BOSS
        and not EntityHasTag(entity, "player_unit")
        and not EntityHasTag(entity, "polymorphed_player")
        and not EntityHasTag(entity, "ew_no_enemy_sync")
        and EntityGetRootEntity(entity) == entity
end

local function identity(entity)
    for _, var in ipairs(EntityGetComponentIncludingDisabled(entity, "VariableStorageComponent") or {}) do
        if ComponentGetValue2(var, "name") == "ew_gid_lid" then
            -- Native GIDs are u64. Never round-trip them through a Lua number.
            local gid = ComponentGetValue2(var, "value_string")
            if type(gid) == "string" and gid ~= "" then
                return gid, ComponentGetValue2(var, "value_bool") == true
            end
        end
    end
end

local function uninitialized(entity)
    for _, var in ipairs(EntityGetComponentIncludingDisabled(entity, "VariableStorageComponent") or {}) do
        if ComponentGetValue2(var, "name") == "initialized" then
            return ComponentGetValue2(var, "value_bool") == false
        end
    end
    return false
end

local function resolve(gid)
    local ok, entity = pcall(ewext.find_by_gid, gid)
    return ok, ok and (tonumber(entity) or 0) or 0
end

local function quiet_kill(entity)
    if not alive(entity) then return end
    -- This is an arena replacement or a reconstruction of an already retired GID,
    -- never the original dying boss. Do not run a second encounter/death/loot sequence.
    for _, lua in ipairs(EntityGetComponentIncludingDisabled(entity, "LuaComponent") or {}) do
        ComponentSetValue2(lua, "script_death", "")
        ComponentSetValue2(lua, "script_damage_received", "")
        ComponentSetValue2(lua, "script_damage_about_to_be_received", "")
        EntitySetComponentIsEnabled(entity, lua, false)
    end
    for _, chest in ipairs(EntityGetComponentIncludingDisabled(entity, "ItemChestComponent") or {}) do
        EntityRemoveComponent(entity, chest)
    end
    local damage = EntityGetFirstComponentIncludingDisabled(entity, "DamageModelComponent")
    if damage then
        ComponentSetValue2(damage, "wait_for_kill_flag_on_death", false)
        ComponentSetValue2(damage, "kill_now", true)
    end
    EntityKill(entity)
end

local function submit(record, reason, responsible)
    if pending[record.gid] then return end
    local ok, entity = resolve(record.gid)
    if not ok or entity ~= record.entity then return end
    -- The stock filename would ask distant peers to load a fresh pre-fight Kolmi
    -- merely to replay her death. KillEntity still reaches existing stock EW replicas.
    local sent, failure = pcall(native_notify, record.entity, record.wait,
        record.x, record.y, "", responsible or 0)
    if not sent then
        if record.error ~= tostring(failure) then
            record.error = tostring(failure)
        end
        return
    end
    record.reason = reason
    pending[record.gid] = record
end

local function observe()
    for _, entity in ipairs(EntityGetWithTag("boss_centipede") or {}) do
        if boss_root(entity) then
            local gid, owner = identity(entity)
            if gid and owner then
                local ok, tracked = resolve(gid)
                if ok and tracked == entity then
                    local record = observed[entity]
                    local first_observation = not record or record.gid ~= gid
                    if first_observation then
                        record = { entity = entity, gid = gid }
                        observed[entity] = record
                    end
                    record.x, record.y = EntityGetTransform(entity)
                    local damage = EntityGetFirstComponentIncludingDisabled(entity, "DamageModelComponent")
                    record.wait = damage ~= nil
                        and ComponentGetValue2(damage, "wait_for_kill_flag_on_death") == true
                    record.hp = damage and tonumber(ComponentGetValue2(damage, "hp")) or nil
                    record.kill = damage and ComponentGetValue2(damage, "kill_now") == true
                    record.uninitialized = uninitialized(entity)
                end
            end
        end
    end
end

local function before_update()
    observe()
    for entity, record in pairs(observed) do
        local ok, tracked = resolve(record.gid)
        if ok and tracked ~= entity then
            observed[entity] = nil -- transferred/despawned: never kill another owner's body
        elseif ok then
            if alive(entity) then
                local gid, owner = identity(entity)
                if not boss_root(entity) or gid ~= record.gid or not owner then
                    observed[entity] = nil
                elseif retired[gid] and retired[gid] ~= entity then
                    submit(record, "reconstruction")
                elseif GlobalsGetValue(REQUEST .. tostring(entity), "") == gid then
                    record.wait = false
                    submit(record, "arena_replacement")
                elseif record.kill or (record.hp and record.hp <= 0) then
                    -- Commit the lethal state before DES can transfer authority and
                    -- reload boss_centipede.xml, whose init_boss resets HP. The original
                    -- body remains alive for the authored wait-for-kill animation/portal.
                    -- A Filename reconstruction can carry HP=0 but initialized=false:
                    -- it has no running death coroutine and would wait for Sampo forever,
                    -- or reset HP in init_boss on activation. Dispose of that inert body
                    -- after acknowledgement instead of leaving an untracked zero-HP boss.
                    submit(record, record.uninitialized and "inert_death" or "death")
                end
            else
                -- Stock death callbacks can reach EW's post-update queue one frame late.
                -- The previous owner snapshot lets us notify BEFORE !alive -> ReleaseAuthority.
                submit(record, "death")
            end
        end
    end
end

local function after_update()
    for gid, record in pairs(pending) do
        local ok, entity = resolve(gid)
        if ok and entity == 0 then
            retired[gid] = retired[gid] or record.entity
            pending[gid] = nil
            observed[record.entity] = nil
            GlobalsSetValue(REQUEST .. tostring(record.entity), "")
            if record.reason ~= "death" then quiet_kill(record.entity) end
        elseif ok and entity ~= record.entity then
            -- A queued authority message may recreate the same GID. Observe it below
            -- and retire that exact local incarnation on the next native update.
            retired[gid] = retired[gid] or record.entity
            pending[gid] = nil
        end
    end
    -- Also cover roots first tracked/reconstructed *inside* the native update, before
    -- a Lua script or a kill can remove them between this and the next frame.
    observe()
end

function lifecycle.install()
    if installed then return true end
    if type(ewext) ~= "table" or type(ewext.des_death_notify) ~= "function"
        or type(ewext.find_by_gid) ~= "function" or type(ewext.module_on_world_update) ~= "function"
    then return false, "ewext_lifecycle_api_unavailable" end
    native_notify = ewext.des_death_notify
    local native_update = ewext.module_on_world_update
    ewext.des_death_notify = function(entity, wait_on_kill, x, y, file, responsible)
        -- Keep the one stock callback on the same terminal path, even if it arrives
        -- after our lethal-state notification. Native DES ignores an untracked entity.
        local record = observed[entity]
        if record or (file == BOSS and boss_root(entity)) then file = "" end
        return native_notify(entity, wait_on_kill, x, y, file, responsible)
    end
    ewext.module_on_world_update = function(...)
        before_update()
        local result = native_update(...)
        after_update()
        return result
    end
    installed = true
    GlobalsSetValue(READY, "1")
    return true
end

return lifecycle
