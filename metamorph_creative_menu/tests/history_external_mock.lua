local root=assert(arg[1])
local native_dofile=dofile
local state={version=2,mana=10,spells={{entity=101,id='A'}}}
local applies=0
local function clone(v) if type(v)~='table' then return v end local o={} for k,x in pairs(v) do o[k]=clone(x) end return o end
dofile=function(path)
 if path=='mods/metamorph_creative_menu/files/features/wands/blueprints.lua' then return {
  capture=function() return clone(state),'ok' end,
  apply=function(_,_,bp) applies=applies+1; state=clone(bp); return true,'loaded' end,
 } end
 local prefix='mods/metamorph_creative_menu/'
 if string.sub(path,1,#prefix)==prefix then return native_dofile(root..'/'..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end
GameGetFrameNum=function() return 10 end
METAMORPH_CREATIVE_MENU_WAND_HISTORY=nil
local history=assert(native_dofile(root..'/files/features/wands/history.lua'))
assert(history.perform(1,2,'edit',function() state.mana=20; return true,'ok' end)==true)
-- Simulate an external card transfer after the history record was created.
state.spells={}; state.external_owner=999
local ok,why=history.undo(1,2)
assert(ok==false and why=='stale_history','stale undo was not rejected')
assert(applies==0 and #state.spells==0 and state.external_owner==999,'stale undo recreated/destroyed externally moved card state')
assert(not history.can_undo(2) and not history.can_redo(2),'stale history chain was not invalidated')
-- Redo has the same precondition in the opposite direction.
state={version=2,mana=10,spells={{entity=201,id='B'}}}; applies=0
assert(history.perform(1,3,'edit2',function() state.mana=30; return true end)==true)
assert(history.undo(1,3)==true and state.mana==10)
local after_normal_undo=applies
state.spells={}; state.external_owner=777
ok,why=history.redo(1,3)
assert(ok==false and why=='stale_history' and applies==after_normal_undo,'stale redo mutated wand')
print('history_external=PASS undo_guard=true redo_guard=true no_external_card_mutation=true')
