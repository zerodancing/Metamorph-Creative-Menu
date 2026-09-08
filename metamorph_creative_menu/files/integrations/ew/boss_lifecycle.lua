-- Final death must reach EW 1.6.3's pending_death_notify BEFORE the native update can
-- release a dead global root. Never infer a custom boss's final death from HP alone.
local lifecycle = {}
local policy = dofile("mods/metamorph_creative_menu/files/integrations/ew/boss_lifecycle_policy.lua")
local global_text = dofile("mods/metamorph_creative_menu/files/core/global_text.lua")
local candidates, observed, pending, retired = {}, {}, {}, {}
local installed, native_notify = false, nil
local last_id, next_sweep = 0, 0

local function alive(entity) return EntityGetIsAlive(entity) == true end
local function resolve(gid)
    local ok, entity = pcall(ewext.find_by_gid, gid)
    return ok, ok and (tonumber(entity) or 0) or 0
end
local function report(event, record)
    local message = event .. " gid=" .. record.gid .. " ent=" .. tostring(record.entity)
    GlobalsSetValue("mcm32_boss_lifecycle_last_v1", global_text.encode_diagnostic(message))
    print("[MCM32 Boss] " .. message)
end

local function discover(entity)
    if policy.is_boss(entity) then candidates[entity] = true end
end
local function discover_gap()
    if type(EntitiesGetMaxID) ~= "function" then return end
    local newest = EntitiesGetMaxID()
    for entity = last_id + 1, newest do discover(entity) end
    last_id = newest
end
local function discover_existing()
    local frame = GameGetFrameNum()
    if frame < next_sweep then return end
    next_sweep = frame + 60
    local seen = {}
    -- Recovery for saves, late component additions, and installations into a running
    -- world. The per-frame path handles only new IDs and known boss candidates.
    for _, tag in ipairs({"ew_des", "boss", "miniboss", "mcm_boss"}) do
        for _, entity in ipairs(EntityGetWithTag(tag) or {}) do
            if not seen[entity] then discover(entity); seen[entity] = true end
        end
    end
end

local function observe()
    for entity in pairs(candidates) do
        if not policy.eligible(entity) then
            candidates[entity] = nil
        else
            local gid, owner = policy.identity(entity)
            if gid and not owner then
                candidates[entity] = nil -- the new owner creates a different local root
            elseif gid then
                local ok, tracked = resolve(gid)
                if ok and tracked == entity then
                    local record = observed[entity]
                    if not record or record.gid ~= gid then
                        record = {entity = entity, gid = gid}
                        observed[entity] = record
                    end
                    record.x, record.y = EntityGetTransform(entity)
                    local damage = EntityGetFirstComponentIncludingDisabled(entity, "DamageModelComponent")
                    record.wait = damage ~= nil and ComponentGetValue2(damage, "wait_for_kill_flag_on_death") == true
                    record.kill = damage ~= nil and ComponentGetValue2(damage, "kill_now") == true
                    record.hp = damage and tonumber(ComponentGetValue2(damage, "hp")) or nil
                elseif ok then
                    candidates[entity] = nil
                end
            end
        end
    end
end

local function drain_events()
    local text = GlobalsGetValue(policy.EVENTS, "")
    if text == "" then return end
    GlobalsSetValue(policy.EVENTS, "")
    for line in text:gmatch("[^;]+") do
        local entity, gid, wait, x, y, responsible = line:match("^(%d+),(%d+),([01]),([^,]+),([^,]+),(%d+)$")
        entity, x, y = tonumber(entity), tonumber(x), tonumber(y)
        if entity and entity > 0 and gid and x and y then
            local record = observed[entity]
            if not record or record.gid ~= gid then
                record = {entity = entity, gid = gid, x = x, y = y, wait = wait == "1"}
                observed[entity] = record
            end
            record.notified = true
            record.responsible = tonumber(responsible) or 0
        end
    end
end

local function quiet_kill(entity, expected_gid)
    if not policy.eligible(entity) then return end
    local gid, owner = policy.identity(entity)
    if gid ~= expected_gid or not owner then return end
    -- Only an acknowledged reconstruction of an already dead GID, never an original
    -- boss or a new phase/new summon. Suppress callbacks throughout its child tree too.
    local function silence(current)
        for _, child in ipairs(EntityGetAllChildren(current) or {}) do silence(child) end
        for _, lua in ipairs(EntityGetComponentIncludingDisabled(current, "LuaComponent") or {}) do
            ComponentSetValue2(lua, "script_death", "")
            ComponentSetValue2(lua, "script_damage_received", "")
            ComponentSetValue2(lua, "script_damage_about_to_be_received", "")
            EntitySetComponentIsEnabled(current, lua, false)
        end
        for _, chest in ipairs(EntityGetComponentIncludingDisabled(current, "ItemChestComponent") or {}) do
            EntityRemoveComponent(current, chest)
        end
    end
    silence(entity)
    local damage = EntityGetFirstComponentIncludingDisabled(entity, "DamageModelComponent")
    if damage then
        ComponentSetValue2(damage, "wait_for_kill_flag_on_death", false)
        ComponentSetValue2(damage, "kill_now", true)
    end
    EntityKill(entity)
end

local function submit(record, reason)
    if pending[record.gid] then return end
    local ok, tracked = resolve(record.gid)
    if not ok or tracked ~= record.entity then return end
    local sent, failure = pcall(native_notify, record.entity, record.wait,
        record.x, record.y, "", record.responsible or 0)
    if not sent then
        if record.error ~= tostring(failure) then
            record.error = tostring(failure)
            report("notify_failed:" .. record.error, record)
        end
        return
    end
    record.reason = reason
    pending[record.gid] = record
    report("queued:" .. reason, record)
end

local function before_update()
    discover_existing()
    discover_gap()
    drain_events()
    observe()
    for entity, record in pairs(observed) do
        local is_alive = alive(entity)
        local valid = not is_alive or policy.eligible(entity)
        if is_alive then
            local gid, owner = policy.identity(entity)
            valid = valid and owner and gid == record.gid
        end
        if not valid then
            observed[entity] = nil
        else
            -- Delayed-kill mods may signal a phase defeat and then restore HP. Do not
            -- carry that notification into a later healthy transfer/despawn.
            if is_alive and record.wait and not record.kill and record.hp and record.hp > 0 then
                record.notified = nil
                GlobalsSetValue(policy.EVENT_GID .. tostring(entity), "")
            end
            local terminal = not is_alive or record.kill or (record.notified and not record.wait)
            -- A real death event remains evidence if native DES already released the
            -- old body. It can then reject a delayed GotAuthority for this exact GID.
            if terminal and record.notified then retired[record.gid] = retired[record.gid] or entity end
            local ok, tracked = resolve(record.gid)
            if ok and tracked ~= entity then
                observed[entity] = nil
                candidates[entity] = nil
            elseif ok then
                if is_alive and retired[record.gid] and retired[record.gid] ~= entity then
                    submit(record, "reconstruction")
                elseif terminal then
                    submit(record, "death")
                end
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
            observed[record.entity], candidates[record.entity] = nil, nil
            GlobalsSetValue(policy.EVENT_GID .. tostring(record.entity), "")
            report("committed:" .. record.reason, record)
            if record.reason == "reconstruction" then quiet_kill(record.entity, gid) end
        elseif ok and entity ~= record.entity then
            retired[gid] = retired[gid] or record.entity
            pending[gid] = nil
        end
    end
    discover_gap()
    observe()
end

function lifecycle.install()
    if installed then return true end
    if type(ewext) ~= "table" or type(ewext.des_death_notify) ~= "function"
        or type(ewext.find_by_gid) ~= "function" or type(ewext.module_on_world_update) ~= "function"
    then return false, "ewext_lifecycle_api_unavailable" end
    native_notify = ewext.des_death_notify
    local native_update = ewext.module_on_world_update
    local native_new = ewext.module_on_new_entity
    last_id = type(EntitiesGetMaxID) == "function" and EntitiesGetMaxID() or 0
    if type(native_new) == "function" then
        ewext.module_on_new_entity = function(arr, len)
            for _, entity in ipairs(arr or {}) do
                discover(entity) -- before TEST 21 demotion hides the healthbar
                last_id = math.max(last_id, entity)
            end
            return native_new(arr, len)
        end
    end
    ewext.des_death_notify = function(entity, wait_on_kill, x, y, file, responsible)
        if alive(entity) then
            local _, owner = policy.identity(entity)
            if not policy.eligible(entity) or owner == false then
                return native_notify(entity, wait_on_kill, x, y, file, responsible)
            end
        end
        local record = observed[entity]
        if not record then
            -- The append preserves identity even if the body died before our first
            -- observation. Only that validated, owner-only mailbox may opt it in.
            local gid = GlobalsGetValue(policy.EVENT_GID .. tostring(entity), "")
            if gid:match("^%d+$") then
                record = {entity = entity, gid = gid, wait = wait_on_kill, x = x, y = y}
                observed[entity] = record
            end
        end
        if record then
            record.notified, record.responsible = true, responsible
            -- Native DES accepts no reentrant calls. Save the stock callback's killer
            -- and process it before the next native update, not from this call stack.
            return
        end
        return native_notify(entity, wait_on_kill, x, y, file, responsible)
    end
    ewext.module_on_world_update = function(...)
        before_update()
        local result = native_update(...)
        after_update()
        return result
    end
    installed = true
    GlobalsSetValue("mcm32_boss_lifecycle_ready_v1", "1")
    return true
end

return lifecycle
