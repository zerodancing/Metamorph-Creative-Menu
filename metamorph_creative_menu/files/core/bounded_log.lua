-- Small filesystem boundary for persistent diagnostics.
-- The writer keeps a recent tail when the file reaches its size budget so crash
-- breadcrumbs survive without letting the mod directory grow forever.
local bounded_log = {}

local function open_file(path, mode)
    if type(io) ~= "table" or type(io.open) ~= "function" then
        return nil, "io.open unavailable; Unsafe mods permission is required"
    end
    return io.open(path, mode)
end

local function file_size(path)
    local file = open_file(path, "r")
    if file == nil then return 0 end
    local size = nil
    if type(file.seek) == "function" then
        local seek_ok, value = pcall(file.seek, file, "end")
        if seek_ok then size = tonumber(value) end
    end
    pcall(file.close, file)
    return size
end

function bounded_log.read_tail(path, max_bytes)
    local file = open_file(path, "r")
    if file == nil then return "" end
    local requested_bytes = math.max(0, tonumber(max_bytes) or 0)
    if requested_bytes > 0 and type(file.seek) == "function" then
        local size_ok, size = pcall(file.seek, file, "end")
        size = size_ok and tonumber(size) or nil
        if size ~= nil and size > requested_bytes then
            pcall(file.seek, file, "set", size - requested_bytes)
        else
            pcall(file.seek, file, "set", 0)
        end
    end
    local read_ok, contents = pcall(file.read, file, "*a")
    pcall(file.close, file)
    return read_ok and tostring(contents or "") or ""
end

function bounded_log.has_content(path)
    local size = file_size(path)
    if size ~= nil then return size > 0 end
    local file = open_file(path, "r")
    if file == nil then return false end
    local read_ok, value = pcall(file.read, file, 1)
    pcall(file.close, file)
    return read_ok and value ~= nil
end

local function compact(path, tail_bytes)
    local preserved_tail = bounded_log.read_tail(path, tail_bytes)
    local file, open_error = open_file(path, "w")
    if file == nil then return false, tostring(open_error or "truncate failed") end
    local marker = "\n# --- older diagnostics truncated; recent crash-recovery tail preserved ---\n"
    local write_ok, write_error = pcall(file.write, file, marker, preserved_tail)
    pcall(file.flush, file)
    pcall(file.close, file)
    if not write_ok then return false, tostring(write_error or "truncate write failed") end
    return true
end

function bounded_log.append(path, text, max_bytes, tail_bytes)
    local output = tostring(text or "")
    local size_budget = math.max(0, tonumber(max_bytes) or 0)
    local preserved_bytes = math.max(0, tonumber(tail_bytes) or 0)
    local current_size = file_size(path)

    if size_budget > 0 and current_size ~= nil and current_size + #output > size_budget then
        local compacted, compact_error = compact(path, math.min(preserved_bytes, size_budget))
        if not compacted then return false, compact_error end
    end

    local file, open_error = open_file(path, "a")
    if file == nil then return false, tostring(open_error or "io.open failed") end
    local write_ok, write_error = pcall(file.write, file, output)
    pcall(file.flush, file)
    pcall(file.close, file)
    if not write_ok then return false, tostring(write_error or "write failed") end
    return true
end

return bounded_log
