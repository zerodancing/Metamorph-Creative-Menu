local root = assert(arg[1], "root required")
local native_dofile = dofile
local tile_calls = 0
local error_labels = 0
local diagnostic_calls = 0
local tab_draw_calls = 0

local ui = {
    ICON_STEP=22,
    EMPTY_SLOT="empty.png",
    audit=function() end,
    bind=function() end,
    begin_frame=function() end,
    gui=function() return 1 end,
    tr=function(_, fallback) return fallback end,
    tile=function() tile_calls=tile_calls+1; return false,false end,
    button=function() return false end,
    pointer_handle=function() return false,false end,
    colored_text=function() end,
    white_text=function(_,_,text) if text == "This section could not be drawn" then error_labels=error_labels+1 end end,
    finish_auto_box=function() end,
    hovered=function() return false end,
}
local failing_tab = {draw=function() tab_draw_calls=tab_draw_calls+1; error("intentional tab regression probe") end}
local harmless_tab = {draw=function() end, warmup_step=function() return true end}
local stubs = {
    ["mods/metamorph_creative_menu/files/ui/runtime.lua"]=ui,
    ["mods/metamorph_creative_menu/files/platform/noita/player_locator.lua"]={get=function() return 1 end},
    ["mods/metamorph_creative_menu/files/platform/noita/input_guard.lua"]={actions_allowed=function() return true end, blocked=function() return false end, resume_serial=function() return 0 end},
    ["mods/metamorph_creative_menu/files/platform/noita/action_bindings.lua"]={update=function() end,consume=function() return false end,label=function() return '—' end},
    ["mods/metamorph_creative_menu/files/platform/noita/menu_inventory_guard.lua"]={
        controls_disabled=function() return false end,
        inventory_open=function() return true end,
        capture_scroll_selection=function() return nil end,
        restore_scroll_selection=function() end,
        acquire_manual_controls=function() return true end,
        release_manual_controls=function() return true end,
    },
}
local tab_paths = {
    "spells.lua","items.lua","materials.lua","perks.lua","creatures.lua","effects.lua","weather.lua","world_rules.lua","players.lua","controls.lua"
}
for index, name in ipairs(tab_paths) do
    stubs["mods/metamorph_creative_menu/files/ui/tabs/"..name] = index == 1 and failing_tab or harmless_tab
end

dofile = function(path)
    if stubs[path] ~= nil then return stubs[path] end
    local prefix="mods/metamorph_creative_menu/"
    if string.sub(path,1,#prefix)==prefix then return native_dofile(root.."/"..string.sub(path,#prefix+1)) end
    return native_dofile(path)
end

GUI_OPTION={NoPositionTween=1}
function GuiCreate() return 1 end
function GuiStartFrame() end
function GuiOptionsAdd() end
function GuiGetScreenDimensions() return 320,180 end
function GuiLayoutBeginVertical() end
function GuiLayoutBeginHorizontal() end
function GuiLayoutEnd() end
function GuiBeginAutoBox() end
function InputIsMouseButtonJustDown() return false end
function print() end
METAMORPH_CREATIVE_MENU_DIAGNOSTICS_CAPTURE=function() diagnostic_calls=diagnostic_calls+1 end

METAMORPH_CREATIVE_MENU_MENU_CONTROLLER=nil
local controller = assert(native_dofile(root.."/files/ui/menu_controller.lua"))
local ok1, err1 = pcall(controller.draw)
local ok2, err2 = pcall(controller.draw)
assert(ok1 and ok2, "tab runtime error escaped menu controller: "..tostring(err1 or err2))
assert(tab_draw_calls == 2, "active tab was not attempted on both frames")
assert(tile_calls == 20, "top tab bar stopped rendering after a tab error")
assert(error_labels == 2, "menu did not show bounded tab error fallback")
assert(diagnostic_calls == 1, "same persistent tab error should be reported once, not every frame")

print("menu_error_isolation=PASS header_survives=true error_contained=true")
