local physics_adapter = {}

local entity_tree = dofile("mods/metamorph_creative_menu/files/platform/noita/entity_tree.lua")
local component_ops = dofile("mods/metamorph_creative_menu/files/features/forms/component_ops.lua")
local tree_cache = dofile("mods/metamorph_creative_menu/files/features/forms/entity_tree_cache.lua")
local controls = dofile("mods/metamorph_creative_menu/files/features/forms/controls.lua")

local valid = component_ops.valid
local component = component_ops.first
local get_value = component_ops.get
local boolean_value = component_ops.boolean
local ensure_controls = component_ops.ensure_controls
local set_component_type_enabled = component_ops.set_type_enabled
local tree_components = tree_cache.components

local steering_x = 0
local steering_y = 0
local captured_tuning = nil

local function clamp_vector(vector_x, vector_y, maximum_length)
    local length = math.sqrt(vector_x * vector_x + vector_y * vector_y)
    if length > maximum_length and length > 0 then
        local scale = maximum_length / length
        return vector_x * scale, vector_y * scale
    end
    return vector_x, vector_y
end

local function configure_ik_attachment(entity)
    entity_tree.walk(entity, function(current_entity)
        for _, animator_component in ipairs(EntityGetComponentIncludingDisabled(current_entity, "IKLimbsAnimatorComponent") or {}) do
            local no_ground_penalty = tonumber(get_value(animator_component, "no_ground_attachment_penalty_coeff", 0.75)) or 0.75
            local ray_length = tonumber(get_value(animator_component, "ground_attachment_ray_length_coeff", 1.15)) or 1.15
            local future_samples = tonumber(get_value(animator_component, "future_state_samples", 10)) or 10
            pcall(ComponentSetValue2, animator_component, "no_ground_attachment_penalty_coeff", math.min(no_ground_penalty, 0.35))
            pcall(ComponentSetValue2, animator_component, "ground_attachment_ray_length_coeff", math.max(ray_length, 1.28))
            pcall(ComponentSetValue2, animator_component, "future_state_samples", math.max(future_samples, 12))
        end
        for _, walker_component in ipairs(EntityGetComponentIncludingDisabled(current_entity, "IKLimbWalkerComponent") or {}) do
            local attachment_tries = tonumber(get_value(walker_component, "ground_attachment_max_tries", 10)) or 10
            local ray_length = tonumber(get_value(walker_component, "ground_attachment_ray_length_coeff", 1.15)) or 1.15
            pcall(ComponentSetValue2, walker_component, "ground_attachment_max_tries", math.max(attachment_tries, 16))
            pcall(ComponentSetValue2, walker_component, "ground_attachment_ray_length_coeff", math.max(ray_length, 1.28))
            pcall(EntitySetComponentIsEnabled, current_entity, walker_component, true)
        end
    end)
end

local function capture_tuning(entity, profile)
    local physics_ai_component = nil
    entity_tree.walk(entity, function(current_entity)
        local candidate = component(current_entity, "PhysicsAIComponent")
        if valid(candidate) then
            physics_ai_component = candidate
            return false
        end
    end)
    local profile_tuning = profile and profile.physics_ai or {}
    local function tuning_value(field_name, default_value)
        if valid(physics_ai_component) then
            local runtime_value = get_value(physics_ai_component, field_name, nil)
            if runtime_value ~= nil then return runtime_value end
        end
        local profile_value = profile_tuning and profile_tuning[field_name] or nil
        return profile_value ~= nil and profile_value or default_value
    end
    return {
        target_vec_max_len = tonumber(tuning_value("target_vec_max_len", 5)) or 5,
        force_coeff = tonumber(tuning_value("force_coeff", 30)) or 30,
        force_balancing_coeff = tonumber(tuning_value("force_balancing_coeff", 1.5)) or 1.5,
        force_max = tonumber(tuning_value("force_max", 100)) or 100,
        torque_coeff = tonumber(tuning_value("torque_coeff", 50)) or 50,
        torque_balancing_coeff = tonumber(tuning_value("torque_balancing_coeff", 0.2)) or 0.2,
        torque_max = tonumber(tuning_value("torque_max", 50)) or 50,
        levitate = boolean_value(tuning_value("levitate", false)) == true,
    }
end

local function ik_attachment_count(entity)
    local attached_count = 0
    local walker_components = tree_components(entity, "IKLimbWalkerComponent")
    for _, walker_component in ipairs(walker_components) do
        if tonumber(get_value(walker_component, "mState", 0)) == 1 then attached_count = attached_count + 1 end
    end
    if #walker_components > 0 then return attached_count, #walker_components end
    for _, animator_component in ipairs(tree_components(entity, "IKLimbsAnimatorComponent")) do
        if get_value(animator_component, "mHasGroundAttachmentOnAnyLeg", false) == true then
            return 1, 1
        end
    end
    return 0, 0
end

local function shortest_angle_delta(current_angle, target_angle)
    local difference = target_angle - current_angle
    while difference > math.pi do difference = difference - math.pi * 2 end
    while difference < -math.pi do difference = difference + math.pi * 2 end
    return difference
end

function physics_adapter.reset()
    steering_x = 0
    steering_y = 0
    captured_tuning = nil
end

function physics_adapter.configure(entity, profile, is_ik)
    steering_x, steering_y = 0, 0
    captured_tuning = capture_tuning(entity, profile)
    set_component_type_enabled(entity, "PhysicsAIComponent", false)
    local physics_tuning = captured_tuning or (profile and profile.physics_ai or {})
    if is_ik then configure_ik_attachment(entity) end
    for _, physics_body_id in ipairs(PhysicsBodyIDGetFromEntity(entity) or {}) do
        if is_ik then
            pcall(PhysicsBodyIDSetGravityScale, physics_body_id, 1)
        elseif physics_tuning.levitate == true then
            pcall(PhysicsBodyIDSetGravityScale, physics_body_id, 0)
        else
            pcall(PhysicsBodyIDSetGravityScale, physics_body_id, 1)
        end
    end
end

function physics_adapter.update(entity, profile, is_ik)
    local controls_component = ensure_controls(entity)
    local direction_x, direction_y, is_moving = controls.direction(controls_component)
    local physics_tuning = captured_tuning or (profile and profile.physics_ai or {})
    local target_vector_length = tonumber(physics_tuning.target_vec_max_len) or 5
    local force_coefficient = tonumber(physics_tuning.force_coeff) or 30
    local force_balance_coefficient = tonumber(physics_tuning.force_balancing_coeff) or 1.5
    local maximum_force = tonumber(physics_tuning.force_max) or 100
    local torque_coefficient = tonumber(physics_tuning.torque_coeff) or 50
    local torque_balance_coefficient = tonumber(physics_tuning.torque_balancing_coeff) or 0.2
    local maximum_torque = tonumber(physics_tuning.torque_max) or 50

    local has_support = true
    if is_ik then
        local attached_count, attachment_count = ik_attachment_count(entity)
        local required_attachments = attachment_count >= 2 and 2 or 1
        has_support = attachment_count == 0 or attached_count >= required_attachments
        if not has_support and direction_y < 0 then direction_y = 0 end
        is_moving = direction_x ~= 0 or direction_y ~= 0
    end

    if is_moving then
        local entity_x, entity_y = EntityGetTransform(entity)
        if entity_x ~= nil then
            for _, limb_component in ipairs(tree_components(entity, "LimbBossComponent")) do
                pcall(ComponentSetValue2, limb_component, "mMoveToPositionX", entity_x + direction_x * 96)
                local target_y = entity_y + direction_y * 96
                if has_support or target_y >= entity_y then
                    pcall(ComponentSetValue2, limb_component, "mMoveToPositionY", target_y)
                end
            end
        end
    end

    local steering_response = is_ik and 0.22 or 0.10
    local target_x = is_moving and direction_x or 0
    local target_y = is_moving and direction_y or 0
    steering_x = steering_x + (target_x - steering_x) * steering_response
    steering_y = steering_y + (target_y - steering_y) * steering_response

    local body_component = component(entity, "PhysicsBodyComponent") or component(entity, "PhysicsBody2Component")
    local velocity_x, velocity_y = 0, 0
    if valid(body_component) then
        local velocity_read_succeeded, current_velocity_x, current_velocity_y = pcall(PhysicsGetComponentVelocity, entity, body_component)
        if velocity_read_succeeded then
            velocity_x, velocity_y = tonumber(current_velocity_x) or 0, tonumber(current_velocity_y) or 0
        end
    end

    local desired_velocity_x, desired_velocity_y = steering_x * target_vector_length, steering_y * target_vector_length
    local force_x = (desired_velocity_x - velocity_x) * force_coefficient - velocity_x * force_balance_coefficient
    local force_y = (desired_velocity_y - velocity_y) * force_coefficient - velocity_y * force_balance_coefficient
    force_x, force_y = clamp_vector(force_x, force_y, maximum_force)
    pcall(PhysicsApplyForce, entity, force_x, force_y)

    if is_moving and (math.abs(direction_x) + math.abs(direction_y)) > 0.001 then
        local _, _, current_rotation = EntityGetTransform(entity)
        current_rotation = tonumber(current_rotation) or 0
        local desired_angle = math.atan2 and math.atan2(direction_y, direction_x) or math.atan(direction_y, direction_x)
        local angular_velocity = 0
        if valid(body_component) then
            local angular_velocity_read_succeeded, current_angular_velocity = pcall(PhysicsGetComponentAngularVelocity, entity, body_component)
            if angular_velocity_read_succeeded then angular_velocity = tonumber(current_angular_velocity) or 0 end
        end
        local torque = shortest_angle_delta(current_rotation, desired_angle) * torque_coefficient
            - angular_velocity * torque_balance_coefficient
        torque = math.max(-maximum_torque, math.min(maximum_torque, torque))
        pcall(PhysicsApplyTorque, entity, torque)
    end
end

return physics_adapter
