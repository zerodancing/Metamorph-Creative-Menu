local root = assert(arg[1], "root required")
local patches = assert(loadfile(root .. "/files/integrations/ew/resilience_patches.lua"))()

-- Minimal, syntactically valid fixture containing the current Entangled Worlds
-- world_sync.lua anchors.  Real Windows installs can expose this source through Noita's
-- VFS with CRLF even though the repository uses LF; both forms must patch identically.
local fixture = [[local world_sync = {}
local iter_slow_2 = 0
local function send_chunks(cx, cy)
    local str = "chunk"
    if cx ~= nil then
        if str ~= nil then
            net.proxy_bin_send(KEY_WORLD_FRAME, str)
        end
    end
end
local int = 4 -- ctx.proxy_opt.world_sync_interval
local function get_all_chunks() end
function world_sync.on_world_update()
    local px, py = EntityGetTransform(ctx.my_player.entity)
    local cx, cy = 0, 0
    local pos_data = "0"
    local ocx, ocy = math.floor(px / CHUNK_SIZE), math.floor(py / CHUNK_SIZE)
    local n = 0
    if true then
        if ctx.spectating_over_peer_id ~= nil and ctx.spectating_over_peer_id ~= ctx.my_id then
            if GameGetFrameNum() % 3 ~= 2 then
                get_all_chunks(cx, cy, pos_data, 16, false)
            else
                get_all_chunks(ocx, ocy, pos_data, 16, true)
            end
        else
            wait = GameGetFrameNum() + 30
        end
    end
end

local PixelRun_const_ptr = ffi.typeof("struct PixelRun const*")
function world_sync.handle_world_data(datum)
    local grid_world = world_ffi.get_grid_world()
end
return world_sync
]]

local function verify(source, label)
    local patched, count = patches.patch_world_sync_source(source, true)
    assert(count == 6, label .. " source did not apply all world-sync edits")
    assert(string.find(patched, "mcm_poly_world_sync_v3", 1, true), label .. " marker missing")
    assert(string.find(patched, "mcm_note_poly_chunk", 1, true), label .. " trail capture missing")
    assert(string.find(patched, "mcm_drain_trail", 1, true), label .. " trail drain missing")
    assert(string.find(patched, "net.proxy_bin_send(KEY_WORLD_END", 1, true),
        label .. " injected trail frame is not terminated")
    assert(string.find(patched, "mcm_trail_count", 1, true), label .. " bounded ring queue missing")
    assert(string.find(patched, "mcm_world_sync_trail_dropped_v1", 1, true), label .. " drop metric missing")
    assert(string.find(patched, "table.remove(mcm_trail_queue, 1)", 1, true) == nil,
        label .. " queue still shifts the whole backlog")
    assert(string.find(patched, "mcm_recv_chunks = mcm_recv_chunks + 1", 1, true), label .. " receive metrics missing")
    assert(string.find(patched, "\r", 1, true) == nil, label .. " patch did not canonicalize line endings")
    local compiled, failure = load(patched, "@patched_world_sync.lua")
    assert(compiled ~= nil, label .. " patched source is invalid: " .. tostring(failure))
end

verify(fixture, "LF")
verify((string.gsub(fixture, "\n", "\r\n")), "CRLF")

local incompatible = "local iter_slow_2 = 0\r\n-- incompatible EW source\r\n"
local unchanged, count = patches.patch_world_sync_source(incompatible)
assert(count == 0 and unchanged == incompatible, "partial patch modified incompatible source")

local release_patched, release_count = patches.patch_world_sync_source(fixture, false)
assert(release_count == 6 and string.find(release_patched, "local EWCM_METRICS_ENABLED = false", 1, true),
    "release world-sync patch did not disable telemetry")

print("ew_world_sync_patch=PASS lf=true crlf=true all_or_nothing=true")
