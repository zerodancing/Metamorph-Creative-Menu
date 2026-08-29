local root=assert(arg[1],"root required")
local native_dofile=dofile
local prefix="mods/metamorph_creative_menu/"

local target_path="data/entities/animals/test_creature.xml"
local target_icon="data/ui_gfx/animal_icons/test_creature.png"
local entries={
    {id="test_creature",path=target_path,category="ANIMALS",display_name="Test Creature",display_description="Test",icon=target_icon},
    {id="player",path="PLAYER",category="HUMANOIDS",display_name="Player",display_description="",icon="player.png",special="player"},
}

local audits,prints,source_calls,ghosts={},{},{},{}
local tile_actions={}
local tile_call=0
local panel_bounds={x=0,y=0,width=140,height=180}
local queued_result=nil
local drag_active=false
local active_payload=nil
local nearby_calls,world_calls,clone_calls,transform_calls={},{},{},{}

local ui={
    EMPTY_SLOT="data/ui_gfx/inventory/inventory_box.png",ICON_STEP=20,
    audit=function(event,detail) audits[#audits+1]={event=event,detail=detail} end,
    translated=function(value) return tostring(value or "") end,
    tr=function(_,fallback) return fallback end,
    resolve=function(path) return path end,
    entity_icon=function() return target_icon end,
    rank_entries=function(_,values) return values end,
    gui=function() return 1 end,
    white_text=function() end,
    button_grid=function() return nil end,
    button=function() return false end,
    wrapped_text=function() end,
    search_input=function(value) return value end,
    scroll_height=function() return 100 end,
    begin_scroll_viewport=function()
        return {padding_left=0,content_width=100,x=10,y=20,width=100,height=80}
    end,
    columns=function() return 5 end,
    scroll_y=function(_,value) return value end,
    tile=function(x,y)
        tile_call=tile_call+1
        local action=tile_actions[tile_call] or {}
        return action.clicked==true,action.right==true,action.hovered==true,x,y,18,18
    end,
    end_scroll_viewport=function() end,
    active_scroll_region=function() return nil end,
    panel_bounds=function() return panel_bounds end,
    drag_ghost=function(background,icon,x,y)
        ghosts[#ghosts+1]={background=background,icon=icon,x=x,y=y}
    end,
}

local drag_drop={
    take_result=function()
        local value=queued_result
        queued_result=nil
        return value
    end,
    source=function(id,payload,bounds,clip)
        source_calls[#source_calls+1]={id=id,payload=payload,bounds=bounds,clip=clip}
        return true
    end,
    active=function() return drag_active end,
    payload=function() return active_payload end,
    mouse_position=function() return 211,133 end,
}

local creature_service={
    spawn_near_player=function(player,path,offset_x,offset_y)
        nearby_calls[#nearby_calls+1]={player=player,path=path,offset_x=offset_x,offset_y=offset_y}
        return 501,"spawned"
    end,
    spawn_at=function(path,x,y)
        world_calls[#world_calls+1]={path=path,x=x,y=y}
        return 502,"spawned"
    end,
    compatibility_status=function() return "safe","test" end,
    transform_plan=function(path) return {target_path=path,mode="direct",reason="direct"} end,
}

local form_manager={
    exact_effect_path_for_target=function() return "effect.xml" end,
    prepare_exact_effect_paths=function() return true end,
    transform_creature=function(player,path)
        transform_calls[#transform_calls+1]={player=player,path=path}
        return true,"transformed"
    end,
    return_to_human=function() return true end,
}

local stubs={
    [prefix.."files/ui/runtime.lua"]=ui,
    [prefix.."files/ui/drag_drop.lua"]=drag_drop,
    [prefix.."files/features/forms/manager.lua"]=form_manager,
    [prefix.."files/features/creatures/ui_catalog.lua"]={
        collect=function() return entries end,
        warmup_step=function() return true,false end,
    },
    [prefix.."files/features/creatures/service.lua"]=creature_service,
    [prefix.."files/features/companion/player_avatar.lua"]={
        request_spawn=function(player,offset_x,offset_y)
            clone_calls[#clone_calls+1]={player=player,offset_x=offset_x,offset_y=offset_y}
            return true
        end,
    },
    [prefix.."files/platform/noita/action_bindings.lua"]={label=function() return "TAB" end},
}

dofile=function(path)
    if stubs[path]~=nil then return stubs[path] end
    if string.sub(path,1,#prefix)==prefix then return native_dofile(root.."/"..string.sub(path,#prefix+1)) end
    return native_dofile(path)
end

function ModDoesFileExist(path)
    return path==target_path or path==target_icon or path=="player.png"
end
function GuiLayoutBeginVertical() end
function GuiLayoutBeginHorizontal() end
function GuiLayoutEnd() end
function GamePrint(text) prints[#prints+1]=tostring(text) end

local tab=assert(native_dofile(root.."/files/ui/tabs/creatures.lua"))
local function draw()
    tile_call=0
    tab.draw(1,140,180)
    tile_actions={}
end
local function creature_payload()
    return {kind="catalog_creature",path=target_path,display_name="Test Creature",background=ui.EMPTY_SLOT,icon=target_icon}
end

-- Only ordinary creature cards become drag sources; the special PLAYER clone keeps its old click action.
draw()
assert(#source_calls==1,"creature catalog did not register exactly one ordinary-mob drag source")
local source=source_calls[1]
assert(source.id=="creatures.catalog."..target_path and source.payload.kind=="catalog_creature"
    and source.payload.path==target_path,"creature drag source payload changed")
assert(source.bounds.x==0 and source.bounds.y==0 and source.bounds.width==18 and source.bounds.height==18,
    "creature drag source did not use measured tile bounds")
assert(source.clip.x==10 and source.clip.y==20 and source.clip.width==100 and source.clip.height==80,
    "creature drag source did not preserve viewport clipping")

-- A short release is the sole owner of LMB spawn, even if GuiImageButton also reports a click.
queued_result={click=true,payload=creature_payload(),release_x=5,release_y=5,world_x=1,world_y=2}
tile_actions[1]={clicked=true}
draw()
assert(#nearby_calls==1 and nearby_calls[1].path==target_path,"short creature click did not spawn nearby exactly once")
assert(#world_calls==0,"short creature click also performed world placement")

-- A completed drag outside the menu creates one creature at the exact world cursor position.
queued_result={click=false,target=nil,payload=creature_payload(),release_x=200,release_y=150,world_x=777,world_y=-55}
draw()
assert(#world_calls==1 and world_calls[1].path==target_path and world_calls[1].x==777 and world_calls[1].y==-55,
    "creature drag did not preserve exact world coordinates")

-- Releasing over the menu or without a world position is a cancel/failure, never a hidden spawn.
queued_result={click=false,target=nil,payload=creature_payload(),release_x=100,release_y=100,world_x=900,world_y=900}
draw()
assert(#world_calls==1,"in-menu creature drag created a hidden creature")
local prints_before=#prints
queued_result={click=false,target=nil,payload=creature_payload(),release_x=200,release_y=150,world_x=nil,world_y=nil}
draw()
assert(#world_calls==1 and #prints==prints_before+1,"missing creature world coordinates were not handled as a visible failure")

-- Existing target ownership prevents a second world action, and the active drag uses the creature icon ghost.
queued_result={click=false,target="future.target",payload=creature_payload(),release_x=200,release_y=150,world_x=4,world_y=5}
draw()
assert(#world_calls==1,"creature drag executed twice after another target accepted it")
drag_active=true
active_payload=creature_payload()
draw()
drag_active=false
active_payload=nil
assert(#ghosts==1 and ghosts[1].icon==target_icon and ghosts[1].x==211 and ghosts[1].y==133,
    "creature drag ghost did not use the selected creature icon")

-- RMB transformation and the special PLAYER clone action remain separate from dragging.
tile_actions[1]={right=true}
draw()
assert(#transform_calls==1 and transform_calls[1].path==target_path,"RMB creature transformation regressed")
tile_actions[2]={clicked=true}
draw()
assert(#clone_calls==1 and clone_calls[1].player==1,"PLAYER clone LMB action regressed")

print("creature_drag_interaction=PASS source=true click_once=true exact_world=true in_menu_cancel=true missing_coords=true ghost=true rmb_transform=true player_clone=true")
