local root = assert(arg[1], "root required")
local bounded_log = dofile(root .. "/files/core/bounded_log.lua")
local path = root .. "/tests/.bounded_log_test.tmp"
os.remove(path)

local ok, err = bounded_log.append(path, "oldest-entry\n" .. string.rep("A", 120) .. "\n", 256, 64)
assert(ok, tostring(err))
ok, err = bounded_log.append(path, "middle-entry\n" .. string.rep("B", 120) .. "\n", 256, 64)
assert(ok, tostring(err))
ok, err = bounded_log.append(path, "latest-entry\n", 256, 64)
assert(ok, tostring(err))

local file = assert(io.open(path, "r"))
local data = file:read("*a")
file:close()
os.remove(path)

assert(#data <= 256, "bounded log exceeded budget: " .. tostring(#data))
assert(string.find(data, "latest-entry", 1, true), "latest diagnostics were lost")
assert(string.find(data, "older diagnostics truncated", 1, true), "compaction marker missing")
assert(not string.find(data, "oldest-entry", 1, true), "oldest diagnostics were not compacted")
print("bounded_log=PASS bytes=" .. tostring(#data))
