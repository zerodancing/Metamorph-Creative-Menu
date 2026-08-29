-- Entangled Worlds extra-module bootstrap. Keep this file intentionally small: each
-- feature owns its transport/outbox implementation under files/integrations/ew/bridge/.
local ew_bootstrap = {}
local ew_api = dofile_once("mods/quant.ew/files/api/ew_api.lua")
local protocol = dofile("mods/metamorph_creative_menu/files/integrations/ew/bridge/protocol.lua")
-- RPC indices are protocol state. The v4 order is asserted by tests and MUST NOT be
-- changed without a namespace bump. Registration below preserves all eleven slots.
local rpc = ew_api.new_rpc_namespace(protocol.NAMESPACE)
local common = dofile("mods/metamorph_creative_menu/files/integrations/ew/bridge/common.lua")
local form_death_intercept = dofile("mods/metamorph_creative_menu/files/integrations/ew/form_death_intercept.lua")
local form_death_intercept_ok, form_death_intercept_reason = form_death_intercept.install()
if not form_death_intercept_ok then
    common.report_error("form_death_intercept.install", form_death_intercept_reason)
end
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
local materials = dofile("mods/metamorph_creative_menu/files/integrations/ew/bridge/materials.lua")
local teleport = dofile("mods/metamorph_creative_menu/files/integrations/ew/bridge/teleport.lua")
if type(forms.set_profiling_enabled) == "function" then forms.set_profiling_enabled(dev_mode) end
if type(materials.set_metrics_enabled) == "function" then materials.set_metrics_enabled(dev_mode) end

-- v4 RPC slots: 1 apply_rules, 2 request_rules, 3 QA telemetry, 4 companion,
-- 5 form pose, 6 reserved perk, 7 apply weather, 8 request weather,
-- 9 possession retirement, 10 reserved old light-form protocol,
-- 11 material paint batch.
world_rules.register(rpc, common)
qa.register(rpc, common)
companion.register(rpc, common)
forms.register_pose(rpc, common)
perks.register(rpc, common)
weather.register(rpc, common)
possession.register(rpc, common)
forms.register_reserved(rpc, common)
materials.register(rpc, common)
-- Bring-player requests use a separate namespace so the established v4 slot order
-- remains byte-for-byte compatible with earlier MCM peers.
teleport.register(ew_api, common)
items.init(common)

local function publish_identity()
    GlobalsSetValue("mcm_world_rules_rpc_ready_v1", "1")
    GlobalsSetValue("mcm_world_rules_rpc_my_id_v1", common.clean(ctx.my_id))
    GlobalsSetValue("mcm_world_rules_rpc_host_id_v1", common.clean(ctx.host_id))
    if dev_mode then
        local sent, received = forms.metrics()
        GlobalsSetValue("mcm_form_pose_sent_v1", tostring(sent))
        GlobalsSetValue("mcm_form_pose_received_v1", tostring(received))
        GlobalsSetValue("mcm_form_sync_mode_v1", "native_full_entity_pose_v1")
        GlobalsSetValue("mcm_light_form_serialize_v1", "disabled_native")
        GlobalsSetValue("mcm_light_form_deserialize_v1", "disabled_native")
    end
end

local function protected_update(scope, callback, ...)
    if type(callback) ~= "function" then
        pcall(common.report_error, scope, "callback_unavailable")
        return false
    end
    local ok, result = pcall(callback, ...)
    if not ok then
        pcall(common.report_error, scope, result)
        return false
    end
    return true, result
end

function ew_bootstrap.on_world_update()
    -- Retry only until EW publishes its health capability. This is normally installed
    -- synchronously at bootstrap, but the retry keeps unusual extra-module order safe.
    if not form_death_intercept_ok then
        form_death_intercept_ok, form_death_intercept_reason = form_death_intercept.install()
    end
    local frame_ok, frame = pcall(GameGetFrameNum)
    frame = frame_ok and (tonumber(frame) or 0) or 0
    if frame <= 1 or frame % 120 == 0 then protected_update("identity.update", publish_identity) end
    protected_update("world_rules.update", world_rules.update)
    protected_update("items.update", items.update)
    protected_update("materials.update", materials.update)
    protected_update("teleport.update", teleport.update)
    protected_update("companion.update", companion.update)
    -- Slot 6 remains registered by perks.register(); the legacy mailbox has no producer,
    -- so polling it every EW frame would only read/write acknowledge Globals forever.
    protected_update("weather.update", weather.update)
    protected_update("possession.update", possession.update)
    if dev_mode then protected_update("qa.update", qa.update, frame) end
    protected_update("forms.update", forms.update, frame)
end

return ew_bootstrap
