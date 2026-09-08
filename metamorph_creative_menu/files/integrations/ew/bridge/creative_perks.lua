local bridge = {}

local SEQ_KEY = "mcm_creative_perk_spawn_seq_v1"
local ENTITY_KEY = "mcm_creative_perk_spawn_entity_v1:"
local ID_KEY = "mcm_creative_perk_spawn_id_v1:"
local X_KEY = "mcm_creative_perk_spawn_x_v1:"
local Y_KEY = "mcm_creative_perk_spawn_y_v1:"
local FRAME_KEY = "mcm_creative_perk_spawn_frame_v1:"
local ACK_KEY = "mcm_creative_perk_spawn_ack_v1"
local STATUS_KEY = "mcm_creative_perk_consume_status_v1"
local HISTORY_FRAMES = 180
local MAX_PICKUP_DISTANCE = 128

local last_sequence = tonumber(GlobalsGetValue(ACK_KEY, "0")) or 0
local entries = {}
local peer_counts = {}
local position_history = {}
local common

local function valid(entity)
    return entity ~= nil and tonumber(entity) ~= 0
        and type(EntityGetIsAlive) == "function" and EntityGetIsAlive(tonumber(entity)) == true
end

local function copy_counts(value)
    local result = {}
    if type(value) == "table" then
        for id, count in pairs(value) do result[tostring(id)] = math.max(0, tonumber(count) or 0) end
    end
    return result
end

local function remote_counts(data)
    if data == nil or not valid(data.entity) or type(util) ~= "table" or type(util.get_ent_variable) ~= "function" then
        return nil
    end
    local ok, value = pcall(util.get_ent_variable, data.entity, "ew_current_perks")
    return ok and type(value) == "table" and value or nil
end

local function consume_registrations()
    local sequence = tonumber(GlobalsGetValue(SEQ_KEY, "0")) or 0
    if sequence <= last_sequence then return end
    local processed, budget = last_sequence, 32
    while processed < sequence and budget > 0 do
        local n = processed + 1
        local suffix = tostring(n)
        local entity = tonumber(GlobalsGetValue(ENTITY_KEY .. suffix, "0")) or 0
        local perk_id = GlobalsGetValue(ID_KEY .. suffix, "")
        local x = tonumber(GlobalsGetValue(X_KEY .. suffix, "0")) or 0
        local y = tonumber(GlobalsGetValue(Y_KEY .. suffix, "0")) or 0
        local frame = tonumber(GlobalsGetValue(FRAME_KEY .. suffix, "0")) or 0
        if entity ~= 0 and perk_id ~= "" then
            entries[#entries + 1] = {entity=entity, perk_id=perk_id, x=x, y=y, frame=frame, sequence=n}
        end
        GlobalsSetValue(ENTITY_KEY .. suffix, "")
        GlobalsSetValue(ID_KEY .. suffix, "")
        GlobalsSetValue(X_KEY .. suffix, "")
        GlobalsSetValue(Y_KEY .. suffix, "")
        GlobalsSetValue(FRAME_KEY .. suffix, "")
        processed, budget = n, budget - 1
    end
    last_sequence = processed
    GlobalsSetValue(ACK_KEY, tostring(processed))
end

local function update_position_history(frame)
    for peer_id, data in pairs(ctx.players or {}) do
        if peer_id ~= ctx.my_id and data ~= nil and valid(data.entity) then
            local x, y = EntityGetTransform(data.entity)
            if tonumber(x) ~= nil and tonumber(y) ~= nil then
                local history = position_history[peer_id] or {}
                history[#history + 1] = {frame=frame, x=x, y=y}
                local cutoff = frame - HISTORY_FRAMES
                local first = 1
                while first <= #history and history[first].frame < cutoff do first = first + 1 end
                if first > 1 then
                    local compact = {}
                    for i=first,#history do compact[#compact+1]=history[i] end
                    history = compact
                end
                position_history[peer_id] = history
            end
        end
    end
end

local function entry_distance_sq(entry, peer_id, frame)
    if valid(entry.entity) then
        local x, y = EntityGetTransform(entry.entity)
        if tonumber(x) ~= nil and tonumber(y) ~= nil then entry.x, entry.y = x, y end
    end
    local best = math.huge
    for _, point in ipairs(position_history[peer_id] or {}) do
        if point.frame >= math.max(entry.frame - 4, frame - HISTORY_FRAMES) then
            local dx, dy = point.x - entry.x, point.y - entry.y
            local d = dx*dx + dy*dy
            if d < best then best = d end
        end
    end
    return best
end

local function consume_nearby(peer_id, perk_id, amount, frame)
    local consumed = 0
    for _=1,amount do
        local best_index, best_distance = nil, MAX_PICKUP_DISTANCE * MAX_PICKUP_DISTANCE
        for index, entry in ipairs(entries) do
            if entry.perk_id == perk_id and valid(entry.entity) then
                local distance = entry_distance_sq(entry, peer_id, frame)
                if distance <= best_distance then best_index, best_distance = index, distance end
            end
        end
        if best_index == nil then break end
        local entry = entries[best_index]
        -- This runs in the MCM owner's EW context, where this pickup is authoritative.
        -- Submit the DES death directly before EntityKill so deletion is network-authoritative
        -- even though vanilla perk pickup on the stock peer only destroyed its local replica.
        local x, y = EntityGetTransform(entry.entity)
        local path = EntityGetFilename(entry.entity) or "data/entities/items/pickup/perk.xml"
        local notify_ok, notify_failure = false, "des_death_notify_unavailable"
        if type(ewext) == "table" and type(ewext.des_death_notify) == "function" then
            notify_ok, notify_failure = pcall(ewext.des_death_notify, entry.entity, false,
                tonumber(x) or entry.x, tonumber(y) or entry.y, tostring(path), 0)
        end
        local ok, failure = pcall(EntityKill, entry.entity)
        if notify_ok and ok then
            consumed = consumed + 1
            GlobalsSetValue(STATUS_KEY,
                "consumed:" .. tostring(perk_id) .. ":peer=" .. tostring(peer_id) .. ":seq=" .. tostring(entry.sequence))
            table.remove(entries, best_index)
        else
            if common ~= nil and type(common.report_error) == "function" then
                common.report_error("creative_perk_consume",
                    "notify=" .. tostring(notify_failure) .. ";kill=" .. tostring(failure))
            end
            break
        end
    end
    return consumed
end

local function cleanup_entries()
    local alive_entries = {}
    for _, entry in ipairs(entries) do
        if valid(entry.entity) then alive_entries[#alive_entries + 1] = entry end
    end
    entries = alive_entries
end

function bridge.init(shared_common)
    common = shared_common
end

function bridge.update()
    consume_registrations()
    local frame = type(GameGetFrameNum)=="function" and (tonumber(GameGetFrameNum()) or 0) or 0
    update_position_history(frame)

    for peer_id, data in pairs(ctx.players or {}) do
        if peer_id ~= ctx.my_id then
            local current = remote_counts(data)
            if current ~= nil then
                local previous = peer_counts[peer_id] or {}
                for perk_id, count in pairs(current) do
                    local old = tonumber(previous[perk_id]) or 0
                    local new = tonumber(count) or 0
                    if new > old then consume_nearby(peer_id, tostring(perk_id), math.floor(new-old), frame) end
                end
                peer_counts[peer_id] = copy_counts(current)
            end
        end
    end
    cleanup_entries()
end

function bridge.debug_state()
    return #entries, last_sequence
end

return bridge
