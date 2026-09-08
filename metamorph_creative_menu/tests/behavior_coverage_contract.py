from pathlib import Path
import sys

root = Path(sys.argv[1] if len(sys.argv) > 1 else '.').resolve()
tests_dir = root / 'tests'

# This is deliberately a behavior map, not a source-layout map. A mechanic may be
# refactored into any files as long as at least one executable regression scenario still
# proves its externally important behavior.
BEHAVIORS = {
    'assignable_actions_support_modifiers_mouse_conflicts_capture_and_migration': {
        'action_bindings_mock.lua', 'settings_action_registry_mock.lua',
    },
    'menu_has_useful_default_direct_navigation_persistence_windows_layout_and_readable_controls': {
        'menu_navigation_bindings_mock.lua', 'ui_responsive_layout_mock.lua',
        'controls_scroll_layout_mock.lua', 'ui_adaptive_sections_mock.lua',
        'menu_inventory_visibility_policy_mock.lua',
        'menu_inventory_policy_controller_mock.lua',
    },
    'long_menu_scroll_is_native_contained_grid_fits_and_horizontal_wheel_is_owned': {
        'scroll_grid_model_mock.lua', 'runtime_scroll_viewport_mock.lua',
    },
    'menu_survives_tab_runtime_error': {'menu_error_isolation_mock.lua'},
    'runtime_update_failure_is_isolated': {'runtime_update_isolation_mock.lua'},
    'network_modules_do_not_touch_worldstate_during_source_load': {'startup_no_world_globals_mock.lua'},
    'menu_inventory_state_is_preserved': {'menu_inventory_guard_mock.lua'},
    'spells_catalog_and_wand_operations_sync': {
        'spell_catalog_mock.lua', 'spell_service_mock.lua', 'spell_inventory_transfer_mock.lua', 'spell_permanent_service_mock.lua',
        'drag_drop_release_mock.lua', 'native_inventory_drop_bounds_mock.lua', 'wand_always_cast_drop_click_mock.lua',
    },
    'spells_drag_uses_press_origin_survives_reflow_and_commits_transactionally_once': {
        'drag_drop_lifecycle_mock.lua', 'horizontal_strip_drag_ownership_mock.lua', 'spell_drag_world_transaction_mock.lua',
    },
    'spells_catalog_renders_real_placement_surfaces_with_shared_drag_sources': {
        'spells_interaction_surface_mock.lua', 'spell_inventory_grid_mock.lua',
    },
    'catalog_search_is_multilingual_ranked_and_requires_explicit_pointer_focus': {
        'search_engine_mock.lua', 'search_field_cache_mock.lua', 'search_focus_mock.lua', 'text_focus_owner_mock.lua',
    },
    'wand_blueprints_preserve_card_state_and_creative_spawning_does_not_unlock_progression': {
        'wand_blueprint_codec_mock.lua', 'wand_blueprints_v2_mock.lua', 'wand_presets_persistence_mock.lua', 'wand_presets_copy_mock.lua', 'wand_presets_ui_mock.lua', 'wand_history_mock.lua', 'history_external_mock.lua', 'spell_factory_unlock_mock.lua',
    },
    'wand_editor_stats_appearance_and_skin_geometry_are_transactional': {
        'wand_appearance_mock.lua', 'wand_appearance_editor_mock.lua', 'wand_skin_catalog_mock.lua',
        'fixed_numeric_editor_bounds_mock.lua', 'fixed_numeric_focus_draft_mock.lua', 'wand_service_slot_limit_mock.lua', 'negative_wand_mock.lua',
        'wand_stats_layout_mock.lua',
    },
    'items_lmb_spawn_rmb_inventory_sync_and_nonstandard_vanilla_item_roles': {
        'item_world_spawn_sync_mock.lua', 'item_inventory_sync_mock.lua', 'item_outlier_catalog_mock.lua',
        'item_icon_descriptor_mock.lua', 'item_icon_transient_fallback_mock.lua', 'item_outbox_failure_mock.lua',
    },
    'items_catalog_drag_uses_shared_threshold_exact_world_coordinates_inventory_cancel_and_transactional_cleanup': {
        'items_drag_interaction_mock.lua', 'item_drag_transaction_mock.lua',
    },
    'items_four_wand_four_item_capacity_and_overflow': {'inventory_capacity_mock.lua'},
    'items_liquid_lmb_rmb_and_preview_cleanup': {
        'item_liquid_service_mock.lua', 'item_liquid_preview_mock.lua', 'liquid_tile_render_mock.lua',
        'item_all_liquid_catalog_mock.lua', 'item_liquid_localized_search_mock.lua',
    },
    'materials_catalog_selection_and_world_painting': {
        'material_catalog_mock.lua', 'material_complete_catalog_mock.lua', 'material_vanilla_data_mock.lua', 'material_painter_mock.lua',
        'material_grid_backend_mock.lua', 'material_feature_wiring_mock.lua',
        'material_tab_deferred_catalog_mock.lua', 'material_tab_preview_mock.lua',
        'ew_material_pixel_scene_patch_mock.lua',
        'material_paint_transport_mock.lua', 'ew_material_stock_transport_mock.lua',
        'ew_material_backpressure_mock.lua',
    },
    'perks_spawn_pickup_apply_transaction': {
        'perk_spawn_mock.lua', 'perk_direct_apply_mock.lua',
        'perk_pickup_hook_mock.lua', 'perk_external_pickup_mock.lua',
        'perk_drag_interaction_mock.lua',
    },
    'perks_global_state_is_transactional': {'perk_global_journal_mock.lua', 'perk_mutation_journal_mock.lua', 'perk_owned_residue_failure_mock.lua', 'perk_pending_cleanup_timeout_mock.lua', 'perk_failed_pickup_rollback_backoff_mock.lua'},
    'perks_stacks_remove_without_residue_across_repeated_cycles': {'perk_service_repeated_cycle_mock.lua', 'perk_player_rebind_mock.lua', 'perk_service_rebind_wiring_mock.lua'},
    'perks_mass_take_and_remove_are_bounded_transactional_jobs': {'perk_batch_queue_mock.lua', 'perk_tab_batch_ui_mock.lua', 'perk_scroll_surface_mock.lua'},
    'perks_non_perk_essences_and_curses_are_removable': {'non_perk_states_mock.lua', 'perk_states_grid_mock.lua'},
    'perks_special_inverse_cleanup': {
        'extra_mana_mock.lua', 'gamble_mock.lua', 'ghost_extra_inverse_mock.lua',
        'ghost_root_ownership_mock.lua', 'beamstone_ownership_mock.lua', 'perk_peer_root_isolation_mock.lua',
        'protection_presentation_mock.lua', 'lukki_order_mock.lua', 'perk_radar_invisibility_regression_mock.lua', 'perk_locomotion_guard_mock.lua', 'perk_always_cast_ownership_mock.lua',
        'perk_tab_unsafe_removal_mock.lua',
    },
    'creature_catalog_and_spawn_surface': {
        'creature_catalog_mock.lua', 'creature_spawn_mock.lua', 'creature_drag_interaction_mock.lua', 'creature_kolmi_spawn_compat_mock.lua', 'creature_kolmi_bootstrap_mock.lua', 'creature_kolmi_encounter_controller_mock.lua', 'creature_kolmi_combat_verify_mock.lua',
        'ew_creature_track_bridge_mock.lua', 'ew_boss_network_pressure_mock.lua', 'form_network_pressure_mock.lua', 'creature_structural_admission_mock.lua', 'creature_compatibility_policy_mock.lua',
        'creature_exact_target_mock.lua', 'creature_menu_visibility_mock.lua',
    },
    'form_rmb_transform_creates_session_and_chained_switch_preserves_human_frame': {'form_transform_session_mock.lua', 'form_chained_transform_human_frame_mock.lua', 'creature_exact_target_mock.lua', 'form_network_marker_hotpath_mock.lua'},
    'form_tab_returns_to_human_without_g_collision_and_after_save_recovery': {
        'form_tab_return_mock.lua', 'form_return_controls_mock.lua',
        'possession_keybind_routing_mock.lua', 'form_save_recovery_mock.lua',
    },
    'form_native_and_external_death_restore_human_and_preserve_corpse': {
        'form_death_guard_mock.lua', 'form_death_handoff_integration_mock.lua',
        'form_external_polymorph_adoption_mock.lua', 'form_corpse_tree_freeze_mock.lua',
        'form_death_channel_ack_mock.lua', 'ew_form_death_intercept_patch_mock.lua',
        'form_network_body_retire_mock.lua',
    },
    'vanilla_gameover_exposes_native_revive_and_restores_player_authority': {
        'death_recovery_native_service_mock.lua', 'native_gameover_ew_gate_mock.lua',
        'death_recovery_ew_disabled_mock.lua',
    },
    'giant_forms_disable_ai_and_accept_player_input': {'boss_dragon_adapter_mock.lua', 'form_physics_static_ik_mock.lua', 'form_physics_flying_ik_mock.lua'},
    'form_runtime_combat_authority_and_presentation': {
        'form_runtime_reset_mock.lua', 'form_combat_laser_mock.lua', 'form_combat_singleton_cleanup_mock.lua', 'form_projectile_failure_mock.lua',
        'form_attack_profile_mock.lua', 'form_primary_projectile_replay_mock.lua', 'form_multiattack_replay_mock.lua', 'form_ranged_aim_replay_mock.lua', 'form_rotating_muzzle_origin_mock.lua', 'form_static_turret_arc_mock.lua', 'form_contextual_attack_fallback_mock.lua', 'form_dormant_attack_mock.lua', 'form_dynamic_attack_state_mock.lua', 'form_late_first_attack_mock.lua', 'form_scripted_attack_math_mock.lua', 'form_scripted_attack_replay_mock.lua', 'form_scripted_attack_state_mock.lua',
        'form_player_authority_mock.lua', 'form_transform_flash_mock.lua', 'form_tank_special_case_removal_mock.lua', 'form_static_tank_aim_mock.lua', 'form_static_weapon_presentation_mock.lua', 'form_manual_actions_mock.lua', 'form_wand_ghost_controller_mock.lua', 'form_fish_breathing_mock.lua',
    },
    'g_possession_replaces_original_and_preserves_position': {
        'possession_replacement_mock.lua', 'possession_client_fallback_mock.lua',
        'possession_remote_replica_mock.lua', 'possession_des_ack_retire_mock.lua',
        'ew_mailbox_drain_mock.lua', 'possession_tree_retirement_mock.lua',
        'possession_creature_policy_mock.lua', 'possession_fast_reject_mock.lua', 'possession_crypt_replacement_mock.lua',
        'possession_robobase_replacement_mock.lua', 'possession_outbox_retention_mock.lua',
    },
    'effects_apply_become_active_remove_and_expire': {'effect_lifecycle_mock.lua', 'effect_variant_catalog_mock.lua', 'effect_editor_catalog_mock.lua', 'effect_control_lock_safety_mock.lua', 'effect_lifetime_entity_mock.lua', 'effect_perk_duration_mock.lua'},
    'weather_time_preset_precise_fields_and_ew_snapshot': {'weather_state_sync_mock.lua', 'weather_clouds_mock.lua', 'lightning_sync_mock.lua'},
    'world_rules_apply_reset_and_network_dirty_state': {
        'world_rules_lifecycle_mock.lua', 'world_rules_sync_mock.lua', 'gravity_mock.lua',
        'world_state_native_restore_mock.lua', 'world_rules_physics_ownership_mock.lua',
        'world_rules_click_deferred_scan_mock.lua', 'world_rules_sync_restart_mailbox_mock.lua',
        'world_rules_restart_recovery_mock.lua', 'world_rules_ui_action_isolation_mock.lua',
        'world_rules_stain_ownership_mock.lua', 'world_rules_magic_multiplier_mock.lua',
        'world_rules_bridge_restart_mailbox_mock.lua', 'world_rules_recovery_write_budget_mock.lua',
        'world_rules_world_state_roundtrip_mock.lua', 'world_rules_magic_partial_rollback_mock.lua',
        'world_rules_sync_local_intent_race_mock.lua', 'world_rules_time_dt_owner_mock.lua', 'false_recovery_mock.lua', 'physics_reentry_mock.lua',
    },
    'host_and_client_have_equal_menu_rights': {'equal_peer_rights_mock.lua'},
    'teleports_are_demand_driven_stream_destinations_use_free_space_and_target_bring_requests': {
        'player_tools_safe_teleport_mock.lua', 'teleport_pending_mock.lua', 'teleport_current_coordinates_ui_mock.lua', 'ew_teleport_bring_mock.lua', 'ew_mailbox_drain_mock.lua',
    },
    'companion_spawn_health_and_network_request': {'companion_guard_mock.lua', 'companion_network_des_mock.lua', 'client_clone_ai_mock.lua', 'clone_idle_scan_mock.lua'},
    'ew_rpc_protocol_and_serialization_are_stable': {'ew_protocol_mock.lua', 'ew_serialization_mock.lua', 'ew_polymorph_profile_patch_mock.lua', 'form_remote_prepare_profile_mock.lua', 'form_pose_entity_generation_mock.lua'},
    'creative_perk_network_visibility_preserves_stock_ew_semantics': {
        'perk_transaction_source_mock.lua', 'ew_perk_visibility_mock.lua', 'ew_perk_sync_patch_mock.lua',
        'creative_perk_registration_mock.lua', 'creative_perk_peer_consume_mock.lua',
    },
    'standalone_noitapatcher_bootstrap_and_ew_reuse': {'standalone_patcher_mock.lua', 'patcher_bridge_ew_shared_path_mock.lua'},
    'ew_compatibility_source_patches_are_verified_and_runtime_bridges_remain_bounded': {
        'ew_resilience_status_mock.lua', 'ew_world_sync_patch_mock.lua', 'ew_perk_sync_patch_mock.lua', 'ew_perk_helper_sync_patch_mock.lua', 'ew_perk_mutation_sync_patch_mock.lua', 'ew_perk_runtime_guard_mock.lua', 'ew_wand_pickup_guard_mock.lua', 'ew_kolmi_crosscall_failopen_mock.lua', 'ew_kolmi_spawn_failopen_mock.lua',
    },
    'ew_global_boss_tracking_is_demoted_before_native_des_classification': {
        'ew_boss_global_demote_mock.lua', 'creature_kolmi_arena_dedupe_mock.lua', 'ew_kolmi_lifecycle_mock.lua', 'ew_boss_lifecycle_mock.lua',
    },
    'qa_is_lazy_and_has_consistent_state_graph': {'qa_controller_mock.lua', 'qa_baselines_scope_mock.lua'},
    'release_dev_mode_unloads_runtime_diagnostics_and_preserves_ew_protocol_slot': {
        'dev_mode_runtime_gate_mock.lua', 'ew_dev_mode_bridge_gate_mock.lua',
    },
    'diagnostics_are_bounded_and_runtime_scanner_executes': {
        'bounded_log_mock.lua', 'diagnostics_scanner_load_mock.lua', 'global_text_mock.lua',
    },
    'input_focus_and_tab_g_keycodes_are_safe': {'keycodes_mock.lua', 'input_guard_mock.lua'},
    'catalog_metadata_localization_and_generated_form_prewarm': {
        'entity_catalog_icon_contract_mock.lua', 'form_prewarm_mock.lua', 'localization_context_fallback_mock.lua',
    },
}

AUXILIARY_TESTS = {
    'gold_lifetime_mock.lua',          # shared ownership primitive used by perks/world rules
    'perk_catalog_mock.lua',           # catalogue normalization/uniqueness
    'perk_transaction_capture_wiring_mock.lua',  # transaction journal delegation
    'xml_utils_mock.lua',              # generated XML escaping primitive
    'utf8_text_regression_mock.lua',   # engine-independent UTF-8 truncation primitive
}

missing = []
for behavior, files in BEHAVIORS.items():
    absent = sorted(name for name in files if not (tests_dir / name).is_file())
    if absent:
        missing.append(f'{behavior}: missing {", ".join(absent)}')

# Every major user-facing feature must have explicit behavioral ownership in the map.
required_domains = ('spells', 'items', 'materials', 'perks', 'creature', 'form', 'possession', 'effects', 'weather', 'world_rules')
covered_names = ' '.join(BEHAVIORS)
for domain in required_domains:
    if domain not in covered_names:
        missing.append(f'no behavior coverage declared for feature domain: {domain}')

if missing:
    print('behavior_coverage_contract=FAIL')
    for message in missing:
        print(' -', message)
    raise SystemExit(1)

covered_tests = sorted({name for names in BEHAVIORS.values() for name in names})
all_mocks = {path.name for path in tests_dir.glob('*_mock.lua')}
known_mocks = set(covered_tests) | AUXILIARY_TESTS
unmapped = sorted(all_mocks - known_mocks)
missing_files = sorted(known_mocks - all_mocks)
if unmapped:
    print('behavior_coverage_contract=FAIL')
    print(' - executable mocks without declared purpose: ' + ', '.join(unmapped))
    raise SystemExit(1)
if missing_files:
    print('behavior_coverage_contract=FAIL')
    print(' - declared tests missing from suite: ' + ', '.join(missing_files))
    raise SystemExit(1)

print(
    'behavior_coverage_contract=PASS '
    f'behaviors={len(BEHAVIORS)} behavioral_tests={len(covered_tests)} auxiliary_tests={len(AUXILIARY_TESTS)}'
)
