local root=assert(arg[1])
local native_dofile=dofile
local original_calls,before_calls,after_calls=0,0,0
perk_pickup=function(entity,player,name,...)
 original_calls=original_calls+1
 return 'ok', entity, player, name, select('#',...)
end
local observer={
 before_pickup=function(entity,player,name,env) before_calls=before_calls+1; return {id=before_calls} end,
 after_pickup=function(context,success) after_calls=after_calls+1; assert(success==true) end,
}
dofile=function(path)
 if path=='mods/metamorph_creative_menu/files/features/perks/external_observer.lua' then return observer end
 return native_dofile(path)
end
METAMORPH_CREATIVE_MENU_PERK_PICKUP_HOOK_V2=nil
METAMORPH_CREATIVE_MENU_PERK_CAPTURE_ACTIVE=false
native_dofile(root..'/files/features/perks/pickup_hook.lua')
local a,b,c,d,n=perk_pickup(7,1,'perk',11,12)
assert(a=='ok' and b==7 and c==1 and d=='perk' and n==2,'hook changed vanilla return values')
assert(original_calls==1 and before_calls==1 and after_calls==1,'ordinary pickup not observed exactly once')
METAMORPH_CREATIVE_MENU_PERK_CAPTURE_ACTIVE=true
perk_pickup(8,1,'menu')
assert(original_calls==2 and before_calls==1 and after_calls==1,'menu pickup recursively observed itself')
print('perk_pickup_hook=PASS ordinary_observed=true menu_recursion_blocked=true')
