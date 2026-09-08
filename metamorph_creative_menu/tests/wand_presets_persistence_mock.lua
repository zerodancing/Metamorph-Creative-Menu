local root=assert(arg[1])
local native_dofile=dofile
local stored=''
local fail_setting_write=false
local current={version=2,stats={slots=3,mana_max=100},mana=50,sprite_file='a.png',meta={name='A'},spells={{action_id='A',slot=0,slot_y=0,permanent=false,uses_remaining=2,frozen=false}}}
local applied=nil
local function clone(v)
 if type(v)~='table' then return v end
 local out={}; for k,x in pairs(v) do out[k]=clone(x) end; return out
end

dofile=function(path)
 if path=='mods/metamorph_creative_menu/files/features/wands/blueprints.lua' then
  return {
   capture=function(w) return clone(current),'ok' end,
   apply=function(player,w,bp) applied=clone(bp); current=clone(bp); return true,'loaded' end,
  }
 end
 if path=='mods/metamorph_creative_menu/files/platform/noita/inventory_slots.lua' then return {} end
 if path=='mods/metamorph_creative_menu/files/features/wands/sync.lua' then return {} end
 if path=='mods/metamorph_creative_menu/files/integrations/ew/world_items.lua' then return {} end
 local prefix='mods/metamorph_creative_menu/'
 if string.sub(path,1,#prefix)==prefix then return native_dofile(root..'/'..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end
ModSettingGet=function(key) return stored end
ModSettingSet=function(key,value)
 if fail_setting_write then error('injected ModSettingSet failure') end
 stored=value; return true
end

local codec=assert(native_dofile(root..'/files/core/wand_blueprint_codec.lua'))
local function reload_presets()
 METAMORPH_CREATIVE_MENU_WAND_PRESETS=nil
 return assert(native_dofile(root..'/files/features/wands/presets.lua'))
end
local presets=reload_presets()
assert(presets.save(' Alpha ',2)==true,'initial save failed')
assert(string.find(stored,'MCM_PRESETS_V1',1,true)~=nil,'persistent wrapper missing')
local immediate=presets.all()
assert(#immediate==1 and immediate[1].name=='Alpha' and immediate[1].blueprint.meta.name=='A','new preset not visible immediately after save')

-- A settings write failure must not publish an unpersisted save into the session cache.
local before_failed_save_storage=stored
local before_failed_save=presets.all()
current.meta.name='Unsaved'; current.mana=11
fail_setting_write=true
local failed_save,failed_save_reason=presets.save('New',2)
fail_setting_write=false
assert(failed_save==false and failed_save_reason=='settings_write_failed','failed save reason changed')
assert(stored==before_failed_save_storage,'failed save changed persistent storage')
local after_failed_save=presets.all()
assert(#after_failed_save==#before_failed_save and after_failed_save[1].name==before_failed_save[1].name and after_failed_save[1].blueprint.meta.name==before_failed_save[1].blueprint.meta.name,'failed save mutated in-memory cache')

-- A settings write failure must likewise leave delete atomic in memory and storage.
local before_failed_delete_storage=stored
local before_failed_delete=presets.all()
fail_setting_write=true
local failed_delete,failed_delete_reason=presets.delete(1)
fail_setting_write=false
assert(failed_delete==false and failed_delete_reason=='settings_write_failed','failed delete reason changed')
assert(stored==before_failed_delete_storage,'failed delete changed persistent storage')
local after_failed_delete=presets.all()
assert(#after_failed_delete==#before_failed_delete and after_failed_delete[1].name==before_failed_delete[1].name and after_failed_delete[1].blueprint.meta.name==before_failed_delete[1].blueprint.meta.name,'failed delete mutated in-memory cache')

-- presets.all() must isolate every nested blueprint table from the internal cache.
local exposed=presets.all()
exposed[1].blueprint.meta.name='CallerMutation'
exposed[1].blueprint.spells[1].action_id='MUTATED_SPELL'
exposed[1].blueprint.stats.slots=999
local isolated=presets.all()
assert(isolated[1].blueprint.meta.name=='A','presets.all leaked nested meta table')
assert(isolated[1].blueprint.spells[1].action_id=='A','presets.all leaked nested spell record')
assert(isolated[1].blueprint.stats.slots==3,'presets.all leaked nested stats table')
assert(presets.load(1,1,2)==true and applied.meta.name=='A' and applied.spells[1].action_id=='A' and applied.stats.slots==3,'presets.load observed caller mutation from presets.all')

current.meta.name='Changed'; current.mana=7
presets=reload_presets()
local list=presets.all()
assert(#list==1 and list[1].name=='Alpha','preset did not survive cache reset')
assert(list[1].blueprint.meta.name=='A' and list[1].blueprint.mana==50 and list[1].blueprint.version==2,'V2 blueprint did not persist')
assert(presets.load(1,1,2)==true and applied~=nil and applied.meta.name=='A','persistent preset load failed')

current.meta.name='Overwrite'; current.mana=99
assert(presets.save('alpha',2)==true,'case-insensitive overwrite save failed')
presets=reload_presets(); list=presets.all()
assert(#list==1 and list[1].blueprint.meta.name=='Overwrite' and list[1].blueprint.mana==99,'same-name preset duplicated instead of overwriting')

-- Existing MCM_PRESETS_V1 data can contain the older wand blueprint payload. Loading it and
-- saving another preset must preserve the user's legacy record rather than resetting storage.
local legacy=table.concat({'MCM_WAND_V1','mana=n10','sprite=sold.png','stat:slots=n2','spell\tOLD_SPELL\t0\t0\t\t0'},'\n')
stored='MCM_PRESETS_V1\n'..codec.escape('Legacy')..'\t'..codec.escape(legacy)
presets=reload_presets(); list=presets.all()
assert(#list==1 and list[1].name=='Legacy' and list[1].blueprint.version==1,'legacy MCM_PRESETS_V1 record failed to load')
assert(list[1].blueprint.mana==10 and list[1].blueprint.stats.slots==2 and list[1].blueprint.spells[1].action_id=='OLD_SPELL','legacy blueprint data changed on load')
current={version=2,stats={slots=4},mana=88,sprite_file='new.png',meta={name='New'},spells={}}
assert(presets.save('New',2)==true,'save beside legacy record failed')
presets=reload_presets(); list=presets.all()
assert(#list==2 and list[1].name=='Legacy' and list[2].name=='New','legacy preset was lost when storage was rewritten')
assert(list[1].blueprint.mana==10 and list[1].blueprint.spells[1].action_id=='OLD_SPELL','legacy preset payload was not preserved')

assert(presets.delete(2)==true,'delete failed')
presets=reload_presets(); list=presets.all()
assert(#list==1 and list[1].name=='Legacy','delete removed the wrong preset')

-- Preset names keep the 80-byte storage cap without splitting a UTF-8 codepoint.
stored=''
presets=reload_presets()
local long_cjk=string.rep('漢',27)
assert(presets.save(long_cjk,2)==true,'UTF-8 preset save failed')
list=presets.all()
assert(#list==1 and list[1].name==string.rep('漢',26) and #list[1].name==78,'preset name split a UTF-8 codepoint')
print('wand_presets_persistence=PASS immediate=true settings=true atomic_failure=true isolated_blueprints=true overwrite=true cache_reset=true legacy_v1=true delete=true')
