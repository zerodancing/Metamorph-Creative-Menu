local root=assert(arg[1], 'root required')
local original_dofile=dofile
local mode_click, clicked_name, right_name=nil,nil,nil
local rendered, labels, events={}, {}, {}
local active=true
local ui={ICON_STEP=20,EMPTY_SLOT='slot',audit=function() end,gui=function() return 1 end,
 tr=function(_,fallback) return fallback end,translated=function(v) return ({['$ordinary']='Ordinary',['$earth']='Earth essence',['$greed']='Greed'})[v] or v or '' end,
 white_text=function(_,_,v) labels[#labels+1]=v end,wrapped_text=function() end,
 search_input=function(v) return v end,scroll_height=function() return 90 end,
 columns=function() return 4 end,search_status=function() end,
 rank_entries=function(_,entries) return entries end,resolve=function(p) return p end,
 dimensions=function() return 18,18 end,
 button_grid=function(items)
  for _,item in ipairs(items) do labels[#labels+1]=item.label end
  if items[1].label=='ADD' then local result=mode_click; mode_click=nil; return result end
 end,
 begin_scroll_viewport=function() return {padding_left=2,content_width=200} end,
 scroll_y=function(_,y) return y end,end_scroll_viewport=function() end,
 tile=function(_,_,_,icon,_,name)
  rendered[#rendered+1]={name=name,icon=icon}
  return name==clicked_name,name==right_name,true
 end,
}
local states={}
function states.list()
 if not active then return {} end
 return {{id='essence_air',name_key='$earth',description_key='Earth description',
  icon='earth.png',count=2},{id='greed_curse',name_key='$greed',description_key='Curse',icon='greed.png',count=1}}
end
function states.remove_one(_,id) events[#events+1]='one:'..id; return true end
function states.remove(_,id) events[#events+1]='all:'..id; active=false; return true end
local service={count=function() return 1 end,can_remove=function(perk)
 assert(perk.id=='ORDINARY','essence sent to perk inverse system'); return true end,
 job_status=function() return nil end,consume_job_notice=function() return nil end,
 remove_one=function(_,perk) events[#events+1]='perk:'..perk.id; return true end}
dofile=function(path)
 if path:match('/ui/runtime.lua$') then return ui end
 if path:match('/ui/drag_drop.lua$') then return {take_result=function() end,source=function() end,active=function() return false end} end
 if path:match('/perks/service.lua$') then return service end
 if path:match('/perks/non_perk_states.lua$') then return states end
 if path:match('/perks/catalog.lua$') then return {all=function() return {{id='ORDINARY',ui_name='$ordinary',ui_description='Description',ui_icon='perk.png'}} end} end
 return original_dofile(path)
end
GuiLayoutBeginVertical=function() end; GuiLayoutEnd=function() end
InputIsMouseButtonDown=function() return false end; GamePrint=function() end
local tab=original_dofile(root..'/files/ui/tabs/perks.lua')
local function draw()
 rendered,labels={},{}; tab.draw(1,220,180)
 for _,label in ipairs(labels) do
  assert(label~='ESSENCES / CURSES' and not label:find('REMOVE:',1,true),'separate removal UI remained')
 end
end
draw(); assert(#rendered==1 and rendered[1].name=='Ordinary','state leaked into ADD: '..#rendered..' '..tostring(rendered[1] and rendered[1].name))
mode_click=2; draw(); assert(#rendered==3,'active states missing from REMOVE grid')
assert(rendered[2].icon=='earth.png','essence icon requires a hover to load')
clicked_name='Earth essence'; draw(); clicked_name=nil
assert(events[#events]=='one:essence_air','LMB did not remove one essence')
clicked_name='Ordinary'; draw(); clicked_name=nil
assert(events[#events]=='perk:ORDINARY','normal perk removal changed')
right_name='Earth essence'; draw(); right_name=nil
assert(events[#events]=='all:essence_air','RMB did not remove all essence copies')
draw(); assert(#rendered==1,'removed state remained in grid')
mode_click=1; draw(); assert(#rendered==1,'ADD catalogue changed after removal')
print('perk_states_grid=PASS add_clean=true standard_grid=true left_one=true right_all=true normal_perks=true')
