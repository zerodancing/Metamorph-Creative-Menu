local root=assert(arg[1])
local frame=100
local world_component=10
local values={[world_component]={damage_flash_multiplier=1.5,mFlashAlpha=0.7}}
GameGetWorldStateEntity=function() return 1 end
GameGetFrameNum=function() return frame end
EntityGetFirstComponentIncludingDisabled=function(entity,component_type)
 if entity==1 and component_type=='WorldStateComponent' then return world_component end
end
ComponentGetValue2=function(component,field) return values[component] and values[component][field] end
ComponentSetValue2=function(component,field,value) values[component][field]=value end

local flash=assert(loadfile(root..'/files/features/forms/transform_flash.lua'))()
flash.suppress(5)
assert(values[world_component].damage_flash_multiplier==0,'flash was not suppressed')
frame=103
flash.restore(false)
assert(values[world_component].damage_flash_multiplier==0,'suppression ended too early')
-- A later owner may legitimately change the same world-rule field. Restore must not
-- overwrite that value merely because this form session once owned the field.
frame=106
values[world_component].damage_flash_multiplier=2.25
flash.restore(false)
assert(values[world_component].damage_flash_multiplier==2.25,'external multiplier was overwritten')
-- A new suppression should capture and restore the new baseline.
flash.suppress(3)
assert(values[world_component].damage_flash_multiplier==0)
frame=110
flash.restore(false)
assert(values[world_component].damage_flash_multiplier==2.25,'new baseline was not restored')
print('form_transform_flash=PASS external_owner_preserved=true baseline_restored=true')
