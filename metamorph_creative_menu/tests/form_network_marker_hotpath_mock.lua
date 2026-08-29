local root=assert(arg[1], 'root required')
local native_dofile=dofile
local current_player=1
local frame=100
local add_tag_calls=0
local add_storage_calls=0
local metadata_writes=0
local runtime_updates=0
local storage_by_entity={}
local fail_storage_once_entity3=true

METAMORPH_CREATIVE_MENU_FORM_MANAGER=nil
local stubs={
 ['mods/metamorph_creative_menu/files/platform/noita/patcher_bridge.lua']={get=function() return {SerializeEntity=function() return 'human' end,CrossCallAdd=function() end} end},
 ['mods/metamorph_creative_menu/files/platform/noita/player_locator.lua']={get=function() return current_player end},
 ['mods/metamorph_creative_menu/files/platform/noita/keycodes.lua']={resolve=function() return 43 end},
 ['mods/metamorph_creative_menu/files/features/forms/profile.lua']={get=function() return {} end},
 ['mods/metamorph_creative_menu/files/features/forms/runtime.lua']={reset=function() end,update=function() runtime_updates=runtime_updates+1 end,family=function() return '' end,draw_health=function() end},
 ['mods/metamorph_creative_menu/files/features/forms/exact_effects.lua']={effect_path=function() return 'effect.xml' end,prepare=function() return 1 end,invalidate_failed_target=function() end,default_duration_frames=function() return 1000 end,prepare_from_catalog=function() return 1 end,runtime_target=function(path) return path end,prepared_count=function() return 1 end},
 ['mods/metamorph_creative_menu/files/features/forms/player_authority.lua']={switch=function() return true end},
 ['mods/metamorph_creative_menu/files/features/forms/transform_flash.lua']={suppress=function() end,restore=function() end},
 ['mods/metamorph_creative_menu/files/features/forms/corpse_service.lua']={detach=function() return true end,update=function() end},
 ['mods/metamorph_creative_menu/files/features/forms/human_restore.lua']={protect_player=function() end,polymorph_effect_components=function() return {} end,serialized_backup_from_effects=function() end,deserialize_backup=function() return 0 end},
 ['mods/metamorph_creative_menu/files/integrations/ew/form_death_channel.lua']={register=function() return true end},
}
dofile=function(path)
 if stubs[path]~=nil then return stubs[path] end
 local prefix='mods/metamorph_creative_menu/'
 if string.sub(path,1,#prefix)==prefix then return native_dofile(root..'/'..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end
function ModDoesFileExist() return true end
function EntityGetIsAlive(id) return id==1 or id==2 or id==3 or id==99 end
function EntityHasTag(id,tag) return (id==2 or id==3) and tag=='polymorphed_player' end
function EntityGetTransform() return 10,20 end
function GameGetFrameNum() return frame end
function LoadGameEffectEntityTo() current_player=2; return 99 end
function EntityAddTag(id,tag) if tag=='metamorph_creative_menu_network_form' then add_tag_calls=add_tag_calls+1 end end
function EntityAddComponent2(id,typ,data)
 if typ=='VariableStorageComponent' then
  add_storage_calls=add_storage_calls+1
  if id==3 and fail_storage_once_entity3 then fail_storage_once_entity3=false; return 0 end
  storage_by_entity[id]=800+id; return 800+id
 end
 return 0
end
function EntityGetFirstComponentIncludingDisabled(id,typ,tag)
 if id==99 and typ=='GameEffectComponent' then return 77 end
 if (id==2 or id==3) and typ=='VariableStorageComponent' and tag=='metamorph_creative_menu_network_form' then return storage_by_entity[id] or 0 end
 return 0
end
function ComponentSetValue2(component,field,value)
 if (component==802 or component==803) and (field=='name' or field=='value_string') then metadata_writes=metadata_writes+1 end
end
function ComponentGetValue2() return 0 end
function print() end

local manager=assert(native_dofile(root..'/files/features/forms/manager.lua'))
assert(manager.transform_creature(1,'data/entities/animals/test.xml',nil,false,{})==true,'transform failed')
assert(add_tag_calls==1 and add_storage_calls==1 and metadata_writes==2,'initial network marker was not written exactly once')
frame=101; manager.update()
frame=102; manager.update()
assert(runtime_updates==2,'form runtime was not updated')
assert(add_tag_calls==1 and add_storage_calls==1 and metadata_writes==2,'network metadata was rewritten on steady-state frames')
current_player=3
frame=103; manager.update()
assert(add_tag_calls==2 and add_storage_calls==2 and metadata_writes==2,'failed replacement marker attempt was incorrectly treated as committed')
frame=104; manager.update()
assert(add_tag_calls==3 and add_storage_calls==3 and metadata_writes==4,'replacement form metadata did not retry after transient creation failure')
frame=105; manager.update()
assert(add_tag_calls==3 and add_storage_calls==3 and metadata_writes==4,'replacement form metadata was rewritten after successful retry')
io.write('form_network_marker_hotpath=PASS event_driven=true replacement_remarked=true transient_retry=true\n')
