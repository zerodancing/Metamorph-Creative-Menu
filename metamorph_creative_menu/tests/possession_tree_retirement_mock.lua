local root=assert(arg[1],'root required')
local native_dofile=dofile

local entity_tree={
    root=function(entity) return entity==11 and 10 or entity end,
    walk=function(entity,visitor)
        if entity==10 then visitor(10); visitor(11); visitor(12) else visitor(entity) end
    end,
}
dofile=function(path)
    if path=='mods/metamorph_creative_menu/files/platform/noita/entity_tree.lua' then return entity_tree end
    local prefix='mods/metamorph_creative_menu/'
    if string.sub(path,1,#prefix)==prefix then return native_dofile(root..'/'..string.sub(path,#prefix+1)) end
    return native_dofile(path)
end

local alive={[10]=true,[11]=true,[12]=true}
local moved=nil
local removed={}
local disabled={}
local killed={}
local comps={[10]={101,102},[11]={111},[12]={121}}
local types={[101]='LuaComponent',[102]='DamageModelComponent',[111]='LuaComponent',[121]='SpriteComponent'}
EntityGetIsAlive=function(entity) return alive[entity]==true end
EntitySetTransform=function(entity,x,y) moved={entity,x,y} end
EntityGetAllComponents=function(entity) return comps[entity] or {} end
ComponentGetTypeName=function(component) return types[component] or '' end
EntityRemoveComponent=function(entity,component) removed[#removed+1]={entity,component} end
EntitySetComponentIsEnabled=function(entity,component,value) disabled[#disabled+1]={entity,component,value} end
EntityKill=function(entity) killed[#killed+1]=entity; alive[entity]=false end

local retirement=assert(native_dofile(root..'/files/features/possession/retirement.lua'))
assert(retirement.retire_without_death_side_effects(11)==true,'multipart child retirement failed')
assert(moved and moved[1]==10,'multipart possession did not move the creature root out of play')
assert(#killed==1 and killed[1]==10,'multipart possession killed clicked child instead of full local root')
local removed_seen={}
for _,entry in ipairs(removed) do removed_seen[entry[1]..':'..entry[2]]=true end
assert(removed_seen['10:101'] and removed_seen['11:111'], 'multipart possession did not suppress Lua death scripts across the tree')
local disabled_seen={}
for _,entry in ipairs(disabled) do disabled_seen[entry[1]..':'..entry[2]]=entry[3] end
assert(disabled_seen['10:102']==false and disabled_seen['12:121']==false,
    'multipart possession did not disable non-Lua components across the tree')

print('possession_tree_retirement=PASS clicked_child_to_root=true whole_tree_suppressed=true')
