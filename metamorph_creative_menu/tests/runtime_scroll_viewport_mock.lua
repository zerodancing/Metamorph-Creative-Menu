local root = assert(arg[1], "root required")
local native_dofile = dofile
local prefix = "mods/metamorph_creative_menu/"
dofile = function(path)
    if string.sub(path, 1, #prefix) == prefix then
        return native_dofile(root .. "/" .. string.sub(path, #prefix + 1))
    end
    return native_dofile(path)
end

-- Noita boundary stubs only. The real runtime.lua, pointer.lua, scroll_model.lua and
-- asset/localization adapters are loaded below.
GUI_OPTION = {Layout_NoLayouting=1}
local wheel = 0
local calls = {}
local stack = {}
local last_info = {false, 0, 0, 1, 1}
local content_by_id = {}

local function note(name, ...)
    calls[#calls + 1] = {name=name,args={...}}
end
local function info(hovered, x, y, w, h)
    last_info = {hovered == true, tonumber(x) or 0, tonumber(y) or 0, tonumber(w) or 1, tonumber(h) or 1}
end

GuiBeginScrollContainer = function(_, id, x, y, w, h)
    note("begin_scroll", id, x, y, w, h)
    stack[#stack + 1] = {id=id,x=x or 0,y=y or 0,w=w,h=h,layout_y=0}
    info(true, x, y, w, h)
end
GuiEndScrollContainer = function()
    note("end_scroll")
    table.remove(stack)
end
GuiLayoutBeginLayer = function() note("begin_layer") end
GuiLayoutEndLayer = function() note("end_layer") end
GuiLayoutBeginVertical = function(_, x, y)
    note("begin_vertical", x, y)
    local top = stack[#stack]
    if top then top.layout_y = tonumber(y) or 0 end
end
GuiLayoutEnd = function() note("layout_end") end
GuiColorSetForNextWidget = function() end
GuiZSetForNextWidget = function() end
GuiOptionsAddForNextWidget = function() end
GuiImage = function(_, _, x, y, _, _, sx, sy)
    note("image", x, y, sx, sy)
    info(false, x, y, math.max(1, (tonumber(sx) or 1) * 24), math.max(1, (tonumber(sy) or 1) * 4))
end
GuiText = function(_, x, y, text)
    note("text", x, y, text)
    local top = stack[#stack]
    if top then
        local h = 5
        local desired = tonumber(content_by_id[top.id]) or 0
        -- Runtime computes content height relative to container_y + padding_top - offset.
        local sentinel_y = top.y + top.layout_y + desired - h
        info(false, 0, sentinel_y, 3, h)
    else
        info(false, x, y, 3, 5)
    end
end
GuiGetPreviousWidgetInfo = function()
    return 0, 0, last_info[1], last_info[2], last_info[3], last_info[4], last_info[5]
end
GuiGetImageDimensions = function() return 24, 4 end
GuiGetTextDimensions = function(_, text) return #tostring(text or "") * 5, 5 end
GuiGetScreenDimensions = function() return 320, 240 end
InputIsMouseButtonJustDown = function(code)
    if code == 4 then return wheel < 0 end
    if code == 5 then return wheel > 0 end
    return false
end
InputIsMouseButtonDown = function() return false end
InputIsKeyDown = function() return false end
InputIsKeyJustDown = function() return false end
InputIsKeyJustUp = function() return false end
GameGetFrameNum = function() return 1 end
GameGetRealWorldTimeSinceStarted = function() return 1 end
ModTextFileGetContent = function(path)
    if path == prefix .. "translations.csv" then
        local h = assert(io.open(root .. "/translations.csv", "rb")); local s=h:read("*a"); h:close(); return s
    end
    return ""
end
ModDoesFileExist = function() return false end
GameTextGetTranslatedOrNot = function(key) return key end

METAMORPH_CREATIVE_MENU_UI_RUNTIME = nil
METAMORPH_CREATIVE_MENU_SCROLL_MODEL = nil
METAMORPH_CREATIVE_MENU_POINTER = nil
local ui = assert(native_dofile(root .. "/files/ui/runtime.lua"))
ui.bind(1)

local function index_of(name, start_at)
    for i = start_at or 1, #calls do if calls[i].name == name then return i end end
    return nil
end

-- Real begin/end sequence, measured content geometry and actual content width. The
-- production regression here is engine-specific: a layout layer opened after the scroll
-- container resets its children to the screen origin. The wrapper must therefore leave
-- contents in the native container coordinate space.
calls = {}; content_by_id[501] = 180; wheel = 1; ui.begin_frame()
local ctx = ui.begin_scroll_viewport("probe.long", 501, 7, 9, 120, 64,
    {padding_left=3,padding_right=4,padding_top=5,padding_bottom=6})
assert(ctx.content_width == 120 - 3 - 4 - 8, "content width ignored padding/scrollbar")
assert(ctx.viewport_height == 64 - 5 - 6, "viewport height ignored vertical padding")
local offset, maximum, content_height = ui.end_scroll_viewport(ctx)
assert(content_height == 180, "runtime did not measure logical content height from sentinel")
assert(maximum == 180 - (64 - 5 - 6), "runtime maximum offset is wrong")
assert(offset == 0, "native viewport retained a detached manual offset")
local a=index_of("begin_scroll"); local c=index_of("begin_vertical")
local d=index_of("layout_end"); local f=index_of("end_scroll")
assert(a and c and d and f and a < c and c < d and d < f,
    "runtime native scroll GUI call order changed")
assert(index_of("begin_layer") == nil and index_of("end_layer") == nil,
    "scroll contents were detached from the native container coordinate space")
assert(ui.scroll_y(ctx, 17) == 22, "free-layout content did not stay relative to container padding")

-- Responsive viewport geometry is derived from actual width at all supported menu sizes.
for _, width in ipairs({96,160,280}) do
    local id=600+width; content_by_id[id]=240; wheel=0; ui.begin_frame()
    local responsive=ui.begin_scroll_viewport("responsive."..tostring(width),id,0,0,width,70)
    assert(responsive.content_width==width-2-2-8,"responsive content width escaped padding/scrollbar at "..tostring(width))
    ui.end_scroll_viewport(responsive)
end

-- Native scrolling owns the wheel and the wrapper never applies a second offset.
content_by_id[502] = 90; wheel = 1; ui.begin_frame()
local short = ui.begin_scroll_viewport("probe.short", 502, 0, 0, 100, 50)
local short_offset, short_maximum = ui.end_scroll_viewport(short)
content_by_id[503] = 900; wheel = 1; ui.begin_frame()
local long = ui.begin_scroll_viewport("probe.very_long", 503, 0, 0, 100, 50)
local long_offset, long_maximum = ui.end_scroll_viewport(long)
assert(short_offset == 0 and long_offset == 0 and short_maximum < long_maximum,
    "runtime applied a second manual scroll offset over native scrolling")

-- Nested viewports keep balanced native container calls without introducing a layout layer.
content_by_id[510] = 300; content_by_id[511] = 200; wheel = 1; ui.begin_frame()
local parent = ui.begin_scroll_viewport("nested.parent", 510, 0, 0, 140, 80)
local child = ui.begin_scroll_viewport("nested.child", 511, 0, 0, 100, 40)
local child_offset = select(1, ui.end_scroll_viewport(child))
local parent_offset = select(1, ui.end_scroll_viewport(parent))
assert(child_offset == 0 and parent_offset == 0, "nested native viewport applied a manual wheel offset")
assert(index_of("begin_layer") == nil and index_of("end_layer") == nil,
    "nested viewport detached contents from its native container")

print("runtime_scroll_viewport=PASS gui_order=true native_coordinates=true no_detached_layer=true geometry=true widths=96_160_280 nested_balanced=true")
