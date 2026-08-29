if type(METAMORPH_CREATIVE_MENU_EW_MATERIAL_PAINT_SYNC) == "table" then
    return METAMORPH_CREATIVE_MENU_EW_MATERIAL_PAINT_SYNC
end

local sync = {}

-- This mailbox crosses from MCM's normal Lua VM into EW's extra-module VM. A fixed
-- ring is intentional: a disconnected/failed EW bridge must not create one permanent
-- Global key per painted frame and eventually bloat the run or save.
local OUTBOX_SEQ = "mcm_material_paint_outbox_seq_v3"
local OUTBOX_ACK = "mcm_material_paint_outbox_ack_v3"
local OUTBOX_SLOT = "mcm_material_paint_outbox_slot_v3"
local OUTBOX_DROPPED = "mcm_material_paint_outbox_dropped_v3"
local OUTBOX_CAPACITY = 32
local MAX_POINTS = 24
local MAX_MATERIAL_NAME = 96
local MAX_COORDINATE = 100000000
-- WorldState does not exist while mod source files are being loaded. Reading a Global
-- here emits a native Lua error; merge the persisted sequence only on first publish.
local cached_sequence = 0

local function ew_enabled()
    if type(ModIsEnabled) ~= "function" then return false end
    local ok, enabled = pcall(ModIsEnabled, "quant.ew")
    return ok and enabled == true
end

local function finite_coordinate(value)
    value = tonumber(value)
    return value ~= nil and value == value and math.abs(value) <= MAX_COORDINATE
end

local function valid_material_name(value)
    return type(value) == "string" and value ~= "" and #value <= MAX_MATERIAL_NAME
        and string.match(value, "^[%w_%.%-]+$") ~= nil
end

local function sanitize_points(points)
    if type(points) ~= "table" or #points == 0 or #points > MAX_POINTS then return nil end
    local clean = {}
    for i = 1, #points do
        local point = points[i]
        if type(point) ~= "table" or not finite_coordinate(point[1]) or not finite_coordinate(point[2]) then
            return nil
        end
        clean[#clean + 1] = {
            math.floor(tonumber(point[1])),
            math.floor(tonumber(point[2])),
        }
    end
    return clean
end

local function encode_points(points)
    local parts = {}
    for i = 1, #points do
        parts[#parts + 1] = tostring(points[i][1]) .. "," .. tostring(points[i][2])
    end
    return table.concat(parts, ";")
end

local function decode_points(text)
    local points = {}
    if type(text) ~= "string" or text == "" then return nil end
    for pair in string.gmatch(text, "[^;]+") do
        if #points >= MAX_POINTS then return nil end
        local xs, ys = string.match(pair, "^(-?%d+),(-?%d+)$")
        if xs == nil or not finite_coordinate(xs) or not finite_coordinate(ys) then return nil end
        points[#points + 1] = { math.floor(tonumber(xs)), math.floor(tonumber(ys)) }
    end
    return #points > 0 and points or nil
end

local function encode_batch(material_name, solid, brush_index, points)
    return table.concat({
        material_name,
        solid and "1" or "0",
        tostring(brush_index),
        encode_points(points),
    }, "|")
end

local function decode_batch(batch)
    if type(batch) ~= "string" or batch == "" or #batch > 2048 then return nil end
    local material, solid_flag, brush_s, points_s = string.match(batch, "^([^|]*)|([01])|(%d+)|(.*)$")
    local brush_index = tonumber(brush_s)
    if not valid_material_name(material) or brush_index == nil or brush_index < 1 or brush_index > 5 then return nil end
    local points = decode_points(points_s)
    if points == nil then return nil end
    return {
        material_name = material,
        solid = solid_flag == "1",
        brush_index = math.floor(brush_index),
        points = points,
    }
end

local function slot_key(sequence)
    return OUTBOX_SLOT .. ":" .. tostring(((sequence - 1) % OUTBOX_CAPACITY) + 1)
end

local function read_slot(sequence)
    if sequence <= 0 then return nil end
    local stored = GlobalsGetValue(slot_key(sequence), "")
    if type(stored) ~= "string" or stored == "" then return nil end
    local stored_sequence, payload = string.match(stored, "^(%d+)#(.*)$")
    if tonumber(stored_sequence) ~= sequence then return nil end
    return payload
end

function sync.publish_batch(material_name, solid, brush_index, points)
    if not ew_enabled() or not valid_material_name(material_name) then return false end
    brush_index = math.floor(tonumber(brush_index) or 0)
    if brush_index < 1 or brush_index > 5 then return false end
    points = sanitize_points(points)
    if points == nil then return false end

    cached_sequence = math.max(cached_sequence, tonumber(GlobalsGetValue(OUTBOX_SEQ, "0")) or 0) + 1
    local payload = encode_batch(material_name, solid == true, brush_index, points)
    GlobalsSetValue(slot_key(cached_sequence), tostring(cached_sequence) .. "#" .. payload)

    local ack = tonumber(GlobalsGetValue(OUTBOX_ACK, "0")) or 0
    if cached_sequence - ack > OUTBOX_CAPACITY then
        local dropped = tonumber(GlobalsGetValue(OUTBOX_DROPPED, "0")) or 0
        GlobalsSetValue(OUTBOX_DROPPED, tostring(dropped + 1))
    end
    -- Publish the sequence last so the EW VM never observes a half-written slot.
    GlobalsSetValue(OUTBOX_SEQ, tostring(cached_sequence))
    return true
end

function sync.outbox_sequence()
    return tonumber(GlobalsGetValue(OUTBOX_SEQ, "0")) or 0
end

function sync.ack_sequence()
    return tonumber(GlobalsGetValue(OUTBOX_ACK, "0")) or 0
end

function sync.first_available_sequence(after_sequence)
    local newest = sync.outbox_sequence()
    local requested = math.max(0, math.floor(tonumber(after_sequence) or 0)) + 1
    local oldest = math.max(1, newest - OUTBOX_CAPACITY + 1)
    return math.max(requested, oldest), newest
end

function sync.read_outbox(sequence)
    sequence = math.floor(tonumber(sequence) or 0)
    return read_slot(sequence)
end

function sync.clear_outbox(sequence)
    sequence = math.floor(tonumber(sequence) or 0)
    if read_slot(sequence) ~= nil then GlobalsSetValue(slot_key(sequence), "") end
end

function sync.mark_ack(sequence)
    sequence = math.max(0, math.floor(tonumber(sequence) or 0))
    local current = sync.ack_sequence()
    if sequence > current then GlobalsSetValue(OUTBOX_ACK, tostring(sequence)) end
end

function sync.decode_batch(batch)
    return decode_batch(batch)
end

function sync.capacity() return OUTBOX_CAPACITY end
function sync.max_points() return MAX_POINTS end

METAMORPH_CREATIVE_MENU_EW_MATERIAL_PAINT_SYNC = sync
return sync
