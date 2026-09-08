local root=assert(arg[1],"root required")
local native_dofile=dofile
local perk={id="TEST_PERK",ui_name="Test Perk",ui_description="Desc",ui_icon="perk.png",func=function() end}
local source_calls,ghosts,audits,prints={},{},{},{}
local nearby_calls,world_calls,apply_calls={},{},{}
local queued_result=nil
local drag_active=false
local active_payload=nil
local tile_action={}
local panel={x=0,y=0,width=140,height=180}
local ui={
 ICON_STEP=20,EMPTY_SLOT="slot",audit=function(e,d) audits[#audits+1]={e,d} end,gui=function() return 1 end,
 tr=function(_,fallback) return fallback end,translated=function(v) return v end,
 white_text=function() end,wrapped_text=function() end,search_input=function(v) return v end,search_status=function() end,
 scroll_height=function() return 90 end,columns=function() return 4 end,rank_entries=function(_,entries) return entries end,
 resolve=function(p) return p end,dimensions=function() return 18,18 end,
 button_grid=function() return nil end,
 begin_scroll_viewport=function() return {padding_left=0,content_width=100,x=10,y=20,width=100,height=80} end,
 scroll_y=function(_,y) return y end,end_scroll_viewport=function() end,
 tile=function(x,y)
   local a=tile_action; return a.clicked==true,a.right==true,a.hovered==true,x,y,18,18
 end,
 panel_bounds=function() return panel end,
 drag_ghost=function(bg,icon,x,y) ghosts[#ghosts+1]={bg=bg,icon=icon,x=x,y=y} end,
}
local service={
 count=function() return 0 end,can_remove=function() return true end,job_status=function() return nil end,consume_job_notice=function() return nil end,
 spawn=function(player,data) nearby_calls[#nearby_calls+1]={player=player,id=data.id}; return true,"spawned",71 end,
 spawn_at=function(data,x,y) world_calls[#world_calls+1]={id=data.id,x=x,y=y}; return true,"spawned",72 end,
 apply=function(player,data) apply_calls[#apply_calls+1]={player=player,id=data.id}; return true,"applied" end,
}
local drag_drop={
 take_result=function() local r=queued_result; queued_result=nil; return r end,
 source=function(id,payload,bounds,clip) source_calls[#source_calls+1]={id=id,payload=payload,bounds=bounds,clip=clip}; return true end,
 active=function() return drag_active end,
 payload=function() return active_payload end,
 mouse_position=function() return 211,133 end,
}
local catalog={all=function() return {perk} end}
dofile=function(path)
 if path=="mods/metamorph_creative_menu/files/ui/runtime.lua" then return ui end
 if path=="mods/metamorph_creative_menu/files/ui/drag_drop.lua" then return drag_drop end
 if path=="mods/metamorph_creative_menu/files/features/perks/service.lua" then return service end
 if path=="mods/metamorph_creative_menu/files/features/perks/catalog.lua" then return catalog end
 return native_dofile(path)
end
GuiLayoutBeginVertical=function() end; GuiLayoutBeginHorizontal=function() end; GuiLayoutEnd=function() end
InputIsMouseButtonDown=function() return false end
GamePrint=function(text) prints[#prints+1]=tostring(text) end
local tab=assert(native_dofile(root.."/files/ui/tabs/perks.lua"))
local function payload() return {kind="catalog_perk",id=perk.id,data=perk,display_name="Test Perk",background="slot",icon="perk.png"} end
local function draw() tab.draw(1,140,180); tile_action={} end

draw()
assert(#source_calls==1 and source_calls[1].payload.kind=="catalog_perk" and source_calls[1].payload.id==perk.id,
 "perk catalog did not register drag source")
assert(source_calls[1].bounds.width==18 and source_calls[1].clip.x==10,"perk drag source bounds/clip changed")

queued_result={click=true,payload=payload(),release_x=5,release_y=5,world_x=1,world_y=2}
tile_action.clicked=true
draw()
assert(#nearby_calls==1 and #world_calls==0,"short perk click did not remain exactly one nearby spawn")

queued_result={click=false,target=nil,payload=payload(),release_x=200,release_y=150,world_x=777,world_y=-55}
draw()
assert(#world_calls==1 and world_calls[1].x==777 and world_calls[1].y==-55,"perk drag lost exact world coordinates")

queued_result={click=false,target=nil,payload=payload(),release_x=100,release_y=100,world_x=999,world_y=999}
draw(); assert(#world_calls==1,"in-menu perk drag created a world perk")
local before_prints=#prints
queued_result={click=false,target=nil,payload=payload(),release_x=200,release_y=150,world_x=nil,world_y=nil}
draw(); assert(#world_calls==1 and #prints==before_prints+1,"missing perk world position was not a visible failure")

queued_result={click=false,target="future.target",payload=payload(),release_x=200,release_y=150,world_x=5,world_y=6}
draw(); assert(#world_calls==1,"perk drag executed after another target accepted release")

tile_action.right=true
draw(); assert(#apply_calls==1 and apply_calls[1].id==perk.id,"RMB TAKE regressed after perk drag support")

drag_active=true; active_payload=payload(); draw(); drag_active=false; active_payload=nil
assert(#ghosts==1 and ghosts[1].x==211 and ghosts[1].y==133,"perk drag ghost missing")
print("perk_drag_interaction=PASS source=true click_once=true exact_world=true in_menu_cancel=true missing_coords=true rmb_take=true ghost=true")
