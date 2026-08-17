-- Protocol-only placeholder for release builds. Slot 3 must remain registered even
-- when developer QA telemetry is disabled, otherwise every later EW RPC shifts.
local qa_reserved = {}

function qa_reserved.register(rpc, _common)
    rpc.opts_reliable()
    rpc.opts_everywhere()
    function rpc.sync_qa_state(...) end
end

function qa_reserved.update(_frame) end

return qa_reserved
