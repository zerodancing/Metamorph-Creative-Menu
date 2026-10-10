local root=assert(arg[1])
local native_dofile=dofile
local persistent={}
local removed={}
dofile=function(path)
 if path=='mods/metamorph_creative_menu/files/features/spells/catalog.lua' then
  return {load=function()return true end,by_id=function()return {LOCKED={spawn_requires_flag='card_unlock_test'},OPEN={}} end}
 end
 return native_dofile(path)
end
GameHasFlagPersistent=function(flag)return persistent[flag]==true end
RemoveFlagPersistent=function(flag)persistent[flag]=nil;removed[#removed+1]=flag end
CreateItemActionEntity=function(id)
 if id=='LOCKED' then persistent.card_unlock_test=true end
 return id=='FAIL' and 0 or 42
end
local factory=assert(native_dofile(root..'/files/features/spells/factory.lua'))
local entity=select(1,factory.create('LOCKED'))
assert(entity==42 and persistent.card_unlock_test~=true and removed[#removed]=='card_unlock_test','new unlock side effect was not reverted')
persistent.card_unlock_test=true
factory.create('LOCKED')
assert(persistent.card_unlock_test==true,'pre-existing unlock was removed')
assert(select(1,factory.create('FAIL'))==0,'failed creation changed result')
print('spell_factory_unlock=PASS new_flag_reverted=true existing_flag_preserved=true')
