# Metamorph: Creative Menu

Metamorph: Creative Menu is a creative and sandbox toolkit for Noita. It provides a single interface for spells, wands, items, materials, perks, effects, creatures, transformations, possession, teleportation, weather, world rules, and related tooling.

**Creator and maintainer:** [zerodancing](https://github.com/zerodancing)

## Download

For normal play, use the ready-to-install build:

[**Download the latest build**](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/download/latest-build/Metamorph-Creative-Menu.zip)

The release archive contains only the runtime files needed by players. Development files such as tests, QA tools, diagnostics, native source, and build tooling remain in the repository and are intentionally excluded from the downloadable build.

The full build requires **Unsafe Mods** because it bundles NoitaPatcher and native Game Over recovery support.

## Installation

1. Download `Metamorph-Creative-Menu.zip` from the latest build release.
2. Extract `metamorph_creative_menu` into Noita's `mods` directory.
3. Enable **Unsafe Mods** in Noita.
4. Enable **Metamorph: Creative Menu** and start a game with mods enabled.

Do not install the standalone GitHub build and the Steam Workshop build at the same time.

## Main features

- searchable catalogs for spells, items, materials, perks, effects, and creatures;
- wand editing, Always Cast management, undo/redo, and persistent wand presets;
- item and creature spawning with inventory/world drag-and-drop;
- material painting with bounded world updates;
- reversible transformations and possession;
- weather, time, gravity, world-rule, and teleportation controls;
- optional Entangled Worlds integration;
- single-player Game Over recovery in the full standalone build.

## Repository layout

`metamorph_creative_menu/` is the complete development source tree. It includes runtime code together with tests, QA utilities, diagnostics, native source, and development tooling.

The repository intentionally keeps those files so development builds can be reproduced and regression-tested. They are not shipped in the ready-to-install release archive.

## Tests

The regression suite is under `metamorph_creative_menu/tests/`. Run it from the mod root with:

```text
python tests/run_all.py .
```

The test runner requires `texlua`.

## Release process

A full source archive named like `Metamorph-Creative-Menu-v3.zip`, `Metamorph-Creative-Menu-v4.zip`, or `Metamorph-Creative-Menu-v4.1.zip` can be uploaded to the repository root. GitHub Actions validates it, runs the regression suite, imports the complete source tree, and removes the uploaded archive from the repository.

The public `latest-build` release is built separately from that complete source tree. Its packaging step removes development-only content and produces a player-facing archive.

## Third-party components

Third-party components and their upstream projects are documented in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
