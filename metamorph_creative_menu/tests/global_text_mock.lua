local root = assert(arg[1], "root required")
local native_dofile = dofile
local global_text = assert(native_dofile(root .. "/files/core/global_text.lua"))

local function valid_encoded(value)
    assert(type(value) == "string", "diagnostic encoder did not return string")
    local index = 1
    while index <= #value do
        local byte = string.byte(value, index)
        assert(byte >= 32 and byte <= 126, "diagnostic output contained non-printable/non-ASCII byte")
        assert(byte ~= 34 and byte ~= 38 and byte ~= 60 and byte ~= 62 and byte ~= 92,
            "diagnostic output contained unsafe literal ASCII")
        if byte == 37 then
            local hex = string.sub(value, index + 1, index + 2)
            assert(#hex == 2 and string.match(hex, "^[0-9A-F][0-9A-F]$"), "diagnostic output ended in partial %HH")
            index = index + 3
        else
            index = index + 1
        end
    end
end

assert(global_text.encode_diagnostic(nil) == "", "nil diagnostic was not empty")
assert(global_text.encode_diagnostic("plain ASCII: / [] () _-+=!?,.;") == "plain ASCII: / [] () _-+=!?,.;",
    "safe ASCII changed")

local dangerous = "quote\" nul\0 cr\r lf\n tab\t <>&\\% Ж🔥"
local encoded = global_text.encode_diagnostic(dangerous)
valid_encoded(encoded)
for _, token in ipairs({"%22","%00","%0D","%0A","%09","%3C","%3E","%26","%5C","%25","%D0%96","%F0%9F%94%A5"}) do
    assert(string.find(encoded, token, 1, true), "missing diagnostic escape " .. token)
end
assert(global_text.encode_diagnostic('%', 2) == '', 'partial percent escape crossed byte limit')
assert(global_text.encode_diagnostic('%', 3) == '%25', 'exact percent escape limit failed')
assert(global_text.encode_diagnostic('%A', 4) == '%25A', 'escape plus ASCII boundary failed')
assert(global_text.encode_diagnostic(string.char(0xC0,0xAF,0xFF)) == '%C0%AF%FF', 'malformed bytes were not deterministic')
local huge = global_text.encode_diagnostic(string.rep('x', 10001))
assert(#huge == 512 and huge == string.rep('x',512), 'default 512-byte diagnostic bound failed')

local globals = {}
function GlobalsGetValue(key, fallback) return globals[key] or fallback end
function GlobalsSetValue(key, value) globals[key] = tostring(value) end
dofile = function(path)
    if path == "mods/metamorph_creative_menu/files/core/global_text.lua" then return global_text end
    return native_dofile(path)
end
local common = assert(native_dofile(root .. "/files/integrations/ew/bridge/common.lua"))
common.report_error('rpc"<&%', 'bad\\\nЖ🔥' .. string.rep('z', 10000))
local stored = assert(globals.mcm_world_rules_rpc_error_v1, 'bridge diagnostic Global missing')
valid_encoded(stored)
assert(#stored <= 512 and string.find(stored, '%22', 1, true) and string.find(stored, '%0A', 1, true),
    'bridge diagnostic Global did not use bounded encoder')
dofile = native_dofile

local function source(path)
    local file = assert(io.open(root .. '/' .. path, 'rb'))
    local text = file:read('*a'); file:close(); return text
end
assert(string.find(source('init.lua'), 'global_text.encode_diagnostic', 1, true), 'init runtime diagnostic not wired to encoder')
assert(string.find(source('files/integrations/ew/bridge/materials.lua'), 'common.encode_diagnostic', 1, true), 'material diagnostic not wired to encoder')
assert(string.find(source('files/integrations/ew/bootstrap.lua'), 'common.encode_diagnostic', 1, true), 'perk runtime guard failure not wired to encoder')
assert(string.find(source('files/integrations/ew/resilience.lua'), 'global_text.encode_diagnostic', 1, true), 'EW resilience status not wired to encoder')

print('global_text=PASS ascii_only=true escapes=true malformed=true bounded=true bridge=true sites=true')
