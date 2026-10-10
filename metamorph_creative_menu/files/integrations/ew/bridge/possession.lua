local possession_bridge = {}
local OUTBOX_SEQ = "mcm_possession_retire_outbox_seq_v1"
local OUTBOX_ENTITY = "mcm_possession_retire_outbox_entity_v1"
local OUTBOX_PATH = "mcm_possession_retire_outbox_path_v1"
local OUTBOX_X = "mcm_possession_retire_outbox_x_v1"
local OUTBOX_Y = "mcm_possession_retire_outbox_y_v1"
local OUTBOX_WAIT = "mcm_possession_retire_outbox_wait_v1"
local OUTBOX_RESPONSIBLE = "mcm_possession_retire_outbox_responsible_v1"
local OUTBOX_ACK = "mcm_possession_retire_outbox_ack_v1"
local MAX_DRAIN_PER_FRAME = 16
local MAX_SEQUENCE_GAP = 4096

local function parse_sequence(value)
    local sequence = tonumber(value)
    if type(sequence) ~= "number" or sequence ~= sequence
        or sequence == math.huge or sequence == -math.huge
        or sequence < 0 or math.floor(sequence) ~= sequence
    then return nil end
    return sequence
end

local last_sequence = parse_sequence(GlobalsGetValue(OUTBOX_ACK, "0")) or 0
local rpc, common
local last_invalid_sequence = nil

local function path_allowed(path)
    return type(path) == "string" and #path > 0 and #path <= 512
        and string.find(path, "..", 1, true) == nil
        and (string.sub(path, 1, 14) == "data/entities/" or string.sub(path, 1, 5) == "mods/")
end

function possession_bridge.register(shared_rpc, shared_common)
    rpc, common = shared_rpc, shared_common
    -- Slot 9 stays registered for v4 wire compatibility. Retirement itself deliberately
    -- uses EW's own ew_death_notify CrossCall so no MCM is required on another peer.
    rpc.opts_reliable()
    rpc.opts_everywhere()
    function rpc.retire_possession_target(_path, _x, _y) return end
end

local PAYLOAD_KEYS = { OUTBOX_ENTITY, OUTBOX_PATH, OUTBOX_X, OUTBOX_Y, OUTBOX_WAIT, OUTBOX_RESPONSIBLE }

local function read_value(base, current, published, fallback)
    local value = GlobalsGetValue(base .. "_" .. tostring(current), "")
    if value == "" and current == published then value = GlobalsGetValue(base, fallback or "") end
    return value
end

local function clear_payload(current, published)
    for _, base in ipairs(PAYLOAD_KEYS) do
        GlobalsSetValue(base .. "_" .. tostring(current), "")
        -- The unsuffixed keys are a compatibility alias for the latest published event.
        -- Never clear them while an earlier event in the same batch is being drained.
        if current == published then GlobalsSetValue(base, "") end
    end
end

function possession_bridge.update()
    local raw_sequence = GlobalsGetValue(OUTBOX_SEQ, "0")
    local sequence = parse_sequence(raw_sequence)
    if sequence == nil then
        raw_sequence = tostring(raw_sequence)
        if raw_sequence ~= last_invalid_sequence then
            last_invalid_sequence = raw_sequence
            common.report_error("possession_retire_sequence", "invalid=" .. raw_sequence)
        end
        return
    end
    last_invalid_sequence = nil
    if sequence <= last_sequence then return end
    if sequence - last_sequence > MAX_SEQUENCE_GAP then
        common.report_error("possession_retire_gap", "last=" .. tostring(last_sequence) .. ";published=" .. tostring(sequence))
        last_sequence = sequence
        GlobalsSetValue(OUTBOX_ACK, tostring(last_sequence))
        return
    end

    local processed = last_sequence
    local drain_until = math.min(sequence, last_sequence + MAX_DRAIN_PER_FRAME)
    for current = last_sequence + 1, drain_until do
        local entity = tonumber(read_value(OUTBOX_ENTITY, current, sequence, "0")) or 0
        local path = read_value(OUTBOX_PATH, current, sequence, "")
        local x = tonumber(read_value(OUTBOX_X, current, sequence, ""))
        local y = tonumber(read_value(OUTBOX_Y, current, sequence, ""))
        local wait_on_kill = read_value(OUTBOX_WAIT, current, sequence, "0") == "1"
        local responsible = tonumber(read_value(OUTBOX_RESPONSIBLE, current, sequence, "0")) or 0
        if entity == 0 or not path_allowed(path) or not common.finite_number(x) or not common.finite_number(y) then
            common.report_error("possession_retire_submit", "seq=" .. tostring(current))
            processed = current
            clear_payload(current, sequence)
        else
            -- Possession is not running from an engine death callback, so the safest path
            -- is to resolve DES immediately while the entity and ew_gid_lid are guaranteed
            -- to still exist. Fallback to EW's stock CrossCall queue on older builds; the
            -- ACK is still observed by main MCM only on the following game update.
            local ok, failure
            if type(ewext) == "table" and type(ewext.des_death_notify) == "function"
                and (type(EntityGetIsAlive) ~= "function" or EntityGetIsAlive(entity))
            then
                ok, failure = pcall(ewext.des_death_notify, entity, wait_on_kill, x, y, path, responsible)
            elseif type(CrossCall) == "function" then
                ok, failure = pcall(CrossCall, "ew_death_notify",
                    entity, wait_on_kill, x, y, path, responsible)
            else
                ok, failure = false, "DES death API unavailable"
            end
            if not ok then
                common.report_error("possession_retire_submit", tostring(failure))
                break
            end
            processed = current
            clear_payload(current, sequence)
        end
    end
    if processed > last_sequence then
        last_sequence = processed
        GlobalsSetValue(OUTBOX_ACK, tostring(processed))
    end
end

return possession_bridge
