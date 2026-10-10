local root=assert(arg[1])
local native_dofile=dofile
local radii={}
local target_module={
 target_under_cursor=function(player,radius)
  radii[#radii+1]=radius
  if radius==96 then return 99 end
  return 0
 end,
 is_creature=function() return true end,
 transform_plan=function(path) return path,'possession' end,
}
local form_manager={
 is_human_ready=function() return true end,
 current_player=function() return 1 end,
 prepare_exact_effect_paths=function() return true end,
 transform_creature=function() return true end,
 return_to_human=function() return true end,
 session_target=function() return nil end,
}
local ew_runtime={mode=function() return 'client' end}
local retirement={retire_without_death_side_effects=function() end}
local ew_retirement={is_owned_locally=function() return true end,queue_remote=function() end}
dofile=function(path)
 if path=='mods/metamorph_creative_menu/files/features/forms/manager.lua' then return form_manager end
 if path=='mods/metamorph_creative_menu/files/integrations/ew/runtime.lua' then return ew_runtime end
 if path=='mods/metamorph_creative_menu/files/features/possession/targeting.lua' then return target_module end
 if path=='mods/metamorph_creative_menu/files/features/possession/retirement.lua' then return retirement end
 if path=='mods/metamorph_creative_menu/files/integrations/ew/possession_retire.lua' then return ew_retirement end
 local prefix='mods/metamorph_creative_menu/'
 if string.sub(path,1,#prefix)==prefix then return native_dofile(root..'/'..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end
local alive={[1]=true,[99]=true}
EntityGetIsAlive=function(entity) return alive[entity]==true end
EntityGetFilename=function(entity) return entity==99 and 'data/entities/animals/sheep.xml' or '' end
EntityGetName=function(entity) return entity==99 and 'sheep' or '' end
EntityGetTransform=function(entity) if entity==99 then return 100,200 end return 10,20 end
EntitySetTransform=function() end
EntityGetFirstComponentIncludingDisabled=function() return 0 end
ComponentGetValue2=function() return 0 end
ComponentSetValue2=function() end
ModDoesFileExist=function() return true end
GameGetFrameNum=function() return 42 end
EntityHasTag=function() return false end

local possession=assert(native_dofile(root..'/files/features/possession/service.lua'))
local ok,reason=possession.possess_under_cursor(1)
assert(ok and reason=='pending',tostring(reason))
assert(#radii==2 and radii[1]==48 and radii[2]==96,'network-safe fallback radii changed')
print('possession_client_fallback=PASS primary=48 fallback=96')
