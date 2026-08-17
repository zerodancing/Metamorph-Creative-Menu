local bridge_common = {}

local ERROR_SEQ = "mcm_world_rules_rpc_error_seq_v1"
local ERROR_VALUE = "mcm_world_rules_rpc_error_v1"
local error_sequence = tonumber(GlobalsGetValue(ERROR_SEQ, "0")) or 0

function bridge_common.clean(value)
    local result = tostring(value or "")
    return result:gsub("[\t\r\n]", " ")
end

function bridge_common.report_error(code, detail)
    error_sequence = error_sequence + 1
    GlobalsSetValue(ERROR_SEQ, tostring(error_sequence))
    GlobalsSetValue(ERROR_VALUE, bridge_common.clean(code) .. ":" .. bridge_common.clean(detail))
end

function bridge_common.finite_number(value)
    return type(value) == "number" and value == value and math.abs(value) < 100000000
end

return bridge_common
