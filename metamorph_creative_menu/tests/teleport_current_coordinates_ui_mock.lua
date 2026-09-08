local root=tostring(arg[1] or ".")
local old_dofile=dofile
local rendered={}
local ui={}
function ui.gui() return 1 end
function ui.tr(key,fallback) if key=="$mcm_teleport_current_coordinates" then return "CURRENT" end return fallback or key end
function ui.wrapped_text(_,_,text,_) rendered[#rendered+1]=tostring(text) end
function ui.colored_text() end
function ui.white_text() end
function ui.scroll_height() return 300 end
function ui.begin_scroll_viewport() return {content_width=200} end
function ui.end_scroll_viewport() end
function ui.button_grid() return nil end
function ui.text_input(value) return value end
function ui.button() return false end

local tools={}
function tools.has_pending_teleport() return false end
function tools.visible_players() return {} end
function tools.position(entity) if entity==1 then return 12.34,-56.78 end return 0,0 end
function tools.locations() return {} end
function tools.teleport_position() error("teleport should not fire") end
function tools.teleport_location() error("location should not fire") end
function tools.teleport_to() error("remote should not fire") end
function tools.bring_to_me() error("bring should not fire") end

dofile=function(path)
    if path=="mods/metamorph_creative_menu/files/ui/runtime.lua" then return ui end
    if path=="mods/metamorph_creative_menu/files/features/player_tools/service.lua" then return tools end
    local prefix="mods/metamorph_creative_menu/"
    if string.sub(path,1,#prefix)==prefix then return old_dofile(root.."/"..string.sub(path,#prefix+1)) end
    return old_dofile(path)
end
function GuiLayoutBeginVertical() end
function GuiLayoutEnd() end
function GuiLayoutBeginHorizontal() end

local tab=dofile("mods/metamorph_creative_menu/files/ui/tabs/players.lua")
tab.draw(1,220,400)
local joined=table.concat(rendered,"\n")
assert(string.find(joined,"X 12.3   Y %-56.8"),"current coordinate line missing: "..joined)
assert(not string.find(joined,"CURRENT",1,true),"redundant coordinate label remained")
print("teleport_current_coordinates_ui=PASS live_position=true formatted=true")
