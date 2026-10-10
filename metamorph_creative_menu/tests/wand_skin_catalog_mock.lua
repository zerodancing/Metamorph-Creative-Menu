local root=assert(arg[1])
local native_dofile=dofile
local catalog={{category='WANDS',path='child.xml',name='Child wand',icon='icon.png'}}
local files={
 ['child.xml']=[[<Entity><Base file="base.xml"></Base><AbilityComponent sprite_file="child_ability.png"></AbilityComponent><SpriteComponent _tags="item" image_file="child_image.png" offset_x="11" offset_y="12"></SpriteComponent></Entity>]],
 ['base.xml']=[[<Entity><AbilityComponent sprite_file="base.png"></AbilityComponent><SpriteComponent _tags="item" image_file="base.png" offset_x="1" offset_y="2"></SpriteComponent><HotspotComponent _tags="shoot_pos" offset.x="7" offset.y="8"></HotspotComponent></Entity>]],
}
dofile=function(path)
 if path=='mods/metamorph_creative_menu/files/features/items/catalog.lua' then return catalog end
 local prefix='mods/metamorph_creative_menu/'
 if string.sub(path,1,#prefix)==prefix then return native_dofile(root..'/'..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end
ModTextFileGetContent=function(path) return files[path] or '' end
local skins=assert(native_dofile(root..'/files/features/wands/skins.lua'))
local entries=skins.entries()
assert(#entries==1,'skin catalog size wrong')
local e=entries[1]
assert(e.sprite_file=='child_ability.png' and e.image_file=='child_image.png' and e.offset_x==11 and e.offset_y==12,'local skin override failed')
assert(e.tip_x==7 and e.tip_y==8,'inherited shoot tip missing')
print('wand_skin_catalog=PASS inheritance=true geometry=true')
