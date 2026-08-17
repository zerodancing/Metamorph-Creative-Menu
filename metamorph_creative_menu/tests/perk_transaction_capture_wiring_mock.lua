local root = assert(arg[1], "root required")
local native_dofile = dofile
local start_calls, stop_calls = 0, 0

METAMORPH_CREATIVE_MENU_PERK_TRANSACTIONS = nil

dofile = function(path)
    if path == "mods/metamorph_creative_menu/files/features/perks/transactions/global_journal.lua" then
        return {
            start_capture = function(token, environment)
                start_calls = start_calls + 1
                assert(type(token) == "table" and token.id == 7, "token was not forwarded")
                assert(type(environment) == "table" and environment.marker == true, "environment was not forwarded")
                return true
            end,
            stop_capture = function(token)
                stop_calls = stop_calls + 1
                assert(type(token) == "table" and token.id == 7, "stop token was not forwarded")
                return true
            end,
        }
    end
    local prefix = "mods/metamorph_creative_menu/"
    if string.sub(path, 1, #prefix) == prefix then
        return native_dofile(root .. "/" .. string.sub(path, #prefix + 1))
    end
    return native_dofile(path)
end

local transactions = assert(native_dofile(root .. "/files/features/perks/transactions.lua"))
local token = {id=7}
assert(transactions.start_capture(token, {marker=true}) == true, "global journal start_capture is not wired")
transactions.stop_capture(token)
assert(start_calls == 1 and stop_calls == 1, "capture delegation count changed")
print("perk_transaction_capture_wiring=PASS lexical_dependency_bound=true")
