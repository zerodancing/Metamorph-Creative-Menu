local root=assert(arg[1])
local alive={[1]=true,[2]=true}
EntityGetIsAlive=function(entity) return alive[entity]==true end

local authority=assert(loadfile(root..'/files/features/forms/player_authority.lua'))()

local registered={}
local pointer=1
local committed_bridge={
 SetPlayerEntity=function(entity) pointer=entity end,
 GetPlayerEntity=function() return pointer end,
 RegisterPlayerEntityId=function(entity) registered[#registered+1]=entity end,
}
local ok,reason=authority.switch(committed_bridge,1,2)
assert(ok and reason=='committed',tostring(reason))
assert(pointer==2 and registered[#registered]==2,'replacement not committed/registered')

pointer=1
local rollback_bridge={
 SetPlayerEntity=function(entity) if entity==1 then pointer=1 end end,
 GetPlayerEntity=function() return pointer end,
 RegisterPlayerEntityId=function(entity) registered[#registered+1]=entity end,
}
local ok2,reason2=authority.switch(rollback_bridge,1,2)
assert(not ok2 and reason2=='rolled_back',tostring(reason2))
assert(pointer==1,'previous player pointer not restored')

local unknown_bridge={
 SetPlayerEntity=function() end,
 GetPlayerEntity=function() error('bridge readback unavailable') end,
}
local ok3,reason3=authority.switch(unknown_bridge,1,2)
assert(not ok3 and reason3=='unknown',tostring(reason3))
assert(alive[1] and alive[2],'authority switch must never destroy candidates')
print('form_player_authority=PASS commit=true rollback=true unknown_safe=true')
