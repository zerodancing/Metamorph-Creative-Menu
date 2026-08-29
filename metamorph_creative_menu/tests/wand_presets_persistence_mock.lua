local root=assert(arg[1])
local native_dofile=dofile
local stored=''
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
ModSettingSet=function(key,value) stored=value; return true end

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
print('wand_presets_persistence=PASS immediate=true settings=true overwrite=true cache_reset=true legacy_v1=true delete=true')
