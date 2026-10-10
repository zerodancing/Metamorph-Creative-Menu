local runtime_effects = {}

function runtime_effects.emit_rain(state)
    local amount = math.max(0, math.min(1, tonumber(state.rainfall) or 0))
    if amount <= 0 or type(GameEmitRainParticles) ~= "function" then return end
    local frame = GameGetFrameNum()
    if state.last_rain_emit_frame == frame then return end
    local interval = amount >= 0.7 and 2 or (amount >= 0.35 and 3 or 5)
    if frame % interval ~= 0 then return end
    local particle_count = math.max(1, math.floor(2 + amount * 12))

    -- Use water so wetness/status behaviour stays native. Bouncing is disabled because
    -- bounced material can remain over the camera and look like rain is still emitting.
    pcall(GameEmitRainParticles, particle_count, 1024, "water", 200, 220, 200, false, true)
    state.last_rain_emit_frame = frame
    state.rain_emitted_total = (tonumber(state.rain_emitted_total) or 0) + particle_count
end

function runtime_effects.update_lightning(state, world_component, write_value)
    local rate = math.max(0, math.min(1, tonumber(state.lightning) or 0))
    local frame = GameGetFrameNum()
    if state.last_lightning_update_frame == frame then return end
    state.last_lightning_update_frame = frame

    if (tonumber(state.lightning_clear_frame) or 0) > 0 and frame >= state.lightning_clear_frame then
        write_value(world_component, "lightning_count", 0)
        state.lightning_clear_frame = 0
    end
    if rate <= 0 or frame < (tonumber(state.next_lightning_frame) or 0) then return end

    local minimum_interval_frames = 90
    local maximum_interval_frames = 720
    local interval_frames = math.floor(maximum_interval_frames - (maximum_interval_frames - minimum_interval_frames) * rate)
    local jitter_frames = 0
    if type(ProceduralRandomi) == "function" then
        local random_succeeded, value = pcall(
            ProceduralRandomi,
            frame,
            7717,
            0,
            math.max(1, math.floor(interval_frames * 0.35))
        )
        if random_succeeded then jitter_frames = tonumber(value) or 0 end
    end

    -- Pulse for one frame only. A persistent positive lightning_count can become an
    -- endless lightning source on engine/mod combinations that do not consume it.
    write_value(world_component, "lightning_count", 1)
    state.lightning_clear_frame = frame + 1
    state.next_lightning_frame = frame + math.max(minimum_interval_frames, interval_frames + jitter_frames)
end

return runtime_effects
