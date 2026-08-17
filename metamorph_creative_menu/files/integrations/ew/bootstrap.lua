-- Entangled Worlds extra-module bootstrap. Keep this file intentionally small: each
-- feature owns its transport/outbox implementation under files/integrations/ew/bridge/.
local ew_bootstrap = {}
local ew_api = dofile_once("mods/quant.ew/files/api/ew_api.lua")
local protocol = dofile("mods/metamorph_creative_menu/files/integrations/ew/bridge/protocol.lua")
-- RPC indices are protocol state. v3 order is asserted by tests and MUST NOT be changed
-- without a namespace bump. Registration order below reproduces v10/v11 slots exactly.
local rpc = ew_api.new_rpc_namespace(protocol.NAMESPACE)
local common = dofile("mods/metamorph_creative_menu/files/integrations/ew/bridge/common.lua")
local perk_runtime_guard = dofile("mods/metamorph_creative_menu/files/integrations/ew/perk_runtime_guard.lua")
local perk_guard_ok, perk_guard_reason = perk_runtime_guard.install()
if not perk_guard_ok then
    GlobalsSetValue("mcm_peer_perk_runtime_guard_v1", "failed:" .. tostring(perk_guard_reason))
end
local world_rules = dofile("mods/metamorph_creative_menu/files/integrations/ew/bridge/world_rules.lua")
local dev_mode = tonumber(dofile("mods/metamorph_creative_menu/dev_mode.lua")) == 1
local qa = dofile(dev_mode
    and "mods/metamorph_creative_menu/files/integrations/ew/bridge/qa.lua"
    or "mods/metamorph_creative_menu/files/integrations/ew/bridge/qa_reserved.lua")
local companion = dofile("mods/metamorph_creative_menu/files/integrations/ew/bridge/companion.lua")
local forms = dofile("mods/metamorph_creative_menu/files/integrations/ew/bridge/forms.lua")
local perks = dofile("mods/metamorph_creative_menu/files/integrations/ew/bridge/perks.lua")
local weather = dofile("mods/metamorph_creative_menu/files/integrations/ew/bridge/weather.lua")
local possession = dofile("mods/metamorph_creative_menu/files/integrations/ew/bridge/possession.lua")
local items = dofile("mods/metamorph_creative_menu/files/integrations/ew/bridge/items.lua")

-- v3 RPC slots: 1 apply_rules, 2 request_rules, 3 QA telemetry, 4 companion,
-- 5 form pose, 6 reserved perk, 7 apply weather, 8 request weather,
-- 9 possession retirement, 10 reserved old light-form protocol.
world_rules.register(rpc, common)
qa.register(rpc, common)
companion.register(rpc, common)
forms.register_pose(rpc, common)
perks.register(rpc, common)
weather.register(rpc, common)
possession.register(rpc, common)
forms.register_reserved(rpc, common)
items.init(common)

local function publish_identity()
    local sent, received = forms.metrics()
    GlobalsSetValue("mcm_world_rules_rpc_ready_v1", "1")
    GlobalsSetValue("mcm_world_rules_rpc_my_id_v1", common.clean(ctx.my_id))
    GlobalsSetValue("mcm_world_rules_rpc_host_id_v1", common.clean(ctx.host_id))
    GlobalsSetValue("mcm_form_pose_sent_v1", tostring(sent))
    GlobalsSetValue("mcm_form_pose_received_v1", tostring(received))
    GlobalsSetValue("mcm_form_sync_mode_v1", "native_full_entity_pose_v1")
    GlobalsSetValue("mcm_light_form_serialize_v1", "disabled_native")
    GlobalsSetValue("mcm_light_form_deserialize_v1", "disabled_native")
end

function ew_bootstrap.on_world_update()
    local frame = GameGetFrameNum()
    if frame <= 1 or frame % 120 == 0 then publish_identity() end
    world_rules.update()
    items.update()
    companion.update()
    perks.update()
    weather.update()
    possession.update()
    qa.update(frame)
    forms.update(frame)
end

return ew_bootstrap
