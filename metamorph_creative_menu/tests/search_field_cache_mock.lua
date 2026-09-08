local root=assert(arg[1],'root required')
METAMORPH_CREATIVE_MENU_SEARCH_ENGINE=nil
local engine=assert(dofile(root..'/files/core/search_engine.lua'))
local original=engine.normalize
local calls=0
engine.normalize=function(value)
    calls=calls+1
    return original(value)
end
local fields={'Fireball','$action_fireball','FIREBALL','data/entities/projectiles/deck/fireball.xml'}
local q1=engine.compile_query('fire')
local before_fields=calls
assert(engine.score(q1,fields)~=nil,'baseline cached-field search did not match')
local first=calls
assert(first-before_fields>=#fields,'baseline search did not normalize fields')
local q2=engine.compile_query('ball')
local before_second=calls
assert(engine.score(q2,fields)~=nil,'second cached-field search did not match')
assert(calls==before_second,'changing only the query renormalized the entire catalogue entry')
local changed={'Fire bolt','$action_firebolt','FIREBOLT','data/entities/projectiles/deck/firebolt.xml'}
local q3=engine.compile_query('bolt')
local before_changed=calls
assert(engine.score(q3,changed)~=nil,'changed field set did not match')
assert(calls-before_changed>=#changed,'changed field set incorrectly reused stale normalized fields')
print('search_field_cache=PASS query_changes_reuse_fields=true changed_fields_invalidate=true')
