local root=assert(arg[1])
local engine=assert(dofile(root..'/files/core/search_engine.lua'))

local function match(query,...)
 local fields={...}
 return engine.matches(query,fields)
end

assert(engine.normalize('ЁЖИК')=='ежик','Cyrillic case/yo folding failed')
assert(engine.normalize('Über Łódź façade')=='uber lodz facade','Latin accent folding failed')
assert(match('огнен','Огненный шар','Fireball'),'Russian substring failed')
assert(match('fireball','Огненный шар','Fireball'),'English alias failed')
assert(match('firball','Fireball'),'one-edit typo tolerance failed')
assert(match('teleport bolt','Teleporting Cast Bolt'),'multi-token search failed')
assert(match('wand_good','data/entities/items/wands/wand_good.xml'),'technical separator search failed')
assert(match('火球','火球术','Fireball'),'CJK literal search failed')
assert(not match('fire -ball','Fireball'),'negative token failed')
assert(not match('xyz','Fireball'),'unrelated query matched')
print('search_engine=PASS multilingual=true english_alias=true accents=true typos=true negatives=true')
