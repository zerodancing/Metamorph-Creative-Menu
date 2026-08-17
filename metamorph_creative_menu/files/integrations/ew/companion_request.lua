if type(METAMORPH_CREATIVE_MENU_EW_COMPANION_REQUEST) == "table" then
    return METAMORPH_CREATIVE_MENU_EW_COMPANION_REQUEST
end

local companion_request = {}

local REQUEST_SEQUENCE_KEY = "mcm_companion_request_seq_v1"
local REQUEST_OFFSET_X_KEY = "mcm_companion_request_x_v1"
local REQUEST_OFFSET_Y_KEY = "mcm_companion_request_y_v1"
local DEFAULT_OFFSET_X = 32
local DEFAULT_OFFSET_Y = -4

local local_request_sequence = 0

local function current_frame()
    if type(GameGetFrameNum) ~= "function" then return 0 end
    local ok, frame_number = pcall(GameGetFrameNum)
    return ok and tonumber(frame_number) or 0
end

function companion_request.enqueue(offset_x, offset_y)
    if type(GlobalsSetValue) ~= "function" then return false, "globals_unavailable" end

    local_request_sequence = local_request_sequence + 1
    GlobalsSetValue(REQUEST_OFFSET_X_KEY, tostring(tonumber(offset_x) or DEFAULT_OFFSET_X))
    GlobalsSetValue(REQUEST_OFFSET_Y_KEY, tostring(tonumber(offset_y) or DEFAULT_OFFSET_Y))
    GlobalsSetValue(
        REQUEST_SEQUENCE_KEY,
        tostring(current_frame()) .. ":" .. tostring(local_request_sequence)
    )
    return true, "queued"
end

METAMORPH_CREATIVE_MENU_EW_COMPANION_REQUEST = companion_request
return companion_request
