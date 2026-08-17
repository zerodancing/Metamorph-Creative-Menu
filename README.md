# Metamorph: Creative Menu

A creative/developer menu for **Noita** with standalone single-player support and optional experimental **Entangled Worlds (`quant.ew`)** compatibility.

## Features

- Spell editing and wand actions
- Item spawning and inventory delivery
- Reversible perk and effect editing
- Creature spawning, transformation and possession
- Native/special attack adapters for transformed creatures
- Weather controls
- World Rules editor
- Player companion spawning
- Search and categorized catalogs
- Recovery/rollback logic for risky transformations
- Experimental multiplayer synchronization through Entangled Worlds

## Installation

1. Download the latest release or the repository archive.
2. Put the folder `metamorph_creative_menu` into your Noita `mods` directory.
3. The final path should look like:

   `Noita/mods/metamorph_creative_menu/`

4. Enable **Metamorph: Creative Menu** in Noita.
5. The bundled NoitaPatcher is a native API extension, so the full feature set requires Noita's **Unsafe mods / unrestricted API** option.

Entangled Worlds is **not required** for standalone play. If a compatible NoitaPatcher API is already provided by EW, MCM can reuse it; EW remains an optional networking layer.

## Controls

- `TAB` — open/close the creative menu; while transformed, the form system also uses the native return/recovery flow.
- Possession and other configurable controls can be changed in the mod settings.

## Repository layout

The complete mod is stored in:

`metamorph_creative_menu/`

The repository also contains the automated regression suite used during development. Player-ready archives will be published through **GitHub Releases**.

## Status

This is the full standalone build of Metamorph: Creative Menu. Entangled Worlds integration is experimental and is not claimed to support every possible multiplayer state or third-party mod interaction.

## Third-party component

The distribution includes **NoitaPatcher**, a third-party native API extension used for extended Noita functionality. NoitaPatcher is not original MCM code; rights to third-party components remain with their respective authors.
