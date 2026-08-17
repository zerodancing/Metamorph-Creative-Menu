local root = assert(arg[1], "root required")
local stored = {}
local frame = 321

function GameGetFrameNum() return frame end
function GlobalsSetValue(key, value) stored[key] = tostring(value) end

METAMORPH_CREATIVE_MENU_EW_COMPANION_REQUEST = nil
local request = assert(dofile(root .. "/files/integrations/ew/companion_request.lua"))

local ok, reason = request.enqueue(48, -12)
assert(ok == true and reason == "queued", "companion request was not queued")
assert(stored.mcm_companion_request_x_v1 == "48", "x offset mailbox mismatch")
assert(stored.mcm_companion_request_y_v1 == "-12", "y offset mailbox mismatch")
assert(stored.mcm_companion_request_seq_v1 == "321:1", "first request sequence mismatch")

frame = 322
request.enqueue(nil, nil)
assert(stored.mcm_companion_request_x_v1 == "32", "default x offset changed")
assert(stored.mcm_companion_request_y_v1 == "-4", "default y offset changed")
assert(stored.mcm_companion_request_seq_v1 == "322:2", "request sequence did not advance")

print("companion_request=PASS mailbox_owned_by_integration=true")
