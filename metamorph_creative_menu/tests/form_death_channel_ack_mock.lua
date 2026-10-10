local root=assert(arg[1], 'root required')
local registered=nil
local globals={}
GlobalsSetValue=function(k,v) globals[k]=tostring(v) end
GameGetFrameNum=function() return 123 end
METAMORPH_CREATIVE_MENU_EW_FORM_DEATH_CHANNEL=nil
local channel=assert(dofile(root..'/files/integrations/ew/form_death_channel.lua'))
local bridge={CrossCallAdd=function(name,fn) assert(name=='metamorph_creative_menu_form_died'); registered=fn end}
assert(channel.register(bridge,function(entity) return entity==44 end)==true,'death channel did not register')
assert(type(registered)=='function','wrapped death handler missing')
assert(globals.mcm_form_death_channel_registration_v1=='native_cross_vm','native registration mode was not published')
assert(registered(43,'death',0,nil,0)==false,'failed handoff reported success')
assert(globals[channel.ack_key()]==nil,'failed handoff published acknowledgement')
assert(registered(44,'death',0,nil,0)==true,'successful handoff was lost')
assert(globals[channel.ack_key()]=='44:123','successful handoff did not publish exact entity acknowledgement')
print('form_death_channel_ack=PASS commit_only=true entity_scoped=true native_cross_vm=true')
