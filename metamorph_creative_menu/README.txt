Metamorph: Creative Menu 2.0.0 — behavior and maintenance guide
================================================================

Purpose
-------

Metamorph: Creative Menu (MCM) is a creative/debug menu for Noita. It is a
standalone single-player mod. Entangled Worlds (`quant.ew`) is optional and adds
only the partial multiplayer integration documented below.

This file describes shipped behavior, not desired future behavior. A source file,
prototype controller or reserved RPC slot does not by itself make a user-facing
feature supported. When code and prose disagree, reproduce the behavior, update
the tests, and correct this document.

The mod bundles NoitaPatcher and a local Base64 codec. NoitaPatcher is a native
extension, so the complete mod requires Unsafe mods / unrestricted API permission.

Installation and upgrade
------------------------

1. Close Noita and extract the archive into `<Noita>/mods/` so the resulting path is
   `<Noita>/mods/metamorph_creative_menu/mod.xml` (without an extra nested folder).
2. When upgrading from 1.x, replace the whole `metamorph_creative_menu` folder instead
   of merging files into the old copy. The mod id is unchanged, so supported settings
   and saved data migrate in place.
3. Enable the mod and Unsafe mods in Noita's Mods menu, then restart the game.

Because `request_no_api_restrictions` is enabled and NoitaPatcher contains a native DLL,
this complete build must be installed manually; Noita does not load it through Steam
Workshop. Entangled Worlds is optional and is installed separately.

Controls and interface
----------------------

The inventory still shows the creative panel, and the configured menu action (F4 by
default) opens or closes it directly. Merely opening or hovering the direct panel keeps
gameplay live. A click inside it, a panel drag, or focused text entry temporarily sets
ControlsComponent.enabled false so the same input cannot also fire the held wand. MCM
restores the captured value only while the field still reads disabled. The first useful
section is Spells; there is no duplicate HOME section. The single-row header names the
current section and exposes layout reset, minimize and close controls. Previous/next
section actions remain assignable for keyboard compatibility but are not header buttons.
The Controls section remains in the icon tab bar and the last section is remembered. The
styled title handle, kept clear of resize hitboxes and window controls, moves the panel. Every outer edge and corner resizes it in
both dimensions. A continuous muted-gold, two-tone Noita-style frame overlays the stock
AutoBox border itself, makes those resize edges visible and brightens the active side on
hover/drag without drawing a second frame across content.
Position, width and height persist between runs and are clamped with the visible frame
outset to the current GUI viewport after resolution changes. The default layout is compact
enough for a 320x240 GUI while scaling with larger resolutions. Tab icons use verified
vanilla assets with fallbacks, including Extra Life, regeneration, Wet, Return and Divide by 2.
Hovering an icon shows only its localized section name, without a placeholder second line.

All catalogue and long-form sections use one measured layout service and native Noita
scroll containers, so their contents remain clipped and positioned relative to the menu.
Horizontal spell strips use their own fixed slot step. Each list starts below the actual
last control in its section and grows to the panel's lower edge, rather than using a fixed
list height or guessed per-section padding. Resizing therefore changes the number of
visible rows immediately, including when translated labels wrap to more lines. Narrow
layouts reflow text buttons into additional rows instead of overlapping.

The in-game CONTROLS section and Noita's mod settings use one action registry. Keyboard,
mouse and exact CTRL/SHIFT/ALT combinations are supported. DELETE/BACKSPACE clears a
binding, ESC cancels capture, R restores one default, and RESET ALL requires confirmation.
Exact duplicate bindings remain editable but are visibly reported as conflicts. Defaults
are F4 for the menu, TAB for return to human, G for possession and middle mouse for the
active material brush. The old possession setting is migrated. Menu navigation, every
section, form return, possession, paint mode/input/size, effect cleanup, weather release,
World Rules reset and next-player teleport are assignable. Catalog LMB/RMB actions remain
described in their sections.

All MCM-owned interface text and settings are registered for English, Russian,
Brazilian Portuguese, Spanish, German, French, Italian, Polish, Simplified Chinese,
Japanese and Korean. Vanilla item/material/perk/entity localization keys are reused
where the game already provides them. Catalogue search fields are inert until clicked,
lose focus when another control is used, and reset when the menu is closed/hidden. Search
normalizes case, common accents and separators, tolerates small spelling mistakes in
longer words, and indexes the current client translation, English translation,
localization key and available technical ids/paths.

Player-visible behavior
-----------------------

When a temporary creature form ends, MCM reactivates the restored human's controls and
clears the form-only control flag. This also covers a transform begun by clicking inside
the menu while its same-click input suppression was active.

Spells
~~~~~~

The Spells tab has two workspaces. CATALOG contains the active wand slot strip, Always Cast
strip, spell inventory and spell catalogue in that order; WAND contains wand statistics,
appearance/locks and presets. There is no separate LOADOUT workspace and no CURRENT STATE
section. Long slot strips scroll independently with the mouse wheel; dragging an occupied
card is reserved for spell drag-and-drop, so the interface does not promise LMB drag-to-scroll
over cards. A short slot click selects that slot, and a short LMB on a catalogue spell has
one explicit action: replace the selected wand slot.

Precise placement is drag-and-drop onto a wand slot, Always Cast, an exact spell-inventory
slot, the world or Trash. Existing wand/inventory/Always Cast cards stay attached to their
source until the destination transaction commits; rejected or unknown targets leave the
source unchanged, and one release performs at most one operation. Catalogue cards are
templates and are never removed by dragging. Existing cards move as entities so mutable or
modded card state is not silently recreated. RMB/Trash deletion, native inventory transfer,
world drop and bounded wand Undo/Redo remain available.

Always Cast cards have their own strip and preserve the wand's effective ordinary-slot
capacity when promoted, demoted or swapped. Internal wand edits use bounded Undo/Redo;
external world/inventory handoffs are deliberately excluded from snapshot undo because a
snapshot alone cannot reclaim the moved external entity safely. Spell creation preserves
pre-existing persistent unlock progression rather than leaving a new unlock flag solely
because Creative Menu instantiated a card.

The WAND workspace exposes fixed-column numeric controls for capacity, spells per cast,
base recharge/cast delay, spread, projectile speed multiplier, maximum mana, mana charge,
recoil recovery and wand level, plus shuffle/never-reload. Recharge/cast-delay frame units
and spread degrees are explained in localized tooltips rather than technical suffix glyphs.
The appearance section edits the displayed name, wand/card lock state, sprite path, sprite
offsets and shoot hotspot, and includes a visual skin catalogue which follows inherited
wand XML presentation data. Persistent named wand presets use a versioned blueprint
format and preserve stats, mana, visual metadata, ordinary/Always Cast cards, slots,
remaining uses and frozen state across worlds and later game runs; V1 blueprints remain
readable. Each preset is shown with its saved wand image when available and exposes
separate APPLY and GET COPY actions. APPLY uses the normal blueprint transaction on the
held wand. GET COPY builds the same blueprint on a new wand, places it in a free quick
inventory slot when possible, and otherwise leaves the fully built wand in the world.
Failed construction or placement removes the newly created entity tree. Wand/card
replacement and preset loading use verified commit/rollback paths, and EW inventory
refresh is requested after committed mutations when available.

Items
~~~~~

A short LMB spawns exactly one supported entity near the player. RMB attempts inventory
delivery. LMB drag uses the same threshold as spell drag-and-drop: dropping over the
matching vanilla quick-inventory area performs the safe inventory give, dropping outside
the menu creates the item at the confirmed world cursor coordinates, and releasing inside
the menu without a registered target cancels the operation. The catalogue card itself is
only a template and is never removed.

The normal quick inventory is treated as four wand slots plus four item slots. If the
relevant row is full, ordinary RMB give retains its established safe overflow behavior.
Dragged world items are created only when the release destination is known; failed XML
load, liquid fill, inventory placement or optional EW world-item handoff removes the newly
created entity tree. Filled containers and catalog liquids use a real filled vanilla
container and the same release rules. Genuine ItemComponent entities stored by vanilla
under `data/entities/animals/` are corrected explicitly instead of being lost to directory
classification: this includes Sampo, the Crystal Key and the authored boss-centipede
reward items. Creature/item hybrids such as the potion mimic remain creatures. Item icons
prefer the entity's authored inventory/body sprite.

Materials
~~~~~~~~~

The Materials tab is a standalone world-painting tool. Its catalogue is built from
CellFactory_GetAllLiquids/Sands/Gases/Fires/Solids with static and particle-FX
materials included, so materials loaded by other enabled mods appear automatically.
Entering the tab performs no CellFactory enumeration on that same GUI frame. The
selected category begins loading on the next draw and expensive per-material
validation/translation is bounded per frame. Select a material and brush size, press
START PAINTING, then close the inventory and hold the configured Draw material binding
(middle mouse by default) in the world. Opening the inventory again stops paint mode.
The drawing input and paint-mode/brush-size actions are independently assignable; the
default remains separate from normal primary/secondary fire, and painting does not
mutate the player ControlsComponent.

Material presentation is shared with the Items liquid catalogue. Liquids use the same
filled vanilla flask and engine-derived potion colour in both sections. Non-liquids use
their authored `materials.xml` Graphics texture and tint, including inherited parent
definitions. Only a material with no authored texture falls back to its actual engine
primary colour; arbitrary/random preview colours are not used.

Painting uses two engine-appropriate placement paths. Ordinary liquids, powders, gases
and fires use the bundled NoitaPatcher direct world-grid interface, with a one-stamp
PixelScene fallback when Noita legally refuses direct construction for a valid authored
material at a particular texture coordinate. Entries reported by
CellFactory_GetAllSolids, plus CellData that is static/platform/textured terrain, use a
tiny one-colour LoadPixelScene mask because Noita's low-level construct_cell may legally
return nil for transparent material-texture texels and CellData.cell_type alone does not
match the public SOLIDS taxonomy. Neither path uses GameCreateParticle. Dynamic
materials still obey normal Noita simulation after placement: liquids flow, gases move,
fire reacts, and unstable materials may transform through material reactions. The
feature has no hard EW dependency. With EW present, MCM prevents EW's filename-only
PixelScene RPC from replaying the MCM brush without its dynamic color/material mapping;
ordinary EW PixelScenes stay unchanged. Every newly encountered 128x128 area, including
solid paint, is first queued as an EW-native aligned world frame and cached for the
current EW world number. Only after its matching
world-frame terminator succeeds are the proxy persistence command and a short-lived
vanilla MagicConvertMaterialComponent tree released. This ordering is important because
EW's proxy ignores a material write for a chunk it does not know yet. Relay trees are
also split at chunk boundaries instead of remaining anchored to the stroke's first
square. An unloaded streaming-edge chunk is rotated behind loaded work instead of
blocking the whole stroke while the player moves. Relay trees and per-frame stamp work
are bounded, and holding the brush still does not resend the same point every frame.
Their filled-disc converters handle dynamic paint over existing solids. The
receiver never loads an MCM file or material RPC, so a nearby stock-EW peer without MCM
can see host or client painting.
All queues and the cross-VM mailbox are fixed-size/bounded. Like EW itself, this assumes
matching CellFactory material ids/order; it cannot create a material absent from the
receiving game and does not add guarantees beyond EW's retained late-join world state.

Perks
~~~~~

LMB always spawns one normal perk pickup entity. With EW enabled, that real vanilla pickup
is handed to EW's normal world-item transport so a stock-EW peer can see/pick it without
MCM. RMB TAKE offers 1, 10 or 100 copies. A single TAKE still uses the canonical immediate
pickup path; 10/100 run as a bounded job from the normal perk-service update with a small
per-frame operation budget. Every copy still receives its own canonical transaction.
Deferred inventory/EW refresh is flushed after each processed group instead of once per
copy, and asynchronous GAMBLE rewards block the next queued copy until their parent scope
closes. The current job shows progress and can be cancelled; errors or a local-player
change stop further copies without reverting already committed ones. REMOVE ALL uses the
same bounded job rather than a synchronous UI loop.

Removal remains available only when MCM has a safe inverse for the tracked state. The
transaction journals try to remove only state owned by that perk application, including
supported entities, components, values, globals and special mechanics. MCM does not
promise a correct inverse for every vanilla edge case or third-party perk. A failed or
partial cleanup stays pending rather than being reported as clean.

Effects
~~~~~~~

The Effects tab applies supported material statuses and GameEffect entities.
Removal protects reserved, perk-owned and unrelated hidden effects. MCM-owned
persistent effects get a short bounded native-expiry window before the owned entity
is retired.

Creatures and forms
~~~~~~~~~~~~~~~~~~~

The Mobs catalog keeps exact XML paths distinct. LMB spawns the selected authored
entity nearby. Dragging an ordinary mob card outside the menu spawns it at the exact
world cursor position; releasing it over the menu cancels the operation. The special
PLAYER clone remains a direct LMB action. RMB transforms the current player when the
path is supported.

Known unsafe transform targets and validated canonical fallbacks are exact-path
data. Broad filename substring bans are not compatibility policy. Native polymorph
membership and static XML inspection are useful signals, but Lua cannot prove that
an engine-level crash is impossible.

Playable forms retain useful native movement, attacks, presentation and physics
where practical. AI or scripted lifecycle components that compete with player input
may be disabled. Complex bosses, physics entities and wrappers are not guaranteed
to reproduce the original AI entity exactly.

Return and death handoff
~~~~~~~~~~~~~~~~~~~~~~~~

The configured return-human action (TAB by default) first expires the native polymorph effect. Serialized NoitaPatcher
recovery is the hard fallback. Supported fatal-damage paths attempt to preserve a
form corpse and return player authority, inventory and relevant state to a restored
human. With EW enabled, MCM installs its primary death guard inside EW after EW has
created the health capability, so mod load order cannot leave the original notplayer
handler active. A tagged MCM form first gets one synchronous MCM restore attempt. If
separately bundled NoitaPatcher instances cannot share that CrossCall, the same EW-side
guard decodes the native polymorph effect's saved player and commits it before retiring
the dead form. EW keeps its exact normal death behavior for untagged or unverified
restores. The older source patch remains a secondary compatibility guard and is tested
independently from optional polymorph profiling. This recovery is engine-sensitive and
cannot guarantee survival from every third-party kill script or process crash.

Possession
~~~~~~~~~~

The configured possession action (G by default) targets an existing supported creature and requests transformation into its
compatible form. Live structural validation admits natural or modded creatures that are
not present in the menu catalogue, while exact known-unsafe paths and internal helpers
remain rejected. Targeting resolves controller/synchronization wrappers and uses a
bounded larger fallback for large bodies or network interpolation offsets. The original
target is retired only after transformation is
confirmed. If EW ownership is uncertain, retirement fails conservatively instead of
deleting an entity that may belong to another peer.

Weather and World Rules
~~~~~~~~~~~~~~~~~~~~~~~

Weather supports time presets, weather presets and the fields exposed by
`features/weather/definitions.lua`. RELEASE stops MCM ownership and restores the
captured time progression value.

World Rules are reversible overrides, not permanent save edits. NATIVE/RESET
restores MCM-owned state from captured baselines and persisted recovery records.
Repeated multipliers are based on a clean baseline and must not compound. Broad
physics/entity work is bounded and deferred to update ticks; GUI clicks only change
desired state.

Teleportation
~~~~~~~~~~~~~

The Teleportation section replaces the old Players naming. It lists currently visible
network players only while the section is open. GO TO streams the destination and finds
nearby free space instead of placing the local player blindly inside terrain. BRING HERE
publishes a targeted EW request for that peer to move safely beside the requester. The
same section exposes authored destinations for the main path, Holy Mountains and major
side locations; destination streaming and free-space adjustment are shared with player
teleports. The next-player action remains assignable for quick use without opening the
section.

The special PLAYER catalog entry
--------------------------------

PLAYER is a clone entry, not a second-player transform target.

- LMB asks `features/companion/player_avatar.lua` to create a player-like clone.
- The builder attempts to copy presentation, maximum HP and the active wand.
- `features/companion/ai.lua` remains the existing autonomous follow/combat
  controller. Do not remove or replace it merely to simplify the PLAYER entry. Its
  source presence is still not a promise of a separately controllable AI feature.
- There is no command system or command UI. Users cannot issue follow, stay,
  attack, target, loadout or mode commands.
- In EW, a peer request is routed to the host. Only the host-authoritative clone runs
  decisions/casting; other clients receive normal EW replication.
- RMB never transforms into PLAYER. It is a no-op for an already-human player and
  calls the normal return-to-human path when the current player is transformed.

Keep PLAYER and its current creation/controller behavior. Do not describe it as a
commandable second player. The supported statement is: "PLAYER clone; RMB does not
transform into it; no user command system."

Entangled Worlds integration
-----------------------------

EW support is partial and experimental, but EW is an optional adapter rather than a core
dependency. Stock EW transports are preferred where they can express the operation, so
world items, dropped spell cards and real perk pickup entities do not require MCM on the
receiving peer. MCM-specific RPC features still need compatible MCM code on the peer(s)
that consume them. Source-patched EW integration is checked by markers and verified patch
results, not merely by a version string.

Current feature boundaries:

- items/wands/spell drops: world entities use EW's native world-item handoff where
  supported; inventory changes request EW inventory refresh. Sampo and the other
  nonstandard vanilla item roles use this same item path;
- perks: LMB uses a real vanilla perk pickup and EW's native world-item handoff. For
  tracked MCM creative copies of EW-global perks, only the sender-advertised creative
  layer is filtered; upstream EW global-perk semantics for ordinary pickups are preserved;
- materials: every touched chunk is seeded through an EW-native aligned frame before its
  vanilla converter entity and stock proxy terrain command are released. Cross-boundary
  strokes use one spatial relay per chunk. Either host or client can originate the
  operation and the receiving peer does not need MCM;
- weather and World Rules: complete snapshots use the host as a routing/rebroadcast
  point, while host and peer users retain equal menu editing rights;
- forms: native EW entity sync is primary, with an additional bounded pose stream for
  the local polymorphed entity;
- possession: confirmed retirement is transported with ownership/identity checks;
- PLAYER: peer-to-host spawn request only, with no command protocol;
- effects: there is no separate MCM multiplayer effect protocol;
- QA telemetry: present only in dev mode; its release RPC slot remains reserved so
  protocol indices do not shift.

Destructive-form world synchronization
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

`integrations/ew/resilience_patches.lua` patches EW's
`files/system/world_sync/world_sync.lua` during mod initialization.

The patch:

1. keeps EW's normal chunk-ring scheduler centered on the polymorphed root/head position
   when a fast form is far from the camera;
2. records a bounded 3x3 neighborhood around root chunks the form leaves;
3. drains old trail chunks in addition to EW's normal scheduling;
4. terminates every injected binary trail frame with EW's normal world-end marker;
5. uses a fixed ring queue, preserves the oldest off-screen work when saturated and
   drains faster above half capacity;
6. publishes sent/received/backlog/drop metrics in developer mode only.

Source returned by Noita may use LF or CRLF. The patch normalizes line endings before
matching. All required anchors are applied transactionally: if one anchor is missing,
the original EW source is returned unchanged.

Critical patch states are published in Globals and failures are visible in-game and
in the log. `anchor_mismatch`, `read_failed`, `write_failed` and
`verification_failed` mean the related compatibility behavior is not active.

Developer-mode world-sync metrics:

- `mcm_world_sync_sent_chunks_v1`, `mcm_world_sync_sent_bytes_v1`;
- `mcm_world_sync_recv_chunks_v1`, `mcm_world_sync_recv_bytes_v1`;
- `mcm_world_sync_trail_backlog_v1`, `mcm_world_sync_trail_sent_v1`;
- `mcm_world_sync_trail_dropped_v1`, `mcm_world_sync_last_poly_chunk_v1`;
- `mcm_compat_world_sync_patch_v1`;
- `mcm_compat_form_death_patch_v1` and
  `mcm_form_death_channel_registration_v1` report the critical multiplayer death guard
  and its active CrossCall registration path.

Developer-mode polymorph observer profiling:

- only EW's `system/polymorph/polymorph.lua` replacement path is instrumented; the
  generic entity serializer used by projectiles/items stays untouched;
- `mcm_ew_poly_serialize_ms_v1`, `mcm_ew_poly_serialize_bytes_v1`;
- `mcm_ew_poly_deserialize_ms_v1`, `mcm_ew_poly_deserialize_bytes_v1`;
- `mcm_ew_poly_*_kind_v1`, `mcm_ew_poly_*_source_v1`, `mcm_ew_poly_*_frame_v1`;
- `mcm_form_remote_prepare_ms_v1`, `mcm_form_remote_prepare_entities_v1`,
  `mcm_form_remote_prepare_components_v1`, `mcm_form_remote_prepare_source_v1`;
- `mcm_compat_poly_profile_patch_v1` reports whether the optional profiling patch was
  applied. Measurements are emitted to `player.log` once per MCM polymorph replacement
  and once for the first articulated remote preparation. Cached pose updates pay no
  profiling timer cost.

No MCM patch can promise perfect synchronization of every Noita pixel, physics body,
scripted boss, third-party entity, late join or reconnect. These remain explicit
limitations.

Runtime error isolation
-----------------------

`init.lua` invokes independent frame services through a protected boundary. A failure
in effects, weather, World Rules, perks, forms, companions, possession or menu update
must not skip all later services in the same frame.

Failures are deduplicated by scope plus error signature. A new error in the same service
is printed immediately, shown with GamePrint when available, sent to developer
diagnostics when enabled, and saved in `mcm_runtime_error_last_v1`; the same recurring
signature is rate-limited for 600 frames to prevent an every-frame log flood.

Performance rules
-----------------

- Release mode must not load diagnostics or QA runtime services.
- Broad world scans must be throttled, bounded and kept out of GUI click/draw paths.
- Catalog XML/icon work is incremental or cached.
- Scrollable UI sections share measured remaining-height layout; do not reintroduce
  per-tab fixed catalogue heights.
- Form tree/component snapshots are cached only for a safe update boundary.
- Weather is reasserted before and after the engine tick, but network mailbox,
  rain-particle and lightning work runs only once per frame.
- Per-frame network processing is bounded. Release mode keeps telemetry disabled;
  developer mode can expose queue/backlog metrics where implemented.
- Do not trade away recovery or synchronization guarantees for a lower line count.

Architecture
------------

The production layers are:

- `files/core/`: game-independent helpers;
- `files/platform/noita/`: Noita API adapters;
- `files/features/`: gameplay services and form adapters;
- `files/integrations/ew/`: EW-only transport, RPCs, mailboxes and compatibility;
- `files/ui/`: rendering and user input routing;
- `files/diagnostics/`: bounded developer diagnostics, shipped but dormant in release mode;
- `files/qa/`: optional in-game QA, shipped but dormant in release mode;
- `tests/`: shipped offline contracts and behavioral mocks.

`init.lua` is the lifecycle/composition root. UI tabs do not own low-level entity
mutation or EW protocol. `item_registry.lua` and `creature_registry.lua` remain stable
extension entry points for other mods.

The EW RPC namespace is positional protocol state. Do not reorder or change a
signature without a namespace bump and updated protocol tests.

Developer mode
--------------

`dev_mode.lua` sets `dev_mode = 0` and returns it in the player release. Persistent
diagnostics, in-game Z QA, profiling and EW telemetry are disabled at runtime, while
their source remains in the archive for manual diagnosis. Set it to `1` only for QA
work. The release RPC slot is still registered as a no-op so protocol indices remain
stable.

Tests
-----

From this mod root:

    python tests/run_all.py

The runner requires `texlua` and `texluac` in PATH. It automatically discovers all
`*_contract.py` and `*_mock.lua` files. The suite covers syntax, dependency direction,
localization, protocol order and executable Noita/EW boundary scenarios.

Offline mocks cannot reproduce separate Noita processes, real NoitaPatcher FFI,
actual proxy scheduling, physics or network races. Changes to forms, world sync,
weather, Rules, possession, perks or inventory still require a real two-client EW run.

Release checklist
-----------------

1. Keep `dev_mode.lua` at `return 0`.
2. Run the complete offline suite.
3. Test inventory open/close, the configured menu action, transform, the configured
   return-human action and fatal-damage recovery in Noita.
4. Test host and peer item/inventory, weather, Rules, form and possession flows.
5. Test a fast destructive polymorph form and inspect world-sync patch status,
   backlog and dropped metrics on both clients.
6. For boss_dragon/maggot_tiny, record sender serialize, observer deserialize and first
   remote-prepare `[MCM EW profile]` lines before changing network representation.
7. Confirm no `compatibility patch failed` or `mcm_runtime_error_last_v1` failure.
8. Run `python tools/build_release.py`; verify the archive includes NoitaPatcher,
   tests, QA, diagnostics and the release builder, while excluding generated caches
   and nested build output.
