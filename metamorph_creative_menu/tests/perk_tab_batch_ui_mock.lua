local root=assert(arg[1],"root required")
local native_dofile=dofile
local draw_index=0
local tile_mode="left"
local select_100=true
local right_down=false
local spawn_calls=0
local apply_calls=0
local queue_calls={}
local cancel_calls=0
local active=nil
local texts={}
local ui={
    ICON_STEP=20,EMPTY_SLOT="slot",audit=function() end,gui=function() return 1 end,
    tr=function(_,fallback) return fallback end,translated=function(v) return v end,
    white_text=function(_,_,text) texts[#texts+1]=tostring(text) end,
    wrapped_text=function(_,_,text) texts[#texts+1]=tostring(text) end,
    search_input=function(v) return v end,columns=function() return 4 end,scroll_height=function() return 90 end,
    begin_scroll_viewport=function(_,_,_,_,w,h) return {padding_left=2,state={offset=0},height=h,content_width=math.max(20,w-12)} end,
    scroll_y=function(_,y) return y end,end_scroll_viewport=function() end,search_status=function() end,
    rank_entries=function(_,entries) return entries end,resolve=function(p) return p end,dimensions=function() return 18,18 end,
    button=function(_,_,label)
        if label=="100" and select_100 then select_100=false; return true end
        if label=="CANCEL" and active~=nil and draw_index>=4 then return true end
        return false
    end,
    button_grid=function(items)
        for index,item in ipairs(items or {}) do
            if item.label=="100" and select_100 then select_100=false; return index end
            if item.label=="CANCEL" and active~=nil and draw_index>=4 then return index end
        end
        return nil
    end,
    tile=function()
        if tile_mode=="left" then return true,false,false end
        if tile_mode=="right" then return false,true,false end
        return false,false,false
    end,
}
local service={
    count=function() return 0 end,can_remove=function() return true end,
    spawn=function(_,perk) spawn_calls=spawn_calls+1; return true,"spawned",123 end,
    apply=function() apply_calls=apply_calls+1; return true,"applied" end,
    start_take_job=function(_,perk,amount) queue_calls[#queue_calls+1]={id=perk.id,amount=amount}; active={kind="take",perk_id=perk.id,total=amount,completed=0}; return true,"queued" end,
    job_status=function() return active end,
    consume_job_notice=function() return nil end,
    cancel_job=function() cancel_calls=cancel_calls+1; active=nil; return true end,
}
local catalog={all=function() return {{id="TEST",ui_name="Test",ui_description="Desc",ui_icon="perk.png",func=function() end}} end}
dofile=function(path)
    if path=="mods/metamorph_creative_menu/files/ui/runtime.lua" then return ui end
    if path=="mods/metamorph_creative_menu/files/features/perks/service.lua" then return service end
    if path=="mods/metamorph_creative_menu/files/features/perks/catalog.lua" then return catalog end
    return native_dofile(path)
end
GuiLayoutBeginVertical=function() end; GuiLayoutBeginHorizontal=function() end; GuiLayoutEnd=function() end
InputIsMouseButtonDown=function(code) return code==2 and right_down end
GamePrint=function() end

local tab=assert(native_dofile(root.."/files/ui/tabs/perks.lua"))
-- Select TAKE 100, but LMB must still spawn exactly one physical pickup.
draw_index=1; tile_mode="left"; tab.draw(1,220,180)
assert(spawn_calls==1 and apply_calls==0 and #queue_calls==0,"LMB did not remain a single physical spawn")
-- RMB uses the selected amount and queues rather than applying synchronously.
draw_index=2; tile_mode="right"; right_down=true; tab.draw(1,220,180)
assert(#queue_calls==1 and queue_calls[1].amount==100,"RMB did not queue selected TAKE amount")
assert(apply_calls==0 and spawn_calls==1,"mass TAKE created physical pickups or immediate apply")
-- A held RMB does not enqueue the same command again.
draw_index=3; tile_mode="right"; right_down=true; tab.draw(1,220,180)
assert(#queue_calls==1,"held RMB repeated batch command")
-- Progress is rendered and CANCEL terminates the current job.
draw_index=4; tile_mode="none"; right_down=false; tab.draw(1,220,180)
assert(cancel_calls==1 and active==nil,"CANCEL did not stop active job")
local saw_progress=false
for _,text in ipairs(texts) do if string.find(text,"0/100",1,true) then saw_progress=true end end
assert(saw_progress,"active batch progress was not rendered")
print("perk_tab_batch_ui=PASS take_selector=true lmb_single_pickup=true rmb_queue=true held_guard=true progress=true cancel=true")
