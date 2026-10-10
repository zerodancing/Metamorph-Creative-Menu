<a id="languages"></a>

[**English**](README.md) · [Русский](README.ru.md) · [Português (Brasil)](README.pt-BR.md) · [Español](README.es.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Italiano](README.it.md) · [Polski](README.pl.md) · [简体中文](README.zh-CN.md) · [日本語](README.ja.md) · [한국어](README.ko.md)

<h1 align="center">Metamorph: Creative Menu</h1>

<p align="center">A creative and sandbox toolkit for Noita: spells, wands, items, materials, perks, effects, creatures, transformations, possession, teleportation, weather, world rules, multiplayer integration and recovery tools.</p>

<p align="center"><strong>Creator and maintainer: <a href="https://github.com/zerodancing">zerodancing</a></strong></p>

---

# Download

For normal play, use the ready-to-install build:

[**⬇️ Download the latest build**](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/download/latest-build/Metamorph-Creative-Menu.zip)

[Latest build page](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/tag/latest-build) · [Changelog](metamorph_creative_menu/CHANGELOG.txt)

The GitHub release is built automatically from the complete development source. Tests, QA utilities, diagnostics, native source files and build tools stay in the repository but are excluded from the player archive.

The standalone GitHub build includes NoitaPatcher and native recovery support, so **Unsafe Mods must be allowed**.

# Installation

1. Download `Metamorph-Creative-Menu.zip` from the latest build link above.
2. Launch Noita and open **Mods** from the main menu.
3. Click **Open mods folder**.
4. Extract or move the `metamorph_creative_menu` folder into the opened `mods` directory. The final path must contain `metamorph_creative_menu/mod.xml` directly, without an extra nested archive folder.
5. If an older copy is already installed, replace the whole `metamorph_creative_menu` folder instead of merging files into it.
6. Return to Noita and refresh the mod list.
7. Allow **Unsafe Mods**.
8. Enable **Metamorph: Creative Menu** and start a game with active mods.

Do not enable the standalone GitHub build and the Steam Workshop build at the same time.

# Standalone build and Steam Workshop build

The build distributed through this GitHub repository is the complete standalone build. It contains NoitaPatcher and features that require unrestricted mod API access, including low-level material operations and native Game Over recovery.

The [Steam Workshop build](https://steamcommunity.com/sharedfiles/filedetails/?id=3785170245) is installed separately. It does not ship the native components required by the standalone-only features.

Both builds use the same mod identity. Installing both at once can therefore produce duplicated or conflicting files and is not supported.

# About the mod

**Metamorph: Creative Menu (MCM)** is a creative menu and sandbox toolkit for Noita.

It brings together tools for:

- spells and spell inventories;
- wand editing and reusable wand presets;
- items and liquid containers;
- the complete material catalog and material painting;
- perks and supported perk removal;
- status effects and GameEffect entities;
- creatures, transformations and possession;
- weather and time;
- global world rules;
- teleportation;
- optional Entangled Worlds integration;
- transformation, death and Game Over recovery paths.

MCM tries to operate on real Noita state instead of replacing everything with decorative copies. Existing spell cards are moved as entities, item delivery respects inventory structure, wand changes use commit/rollback paths, materials remain real simulated materials, and reversible world rules keep enough original state to restore supported settings later.

Entangled Worlds is optional. MCM remains a complete single-player mod without it.

# Controls

Default controls are:

| Action | Default input |
| --- | --- |
| Open / close the creative menu | **F4** |
| Return to human form while transformed | **TAB** |
| Possess a creature in the world | **G** |
| Draw with the selected material | **Middle mouse button** |

The creative panel is also available through Noita's inventory interface.

Bindings can be changed from MCM's **CONTROLS** section and from Noita's mod settings. Keyboard keys, mouse buttons and exact **CTRL / SHIFT / ALT** combinations are supported.

During binding capture:

- **DELETE / BACKSPACE** clears the binding;
- **ESC** cancels capture;
- **R** restores the default for that action;
- **RESET ALL** restores all default bindings after confirmation.

Duplicate bindings remain editable, but MCM reports conflicts instead of silently replacing another action.

Actions for menu navigation, sections, form return, possession, material painting, effect cleanup, weather release, world-rule reset and supported multiplayer actions can be rebound.

# Creative Menu window

The direct creative panel is a persistent resizable window rather than a fixed debug overlay.

It can be:

- moved by its title handle;
- resized from edges and corners;
- minimized;
- closed;
- restored to its default layout.

Its position, width, height and last open section are remembered between runs. The saved geometry is clamped back into the visible GUI area after resolution changes.

Lists and catalogs use measured layouts and Noita scroll containers. Resizing the window changes the visible amount of content immediately, and translated labels are allowed to wrap without overlapping neighboring controls. Narrow layouts reflow controls into additional rows instead of drawing them on top of each other.

Opening or merely hovering the detached menu does not permanently disable gameplay. When a click, drag or focused text field would otherwise also trigger the player, MCM temporarily suppresses the relevant player controls and restores them afterward.

# Search and localization

Search is available for the major catalogs, including spells, items, materials, perks and creatures.

Depending on the entry, search can match:

- the current interface language;
- the English name;
- localization keys;
- technical identifiers;
- XML paths.

Search is case-insensitive, normalizes common accents and separators, and tolerates small spelling mistakes in longer queries.

MCM's own interface is localized into:

- English;
- Russian;
- Brazilian Portuguese;
- Spanish;
- German;
- French;
- Italian;
- Polish;
- Simplified Chinese;
- Japanese;
- Korean.

For ordinary Noita content, the mod reuses the game's localization keys whenever possible instead of maintaining duplicate names.

# Spells

The Spells section works with both the catalog and the player's existing spell entities.

The main spell workspace contains:

- the active wand's ordinary slots;
- the wand's **ALWAYS CAST** cards;
- the player's spell inventory;
- the searchable spell catalog.

## Selected-slot replacement

A short click selects a wand slot. A short LMB click on a catalog spell then replaces that selected slot.

This is the fast path for ordinary editing. More precise movement uses drag-and-drop.

## Transactional drag-and-drop

Existing spell cards can be dragged:

- between wand slots;
- from ordinary slots to **ALWAYS CAST**;
- from **ALWAYS CAST** back to ordinary slots;
- into an exact spell-inventory slot;
- from inventory back to the wand;
- into the game world;
- into the trash where supported.

For an existing card, MCM moves the actual entity whenever possible. Mutable card state, remaining uses and state added by other mods are therefore not discarded merely because the card changed location.

The source remains intact until the destination transaction commits. Invalid or unknown drop targets cancel the operation rather than deleting the original card. One mouse release performs at most one committed operation.

Catalog cards are templates and are never consumed by dragging.

## Always Cast

Always Cast cards have their own strip. Promotion, demotion and swapping take the wand's effective ordinary-slot capacity into account so the wand does not end up with an invalid slot structure.

## Undo and redo

Internal wand mutations have a bounded **UNDO / REDO** history.

Operations that hand a real entity to the outside world or to another inventory cannot always be reversed safely from a wand snapshot, so those external handoffs are intentionally not promised as universally undoable.

# Wands

The wand workspace edits the currently held wand.

Supported statistics include:

- capacity / slots;
- spells per cast;
- recharge time;
- cast delay;
- spread;
- projectile speed multiplier;
- maximum mana;
- mana charge speed;
- recoil recovery;
- wand level;
- shuffle;
- never-reload behavior.

MCM also edits wand presentation and related metadata:

- displayed name;
- wand and card locks;
- sprite path;
- sprite offsets;
- firing / shoot position.

A visual appearance catalog follows authored wand XML data when available.

## Wand presets

Wands can be stored as persistent named presets and reused in later worlds or later Noita sessions.

A preset can retain:

- wand statistics;
- mana values;
- visual metadata;
- ordinary spell cards;
- Always Cast cards;
- slot positions;
- remaining uses;
- frozen card state.

Each preset has two separate operations:

- **APPLY** writes the stored blueprint to the wand currently held by the player;
- **GET COPY** constructs a new wand from the same blueprint.

A copied wand is placed into a free quick-inventory wand slot when possible. If no suitable slot is available, the completed wand is left in the world near the player.

Wand replacement and preset loading use commit/rollback paths. If construction or placement cannot be completed, MCM attempts to remove the incomplete entity tree instead of leaving a broken partial wand behind.

# Items and liquids

## Items

A short **LMB** click on an item catalog entry spawns one supported item near the player.

**RMB** attempts to deliver the item to the appropriate inventory area.

Catalog entries can also be dragged:

- onto a matching quick-inventory target;
- outside the menu to an exact world position.

Releasing a dragged catalog card inside the menu without a valid target cancels the operation. The catalog card itself is only a template and remains available.

MCM respects Noita's normal quick-inventory separation between wand slots and item slots. A failed XML load, liquid fill, inventory handoff or optional multiplayer handoff removes the newly created entity when possible.

Some genuine inventory items live under creature-oriented game directories. MCM classifies known cases by behavior instead of assuming that a directory name alone determines whether something is an item or a creature.

## Liquids

Liquid entries create real filled Noita containers rather than decorative menu objects.

The resulting container can be carried, dropped, broken and spilled, and its contents participate in normal material reactions.

# Materials

The Materials section is a world-painting tool backed by Noita's actual material registry.

The catalog is assembled from the engine's registered liquids, sands / powders, gases, fires, solids and related static or particle-effect materials. Materials added correctly by other active mods can therefore appear automatically.

Material discovery and expensive validation are spread over bounded work instead of performing the whole catalog scan in a single UI frame.

## Material presentation

Liquids use the same filled-container presentation as the Items section.

For non-liquids, MCM prefers authored `materials.xml` textures and tint information, including inherited definitions. If no authored texture is available, the fallback is derived from the material's actual engine color rather than an arbitrary preview color.

## Painting

1. Select a material.
2. Select the brush size.
3. Enable painting mode.
4. Close the inventory.
5. Hold the configured drawing input in the game world.

Opening the inventory stops active painting mode.

Painting does not simply emit decorative particles. MCM places real cells into the world using an engine-appropriate path. Dynamic materials continue to obey Noita simulation: liquids flow, powders fall, gases move, fire reacts, and unstable substances can transform through material reactions.

Different material classes require different placement strategies. The standalone build can use NoitaPatcher's direct world-grid access and a small PixelScene fallback for authored cases that Noita refuses to construct directly at a particular texture coordinate.

Work queues are bounded so holding a large brush does not intentionally perform an unbounded amount of work in a single frame.

# Perks

## Spawning and taking perks

**LMB** spawns a normal perk pickup in the world.

The take action can grant the selected perk in small or bulk quantities. Bulk actions are processed as bounded jobs rather than applying every copy in one UI frame.

The interface reports job progress, and pending work can be canceled. Copies already committed before cancellation remain applied.

Each granted copy still uses the normal perk application path instead of faking the final state directly.

## Removing perks

Removing a perk is fundamentally more complicated than granting it. Perks may change globals, components, entities, player statistics or long-running mechanics, and Noita does not provide one universal inverse operation.

MCM therefore removes only state for which it has a sufficiently safe tracked inverse. The transaction journal attempts to remove state owned by that perk application without resetting unrelated player state.

If a cleanup is partial or cannot be proven complete, it remains treated as incomplete rather than being silently reported as successful.

Third-party perks are not guaranteed to be removable even when they can be granted.

# Effects

The Effects section applies and removes supported material statuses and GameEffect entities.

Removal is ownership-aware where possible. MCM avoids indiscriminately deleting similar hidden effects that belong to perks, the game or another system.

Persistent effects created by MCM use bounded cleanup / expiry handling so clearing one MCM-owned effect does not intentionally reset unrelated state.

# Creatures

The creature catalog preserves exact XML paths instead of merging all similarly named entities together.

Supported interactions include:

- **LMB** — spawn the selected authored entity near the player;
- drag outside the menu — spawn at the confirmed world cursor position;
- **RMB** — transform the current player into a supported form;
- the special **PLAYER** entry — create or restore player-related state as described below.

Dropping a dragged creature card back over the menu cancels world spawning.

Compatibility rules for dangerous or unusual transformation targets are exact-path data. A filename that merely contains a familiar word is not automatically treated as the same creature.

# Transformations and returning to human form

Playable forms keep useful native movement, attacks, presentation and physics where practical. Components that directly compete with player input may be disabled or adapted while the form is player-controlled.

Some complex creatures require additional compatibility logic. Bosses, scripted wrappers and physics-heavy entities are not guaranteed to behave exactly like their original AI-controlled versions while used as a player form.

The configured return action — **TAB by default** — first uses the normal transformation-ending path. When that is not enough, the standalone build has additional NoitaPatcher-backed restoration paths.

For supported fatal-damage cases, MCM attempts to:

- leave the dead temporary form or corpse in the world when appropriate;
- restore a human player entity;
- return player authority and controls;
- preserve inventory;
- restore relevant player state.

This is recovery logic, not absolute immortality. A third-party kill script, incompatible engine state or process crash can bypass the supported handoff.

# Possession

Possession controls a creature that already exists in the world instead of selecting a form from the catalog.

The default input is **G**.

Point at a suitable creature and use the possession action. MCM validates the target, prepares a compatible form transition and removes or retires the original world entity only after the new player-controlled state has been confirmed.

If the transition fails, the original creature should not simply disappear.

Possession is not limited to MCM's built-in catalog. A compatible creature created by another mod may work, but universal compatibility with every third-party entity is not guaranteed.

# Player entry

**PLAYER** is a special entry in the creature catalog rather than an ordinary polymorph target.

Its spawn action creates a separate player-like character and attempts to copy appropriate player presentation and maximum-health information.

Using the transform action on **PLAYER** does not transform an already-human player into a duplicate. If the player is currently in another form, the action is used as a return-to-human operation.

# Single-player Game Over recovery

The standalone single-player build includes an additional recovery path for the stock Noita Game Over screen.

When the native integration can safely identify the required game structures, MCM adds an **“I didn't die”** action to the Game Over interface.

MCM keeps a rolling player backup while the game is running. Activating the recovery action requests restoration through the normal MCM update path rather than rebuilding the whole player directly inside the UI click handler.

A supported recovery attempts to:

- restore or acquire a live player entity;
- make that entity authoritative again;
- clear the engine Game Over state;
- restore controls and usable player state;
- perform best-effort cleanup of Game Over audio, music and interface state;
- provide a short protection window after restoration.

The native helper is designed to fail closed. It scans the running supported Noita executable for known structures instead of writing to one permanently hard-coded address. If the expected structures cannot be identified safely after a game update, the optional recovery action is not used rather than writing to an uncertain location.

# Weather and time

MCM can control supported weather and time state, including presets and individual parameters exposed by the current implementation.

Forced state can later be released back to normal game control. For example, after forcing a specific time of day, MCM can stop owning that setting so Noita's natural time flow resumes.

Weather changes are treated as stateful controls rather than one-way console commands.

# World rules

The **RULES** section changes supported global game behavior.

Rules cover areas such as:

- creature relationships;
- gold behavior;
- spell use;
- fog of war;
- selected kill rewards;
- healing drops;
- blood-related behavior;
- gravity;
- physics behavior;
- kick force;
- physics joints;
- the day-night cycle;
- other supported global parameters.

The important design goal is reversibility.

For supported rules, MCM records or derives the original state so the setting can later be restored. Multiplier-style controls are applied relative to the original value instead of repeatedly multiplying an already modified result.

Rules that need to touch many entities or physics objects use bounded update work rather than trying to rewrite the entire world synchronously from one menu click.

# Teleportation

The teleport section provides prepared destinations around the world, including locations on the main route, Holy Mountains, major side areas and other supported landmarks.

Before moving the player, MCM can request destination-area loading and searches for nearby usable space rather than intentionally placing the player directly inside solid terrain.

Teleportation still depends on the world actually being able to load and provide a valid destination. Heavily modified worlds can therefore require fallback behavior.

# Entangled Worlds

**Entangled Worlds / Noita Proxy is optional.** MCM works without it.

When EW is present, MCM enables additional multiplayer-aware behavior. All peers should use compatible MCM builds when relying on MCM-specific synchronized state.

## Authority and forms

Player forms require special ownership handling because a transformed player must not accidentally leave a second network authority behind.

MCM coordinates form ownership, retirement and return-to-human paths with EW where supported. Boss and Kolmi-style entities have additional lifecycle handling intended to prevent duplicate authorities and stale network-controlled copies.

The ordinary EW death path remains in charge for entities that are not recognized as MCM-owned form state.

## Items, wands and spells

Where possible, MCM uses EW's normal item / inventory mechanisms rather than inventing a parallel transport system.

Committed wand and spell inventory mutations request the appropriate multiplayer refresh when that integration is available. World items created by MCM can be handed to the standard EW world-item path.

## Perks

Normal perk pickups can use EW's regular world-item synchronization. MCM's own perk state handling coordinates refresh and bounded operations so bulk actions do not intentionally emit one expensive global refresh for every copy.

## Materials

Material painting has a dedicated compatibility path because world-cell updates are not ordinary item entities.

MCM keeps paint work bounded, separates work at chunk boundaries and coordinates required EW world-frame / persistence steps before releasing synchronized conversion work. An unloaded streaming-edge chunk is deferred instead of blocking the whole active stroke.

The goal is that nearby EW peers can observe supported painted world state without requiring the normal MCM UI action to be replayed remotely as a filename-only PixelScene call.

This still inherits EW's material-id assumptions: a receiving game cannot correctly create a material that does not exist there or whose engine material registry is incompatible.

## Weather, possession and world state

Supported MCM multiplayer state also includes coordination for weather, possession and selected world-rule or lifecycle behavior. Ownership checks are used to avoid both peers trying to become authoritative for the same state at once.

EW support is intentionally conservative. When the integration cannot prove a safe synchronized path, MCM prefers the local supported behavior over pretending that every single-player operation is automatically multiplayer-safe.

# Compatibility and limitations

Noita exposes many systems through loosely coupled entities, XML, Lua components and native engine behavior. MCM therefore cannot promise universal compatibility with every modded entity or every future game update.

Important limitations include:

- a creature being spawnable does not automatically make it a safe player form;
- a perk being grantable does not automatically mean it has a reliable inverse;
- external spell or item handoffs cannot always be undone from an internal snapshot;
- third-party scripts can bypass supported death and recovery paths;
- native recovery features depend on supported Noita executable behavior and fail closed if the required structures cannot be identified;
- Entangled Worlds cannot synchronize a material absent from the receiving game's registry;
- heavily modified inventories, entities or world rules may require compatibility work specific to that mod.

MCM tries to preserve original state and roll back failed mutations, but a sandbox tool that modifies live game state cannot make every third-party combination transactional.

# Saved data

MCM persists user-facing state that is expected to survive between runs, including supported settings, key bindings, menu layout and wand presets.

The mod identity remains stable so normal upgrades can keep supported saved state. Replacing the whole mod folder is still recommended when installing a new standalone build, because merging old and new files can leave obsolete runtime files behind.

# Troubleshooting

## The mod does not appear

Confirm that the folder structure ends in:

`mods/metamorph_creative_menu/mod.xml`

An extra archive directory above `metamorph_creative_menu` prevents Noita from seeing the mod correctly.

## Native or material features do not work

Confirm that **Unsafe Mods** are allowed and that you installed the standalone GitHub build rather than mixing it with the Workshop build.

## The menu opens but a control also fires in-game

Check custom bindings for conflicts. MCM reports duplicate bindings, but it intentionally allows you to keep them if desired.

## A creature cannot be transformed into safely

Not every spawnable XML entity is a supported player form. Exact-path compatibility rules exist for creatures that need special handling.

## A perk cannot be removed

Removal is only offered where MCM has a supported inverse for the tracked state. This is intentional; guessing at cleanup can damage unrelated player state.

## Multiplayer behavior differs between peers

Use compatible MCM builds on all participating peers and keep the underlying Noita / Entangled Worlds environment compatible. MCM cannot correct an incompatible material registry or arbitrary third-party network modifications.

# Reporting bugs

A useful bug report should include:

- what you were trying to do;
- the exact MCM section and action involved;
- whether the problem occurs in single-player, Entangled Worlds, or both;
- whether the standalone or Workshop build is installed;
- whether other gameplay mods are active;
- reliable reproduction steps;
- relevant Noita / EW logs when available.

For transformation, possession, item or material problems, include the exact entity or material when possible. Exact technical identifiers are often more useful than a translated display name.

# Repository and development source

The repository intentionally contains the **complete development tree**, not the same stripped archive that players download.

`metamorph_creative_menu/` contains runtime code together with:

- automated tests;
- QA utilities;
- diagnostics;
- native source;
- build tooling;
- release-cleanup rules;
- development documentation.

Those files are useful for development and regression testing, so they remain in GitHub source. The ready-to-install player ZIP is generated separately and excludes development-only content.

The player package also receives release-only cleanup, including the minimal player `README.txt`, while the source tree keeps its development documentation.

# Tests

The automated test suite lives under `metamorph_creative_menu/tests/` and combines Python contract checks with Lua mock tests.

From the repository root, the release workflow runs the suite against the complete imported source before publishing a player build. `texlua` is required for the Lua mock portion.

Source hygiene checks also guard production-facing files and documentation against development-history debris, stale debug surfaces and accidental process artifacts.

# Source archive import and release process

Development source can be imported from a full archive whose name follows the `Metamorph-Creative-Menu-v...zip` family.

The import workflow verifies the archive structure, requires the full development components, checks source hygiene and runs the regression suite before committing the imported tree.

A ModWorkshop / player-style archive is not treated as development source.

The public `latest-build` release is then produced from the complete source by a separate player builder. The builder removes QA, tests, diagnostics, native source and other development-only payload, applies the release cleanup rules, validates the resulting archive and only then updates the stable download asset.

This separation allows the repository to stay useful for development while keeping the normal player download small and free of development instrumentation.

# Third-party components

Third-party components, bundled dependencies and upstream projects are documented in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
