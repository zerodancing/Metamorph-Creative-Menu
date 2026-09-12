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
local companion = dofile("mods/metamorph_creative_menu/files/integrations/ew/bridge/companion.lua")
local forms = dofile("mods/metamorph_creative_menu/files/integrations/ew/bridge/forms.lua")
local perks = dofile("mods/metamorph_creative_menu/files/integrations/ew/bridge/perks.lua")
local weather = dofile("mods/metamorph_creative_menu/files/integrations/ew/bridge/weather.lua")
local possession = dofile("mods/metamorph_creative_menu/files/integrations/ew/bridge/possession.lua")
local items = dofile("mods/metamorph_creative_menu/files/integrations/ew/bridge/items.lua")

-- v3 RPC slots are positional. Slot 3 is reserved to preserve wire compatibility.
world_rules.register(rpc, common)
rpc.opts_reliable()
rpc.opts_everywhere()
function rpc.reserved_protocol_slot_3(...) end
companion.register(rpc, common)
forms.register_pose(rpc, common)
perks.register(rpc, common)
weather.register(rpc, common)
possession.register(rpc, common)
forms.register_reserved(rpc, common)
items.init(common)

local function publish_identity()
    GlobalsSetValue("mcm_world_rules_rpc_ready_v1", "1")
    GlobalsSetValue("mcm_world_rules_rpc_my_id_v1", common.clean(ctx.my_id))
    GlobalsSetValue("mcm_world_rules_rpc_host_id_v1", common.clean(ctx.host_id))
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
    forms.update(frame)
end

return ew_bootstrap
