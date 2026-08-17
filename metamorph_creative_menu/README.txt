Metamorph: Creative Menu — project behavior and architecture contract
=====================================================================

About the project
-----------------

Metamorph: Creative Menu (MCM) is a creative/developer menu for Noita. The project is developed with AI assistance and is intended to remain useful both as a player-facing creative tool and as a developer/debugging toolkit.

MCM is standalone in single player. The required NoitaPatcher runtime and Base64 codec are bundled with the mod. Entangled Worlds / Noita Proxy (`quant.ew`) is optional and only provides the experimental multiplayer integration layer. If EW already exposes a compatible NoitaPatcher API, MCM may reuse it instead of loading a second provider.

The bundled NoitaPatcher is a native API extension. Full MCM functionality therefore requires Noita's Unsafe mods / unrestricted API permission. Bundling NoitaPatcher removes the hard dependency on the EW folder; it does not turn native DLL functionality into the safe Noita API.

This document defines the player-visible behavior and the architecture contract that must be preserved during refactors. It is not an exhaustive description of every implementation detail. The code may contain additional recovery state, helper entities, RPCs, compatibility shims, diagnostics, caches and engine workarounds required to preserve the behavior described here.

Core development rule: working behavior must not be removed or simplified merely because its implementation looks complicated, unusual or workaround-heavy. Before deleting or substantially rewriting such code, determine which Noita/EW/runtime problem it solves and prove with tests that the replacement preserves the same behavior.

Equal host and peer rights
--------------------------

In supported multiplayer scenarios, host and peer users are intended to have the same MCM-facing rights and capabilities. The host may still be a technical routing, confirmation or rebroadcast point when required by Entangled Worlds, but that does not make a feature host-only from the user's perspective.

Any old comment, document or test claiming that peers must be forbidden from changing weather, World Rules or another menu feature merely because they are not the host is obsolete unless a newer explicit protocol requirement says otherwise.

Main behavior
-------------

1. Creative menu
~~~~~~~~~~~~~~~~

TAB opens the creative/developer menu. The current tabs are Spells, Items, Perks, Mobs, Effects, Weather and Rules. Search is part of normal use in large catalogs and must survive refactoring.

2. Spells
~~~~~~~~~

The Spells tab can edit the currently held wand: select a slot, place supported spells in arbitrary order, replace an existing action, delete it or drop it into the world. Operations that must be visible to other players should use the EW integration when EW is active.

Spell replacement is transactional: do not destroy the old spell until the replacement has been attached and verified.

3. Items
~~~~~~~~

The Items tab can spawn supported Noita items such as wands, books, eggs, stones, containers, quest objects and other catalog entries.

LMB spawns the item near the player. RMB attempts to place it into the appropriate inventory row. The standard quick inventory has four wand slots and four item slots. If no suitable slot is available, the item must remain in the world rather than disappearing, replacing another item or corrupting inventory state.

World-spawn and inventory operations that require multiplayer visibility must use the EW bridge when EW is enabled.

4. Perks
~~~~~~~~

LMB spawns a normal perk pickup. RMB applies the perk to the local player through the canonical pickup path. The editor can also remove supported perks, including perks obtained outside MCM when a safe inverse is known.

Removing a perk must remove the state owned by that perk without blindly overwriting unrelated state from other perks, mods or the game. Owned state may include entities, companions, tentacles, visual effects, components, physics changes, statistics, globals, run flags and world changes.

Perks remain per-player. Multiplayer synchronization should expose visible/shared consequences without turning one player's perk ownership into every player's perk ownership.

5. Search
~~~~~~~~~

Large catalogs must remain searchable. Search supports translated names and relevant IDs/paths/descriptions depending on the tab. Exclusion tokens and normalized separators are part of the current search behavior.

6. Creatures, objects and transformations
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

In the MOBS catalog, LMB spawns an entry and RMB transforms the current player into it. The system attempts to preserve useful native attacks, animations, movement, physics, presentation and authored behavior while disabling AI that would fight player controls or cause duplicate simulation.

Compatibility is exact-path based. Do not add broad substring blacklists such as blocking every filename containing `physics`, `effect`, `sprite` or `body`. Different XML paths with the same basename are separate authored entities and must remain separate catalog entries.

Known unsafe forms are recorded as exact paths. Known safe exceptions are also exact paths. Wrapper-to-canonical routing is permitted only for explicitly validated path pairs. Static XML analysis and native polymorph-table membership are useful signals, but a hard engine crash cannot be proven impossible by Lua `pcall` inside the same process.

7. Returning to human form
~~~~~~~~~~~~~~~~~~~~~~~~~~

While transformed, TAB must return the player to the normal human form. Native polymorph expiry is the primary route; serialized backup/hard recovery is a fallback. TAB return is a normal part of the form lifecycle, not an optional emergency-only feature.

8. Death while transformed
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Fatal damage to a supported transformed body should kill the creature form while allowing the player to continue as a restored human at the death position instead of ending the run because the temporary body died.

The form corpse should remain when appropriate. Human inventory and relevant player state should survive the handoff. The death flow is engine-sensitive, so recovery code must treat unknown player-authority states conservatively and must not destroy an entity when authority is uncertain.

9. Special forms
~~~~~~~~~~~~~~~~

Boss Dragon, Maggot Tiny and other unusual families may require dedicated adapters. Do not re-enable original AI merely to make an adapter look simpler: competing AI can create duplicated attacks, movement conflicts, lag, physics problems and multiplayer desync.

10. Possession
~~~~~~~~~~~~~~

The default possession key is G and can be changed in mod settings. The player points at a supported creature and takes over its compatible form. The original target is retired only after the transformation is confirmed. Possession should feel like taking the target's place, not creating an unrelated duplicate nearby.

11. Effects
~~~~~~~~~~~

The Effects tab applies supported status/timed effects and removes them when safe. Removal must preserve unrelated protected/perk/internal effects and restore editor-owned state where possible.

12. Weather
~~~~~~~~~~~

The Weather tab controls time presets, weather presets and advanced supported WorldState fields such as cloud cover, fog, wind, rain and lightning behavior. Weather state is synchronized through EW when EW is active. Host and peer users have equal MCM-facing rights; routing through a host is an implementation detail.

13. World Rules
~~~~~~~~~~~~~~~

World Rules are reversible overrides rather than permanent save edits. NATIVE/RESET restores the baseline captured for state owned by MCM. Repeated multipliers must not accumulate against an already overridden value. Critical persistent values keep recovery information so a later Lua session can restore native state after an interrupted run.

Expensive physics/entity scans must not run directly from GUI draw/click paths. UI actions update desired rule state; broad application belongs in bounded world-update work.

14. Experimental multiplayer integration
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

MCM is primarily a standalone single-player mod. Entangled Worlds support is partial/experimental and does not guarantee every Noita/EW edge case. The integration aims to synchronize shared world effects such as items, supported spell operations, forms, possession, visible perk consequences, effects, weather, time and World Rules while keeping player-local ownership local when appropriate.

All peers should use the same MCM build and a compatible EW version.

15. Performance
~~~~~~~~~~~~~~~

The mod should remain usable on weaker systems. Avoid unnecessary work every frame, broad world scans, repeated XML parsing, eager loading of large catalogs and duplicated network simulation. Optimize without silently removing existing features or weakening recovery/synchronization guarantees.

Refactoring and cleanup rules
-----------------------------

Current priority is reliability and maintainability of existing features, not feature count.

- Preserve existing player-facing behavior.
- Preserve standalone functionality without requiring Entangled Worlds.
- Preserve experimental EW integration and equal user-facing host/peer rights.
- Remove code only when it is demonstrably unused.
- Remove duplication when behavior is preserved.
- Split large modules by responsibility rather than by arbitrary line count.
- Keep exact-path compatibility registries and protocol slots stable when they are part of compatibility.
- Prefer behavior tests over tests that search for a particular source string.
- Keep necessary Noita/EW workarounds until a tested replacement exists.
- Treat current verified in-game behavior as a stronger source of truth than stale comments.

Project architecture and code navigation
----------------------------------------

The architecture should answer: "If a specific gameplay aspect breaks, which folder owns it?"

Top-level layers:

- `files/features/` — MCM gameplay features.
- `files/integrations/ew/` — code that exists specifically for Entangled Worlds / Noita Proxy: RPCs, network bridges, mailboxes, sync and EW-specific resilience patches.
- `files/platform/noita/` — low-level Noita API/component adapters. UI should not directly implement Entity/Component transactions when a platform/feature boundary exists.
- `files/ui/` — presentation, search, buttons, tabs, localization lookup and forwarding user intent to feature services.
- `files/core/` — small generic algorithms/utilities with no gameplay or Noita ownership.
- `files/diagnostics/` — bounded logs, passive observation and diagnostics.
- `files/qa/` — in-game Z QA scenario infrastructure.
- `tests/` — offline regression tests; `tests/TESTING.txt` documents the test system.

`files/item_registry.lua` and `files/creature_registry.lua` intentionally remain stable extension entry points for external mods.

Spells — `files/features/spells/`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- `catalog.lua` — vanilla spell catalog normalization, categories and icon metadata.
- `service.lua` — wand contents, slots/capacity, add/replace/delete/drop, mana preservation and required EW sync.
- `files/ui/tabs/spells.lua` — rendering, search and commands only.

Items — `files/features/items/`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- `catalog.lua` — built-in item catalog.
- `ui_catalog.lua` — combined built-in/external/liquid menu catalog.
- `service.lua` — world spawn, RMB inventory delivery, world fallback and filled containers.
- `liquid_preview.lua` — hidden probe used to obtain actual liquid colors.
- `files/platform/noita/inventory_slots.lua` — low-level slot/pickup confirmation.
- `files/integrations/ew/world_items.lua` — multiplayer world-item/inventory transport.
- `files/ui/tabs/items.lua` — rendering and user commands.

Perks — `files/features/perks/`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- `catalog.lua` — unique vanilla perk catalog.
- `service.lua` — public spawn/apply/count/remove API and removal strategy selection.
- `pickup_service.lua` — canonical application using a real perk entity.
- `transactions.lua` — ownership journal for MCM-applied perk copies and rollback.
- `transactions/global_journal.lua` — Globals/run-flag capture and restoration.
- `inverse_registry.lua` — explicit inverse dispatcher.
- `inverse/player.lua`, `inverse/world.lua`, `inverse/companions.lua`, `inverse/lukki.lua` — special inverse families.
- `root_companions.lua` — ownership of detached companion entities.
- `presentation.lua` — perk icons/GameEffect/presentation residue cleanup.
- `files/ui/tabs/perks.lua` — menu only.

Creatures — `files/features/creatures/`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- `catalog.lua` — known vanilla entity paths.
- `catalog_builder.lua` — full catalog construction and incremental warmup.
- `classification.lua` — structural independent-creature classification; filename hints are diagnostic only.
- `compatibility.lua` — verified/candidate/unsafe/unsupported status without dangerous trial polymorph.
- `compatibility_overrides.lua` — the manual exact-path safe/unsafe/canonical registry.
- `metadata.lua` — XML/name metadata.
- `diagnostics.lua` — deeper component/attack/profile inspection.
- `ui_catalog.lua` — MOBS-ready data.
- `service.lua` — collect/canonical/prewarm/spawn facade.
- `files/ui/tabs/creatures.lua` — rendering, search and spawn/transform intent.

Forms — `files/features/forms/`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This is the most sensitive subsystem.

- `manager.lua` — session lifecycle, transform start, TAB return, death handoff and transition coordination.
- `runtime.lua` — active-form dispatcher.
- `family.lua` — form family/lifecycle root detection.
- `controls.lua` — normalized player input.
- `combat.lua` — attacks, aiming, lasers and manual combat adapters.
- `presentation.lua` — vision/herd/DamageModel/CharacterData/presentation profile.
- `component_ops.lua` — shared component operations.
- `entity_tree_cache.lua` — active-form entity-tree cache.
- `adapters/ghost.lua`, `fish.lua`, `worm.lua`, `physics.lua`, `boss_dragon.lua` — family-specific behavior.
- `exact_effects.lua` — exact polymorph wrappers/runtime clones.
- `human_restore.lua` — serialized human restoration.
- `player_authority.lua` — transactional authoritative-player switching.
- `corpse_service.lua` — creature-form corpse lifecycle/synchronization.
- `death_guard.lua` — native death callback boundary.
- `transform_flash.lua` — temporary polymorph-flash ownership and restoration.
- `profile.lua` — form profile analysis.
- `noop.lua` — deliberately empty runtime script used when original lifecycle/AI must be disabled.

Possession — `files/features/possession/`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- `keybinds.lua` — configured key handling.
- `targeting.lua` — entity selection under the cursor, including EW tolerance/fallback.
- `service.lua` — possession state machine/transaction.
- `retirement.lua` — local target retirement.
- `files/integrations/ew/possession_retire.lua` — network retire/handoff.

Effects — `files/features/effects/`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- `catalog.lua` — available effects and metadata.
- `policy.lua` — shared identity/safety policy.
- `service.lua` — application, ownership, removal, expiry, snapshot and residue checks.
- `files/ui/tabs/effects.lua` — presentation and commands.

Weather — `files/features/weather/`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- `definitions.lua` — fields and presets.
- `runtime_effects.lua` — rain/lightning/runtime weather effects.
- `service.lua` — local user operations and ownership state.
- `files/integrations/ew/weather_sync.lua` — network snapshot/mailbox and equal-rights routing.
- `files/ui/tabs/weather.lua` — UI.

World Rules — `files/features/world_rules/`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- `definitions.lua` — rule definitions and choices.
- `service.lua` — public state machine and orchestration.
- `world_state.lua` — WorldState fields.
- `physics.lua` — bounded runtime physics/character gravity and damping ownership.
- `stains.lua` — stain/status rules.
- `magic_numbers.lua` — MagicNumbers ownership/transactions.
- `gold_lifetime.lua` — gold lifetime behavior.
- `files/integrations/ew/world_rules_sync.lua` — EW snapshots/mailbox/equal peer rights.
- `files/ui/tabs/world_rules.lua` — UI.

Companion — `files/features/companion/`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- `player_avatar.lua` — companion creation/lifecycle.
- `ai.lua` — companion AI.
- `health.lua` — narrow initial-health repair without undoing combat damage.
- `spawn_guard.lua` — per-entity fallback for separate Lua VMs.
- `player_clone.xml` — clone entity.
- `files/integrations/ew/companion_request.lua` — peer-to-host request transport when required by EW.

Entangled Worlds — `files/integrations/ew/`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- `bootstrap.lua` — small EW attachment point.
- `runtime.lua` — EW discovery/common runtime capabilities.
- `perk_sync.lua`, `world_items.lua`, `possession_retire.lua`, `companion_request.lua`, `weather_sync.lua`, `world_rules_sync.lua` — feature-specific integration.
- `serialization.lua` — EW-specific serialized-data handling where needed.
- `form_death_channel.lua` — CrossCall registration/sending for form death.
- `resilience.lua` and `resilience_patches.lua` — version-sensitive EW compatibility patches and status reporting.
- `bridge/protocol.lua` — RPC namespace/order/version; protocol slots must not move silently.
- `bridge/*.lua` — feature-specific network bridges.

A network bug should be debugged at the boundary between the feature and its EW bridge. Do not "fix" a network bug by adding a host-only user restriction.

Noita platform — `files/platform/noita/`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- `inventory_slots.lua` — vanilla inventory mechanics.
- `entity_tree.lua` — entity tree/root traversal.
- `player_locator.lua` — local player lookup.
- `keycodes.lua` — keycode normalization.
- `input_guard.lua` — Alt-Tab/focus-gap action quarantine.
- `localization.lua` — safe translation lookup.
- `assets.lua` — asset/XML path helpers.
- `patcher_bridge.lua` — NoitaPatcher capability provider/reuse.
- `menu_inventory_guard.lua` — wheel-scroll conflict suppression and held-item restoration.

Diagnostics — `files/diagnostics/`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- `logger.lua` — bounded persistent log and runtime error capture.
- `entity_inspection.lua` — safe entity summaries/diagnostic storage reads.
- `runtime_context.lua` — shared QA/EW runtime context.
- `scan_support.lua`, `catalog_scanner.lua`, `runtime_scanner.lua`, `runtime_recorder.lua`, `scanner.lua`, `service.lua` — bounded diagnostics and performance sampling.

QA — `files/qa/`
~~~~~~~~~~~~~~~~~

- `controller.lua` — Z key and lazy loading of the heavy runner.
- `runner.lua` — sequential in-game regression scenario state machine.
- `cases.lua` — required cases and timeouts.
- `baselines.lua` — snapshots, rollback and residue checks.
- `spell_roundtrip.lua` — spell-specific roundtrip scenario.

The QA runner intentionally remains sequential because apply -> verify -> rollback order is part of test safety.

Dependency rules
~~~~~~~~~~~~~~~~

1. UI displays state and calls feature services; it does not own gameplay transactions or network protocols.
2. UI should not perform low-level Entity/Component mutations when a platform/feature boundary exists.
3. `core` must not depend on Noita APIs, gameplay features, UI, EW or diagnostics.
4. `platform` must not depend on gameplay features or EW.
5. Gameplay features must not depend on UI, diagnostics or QA.
6. EW-specific transport/mailbox/RPC belongs in `integrations/ew` rather than tabs or general gameplay services. A standalone entity script may inspect EW role only to prevent duplicate simulation, not to remove user rights.
7. Large services/coordinators should be split by responsibility before becoming god objects.
8. New production modules need a real runtime consumer unless they are documented stable extension points.
9. External registry paths and wire-protocol slots are compatibility surfaces; do not rename/reorder them for aesthetics.
10. Compatibility aliases may remain temporarily, but new internal names should describe actual roles (`service`, `runtime`, `catalog`, `sync`, `adapter`, etc.).
11. Exported module tables should be named after responsibility rather than generic `api` in production code.
12. Network mailbox/CrossCall implementation details belong to the integration layer.

Testing
-------

Static tests are appropriate for syntax, dependency direction, protocol layout, localization completeness and other genuinely static contracts. They should not replace behavior verification with fragile searches for a specific source line or documentation sentence.

Prefer executable Lua mock/integration scenarios that load production modules, replace only the Noita/EW boundary and assert observable state/rollback/network results.

After risky changes, run real in-game checks for transformations, TAB return, form death, Boss Dragon/Maggot Tiny, possession, inventory operations, perk apply/remove, effects, weather/World Rules synchronization, equal host/peer rights and rollback/residue cleanup.

Completeness of this document
-----------------------------

This document focuses on behavior and ownership boundaries. Additional helper entities, caches, backup states, temporary components, RPCs, special-case handlers, compatibility patches, optimizations and diagnostics may exist to implement those behaviors.

The goal of refactoring is not to minimize line count at any cost. The goal is a smaller, clearer, faster and more reliable project without losing verified functionality.

Developer mode
--------------

`dev_mode.lua` controls only built-in diagnostics/QA infrastructure.

For normal play and public releases:

    dev_mode = 0

At `0`, MCM does not load the runtime diagnostics service or Z QA controller, does not run their per-frame updates, does not show MOBS review/logging controls and does not load EW QA telemetry. The QA RPC slot remains reserved with a no-op handler so protocol ordering does not change.

For development only:

    dev_mode = 1

This enables persistent diagnostics, Z QA, MOBS review logging and EW QA telemetry. Offline tests in `tests/` are independent of `dev_mode` and are run manually. Restore `dev_mode = 0` before publishing a player build.
