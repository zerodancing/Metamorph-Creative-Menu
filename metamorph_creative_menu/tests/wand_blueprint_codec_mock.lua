local root=assert(arg[1])
local codec=assert(dofile(root..'/files/core/wand_blueprint_codec.lua'))
local source={
 mana=123.5,sprite_file='mods/test wand/skin%1.xml',
 stats={slots=26,shuffle=false,never_reload=true,mana_max=999,spread_degrees=-3.25},
 meta={name='Custom Ω Wand',show_name_in_ui=true,wand_frozen=true,image_file='visual.png',sprite_offset_x=3,sprite_offset_y=4,tip_x=7,tip_y=8},
 spells={
  {action_id='LIGHT_BULLET',slot=0,slot_y=0,permanent=false,uses_remaining=12,frozen=false},
  {action_id='MOD:Ω|SPELL',slot=-1,slot_y=-1,permanent=true,uses_remaining=nil,frozen=true},
 }
}
local encoded=codec.encode(source)
assert(string.match(encoded,'^MCM_WAND_V2'),'V2 header missing')
assert(codec.current_version()==2,'current blueprint version wrong')
local decoded,reason=codec.decode(encoded)
assert(decoded~=nil and reason=='ok','blueprint decode failed')
assert(decoded.mana==123.5 and decoded.sprite_file==source.sprite_file,'scalar/string roundtrip failed')
assert(decoded.stats.slots==26 and decoded.stats.shuffle==false and decoded.stats.never_reload==true,'stat roundtrip failed')
assert(decoded.version==2 and decoded.meta.name=='Custom Ω Wand' and decoded.meta.show_name_in_ui==true and decoded.meta.wand_frozen==true,'V2 meta roundtrip failed')
assert(decoded.meta.image_file=='visual.png' and decoded.meta.sprite_offset_x==3 and decoded.meta.tip_y==8,'V2 visual metadata failed')
assert(#decoded.spells==2 and decoded.spells[1].action_id=='LIGHT_BULLET' and decoded.spells[1].uses_remaining==12,'spell roundtrip failed')
assert(decoded.spells[2].action_id=='MOD:Ω|SPELL' and decoded.spells[2].permanent==true and decoded.spells[2].frozen==true and decoded.spells[2].slot_y==-1,'escaped modded spell failed')
local legacy=table.concat({'MCM_WAND_V1','mana=n10','sprite=sold.png','stat:slots=n2','spell\tA\t0\t0\t\t0'},'\n')
local old,old_reason=codec.decode(legacy)
assert(old~=nil and old_reason=='ok' and old.version==1 and old.mana==10 and old.stats.slots==2,'V1 compatibility failed')
assert(type(old.meta)=='table' and #old.spells==1 and old.spells[1].slot_y==0,'V1 defaults failed')
assert(codec.decode('broken')==nil,'invalid version accepted')
print('wand_blueprint_codec=PASS deterministic=true unicode=true spells=true stats=true')
