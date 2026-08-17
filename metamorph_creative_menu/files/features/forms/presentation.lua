local form_presentation = {}

local component_ops = dofile("mods/metamorph_creative_menu/files/features/forms/component_ops.lua")

local valid = component_ops.valid
local component = component_ops.first
local get_value = component_ops.get
local boolean_value = component_ops.boolean
local set_typed_scalar = component_ops.set_typed_scalar
local set_if_present = component_ops.set_fields_if_present

local CHARACTER_DATA_FIELDS = {
    "platforming_type", "mass", "buoyancy_check_offset_y", "liquid_velocity_coeff", "gravity",
    "fly_recharge_spd", "fly_recharge_spd_ground", "flying_needs_recharge",
    "flying_in_air_wait_frames", "flying_recharge_removal_frames", "climb_over_y",
    "check_collision_max_size_x", "check_collision_max_size_y", "ground_stickyness",
    "fly_time_max",
}

local PLATFORMING_FIELDS = {
    "jump_velocity_x", "jump_velocity_y", "jump_keydown_buffer",
    "fly_speed_mult", "fly_speed_change_spd", "fly_model_player", "fly_smooth_y",
    "accel_x", "accel_x_air", "pixel_gravity",
    "swim_idle_buoyancy_coeff", "swim_down_buoyancy_coeff", "swim_up_buoyancy_coeff",
    "swim_drag", "swim_extra_horizontal_drag",
    "mouse_look", "mouse_look_buffer", "keyboard_look", "turning_buffer",
    "run_animation_velocity_switching_threshold", "run_animation_velocity_switching_enabled",
    "turn_animation_frames_between", "precision_jumping_max_duration_frames",
    "velocity_min_x", "velocity_max_x", "velocity_min_y", "velocity_max_y",
    "run_velocity", "fly_velocity_x", "fly_speed_max_up", "fly_speed_max_down",
}

function form_presentation.ensure_vision(entity)
    -- LightComponent illuminates revealed pixels, while the fog components reveal new
    -- terrain. Keep both capabilities on a player-controlled creature form.
    if not valid(EntityGetFirstComponentIncludingDisabled(entity, "LightComponent", "metamorph_creative_menu_form_light")) then
        pcall(EntityAddComponent2, entity, "LightComponent", {
            _tags = "metamorph_creative_menu_form_light", r = 255, g = 255, b = 255,
            radius = 350, fade_out_time = 5,
        })
    end
    if not valid(component(entity, "FogOfWarRadiusComponent")) then
        pcall(EntityAddComponent2, entity, "FogOfWarRadiusComponent", {
            _tags = "metamorph_creative_menu_form_vision", radius = 256,
        })
    end
    if not valid(component(entity, "FogOfWarRemoverComponent")) then
        pcall(EntityAddComponent2, entity, "FogOfWarRemoverComponent", {
            _tags = "metamorph_creative_menu_form_vision", radius = 140,
        })
    end
end

function form_presentation.apply_native_herd(entity, profile)
    if type(profile) ~= "table" or type(profile.genome) ~= "table" then return end
    local herd_id_or_name = profile.genome.herd_id
    if herd_id_or_name == nil or herd_id_or_name == "" then return end
    local genome_component = component(entity, "GenomeDataComponent")
    if not valid(genome_component) then return end
    if type(herd_id_or_name) == "number" then
        pcall(ComponentSetValue2, genome_component, "herd_id", herd_id_or_name)
    elseif type(GenomeSetHerdId) == "function" then
        pcall(GenomeSetHerdId, entity, tostring(herd_id_or_name))
    end
end

function form_presentation.sync_damage_ui(entity)
    local damage_model_component = component(entity, "DamageModelComponent")
    if not valid(damage_model_component) then return end
    local maximum_hp = tonumber(get_value(damage_model_component, "max_hp", 0)) or 0
    if maximum_hp > 0 then
        pcall(ComponentSetValue2, damage_model_component, "max_hp_old", maximum_hp)
        pcall(ComponentSetValue2, damage_model_component, "mLastMaxHpChangeFrame", -10000)
    end
end

function form_presentation.prime_transform_damage_ui(entity)
    local damage_model_component = component(entity, "DamageModelComponent")
    if not valid(damage_model_component) then return end
    -- Clear damage-feedback frames inherited by the newly created polymorph body once.
    pcall(ComponentSetValue2, damage_model_component, "mLastDamageFrame", -120)
    pcall(ComponentSetValue2, damage_model_component, "mLastMaxHpChangeFrame", -10000)
end

function form_presentation.apply_damage_overlay(entity, profile)
    local damage_model_component = component(entity, "DamageModelComponent")
    if not valid(damage_model_component) or type(profile) ~= "table" then return false end
    local damage_overrides = profile.damage_override or {}
    local changed = false
    for field_name, field_value in pairs(damage_overrides) do
        if field_name ~= "_enabled" and field_name ~= "_tags" then
            changed = set_typed_scalar(damage_model_component, field_name, field_value) or changed
        end
    end
    form_presentation.sync_damage_ui(entity)
    return changed
end

function form_presentation.apply_character_profile(entity, profile)
    if type(profile) ~= "table" then return end
    local character_data_component = component(entity, "CharacterDataComponent")
    local platforming_component = component(entity, "CharacterPlatformingComponent")
    set_if_present(character_data_component, profile.character_data, CHARACTER_DATA_FIELDS)
    set_if_present(platforming_component, profile.platforming, PLATFORMING_FIELDS)

    -- Preserve each creature's authored flight model rather than replacing it with an
    -- infinite player levitation resource.
    if profile.can_fly and valid(character_data_component) then
        local native_recharge = boolean_value(profile.character_data and profile.character_data.flying_needs_recharge)
        if profile.pure_flyer == true then
            pcall(ComponentSetValue2, character_data_component, "flying_needs_recharge", false)
            local maximum_flight_time = tonumber(profile.character_data and profile.character_data.fly_time_max)
                or tonumber(get_value(character_data_component, "fly_time_max", 0)) or 0
            if maximum_flight_time > 0 then
                pcall(ComponentSetValue2, character_data_component, "mFlyingTimeLeft", maximum_flight_time)
            end
        else
            if native_recharge == false then
                pcall(ComponentSetValue2, character_data_component, "flying_needs_recharge", false)
            end
            local maximum_flight_time = tonumber(profile.character_data and profile.character_data.fly_time_max)
                or tonumber(get_value(character_data_component, "fly_time_max", 0)) or 0
            local remaining_flight_time = tonumber(get_value(character_data_component, "mFlyingTimeLeft", 0)) or 0
            if maximum_flight_time > 0 and remaining_flight_time <= 0 then
                pcall(ComponentSetValue2, character_data_component, "mFlyingTimeLeft", maximum_flight_time)
            end
        end
    end
end

return form_presentation
