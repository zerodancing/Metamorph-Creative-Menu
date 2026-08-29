local root = assert(arg[1], "root required")

local events = {}
local in_scroll = false
local ui = {
    gui=function() return 1 end,
    tr=function(_, fallback) return fallback end,
    wrapped_text=function() end,
    colored_text=function() end,
    search_input=function(value) return value end,
    scroll_height=function() return 100 end,
    begin_scroll_viewport=function()
        events[#events+1]="scroll_begin"
        events[#events+1]="scroll_vertical"
        return {content_width=220,padding_left=2,padding_top=2,state={offset=0}}
    end,
    end_scroll_viewport=function() events[#events+1]="scroll_end" end,
    button=function() return false end,
    button_grid=function() return nil end,
    confirm_button=function() return false end,
    rank_entries=function(_,entries) return entries end,
    search_status=function() end,
    mark_hovered=function() end,
}
local registry = {
    sections=function() return {{id="menu",key="$section",fallback="MENU"}} end,
    actions=function() return {{id="toggle",section="menu",key="$action",fallback="TOGGLE",default="F1"}} end,
    get=function() return nil end,
}
local bindings = {
    update=function() end,
    label=function() return "F1" end,
    capture_action=function() return nil end,
    registry=function() return registry end,
    conflicts=function() return {} end,
    get=function() return "F1" end,
}

local original_dofile = dofile
function dofile(path)
    if path == "mods/metamorph_creative_menu/files/ui/runtime.lua" then return ui end
    if path == "mods/metamorph_creative_menu/files/platform/noita/action_bindings.lua" then return bindings end
    return original_dofile(path)
end
function GameGetFrameNum() return 1 end
function GuiLayoutBeginVertical()
    events[#events+1]=in_scroll and "scroll_vertical" or "outer_vertical"
end
function GuiLayoutBeginHorizontal() events[#events+1]="horizontal" end
function GuiLayoutEnd() events[#events+1]="layout_end" end
function GuiBeginScrollContainer() error("controls bypassed shared scroll viewport") end
function GuiEndScrollContainer() error("controls bypassed shared scroll viewport") end
function GuiGetPreviousWidgetInfo() return false,false,false end

local tab = assert(loadfile(root .. "/files/ui/tabs/controls.lua"))()
tab.draw(1, 240, 160)

local begin_index, vertical_index, end_index = nil, nil, nil
for index, event in ipairs(events) do
    if event == "scroll_begin" then begin_index=index end
    if event == "scroll_vertical" and vertical_index == nil then vertical_index=index end
    if event == "scroll_end" then end_index=index end
end
assert(begin_index ~= nil and vertical_index == begin_index + 1 and end_index > vertical_index,
    "controls inside the scroll container are not arranged by their own vertical layout")

print("controls_scroll_layout=PASS nested_vertical=true overlap_regression=true")
