local root = assert(arg[1], "root required")
local native_dofile = dofile

local function finite_number(value)
    return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end


local function load_common(errors)
    local previous_dofile = dofile
    dofile = function(path)
        if path == "mods/metamorph_creative_menu/files/core/global_text.lua" then
            return native_dofile(root .. "/files/core/global_text.lua")
        end
        return previous_dofile(path)
    end
    local common = assert(native_dofile(root .. "/files/integrations/ew/bridge/common.lua"))
    dofile = previous_dofile
    local real_report = common.report_error
    common.report_error = function(scope, detail)
        errors[#errors + 1] = {scope=tostring(scope), detail=tostring(detail)}
        return real_report(scope, detail)
    end
    return common
end

local function assert_safe_diagnostic(globals, label)
    local value = tostring(globals.mcm_world_rules_rpc_error_v1 or "")
    assert(#value <= 512, label .. " diagnostic exceeded 512 bytes")
    assert(not string.find(value, '"', 1, true), label .. " diagnostic contained quote")
    for index=1,#value do
        local byte=string.byte(value,index)
        assert(byte >= 32 and byte <= 126, label .. " diagnostic contained non-ASCII/control byte")
    end
end

local function make_rpc_proxy(send_name, sends, state)
    local receiver
    local proxy = {}
    setmetatable(proxy, {
        __newindex=function(t, key, value)
            if key == send_name then
                receiver = value
                rawset(t, key, function(...)
                    if state.fail_send then error('simulated rpc failure "<&%\\ Ж🔥') end
                    sends[#sends+1] = {...}
                end)
            else
                rawset(t, key, value)
            end
        end,
    })
    function proxy.opts_reliable() end
    function proxy.opts_everywhere() end
    return proxy, function() return receiver end
end

local function run_teleport()
    local globals, sends, errors, state = {}, {}, {}, {fail_send=false, guarded=false, reads=0}
    local loaded = true
    local transforms = {[10]={0,0}, [20]={100,100}}
    ctx={my_id='peer-target',my_player={entity=10},players={['peer-target']={entity=10},['peer-source']={entity=20}},rpc_player_data={entity=20}}
    function GlobalsGetValue(key, fallback)
        if state.guarded and string.find(key, '_v1_', 1, true) then
            state.reads = state.reads + 1
            assert(state.reads < 200, 'teleport attempted unbounded huge-gap mailbox reads')
        end
        return globals[key] or fallback
    end
    function GlobalsSetValue(key, value) globals[key]=tostring(value) end
    function GameGetFrameNum() return 20 end
    function DoesWorldExistAt() return loaded end
    function FindFreePositionForBody(x,y) return x,y end
    function EntityGetIsAlive(entity) return transforms[entity] ~= nil end
    function EntityGetTransform(entity) return transforms[entity][1], transforms[entity][2] end
    function EntitySetTransform(entity,x,y) transforms[entity]={x,y} end
    function EntityGetFirstComponentIncludingDisabled() return 70 end
    function ComponentSetValue2() end
    function GameSetCameraPos() end

    local rpc_proxy, get_receiver = make_rpc_proxy('request_bring', sends, state)
    local ew_api={new_rpc_namespace=function(namespace)
        assert(namespace=='metamorph_creative_menu:teleport:v1:', 'teleport v1 namespace changed')
        return rpc_proxy
    end}
    local common=load_common(errors)
    local bridge=assert(loadfile(root..'/files/integrations/ew/bridge/teleport.lua'))()
    bridge.register(ew_api,common)
    local receiver=assert(get_receiver(),'teleport receiver missing')

    bridge.update()
    assert(#sends==0 and globals.mcm_teleport_bring_outbox_ack_v1==nil, 'empty teleport v1 mailbox changed state')

    for i=1,40 do
        local suffix='_'..i
        globals['mcm_teleport_bring_outbox_peer_v1'..suffix]='peer-source'
        globals['mcm_teleport_bring_outbox_target_x_v1'..suffix]='100'
        globals['mcm_teleport_bring_outbox_target_y_v1'..suffix]='100'
        globals['mcm_teleport_bring_outbox_dest_x_v1'..suffix]=tostring(i)
        globals['mcm_teleport_bring_outbox_dest_y_v1'..suffix]='0'
    end
    globals.mcm_teleport_bring_outbox_seq_v1='40'

    receiver('peer-target',100,100)
    bridge.update()
    assert(#sends==16, 'teleport did not bound first drain to 16: '..tostring(#sends))
    assert(globals.mcm_teleport_bring_outbox_ack_v1=='16','teleport first ACK was not 16')
    assert(globals.mcm_teleport_bring_outbox_peer_v1_1=='' and globals.mcm_teleport_bring_outbox_peer_v1_16=='', 'processed teleport keys were not cleared')
    assert(globals.mcm_teleport_bring_outbox_peer_v1_17=='peer-source','unprocessed teleport key was cleared early')
    assert(transforms[10][1]==100 and transforms[10][2]==100,'apply_pending did not run while mailbox backlog remained')
    bridge.update(); assert(#sends==32 and globals.mcm_teleport_bring_outbox_ack_v1=='32','teleport second drain was not 16')
    bridge.update(); assert(#sends==40 and globals.mcm_teleport_bring_outbox_ack_v1=='40','teleport final drain was not 8')

    globals.mcm_teleport_bring_outbox_seq_v1='41'
    globals.mcm_teleport_bring_outbox_peer_v1_41='peer-source'; globals.mcm_teleport_bring_outbox_target_x_v1_41='100'; globals.mcm_teleport_bring_outbox_target_y_v1_41='100'; globals.mcm_teleport_bring_outbox_dest_x_v1_41='41'; globals.mcm_teleport_bring_outbox_dest_y_v1_41='0'
    state.fail_send=true; bridge.update()
    assert(globals.mcm_teleport_bring_outbox_ack_v1=='40','failed teleport RPC was acknowledged')
    assert(globals.mcm_teleport_bring_outbox_peer_v1_41=='peer-source','failed teleport RPC payload was cleared')
    assert_safe_diagnostic(globals, 'teleport rpc failure')
    assert(string.find(globals.mcm_world_rules_rpc_error_v1 or '', '%22', 1, true), 'teleport RPC diagnostic was not encoded')
    state.fail_send=false; bridge.update(); assert(globals.mcm_teleport_bring_outbox_ack_v1=='41','teleport retry did not acknowledge success')

    globals.mcm_teleport_bring_outbox_seq_v1='43'
    globals.mcm_teleport_bring_outbox_peer_v1_42='peer-source'; globals.mcm_teleport_bring_outbox_target_x_v1_42='nan'; globals.mcm_teleport_bring_outbox_target_y_v1_42='100'; globals.mcm_teleport_bring_outbox_dest_x_v1_42='42'; globals.mcm_teleport_bring_outbox_dest_y_v1_42='0'
    globals.mcm_teleport_bring_outbox_peer_v1_43='peer-source'; globals.mcm_teleport_bring_outbox_target_x_v1_43='100'; globals.mcm_teleport_bring_outbox_target_y_v1_43='100'; globals.mcm_teleport_bring_outbox_dest_x_v1_43='43'; globals.mcm_teleport_bring_outbox_dest_y_v1_43='0'
    local before=#sends; bridge.update()
    assert(globals.mcm_teleport_bring_outbox_ack_v1=='43' and #sends==before+1,'invalid teleport middle record blocked next message')

    state.guarded=true; state.reads=0; local error_before=#errors
    globals.mcm_teleport_bring_outbox_seq_v1='1000000'; bridge.update()
    assert(globals.mcm_teleport_bring_outbox_ack_v1=='1000000','teleport huge gap did not resync ACK')
    assert(#errors==error_before+1,'teleport huge gap did not report exactly once')
    assert_safe_diagnostic(globals, 'teleport huge gap')
    local gap_error_seq=globals.mcm_world_rules_rpc_error_seq_v1
    local reads_after=state.reads; bridge.update()
    assert(#errors==error_before+1 and state.reads==reads_after,'teleport huge gap repeated diagnostic/work')
    assert(globals.mcm_world_rules_rpc_error_seq_v1==gap_error_seq,'teleport huge gap diagnostic was written more than once')
    state.guarded=false

    globals.mcm_teleport_bring_outbox_seq_v1='1000001'
    globals.mcm_teleport_bring_outbox_peer_v1='peer-source'; globals.mcm_teleport_bring_outbox_target_x_v1='100'; globals.mcm_teleport_bring_outbox_target_y_v1='100'; globals.mcm_teleport_bring_outbox_dest_x_v1='77'; globals.mcm_teleport_bring_outbox_dest_y_v1='0'
    before=#sends; bridge.update()
    assert(#sends==before+1 and sends[#sends][2]==77 and globals.mcm_teleport_bring_outbox_ack_v1=='1000001','teleport v1 base-key peer compatibility regressed')
    local stable_sends=#sends
    for _, invalid in ipairs({'-1','1000001.5','nan','inf'}) do
        local invalid_errors=#errors
        globals.mcm_teleport_bring_outbox_seq_v1=invalid
        bridge.update()
        assert(globals.mcm_teleport_bring_outbox_ack_v1=='1000001' and #sends==stable_sends,
            'invalid teleport sequence advanced mailbox: '..invalid)
        bridge.update()
        assert(#errors==invalid_errors+1,
            'unchanged invalid teleport sequence emitted a diagnostic every frame: '..invalid)
    end
    return errors
end

local function run_possession()
    local globals, sends, errors, state = {}, {}, {}, {fail_send=false, guarded=false, reads=0}
    local alive, paths, transforms = {[1]=true}, {}, {[1]={100,100}}
    ctx={my_player={entity=1}}
    function GlobalsGetValue(key, fallback)
        if state.guarded and string.find(key, '_v1_', 1, true) then
            state.reads=state.reads+1
            assert(state.reads < 150, 'possession attempted unbounded huge-gap mailbox reads')
        end
        return globals[key] or fallback
    end
    function GlobalsSetValue(key,value) globals[key]=tostring(value) end
    function EntityGetIsAlive(entity) return alive[entity]==true end
    function EntityGetTransform(entity) local p=transforms[entity] or {0,0}; return p[1],p[2] end
    function EntityGetInRadius(x,y,r)
        local out={}
        for entity,is_alive in pairs(alive) do
            if is_alive and entity~=1 then out[#out+1]=entity end
        end
        return out
    end
    function EntityGetParent() return 0 end
    function EntityGetFilename(entity) return paths[entity] or '' end
    function EntityHasTag(entity,tag) return tag=='ew_replicated' and entity~=1 and alive[entity]==true end
    function EntityGetAllChildren() return {} end
    function EntityGetAllComponents() return {} end
    function EntitySetTransform(entity,x,y) transforms[entity]={x,y} end
    function EntityKill(entity) alive[entity]=false end
    function EntityRemoveComponent() end
    function EntitySetComponentIsEnabled() end
    function ComponentGetTypeName() return '' end

    CrossCall=function(name,entity,wait,x,y,path,responsible)
        assert(name=='ew_death_notify','possession bridge used non-stock EW channel')
        if state.fail_send then error('simulated EW death notify failure "<&%\\ Ж🔥') end
        sends[#sends+1]={entity,wait,x,y,path,responsible}
    end
    local rpc={opts_reliable=function() end,opts_everywhere=function() end}
    local common=load_common(errors)
    local bridge=assert(loadfile(root..'/files/integrations/ew/bridge/possession.lua'))()
    bridge.register(rpc,common)

    bridge.update()
    assert(#sends==0 and globals.mcm_possession_retire_outbox_ack_v1==nil, 'empty possession v1 mailbox changed state')

    for i=1,40 do
        local entity=1000+i; alive[entity]=true; paths[entity]='mods/example/entities/mob.xml'; transforms[entity]={i,0}
        local suffix='_'..i
        globals['mcm_possession_retire_outbox_entity_v1'..suffix]=tostring(entity)
        globals['mcm_possession_retire_outbox_path_v1'..suffix]='mods/example/entities/mob.xml'
        globals['mcm_possession_retire_outbox_x_v1'..suffix]=tostring(i)
        globals['mcm_possession_retire_outbox_y_v1'..suffix]='0'
    end
    globals.mcm_possession_retire_outbox_seq_v1='40'
    bridge.update(); assert(#sends==16 and globals.mcm_possession_retire_outbox_ack_v1=='16','possession first drain was not 16/ACK16')
    bridge.update(); assert(#sends==32 and globals.mcm_possession_retire_outbox_ack_v1=='32','possession second drain was not 16/ACK32')
    bridge.update(); assert(#sends==40 and globals.mcm_possession_retire_outbox_ack_v1=='40','possession final drain was not 8/ACK40')
    assert(sends[1][2]==false and sends[1][5]=='mods/example/entities/mob.xml','possession did not use stock EW death-notify shape')

    local e41=1041; alive[e41]=true; paths[e41]='mods/example/entities/mob.xml'; transforms[e41]={41,0}
    globals.mcm_possession_retire_outbox_seq_v1='41'; globals.mcm_possession_retire_outbox_entity_v1_41=tostring(e41); globals.mcm_possession_retire_outbox_path_v1_41='mods/example/entities/mob.xml'; globals.mcm_possession_retire_outbox_x_v1_41='41'; globals.mcm_possession_retire_outbox_y_v1_41='0'
    state.fail_send=true; bridge.update(); assert(globals.mcm_possession_retire_outbox_ack_v1=='40','failed possession EW death-notify was acknowledged')
    assert_safe_diagnostic(globals, 'possession EW death-notify failure')
    state.fail_send=false; bridge.update(); assert(globals.mcm_possession_retire_outbox_ack_v1=='41','possession EW death-notify retry did not acknowledge success')

    local e43=1043; alive[e43]=true; paths[e43]='mods/example/entities/mob.xml'; transforms[e43]={43,0}
    globals.mcm_possession_retire_outbox_seq_v1='43'; globals.mcm_possession_retire_outbox_entity_v1_42='0'; globals.mcm_possession_retire_outbox_path_v1_42=''; globals.mcm_possession_retire_outbox_x_v1_42='bad'; globals.mcm_possession_retire_outbox_y_v1_42='0'; globals.mcm_possession_retire_outbox_entity_v1_43=tostring(e43); globals.mcm_possession_retire_outbox_path_v1_43='mods/example/entities/mob.xml'; globals.mcm_possession_retire_outbox_x_v1_43='43'; globals.mcm_possession_retire_outbox_y_v1_43='0'
    local before=#sends; bridge.update(); assert(#sends==before+1 and globals.mcm_possession_retire_outbox_ack_v1=='43','invalid possession middle record blocked next message')

    state.guarded=true; state.reads=0; local error_before=#errors; globals.mcm_possession_retire_outbox_seq_v1='1000000'; bridge.update()
    assert(globals.mcm_possession_retire_outbox_ack_v1=='1000000','possession huge gap did not resync ACK')
    assert(#errors==error_before+1,'possession huge gap did not report once')
    local reads_after=state.reads; bridge.update(); assert(#errors==error_before+1 and state.reads==reads_after,'possession huge gap repeated diagnostic/work')
    state.guarded=false

    local ebase=2001; alive[ebase]=true; paths[ebase]='mods/example/entities/old_peer.xml'; transforms[ebase]={9,10}
    globals.mcm_possession_retire_outbox_seq_v1='1000001'; globals.mcm_possession_retire_outbox_entity_v1=tostring(ebase); globals.mcm_possession_retire_outbox_path_v1='mods/example/entities/old_peer.xml'; globals.mcm_possession_retire_outbox_x_v1='9'; globals.mcm_possession_retire_outbox_y_v1='10'
    before=#sends; bridge.update(); assert(#sends==before+1 and sends[#sends][5]=='mods/example/entities/old_peer.xml' and globals.mcm_possession_retire_outbox_ack_v1=='1000001','possession v1 base-key compatibility regressed')
    local stable_sends=#sends
    for _, invalid in ipairs({'-1','1000001.5','nan','inf'}) do
        local invalid_errors=#errors
        globals.mcm_possession_retire_outbox_seq_v1=invalid
        bridge.update()
        assert(globals.mcm_possession_retire_outbox_ack_v1=='1000001' and #sends==stable_sends,
            'invalid possession sequence advanced mailbox: '..invalid)
        bridge.update()
        assert(#errors==invalid_errors+1,
            'unchanged invalid possession sequence emitted a diagnostic every frame: '..invalid)
    end
    dofile=native_dofile
    ewext=nil
    return errors
end

local teleport_errors=run_teleport()
local possession_errors=run_possession()
print('ew_mailbox_drain=PASS teleport_16_16_8=true possession_16_16_8=true atomic_ack=true invalid_continue=true huge_gap=true v1_compatible=true errors='..tostring(#teleport_errors+#possession_errors))
