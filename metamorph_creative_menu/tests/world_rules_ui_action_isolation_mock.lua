local root=assert(arg[1],"root required")
local native_dofile=dofile
local tile_calls=0
local white_labels={}
local step_calls=0
local click_once=true
local diagnostics=0
local prints=0
local service={
    can_edit=function() return true,"singleplayer" end,
    has_overrides=function() return false end,
    rules=function() return {{id="relations",label="REL",description="DESC",choices={{native=true},{value=1}}}} end,
    choice_label=function() return "NATIVE" end,
    is_overridden=function() return false end,
    supported=function() return true end,
    step=function()
        step_calls=step_calls+1
        error("intentional Rules mutation failure")
    end,
    reset=function() return true,"ok" end,
}
local ui={
    ICON_STEP=20, EMPTY_SLOT="empty.png",
    audit=function() end,
    gui=function() return 1 end,
    tr=function(_,fallback) return fallback end,
    white_text=function(_,_,text) white_labels[#white_labels+1]=tostring(text) end,
    button=function() return false end,
    search_input=function(value) return value end,
    columns=function() return 4 end,
    scroll_height=function() return 100 end,
    mark_hovered=function() end,
    begin_scroll_viewport=function(_,_,_,_,width,height) return {content_width=math.max(20,(tonumber(width) or 100)-12),padding_left=2,padding_top=2,state={offset=0},height=height} end,
    scroll_y=function(_,y) return y end, end_scroll_viewport=function() end,
    confirm_button=function() return false end,
    report_error_once=function(_,_,reason,scope)
        if scope=="ui.rules.action" and string.find(tostring(reason),"intentional Rules mutation failure",1,true) then
            diagnostics=diagnostics+1; prints=prints+1
        end
        return true
    end,
    clear_error_notice=function() end,
    rank_entries=function(_,entries) return entries end,
    search_status=function() end,
    matches_search=function() return true end,
    tile=function()
        tile_calls=tile_calls+1
        if click_once then click_once=false; return true,false end
        return false,false
    end,
}
local stubs={
    ["mods/metamorph_creative_menu/files/ui/runtime.lua"]=ui,
    ["mods/metamorph_creative_menu/files/features/world_rules/service.lua"]=service,
}
dofile=function(path)
    if stubs[path] ~= nil then return stubs[path] end
    local prefix="mods/metamorph_creative_menu/"; if string.sub(path,1,#prefix)==prefix then return native_dofile(root.."/"..string.sub(path,#prefix+1)) end
    return native_dofile(path)
end
function GuiLayoutBeginVertical() end
function GuiLayoutBeginHorizontal() end
function GuiLayoutEnd() end
function GuiBeginScrollContainer() end
function GuiEndScrollContainer() end
function GuiGetPreviousWidgetInfo() return false,false,false end

local tab=assert(native_dofile(root.."/files/ui/tabs/world_rules.lua"))
local ok1,err1=pcall(tab.draw,nil,220,180)
local ok2,err2=pcall(tab.draw,nil,220,180)
assert(ok1 and ok2,"Rules action exception escaped tab draw: "..tostring(err1 or err2))
assert(step_calls==1,"probe did not execute exactly one failing Rules mutation")
assert(tile_calls==2,"Rules grid stopped drawing after a mutation error")
assert(diagnostics==1,"Rules mutation exception was not reported to diagnostics")
for _,text in ipairs(white_labels) do
    assert(not string.find(text,"RULE ERROR:",1,true),"Rules tab kept a stale permanent error row")
end
assert(prints==1,"Rules error was not reported exactly once to the transient user channel")

io.write("world_rules_ui_action_isolation=PASS draw_survives=true second_frame=true transient_error=true\n")
