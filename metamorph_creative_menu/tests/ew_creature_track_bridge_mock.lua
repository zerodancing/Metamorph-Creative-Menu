local root=assert(arg[1],'root required')
local native_dofile=dofile
local runtime={enabled=function() return true end}
dofile=function(path)
    if path=='mods/metamorph_creative_menu/files/integrations/ew/runtime.lua' then return runtime end
    local prefix='mods/metamorph_creative_menu/'
    if string.sub(path,1,#prefix)==prefix then return native_dofile(root..'/'..string.sub(path,#prefix+1)) end
    return native_dofile(path)
end

local alive={[77]=true,[78]=true,[79]=true}
local tags={
    [77]={enemy=true},
    [78]={helpless_animal=true},
    [79]={},
}
local added={}
EntityGetIsAlive=function(e) return alive[e]==true end
EntityGetRootEntity=function(e) return e end
EntityHasTag=function(e,t) return tags[e] and tags[e][t]==true or false end
EntityAddTag=function(e,t) tags[e]=tags[e] or {}; tags[e][t]=true; added[#added+1]={e,t} end
EntityGetComponentIncludingDisabled=function() return {} end

-- ewext must never be consulted: native DES discovers enemy/helpless_animal itself.
ewext=setmetatable({}, {__index=function(_,key) error('manual ewext access: '..tostring(key)) end})
GlobalsGetValue=function() error('tracking mailbox must not be used') end
GlobalsSetValue=function() error('tracking mailbox must not be used') end

local helper=assert(native_dofile(root..'/files/integrations/ew/world_entities.lua'))
local ok,reason=helper.track(77)
assert(ok==true and reason=='native_auto','ordinary enemy did not stay on native DES discovery path')
ok,reason=helper.track(78)
assert(ok==true and reason=='native_auto','native DES helpless-animal discovery path changed')
ok,reason=helper.track(79)
assert(ok==true and reason=='native_forced','nonstandard entity did not receive documented ew_synced opt-in')
assert(tags[79].ew_synced==true and #added==1,'unexpected tags were mutated by native DES adapter')
local seq,ack,status=helper.outbox_state()
assert(seq==0 and ack==0 and status=='native_des_stock_only_v1','ordinary tracking unexpectedly entered creative registry')
print('ew_creature_track_bridge=PASS native_enemy_discovery=true manual_gid=false manual_death_hook=false ew_synced_fallback=true')
