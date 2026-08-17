# Metamorph: Creative Menu — English

[English](README.en.md) · [Русский](README.ru.md) · [Português (Brasil)](README.pt-BR.md) · [Español](README.es-ES.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Italiano](README.it.md) · [Polski](README.pl.md) · [简体中文](README.zh-CN.md) · [日本語](README.ja.md) · [한국어](README.ko.md)

## About

**Metamorph: Creative Menu (MCM)** is a creative/developer menu for **Noita**. It is designed to work as a complete standalone single-player mod while also providing optional experimental compatibility with **Entangled Worlds / Noita Proxy**.

MCM lets you edit wands, spawn or take items, apply and remove perks/effects, transform into creatures, possess an existing creature under the cursor, change weather, override world rules and spawn a player-like companion. The project also contains extensive recovery, ownership and regression-test systems because many Noita operations are destructive or engine-dependent.

## Requirements

- A working copy of Noita.
- The folder `metamorph_creative_menu` installed under `Noita/mods/`.
- **Unsafe mods / unrestricted API enabled** in Noita. This is required by the bundled native **NoitaPatcher** extension used by MCM's extended functionality.
- Entangled Worlds is **optional**. It is not required for normal single-player use.

## Installation

1. Download a packaged build from [Releases](https://github.com/zerodancing/Metamorph-Creative-Menu/releases) or download/clone this repository.
2. Copy the whole `metamorph_creative_menu` folder into `Noita/mods/`.
3. Make sure `Noita/mods/metamorph_creative_menu/mod.xml` exists directly at that path.
4. Open Noita → Mods.
5. Enable **Unsafe mods / unrestricted API**.
6. Enable **Metamorph: Creative Menu** and restart the run/game if needed.

Do not rename the internal mod folder: runtime paths use `mods/metamorph_creative_menu/...`.

## Controls

- **TAB** — open/close the Creative Menu.
- **TAB while transformed** — request a return to the normal human player form.
- **G** by default — possess/transform into a supported creature under the cursor. The key can be rebound in MCM settings.
- Most catalog tiles use **LMB** and **RMB** for two different actions; the exact action is shown in the UI.

## Features

### Spells / wand editing

Hold a wand, select a wand slot and choose any supported spell from the searchable categorized catalog. MCM can replace the selected spell, delete it, or drop the spell entity into the world. Replacement is handled transactionally so the old spell is not removed until the new spell has been attached and verified.

### Items

The Items tab provides searchable categories for containers, liquids, stones, eggs, wands, books, bonuses, orbs, quest items and other supported entities.

- **LMB:** spawn the item near the player.
- **RMB:** try to place the item directly into a suitable inventory slot.
- If inventory pickup fails or the correct slot is full, MCM keeps the item in the world instead of silently destroying or replacing another item.
- Liquid/container entries can create filled flasks and related containers.

### Perks

- **ADD mode:** LMB spawns a normal perk pickup; RMB applies it directly.
- **REMOVE mode:** LMB removes one stack; RMB attempts to remove all stacks.
- MCM tracks many changes made by perks so removal can restore owned components, entities, values and global state without intentionally overwriting unrelated changes from other systems.
- Some externally obtained or unusual perks may not have a perfectly safe inverse. In that case MCM prefers refusing an unsafe removal over blindly deleting unrelated state.

### Search

Large catalogs include search. Search may match translated names, IDs and descriptions, depending on the tab.

### Creatures, objects and forms

The MOBS catalog includes creatures and supported object/projectile-style entries.

- **LMB:** spawn the selected entry in the world.
- **RMB:** transform the player into it.
- **TAB:** return to the human form.

MCM uses exact-path compatibility data rather than broad filename blacklists. Some crash-prone placement-wrapper XMLs are routed to a known safe canonical target for transformation while still spawning the authored wrapper normally.

Player-controlled forms try to preserve useful native movement, attacks, presentation and physics while disabling AI that would fight the player's controls. Complex creatures may use specialized adapters and therefore can be approximate rather than frame-perfect copies of their original AI behavior.

### Human return and form death

A normal TAB return first uses Noita's native polymorph lifecycle. MCM also keeps a serialized human backup through NoitaPatcher for hard recovery paths.

When a supported transformed body receives fatal damage, MCM attempts a **death handoff**: the current creature form is allowed to die while player authority is transferred back to the restored human body, preventing the creature body's death from automatically ending the player's run.

Because this touches engine death/polymorph order, unusual scripted deaths can still be creature-specific edge cases; report reproducible failures.

### Possession

Aim at a supported existing creature and press the configured possession key (**G** by default). MCM transforms the player using the target's authored/compatible form and retires the original target so the action behaves like taking over that creature rather than merely creating a duplicate next to it.

### PLAYER companion

The `PLAYER` entry can spawn a player-like allied companion. MCM can clone player presentation/inventory information and, when the required NoitaPatcher capability is available, can use the copied wand more like an actual player. Multiplayer authority is routed through the EW integration when EW is active.

### Effects

Apply supported status/timed effects to the current player, choose duration where supported, and remove effects through the editor. MCM tries to distinguish editor-owned state from unrelated perk/internal effects so a bulk removal does not intentionally destroy protected game state.

### Weather

Weather provides presets and advanced editing.

Time presets:
- morning
- day
- evening
- night

Weather presets:
- clear
- cloudy
- foggy
- storm

Advanced controls include supported WorldState values such as time of day, cloud cover, fog, wind, wind speed, rain and lightning-related behavior. **RELEASE** stops MCM from actively holding its weather override.

### World Rules

World Rules are designed as **reversible overrides**, not permanent edits. `NATIVE`/RESET restores the baseline that MCM captured for values it owns. Persistent recovery records are used for critical rules so an interrupted session can restore recorded native values before accepting new overrides.

Current rule set:

- CREATURE RELATIONS
- GOLD NEVER EXPIRES
- UNLIMITED SPELL USES
- REVEAL FOG OF WAR
- TRICK-KILL BLOOD MONEY
- HEALING DROP CHANCE
- FRIENDLY RATS
- GORE AMOUNT
- TRICK-KILL GOLD
- DAMAGE FLASH
- STAIN SHEDDING
- WORLD GRAVITY
- PHYSICS DAMPING
- BLOOD VOLUME
- KICK FORCE
- JOINT STRENGTH
- DAY CYCLE SPEED

Physics rules affect loaded/nearby runtime physics rather than magically rewriting every unloaded entity in the infinite world. Heavy scans are deferred to world update rather than performed directly inside GUI clicks.

## Standalone mode and Entangled Worlds

**MCM does not require Entangled Worlds for single player.** The repository contains its own NoitaPatcher loader/DLL and local Base64 codec.

When `quant.ew` is enabled, MCM activates an experimental integration layer for shared world items, perks, weather, World Rules, forms/possession, companion requests and compatibility/resilience behavior. If EW already provides a compatible NoitaPatcher API, MCM can reuse it.

Network support is intentionally described as **experimental/partial**: host and client are intended to have equal user-facing Creative Menu rights, but not every Noita/EW edge case can be guaranteed synchronized.

For multiplayer, all peers should use the same MCM build and a compatible EW build.

## Compatibility and safety

- Some Noita entities can crash native polymorph at engine level; Lua `pcall` cannot catch a hard native crash.
- MCM therefore uses exact XML-path compatibility policy, static structure checks, native polymorph signals, logged review results and a small number of narrow safe-routing exceptions.
- Do not interpret every catalog entry as guaranteed perfect player control. Exotic bosses, physics-driven objects and scripted entities can need dedicated adapters.
- Release mode has `dev_mode = 0`; tests and QA tools are kept in the repository for development and regression checking.

## Troubleshooting

**Menu does not open:** verify the folder is exactly `Noita/mods/metamorph_creative_menu/` and the mod is enabled.

**Extended form recovery / World Rules capabilities are missing:** verify Unsafe mods / unrestricted API is enabled and the bundled `NoitaPatcher/noitapatcher.dll` is present.

**A transformed form does not return correctly:** include the exact creature XML/name and describe whether TAB return or fatal-death return failed.

**EW mismatch/desync:** confirm every peer uses the same MCM version and a compatible Entangled Worlds version.

## Bug reports

Please use [GitHub Issues](https://github.com/zerodancing/Metamorph-Creative-Menu/issues). Include:
- MCM version/commit;
- Noita version/build;
- whether Entangled Worlds was enabled and its version;
- single-player or multiplayer;
- exact entity/perk/effect/rule involved;
- reproducible steps;
- relevant logs/diagnostics if available.

## Third-party components and credits

MCM bundles **NoitaPatcher** by dextercd and **lbase64** by Ilya Kolbin. It optionally integrates with **Noita Entangled Worlds** by IntQuant and contributors. Exact bundled paths, purposes, upstream links and license/status information are documented in [THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md).

## Links

- MCM: https://github.com/zerodancing/Metamorph-Creative-Menu
- Releases: https://github.com/zerodancing/Metamorph-Creative-Menu/releases
- Issues: https://github.com/zerodancing/Metamorph-Creative-Menu/issues
- Noita: https://noitagame.com/
- NoitaPatcher: https://github.com/dextercd/NoitaPatcher
- NoitaPatcher docs: https://dexter.döpping.eu/NoitaPatcher/
- Entangled Worlds: https://github.com/IntQuant/noita_entangled_worlds
- lbase64: https://github.com/iskolbin/lbase64

## Developers

The playable mod is in `metamorph_creative_menu/`. Automated regression mocks, architecture contracts and behavior-coverage checks are in `metamorph_creative_menu/tests/`; see `metamorph_creative_menu/tests/TESTING.txt`.

No top-level license for MCM's original code has been selected yet. Third-party components retain their own terms.
