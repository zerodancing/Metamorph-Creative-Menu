local root=assert(arg[1],'root required')
local patches=assert(loadfile(root..'/files/integrations/ew/resilience_patches.lua'))()
local fixture=[[function death(damage_type_bit_field, damage_message, entity_thats_responsible, drop_items)
    local ent = GetUpdatedEntityID()
    local x, y = EntityGetTransform(ent)
    local wait_on_kill = false
    local damage = EntityGetFirstComponentIncludingDisabled(ent, "DamageModelComponent")
    if damage ~= nil then
        wait_on_kill = ComponentGetValue2(damage, "wait_for_kill_flag_on_death")
    end
    CrossCall("ew_death_notify", ent, wait_on_kill, x, y, EntityGetFilename(ent), entity_thats_responsible)
end
]]
local patched,count=patches.patch_boss_death_pressure_source(fixture)
assert(count==1,'boss death pressure patch did not apply')
assert(string.find(patched,'mcm_boss_death_pressure_v1',1,true),'marker missing')
assert(string.find(patched,'BossHealthBarComponent',1,true),'boss healthbar detection missing')
assert(string.find(patched,'StreamingKeepAliveComponent',1,true),'global keepalive detection missing')
assert(string.find(patched,'mcm_ew_boss_death_pressure_until_v1',1,true),'pressure global missing')
assert(string.find(patched,'CrossCall("ew_death_notify"',1,true),'stock EW death notify was replaced')
local compiled,err=load(patched,'@patched_death_notify.lua')
assert(compiled~=nil,'patched death notifier invalid: '..tostring(err))
local again,n2=patches.patch_boss_death_pressure_source(patched)
assert(n2==0 and again==patched,'patch is not idempotent')
print('ew_boss_network_pressure=PASS stock_death_semantics=true pressure_only=true')
