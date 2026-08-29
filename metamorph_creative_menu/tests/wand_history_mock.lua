local root=assert(arg[1])
local native_dofile=dofile
local frame=100
local state={version=2,stats={slots=2},mana=10,sprite_file='a.png',meta={name='A'},spells={}}
local apply_calls=0
local function clone(v)
 if type(v)~='table' then return v end
 local out={}; for k,x in pairs(v) do out[k]=clone(x) end; return out
end

dofile=function(path)
 if path=='mods/metamorph_creative_menu/files/features/wands/blueprints.lua' then
  return {
   capture=function(w) return clone(state),'ok' end,
   apply=function(player,w,bp) apply_calls=apply_calls+1; state=clone(bp); return true,'loaded' end,
  }
 end
 local prefix='mods/metamorph_creative_menu/'
 if string.sub(path,1,#prefix)==prefix then return native_dofile(root..'/'..string.sub(path,#prefix+1)) end
 return native_dofile(path)
end
GameGetFrameNum=function() return frame end
local history=assert(native_dofile(root..'/files/features/wands/history.lua'))

assert(history.perform(1,2,'mana +',function() state.mana=20; return true,'ok' end,{coalesce_key='mana',coalesce_frames=20})==true,'first edit failed')
frame=105
assert(history.perform(1,2,'mana ++',function() state.mana=30; return true,'ok' end,{coalesce_key='mana',coalesce_frames=20})==true,'second edit failed')
assert(history.can_undo(2) and history.undo_label(2)=='mana ++','coalesced undo record wrong')
assert(history.undo(1,2)==true and state.mana==10,'undo did not restore pre-coalesced value')
assert(history.can_redo(2) and history.redo(1,2)==true and state.mana==30,'redo did not restore final value')
-- A held/repeated numeric edit may fire every frame. It must remain one undo record rather
-- than filling the bounded history with dozens of nearly identical steps.
for index=1,100 do
 frame=106+index
 assert(history.perform(1,2,'held mana '..index,function() state.mana=30+index; return true,'ok' end,
  {coalesce_key='held_mana',coalesce_frames=45})==true,'held edit failed at '..index)
end
assert(history.undo(1,2)==true and state.mana==30,'held/repeated edits did not coalesce into one undo record')
assert(history.redo(1,2)==true and state.mana==130,'redo did not restore final held/repeated value')
local calls=apply_calls
assert(history.perform(1,2,'noop',function() return true,'ok' end)==true,'noop operation failed')
assert(history.undo_label(2)=='held mana 100','noop created history entry')
history.clear(2)
assert(not history.can_undo(2) and not history.can_redo(2),'history clear failed')
assert(apply_calls==calls,'history query/noop unexpectedly applied blueprint')
print('wand_history=PASS undo=true redo=true coalesce=true noop=true bounded_state=true')
