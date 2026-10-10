if type(METAMORPH_CREATIVE_MENU_FORM_COMPAT) == "table" then return METAMORPH_CREATIVE_MENU_FORM_COMPAT end

local form_runtime = {}

local profile_api = dofile("mods/metamorph_creative_menu/files/features/forms/profile.lua")
local component_ops = dofile("mods/metamorph_creative_menu/files/features/forms/component_ops.lua")
local tree_cache = dofile("mods/metamorph_creative_menu/files/features/forms/entity_tree_cache.lua")
local presentation = dofile("mods/metamorph_creative_menu/files/features/forms/presentation.lua")
local form_family = dofile("mods/metamorph_creative_menu/files/features/forms/family.lua")
local ghost_adapter = dofile("mods/metamorph_creative_menu/files/features/forms/adapters/ghost.lua")
local fish_adapter = dofile("mods/metamorph_creative_menu/files/features/forms/adapters/fish.lua")
local worm_adapter = dofile("mods/metamorph_creative_menu/files/features/forms/adapters/worm.lua")
local physics_adapter = dofile("mods/metamorph_creative_menu/files/features/forms/adapters/physics.lua")
local form_combat = dofile("mods/metamorph_creative_menu/files/features/forms/combat.lua")
local boss_dragon_adapter = dofile("mods/metamorph_creative_menu/files/features/forms/adapters/boss_dragon.lua")
local scripted_attacks = dofile("mods/metamorph_creative_menu/files/features/forms/scripted_attacks.lua")
local manual_actions = dofile("mods/metamorph_creative_menu/files/features/forms/adapters/manual_actions.lua")
local projectile_forms = dofile("mods/metamorph_creative_menu/files/features/forms/projectile_forms/controller.lua")
local static_weapon_presentation = dofile("mods/metamorph_creative_menu/files/features/forms/adapters/static_weapon_presentation.lua")
local held_wand_forms = dofile("mods/metamorph_creative_menu/files/features/forms/held_wand_forms/controller.lua")

local applied_entity = 0
local applied_started = -1
local active_family = ""
local root_lifecycle_is_temporary = false

local ensure_controls = component_ops.ensure_controls
local add_death_guard = component_ops.add_death_guard

local setup_manual_barrels = form_combat.setup_manual_barrels
local configure_non_ai_player = form_combat.configure_non_ai_player
local configure_ranged_player = form_combat.configure_ranged_player
local update_ranged_attacks = form_combat.update_ranged_attacks
local update_manual_aim = form_combat.update_manual_aim
local update_manual_lasers = form_combat.update_manual_lasers

local ensure_form_vision = presentation.ensure_vision
local apply_native_herd = presentation.apply_native_herd
local sync_damage_ui = presentation.sync_damage_ui
local prime_transform_damage_ui = presentation.prime_transform_damage_ui
local apply_damage_overlay = presentation.apply_damage_overlay
local apply_character_profile = presentation.apply_character_profile

local claim_root_lifecycle = form_family.claim_root_lifecycle
local runtime_family = form_family.detect



local stabilize_special_ghost_lifecycle = ghost_adapter.stabilize_lifecycle
local configure_ghost_player = ghost_adapter.configure
local update_ghost_player = ghost_adapter.update

local function configure_character_player(entity)
    configure_non_ai_player(entity)
    setup_manual_barrels(entity)
end

local function configure_fish_player(entity, profile)
    configure_non_ai_player(entity)
    setup_manual_barrels(entity)
    fish_adapter.configure(entity, profile)
end

local update_fish_player = fish_adapter.update

local function configure_worm_player(entity)
    worm_adapter.configure(entity, root_lifecycle_is_temporary)
end

local update_worm_player = worm_adapter.update

local function configure_physics_player(entity, profile, is_ik)
    configure_non_ai_player(entity)
    setup_manual_barrels(entity)
    physics_adapter.configure(entity, profile, is_ik)
end

local update_physics_player = physics_adapter.update

local reset_tree_component_cache = tree_cache.reset

local configure_boss_dragon = boss_dragon_adapter.configure
local update_boss_dragon = boss_dragon_adapter.update

function form_runtime.reset()
    applied_entity = 0
    applied_started = -1
    active_family = ""
    worm_adapter.reset()
    physics_adapter.reset()
    form_combat.reset()
    scripted_attacks.reset()
    manual_actions.reset()
    projectile_forms.reset()
    static_weapon_presentation.reset()
    held_wand_forms.reset()
    boss_dragon_adapter.reset()
    root_lifecycle_is_temporary = false
end

function form_runtime.apply(entity, session)
    reset_tree_component_cache()
    if entity == nil or entity == 0 or not EntityGetIsAlive(entity) or type(session) ~= "table" then
        return false
    end
    -- Belt-and-suspenders guard: form_manager owns the lifecycle invariant, and this
    -- module additionally refuses to mutate a restored human if called incorrectly.
    if not EntityHasTag(entity, "polymorphed_player") then return false end

    local profile_path = session.requested_target or session.target
    local profile = session.profile or profile_api.get(profile_path)
    root_lifecycle_is_temporary = claim_root_lifecycle(entity)
    if session.compatibility_mode == "canonical_damage_overlay" or session.compatibility_mode == "canonical_crash_fallback" then
        apply_damage_overlay(entity, profile)
    end
    apply_character_profile(entity, profile)
    apply_native_herd(entity, profile)
    ensure_form_vision(entity)
    sync_damage_ui(entity)
    prime_transform_damage_ui(entity)
    stabilize_special_ghost_lifecycle(entity)
    if session.allow_death_handoff == true then
        add_death_guard(entity)
    end

    -- Projectile-shaped forms (currently Boss Pit wands) are not creatures with an AI
    -- body at all. Give them a dedicated controller instead of forcing projectile
    -- lifecycle/rendering through character/physics adapters.
    local projectile_owned = projectile_forms.configure(entity, profile_path, profile)
    if not projectile_owned then
        -- Snapshot manual melee/physics-projectile capabilities before family
        -- adapters disable native AnimalAI. Normal ranged attacks stay in form_combat.
        manual_actions.configure(entity, profile_path, profile)
    end

    active_family = projectile_owned and "projectile_form" or runtime_family(entity)
    if active_family == "ghost_native" then
        configure_ghost_player(entity)
        if not held_wand_forms.configure(entity, profile_path) then
            configure_ranged_player(entity)
        end
    elseif active_family == "boss_dragon" then
        configure_boss_dragon(entity)
    elseif active_family == "ik_physics" then
        configure_physics_player(entity, profile, true)
    elseif active_family == "physics" then
        configure_physics_player(entity, profile, false)
    elseif active_family == "worm_native" then
        configure_ranged_player(entity)
        configure_worm_player(entity)
    elseif active_family == "fish" then
        configure_fish_player(entity, profile)
    elseif active_family == "character" then
        configure_character_player(entity)
    end

    if not projectile_owned then static_weapon_presentation.configure(entity) end

    -- Some vanilla creatures implement part or all of their firing in Lua rather than
    -- AnimalAI/AIAttack. Snapshot/disable only those known attack scripts and replay
    -- their authored projectile patterns under player fire input. Component-authored
    -- attacks remain active through form_combat, so mixed creatures keep both layers.
    if not projectile_owned then scripted_attacks.configure(entity, profile_path) end

    applied_entity = entity
    applied_started = tonumber(session.started) or GameGetFrameNum()
    return true
end

function form_runtime.update(entity, session)
    reset_tree_component_cache()
    if entity == nil or entity == 0 or not EntityGetIsAlive(entity) or type(session) ~= "table" then
        form_runtime.reset()
        return
    end
    if not EntityHasTag(entity, "polymorphed_player") then
        form_runtime.reset()
        return
    end
    if applied_entity ~= entity or applied_started ~= tonumber(session.started) then
        form_runtime.apply(entity, session)
        -- apply() may add/disable compatibility components. Build the update snapshot
        -- from the post-apply tree rather than reusing anything observed during apply.
        reset_tree_component_cache()
    end

    local profile = session.profile or profile_api.get(session.requested_target or session.target)
    -- max_hp_old/mLastMaxHpChangeFrame are presentation history, not invariants. They
    -- are primed when the form is applied, but must not be overwritten every frame:
    -- doing so hides legitimate max-HP changes from perks/effects while transformed.
    -- The short transition window below is sufficient to discard stale polymorph UI.
    -- The polymorph swap can rewrite the damage presentation timestamps for a few
    -- updates after the new body exists. Keep only that tiny transition window clean;
    -- after it expires real damage flashes/feedback are untouched.
    local now = tonumber(GameGetFrameNum()) or 0
    if applied_started >= 0 and now - applied_started <= 8 then
        prime_transform_damage_ui(entity)
    end
    -- apply() performs one defensive lifecycle scan for every form. Repeating that
    -- whole-tree Ghost/Lua scan every frame is only necessary for native ghost forms.
    if active_family == "ghost_native" then
        stabilize_special_ghost_lifecycle(entity)
        update_ghost_player(entity)
        held_wand_forms.update(entity)
    elseif active_family == "boss_dragon" then
        update_boss_dragon(entity)
    elseif active_family == "ik_physics" then
        update_physics_player(entity, profile, true)
    elseif active_family == "physics" then
        update_physics_player(entity, profile, false)
    elseif active_family == "worm_native" then
        update_worm_player(entity)
    elseif active_family == "fish" then
        update_fish_player(entity)
    elseif active_family == "projectile_form" then
        projectile_forms.update(entity)
        return
    end

    static_weapon_presentation.update(entity)

    -- Player-only actions (melee/physics-projectile control) are evaluated after the
    -- family movement adapter. An owned input surface is then withheld from both ranged replay
    -- layers, preventing one RMB/LMB press from triggering two attacks.
    if not held_wand_forms.active() then manual_actions.update(entity) end
    local allow_primary = not manual_actions.owns_primary() and not held_wand_forms.owns_primary()
    local allow_secondary = not manual_actions.owns_secondary()

    -- BossDragonComponent has its own authored projectile interface and dedicated
    -- adapter. Wand ghosts are another explicit ownership boundary: their real carried
    -- procedural wand is fired by a short native AnimalAI attack state, so the generic
    -- descriptor replay must not reacquire the fallback orb_pink attack underneath it.
    if active_family ~= "boss_dragon" and not held_wand_forms.active() then
        if form_combat.manual_ranged_owned() then update_manual_aim(entity) end
        if not scripted_attacks.manages_lasers() then update_manual_lasers(entity, allow_secondary, allow_primary) end
        update_ranged_attacks(entity, allow_secondary, allow_primary)
    end
    scripted_attacks.update(entity, allow_secondary, allow_primary)
end

function form_runtime.family()
    return active_family
end

function form_runtime.draw_health(entity, session)
    -- Kept as a stable hook for form_manager.  The vanilla player HUD already reads a
    -- playerized creature DamageModelComponent.
    return false
end

METAMORPH_CREATIVE_MENU_FORM_COMPAT = form_runtime
return form_runtime
