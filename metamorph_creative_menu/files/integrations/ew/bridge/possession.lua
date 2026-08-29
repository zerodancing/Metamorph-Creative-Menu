local possession_bridge = {}
local OUTBOX_SEQ = "mcm_possession_retire_outbox_seq_v1"
local OUTBOX_PATH = "mcm_possession_retire_outbox_path_v1"
local OUTBOX_X = "mcm_possession_retire_outbox_x_v1"
local OUTBOX_Y = "mcm_possession_retire_outbox_y_v1"
local OUTBOX_ACK = "mcm_possession_retire_outbox_ack_v1"
local last_sequence = tonumber(GlobalsGetValue(OUTBOX_ACK, "0")) or 0
local rpc, common

local function safe_retire_owned_entity(entity)
    if entity == nil or entity == 0 or not EntityGetIsAlive(entity) then return false end
    local ok_util, util_min = pcall(dofile, "mods/quant.ew/files/resource/util_min.lua")
    if not ok_util or type(util_min) ~= "table" or type(util_min.do_i_own) ~= "function" then return false end
    local ok_owner, owned = pcall(util_min.do_i_own, entity)
    if not ok_owner or owned ~= true then return false end
    local tree, queue, seen, index = {}, {entity}, {}, 1
    while index <= #queue do
        local current = queue[index]; index = index + 1
        if current ~= nil and current ~= 0 and EntityGetIsAlive(current) and not seen[current] then
            seen[current] = true; tree[#tree + 1] = current
            for _, child in ipairs(EntityGetAllChildren(current) or {}) do queue[#queue + 1] = child end
        end
    end
    pcall(EntitySetTransform, entity, 10000000, 10000000)
    for _, current in ipairs(tree) do
        for _, component in ipairs(EntityGetAllComponents(current) or {}) do
            local ok_name, name = pcall(ComponentGetTypeName, component)
            if ok_name and name == "LuaComponent" then pcall(EntityRemoveComponent, current, component)
            else pcall(EntitySetComponentIsEnabled, current, component, false) end
        end
    end
    if EntityGetIsAlive(entity) then pcall(EntityKill, entity) end
    return true
end

function possession_bridge.register(shared_rpc, shared_common)
    rpc, common = shared_rpc, shared_common
    rpc.opts_reliable()
    rpc.opts_everywhere()
    function rpc.retire_possession_target(path, x, y)
        if type(path) ~= "string" or #path == 0 or #path > 512
            or string.find(path, "..", 1, true) ~= nil
            or (string.sub(path, 1, 14) ~= "data/entities/" and string.sub(path, 1, 5) ~= "mods/")
        then return end
        x, y = tonumber(x), tonumber(y)
        if not common.finite_number(x) or not common.finite_number(y) then return end
        local sender_data = ctx.rpc_player_data
        local sender_entity = sender_data ~= nil and sender_data.entity or 0
        if sender_entity == nil or sender_entity == 0 or not EntityGetIsAlive(sender_entity) then return end
        local sx, sy = EntityGetTransform(sender_entity)
        if not common.finite_number(sx) or not common.finite_number(sy) then return end
        local dx, dy = sx - x, sy - y
        if dx * dx + dy * dy > 512 * 512 then return end
        local best, best_d2 = 0, 96 * 96
        for _, raw in ipairs(EntityGetInRadius(x, y, 96) or {}) do
            local root, guard = raw, 0
            while root ~= nil and root ~= 0 and guard < 32 do
                local parent = EntityGetParent(root)
                if parent == nil or parent == 0 then break end
                root, guard = parent, guard + 1
            end
            if root ~= nil and root ~= 0 and root ~= sender_entity and EntityGetIsAlive(root)
                and tostring(EntityGetFilename(root) or "") == path then
                local rx, ry = EntityGetTransform(root)
                if common.finite_number(rx) and common.finite_number(ry) then
                    local ex, ey = rx - x, ry - y
                    local d2 = ex * ex + ey * ey
                    if d2 <= best_d2 then best, best_d2 = root, d2 end
                end
            end
        end
        if best ~= 0 then safe_retire_owned_entity(best) end
    end
end

function possession_bridge.update()
    local sequence = tonumber(GlobalsGetValue(OUTBOX_SEQ, "0")) or 0
    if sequence <= last_sequence then return end
    local processed = last_sequence
    for current = last_sequence + 1, sequence do
        local suffix = "_" .. tostring(current)
        local path = GlobalsGetValue(OUTBOX_PATH .. suffix, "")
        local x = tonumber(GlobalsGetValue(OUTBOX_X .. suffix, ""))
        local y = tonumber(GlobalsGetValue(OUTBOX_Y .. suffix, ""))
        if current == sequence then
            if path == "" then path = GlobalsGetValue(OUTBOX_PATH, "") end
            if x == nil then x = tonumber(GlobalsGetValue(OUTBOX_X, "")) end
            if y == nil then y = tonumber(GlobalsGetValue(OUTBOX_Y, "")) end
        end
        if path == "" or not common.finite_number(x) or not common.finite_number(y) then
            common.report_error("possession_retire_submit", "seq=" .. tostring(current)); processed = current
        else
            local ok, failure = pcall(rpc.retire_possession_target, path, x, y)
            if not ok then common.report_error("possession_retire_send", failure); break end
            processed = current
        end
    end
    last_sequence = processed
    GlobalsSetValue(OUTBOX_ACK, tostring(processed))
end
return possession_bridge
