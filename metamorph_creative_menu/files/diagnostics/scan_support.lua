if type(METAMORPH_CREATIVE_MENU_DIAGNOSTIC_SCAN_SUPPORT) == "table" then return METAMORPH_CREATIVE_MENU_DIAGNOSTIC_SCAN_SUPPORT end

local scan_support = {}
local logger = dofile("mods/metamorph_creative_menu/files/diagnostics/logger.lua")
local one_line = logger.one_line

local function severity_counter(report, level)
    if level == "PASS" then report.pass = report.pass + 1
    elseif level == "WARN" then report.warn = report.warn + 1
    elseif level == "FAIL" then report.fail = report.fail + 1
    else report.info = report.info + 1 end
end

function scan_support.add(report, level, code, details)
    level = level == "PASS" and "PASS" or level == "WARN" and "WARN" or level == "FAIL" and "FAIL" or "INFO"
    code = one_line(code)
    details = one_line(details or "")
    severity_counter(report, level)
    report.rows[#report.rows + 1] = string.format("[%s] %s%s", level, code, details ~= "" and (" " .. details) or "")
end

function scan_support.sample_list(values, max_count)
    local out = {}
    max_count = math.max(1, tonumber(max_count) or 8)
    for index, value in ipairs(values or {}) do
        if index > max_count then break end
        out[#out + 1] = one_line(value)
    end
    if #(values or {}) > max_count then out[#out + 1] = "+" .. tostring(#values - max_count) .. " more" end
    return table.concat(out, ",")
end

function scan_support.finite(value)
    return type(value) == "number" and value == value and math.abs(value) < 1000000000
end

function scan_support.safe_module(report, field, path)
    local ok, result = pcall(dofile, path)
    if ok and type(result) == "table" then
        report.modules[field] = result
        return result
    end
    scan_support.add(report, "FAIL", "module." .. tostring(field), "load_error=" .. tostring(result))
    return nil
end

function scan_support.component_count(entity, component_type)
    local ok, values = pcall(EntityGetComponentIncludingDisabled, entity, component_type)
    return ok and type(values) == "table" and #values or 0
end

function scan_support.component_enabled_count(entity, component_type)
    local ok, values = pcall(EntityGetComponentIncludingDisabled, entity, component_type)
    if not ok or type(values) ~= "table" then return 0, 0 end
    local enabled = 0
    for _, component in ipairs(values) do
        local ok_enabled, is_enabled = pcall(ComponentGetIsEnabled, component)
        if ok_enabled and is_enabled == true then enabled = enabled + 1 end
    end
    return enabled, #values
end

METAMORPH_CREATIVE_MENU_DIAGNOSTIC_SCAN_SUPPORT = scan_support
return scan_support
