local forms_bridge = {}
local rpc, common
local last_remote_pose_frame = {}
local last_pose_send_frame = -100000
local last_remote_root_frame = {}
local remote_articulated_prepared = {}
local form_pose_sent, form_pose_received = 0, 0


local function finite_number(value)
    return type(value) == "number" and value == value and math.abs(value) < 100000000
end

local function worm_target_speed(entity)
    local worm = EntityGetFirstComponentIncludingDisabled(entity, "WormComponent")
    if worm ~= nil and worm ~= 0 then
        local ok, speed = pcall(ComponentGetValue2, worm, "mTargetSpeed")
        if ok and finite_number(speed) then return speed end
        ok, speed = pcall(ComponentGetValue2, worm, "speed")
        if ok and finite_number(speed) then return speed end
    end
    return 0
end

local function motion_state(entity)
    local component = EntityGetFirstComponentIncludingDisabled(entity, "CharacterDataComponent")
    if component ~= nil and component ~= 0 then
        local ok, x, y = pcall(ComponentGetValue2, component, "mVelocity")
        if ok and finite_number(x) and finite_number(y) then return 1, x, y, 0 end
    end
    component = EntityGetFirstComponentIncludingDisabled(entity, "GhostComponent")
    if component ~= nil and component ~= 0 then
        local ok, x, y = pcall(ComponentGetValue2, component, "velocity")
        if ok and finite_number(x) and finite_number(y) then return 2, x, y, 0 end
    end
    -- Boss forms are adapted locally to WormPlayer. The remote entity is the full entity
    -- serialized by EW, not a replacement proxy; test BossDragon first so its native AI
    -- motor stays disabled while the serialized WormPlayer driver owns movement.
    local dragon = EntityGetFirstComponentIncludingDisabled(entity, "BossDragonComponent")
    if dragon ~= nil and dragon ~= 0 then
        local player_driver = EntityGetFirstComponentIncludingDisabled(entity, "WormPlayerComponent")
        if player_driver ~= nil and player_driver ~= 0 then
            local ok, x, y = pcall(ComponentGetValue2, player_driver, "mDirection")
            if ok and finite_number(x) and finite_number(y) then return 5, x, y, worm_target_speed(entity) end
        end
        local ok, x, y = pcall(ComponentGetValue2, dragon, "mTargetVec")
        if ok and finite_number(x) and finite_number(y) then return 5, x, y, worm_target_speed(entity) end
    end
    component = EntityGetFirstComponentIncludingDisabled(entity, "WormPlayerComponent")
    if component ~= nil and component ~= 0 then
        local ok, x, y = pcall(ComponentGetValue2, component, "mDirection")
        if ok and finite_number(x) and finite_number(y) then return 3, x, y, worm_target_speed(entity) end
    end
    component = EntityGetFirstComponentIncludingDisabled(entity, "AdvancedFishAIComponent")
    if component ~= nil and component ~= 0 then
        local ok, x, y = pcall(ComponentGetValue2, component, "mTargetVec")
        if ok and finite_number(x) and finite_number(y) then return 4, x, y, 0 end
    end
    return 0, 0, 0, 0
end

local REMOTE_GAMEPLAY_COMPONENTS = {
    "WormAIComponent", "AnimalAIComponent", "AIAttackComponent", "PhysicsAIComponent",
    "PathFindingComponent", "PathFindingGridMarkerComponent", "CellEaterComponent",
}

local function remote_tree(root, fn)
    local queue, index, seen = {root}, 1, {}
    while index <= #queue do
        local entity = queue[index]; index = index + 1
        if entity ~= nil and entity ~= 0 and not seen[entity] and EntityGetIsAlive(entity) then
            seen[entity] = true
            fn(entity)
            for _, child in ipairs(EntityGetAllChildren(entity) or {}) do queue[#queue + 1] = child end
        end
    end
end

local function disable_remote_ai(entity)
    remote_tree(entity, function(current)
        for _, component_type in ipairs(REMOTE_GAMEPLAY_COMPONENTS) do
            for _, comp in ipairs(EntityGetComponentIncludingDisabled(current, component_type) or {}) do
                pcall(EntitySetComponentIsEnabled, current, comp, false)
            end
        end
    end)
end

local function prepare_remote_articulated(entity, kind)
    local cached = remote_articulated_prepared[entity]
    if cached == kind then
        local driver = EntityGetFirstComponentIncludingDisabled(entity, "WormPlayerComponent")
        if driver ~= nil and driver ~= 0 then return end
        remote_articulated_prepared[entity] = nil -- entity id may have been reused
    end
    disable_remote_ai(entity)
    local worm = EntityGetFirstComponentIncludingDisabled(entity, "WormComponent")
    local driver = EntityGetFirstComponentIncludingDisabled(entity, "WormPlayerComponent")
    if kind == 5 then
        local dragon = EntityGetFirstComponentIncludingDisabled(entity, "BossDragonComponent")
        if (worm == nil or worm == 0) and dragon ~= nil and dragon ~= 0 and type(EntityAddComponent2) == "function" then
            local function dvalue(field, default)
                local ok, value = pcall(ComponentGetValue2, dragon, field)
                value = ok and tonumber(value) or nil
                return value ~= nil and value or default
            end
            local speed = math.max(0, dvalue("speed", 1))
            local ok, created = pcall(EntityAddComponent2, entity, "WormComponent", {
                _tags="metamorph_creative_menu_remote_worm_driver", speed=speed,
                max_speed=math.max(25, speed * 4), acceleration=math.max(0, dvalue("acceleration", 3)),
                gravity=0, tail_gravity=0, part_distance=dvalue("part_distance", 10),
                ground_check_offset=dvalue("ground_check_offset", 0), hitbox_radius=dvalue("hitbox_radius", 1),
                bite_damage=dvalue("bite_damage", 2), target_kill_radius=dvalue("target_kill_radius", 1),
                target_kill_ragdoll_force=dvalue("target_kill_ragdoll_force", 1),
                eat_anim_wait_mult=dvalue("eat_anim_wait_mult", 0.05), jump_cam_shake=dvalue("jump_cam_shake", 20),
            })
            if ok then worm = created end
        end
        if dragon ~= nil and dragon ~= 0 then pcall(EntitySetComponentIsEnabled, entity, dragon, false) end
    end
    if (driver == nil or driver == 0) and type(EntityAddComponent2) == "function" then
        local ok, created = pcall(EntityAddComponent2, entity, "WormPlayerComponent", {_tags="metamorph_creative_menu_remote_worm_driver"})
        if ok then driver = created end
    end
    if worm ~= nil and worm ~= 0 then pcall(EntitySetComponentIsEnabled, entity, worm, true) end
    if driver ~= nil and driver ~= 0 then pcall(EntitySetComponentIsEnabled, entity, driver, true) end
    remote_articulated_prepared[entity] = kind
end

local function apply_motion_state(entity, kind, x, y, speed)
    if kind == 3 or kind == 5 then
        prepare_remote_articulated(entity, kind)
        local driver = EntityGetFirstComponentIncludingDisabled(entity, "WormPlayerComponent")
        if driver ~= nil and driver ~= 0 then pcall(ComponentSetValue2, driver, "mDirection", x, y) end
        local worm = EntityGetFirstComponentIncludingDisabled(entity, "WormComponent")
        if worm ~= nil and worm ~= 0 and finite_number(tonumber(speed)) then
            pcall(ComponentSetValue2, worm, "mTargetSpeed", tonumber(speed) or 0)
        end
        return
    end
    local component_type, field
    if kind == 1 then component_type, field = "CharacterDataComponent", "mVelocity"
    elseif kind == 2 then component_type, field = "GhostComponent", "velocity"
    elseif kind == 4 then component_type, field = "AdvancedFishAIComponent", "mTargetVec"
    else return end
    local component = EntityGetFirstComponentIncludingDisabled(entity, component_type)
    if component ~= nil and component ~= 0 then pcall(ComponentSetValue2, component, field, x, y) end
end

-- Deliberately UNRELIABLE. This is a latest-pose stream, not an event log: losing an
-- old pose is harmless and reliable delivery would create exactly the kind of backlog
-- that hurts after Alt-Tab. EW's normal player position serializer requires both
-- CharacterDataComponent and CharacterPlatformingComponent; many playable creatures do
-- not have that pair, so this fills the gap for polymorphed player entities only.

function forms_bridge.register_pose(shared_rpc, shared_common)
    rpc, common = shared_rpc, shared_common
    function rpc.sync_form_pose(source_frame, x, y, rotation, scale_x, scale_y, phys_info, motion_kind, motion_x, motion_y, motion_speed)
    local sender = ctx.rpc_peer_id
    local data = ctx.rpc_player_data
    local frame = tonumber(source_frame) or -1
    if sender == nil or data == nil or sender == ctx.my_id or frame < 0 then return end
    if frame <= (last_remote_pose_frame[sender] or -1) then return end
    if data.currently_polymorphed ~= true then return end
    local entity = tonumber(data.entity) or 0
    if entity == 0 or not EntityGetIsAlive(entity) or not EntityHasTag(entity, "ew_client") then return end
    x, y = tonumber(x), tonumber(y)
    rotation, scale_x, scale_y = tonumber(rotation) or 0, tonumber(scale_x) or 1, tonumber(scale_y) or 1
    if not finite_number(x) or not finite_number(y) or not finite_number(rotation) then return end
    last_remote_pose_frame[sender] = frame
    form_pose_received = form_pose_received + 1

    local kind = tonumber(motion_kind) or 0
    local articulated = kind == 3 or kind == 5
    -- Worm/dragon forms keep their original serialized articulated bodies. Replaying an
    -- absolute root/physics snapshot at 20 Hz creates visible snapping and is expensive.
    -- Keep direction updates frequent, but correct the root only about five times/sec.
    local allow_root_correction = true
    if articulated then
        local previous_root = last_remote_root_frame[sender] or -100000
        allow_root_correction = frame - previous_root >= 8
        if allow_root_correction then last_remote_root_frame[sender] = frame end
    end
    local physics_applied = false
    if allow_root_correction and not articulated and type(phys_info) == "table"
        and type(util) == "table" and type(util.set_phys_info) == "function" then
        local fps = tonumber(data.fps) or 60
        local ok, result = pcall(util.set_phys_info, entity, phys_info, fps)
        physics_applied = ok and result == true
    end
    if allow_root_correction and not physics_applied then
        local target_x, target_y = x, y
        if articulated then
            local current_x, current_y = EntityGetTransform(entity)
            if finite_number(current_x) and finite_number(current_y) then
                local dx, dy = x - current_x, y - current_y
                local distance2 = dx * dx + dy * dy
                if distance2 < 56 * 56 then
                    -- Let the remote WormPlayer simulation absorb tiny drift; snapping
                    -- the root here is more visible than the error we are correcting.
                    allow_root_correction = false
                elseif distance2 < 320 * 320 then
                    -- Medium drift is eased instead of teleported. Large divergence still
                    -- gets a hard correction so unloaded terrain/network stalls recover.
                    target_x = current_x + dx * 0.35
                    target_y = current_y + dy * 0.35
                end
            end
        end
        if allow_root_correction then
            pcall(EntitySetTransform, entity, target_x, target_y, rotation, scale_x, scale_y)
        end
    end
    apply_motion_state(entity, kind, tonumber(motion_x) or 0, tonumber(motion_y) or 0, tonumber(motion_speed) or 0)
end
end

function forms_bridge.register_reserved(shared_rpc, shared_common)
    rpc, common = shared_rpc, shared_common
    rpc.opts_reliable()
    rpc.opts_everywhere()
    function rpc.announce_light_form_protocol(version)
        return
    end
end

local function send_form_pose(frame)
    local data = ctx.my_player
    local entity = data ~= nil and tonumber(data.entity) or 0
    if entity == 0 or not EntityGetIsAlive(entity) or not EntityHasTag(entity, "polymorphed_player") then return end

    -- EW's native player position serializer already handles forms that expose both
    -- CharacterDataComponent and CharacterPlatformingComponent. Do not run a second
    -- absolute-pose stream on top of it; this RPC exists only for forms that native EW
    -- cannot serialize (worms, ghosts, fish and unusual physics forms).
    local character_data = EntityGetFirstComponentIncludingDisabled(entity, "CharacterDataComponent")
    local platforming = EntityGetFirstComponentIncludingDisabled(entity, "CharacterPlatformingComponent")
    if character_data ~= nil and character_data ~= 0 and platforming ~= nil and platforming ~= 0 then return end

    local motion_kind, motion_x, motion_y, motion_speed = motion_state(entity)
    local interval = 3 -- latest-pose stream ~20 Hz; articulated root correction is budgeted below
    if frame - last_pose_send_frame < interval then return end
    local x, y, rotation, scale_x, scale_y = EntityGetTransform(entity)
    if not finite_number(x) or not finite_number(y) then return end
    last_pose_send_frame = frame

    local phys_info = false
    if motion_kind ~= 3 and motion_kind ~= 5 and type(util) == "table" and type(util.get_phys_info) == "function" then
        local has_phys = EntityGetFirstComponentIncludingDisabled(entity, "PhysicsBodyComponent") ~= nil
            or EntityGetFirstComponentIncludingDisabled(entity, "PhysicsBody2Component") ~= nil
        if has_phys then
            local ok, value = pcall(util.get_phys_info, entity, false)
            if ok and type(value) == "table" then phys_info = value end
        end
    end
    form_pose_sent = form_pose_sent + 1
    rpc.sync_form_pose(frame, x, y, rotation or 0, scale_x or 1, scale_y or 1,
        phys_info, motion_kind, motion_x, motion_y, motion_speed)
end

function forms_bridge.update(frame) send_form_pose(frame) end
function forms_bridge.metrics() return form_pose_sent, form_pose_received end
return forms_bridge
