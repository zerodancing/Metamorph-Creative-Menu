local root = assert(arg[1], "root required")
local native_dofile = dofile
local global_reads = 0

function GlobalsGetValue()
    global_reads=global_reads+1
    error("WorldState doesn't exist at the moment")
end

local runtime={enabled=function() return false end,mode=function() return "off" end}
dofile=function(path)
    if path=="mods/metamorph_creative_menu/files/integrations/ew/runtime.lua" then return runtime end
    local prefix="mods/metamorph_creative_menu/"
    if string.sub(path,1,#prefix)==prefix then return native_dofile(root.."/"..string.sub(path,#prefix+1)) end
    return native_dofile(path)
end

METAMORPH_CREATIVE_MENU_EW_MATERIAL_PAINT_SYNC=nil
METAMORPH_CREATIVE_MENU_WORLD_RULE_SYNC=nil
for _, relative in ipairs({
    "files/integrations/ew/material_paint_sync.lua",
    "files/integrations/ew/weather_sync.lua",
    "files/integrations/ew/world_items.lua",
    "files/integrations/ew/possession_retire.lua",
    "files/integrations/ew/world_rules_sync.lua",
}) do
    assert(native_dofile(root.."/"..relative), relative.." failed to load without WorldState")
end
assert(global_reads==0,"network module read Globals before WorldState existed")

io.write("startup_no_world_globals=PASS modules=5 global_reads=0\n")
