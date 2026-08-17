local root = assert(arg[1], "root required")
local native_dofile = dofile
local globals = {
    mcm_world_rules_rpc_ready_v1="1",
    mcm_world_rules_rpc_my_id_v1="client-a",
    mcm_world_rules_rpc_host_id_v1="host",
}
local is_host=false
local applied=nil
local remote_authoritative=nil

function GlobalsGetValue(key,fallback) local v=globals[key]; if v==nil then return fallback end; return v end
function GlobalsSetValue(key,value) globals[key]=tostring(value) end
function ModIsEnabled(name) return name=="quant.ew" end
function GameHasFlagRun(flag) return flag=="ew_flag_this_is_host" and is_host end
function GameGetFrameNum() return 100 end
function print() end

METAMORPH_CREATIVE_MENU_WORLD_RULE_SYNC=nil
local sync=assert(native_dofile(root.."/files/integrations/ew/world_rules_sync.lua"))
local callbacks={
    encode_snapshot=function() return "2,1,3" end,
    decode_snapshot=function(encoded)
        local out={}
        for value in string.gmatch(encoded,"[^,]+") do out[#out+1]=tonumber(value) end
        return #out>0 and out or nil
    end,
    apply_snapshot=function(choices) applied=choices end,
    set_remote_authoritative=function(value) remote_authoritative=value end,
}

local allowed,role=sync.can_edit()
assert(allowed==true and role=="ew_peer","client lost world-rule editing rights")
sync.mark_dirty("2,1,3")
sync.update(100,callbacks)
assert(globals.mcm_world_rules_outbox_version_v1=="2","world-rule protocol version changed")
assert(globals.mcm_world_rules_outbox_snapshot_v1=="2,1,3","local world-rule snapshot was not published")
assert(tonumber(globals.mcm_world_rules_outbox_seq_v1 or "0")>=1,"world-rule snapshot sequence was not committed")

-- Simulate a host-accepted rebroadcast of another peer's complete latest snapshot.
globals.mcm_world_rules_remote_seq_v1="9"
globals.mcm_world_rules_remote_version_v1="2"
globals.mcm_world_rules_remote_snapshot_v1="1,3,2"
globals.mcm_world_rules_remote_origin_v1="peer-b"
sync.update(101,callbacks)
assert(type(applied)=="table" and applied[1]==1 and applied[2]==3 and applied[3]==2,"remote world-rule snapshot was not applied")

-- In singleplayer/network-off mode the service must explicitly clear remote authority.
function ModIsEnabled() return false end
sync.update(102,callbacks)
assert(remote_authoritative==false,"network-off mode left stale remote authority")

io.write("world_rules_sync=PASS client_publish=true remote_apply=true\n")
