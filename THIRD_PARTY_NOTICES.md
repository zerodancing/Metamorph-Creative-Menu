# Third-party notices

This file documents external projects and code used by or integrated with **Metamorph: Creative Menu (MCM)**.

## NoitaPatcher

- **Project:** NoitaPatcher
- **Author / upstream:** dextercd
- **Repository:** https://github.com/dextercd/NoitaPatcher
- **Documentation:** https://dexter.döpping.eu/NoitaPatcher/
- **Bundled in this repository:**
  - `metamorph_creative_menu/NoitaPatcher/load.lua`
  - `metamorph_creative_menu/NoitaPatcher/noitapatcher.dll`
- **Purpose in MCM:** extended Noita API functionality used for entity serialization/deserialization, player authority handoff, hard form recovery, CrossCall registration, MagicNumbers runtime changes, exact companion wand use and related fallbacks.
- **License/status note:** GitHub currently reports no detected repository license for `dextercd/NoitaPatcher`. The upstream repository and documentation are authoritative for NoitaPatcher terms. NoitaPatcher is **not** covered by any license that may later be chosen for MCM's original code.

## lbase64

- **Project:** lbase64, version header `v1.5.3`
- **Author:** Ilya Kolbin
- **Repository:** https://github.com/iskolbin/lbase64
- **Bundled file:** `metamorph_creative_menu/files/lib/base64.lua`
- **Purpose in MCM:** decoding serialized form/player backup data.
- **License:** the bundled source includes its full license notice and offers a choice of the **MIT License** or **Public Domain / Unlicense-style dedication**. The original notice is preserved in the file.

## Entangled Worlds / Noita Proxy

- **Project:** Noita Entangled Worlds (`quant.ew`)
- **Upstream:** IntQuant and contributors
- **Repository:** https://github.com/IntQuant/noita_entangled_worlds
- **Releases:** https://github.com/IntQuant/noita_entangled_worlds/releases
- **Bundled:** **No.** Entangled Worlds itself is not included in this repository.
- **Purpose in MCM:** optional, experimental multiplayer compatibility. When `quant.ew` is enabled, MCM uses dedicated integration code for world items, perks, weather, world rules, possession, companions and resilience patches.
- **Upstream licenses:** the Entangled Worlds repository publishes both MIT and Apache-2.0 license files.
- **Important:** single-player MCM does not require Entangled Worlds. Core MCM extended features use the bundled NoitaPatcher instead of reading NoitaPatcher from the EW folder.

## Noita

- **Game:** Noita by Nolla Games
- **Official site:** https://noitagame.com/
- **Steam:** https://store.steampowered.com/app/881100/Noita/
- MCM is an unofficial game mod and is not affiliated with or endorsed by Nolla Games.
- MCM references Noita's runtime APIs, entity XML paths, translations and game resources as part of normal mod operation. Noita itself is not distributed by this repository.

## MCM project license

At the time this notice was written, the repository does not declare a top-level license for MCM's original code. That means no repository-wide license should be interpreted as relicensing the third-party components listed above.

If a project license is added later, this file should remain and the project license should explicitly exclude third-party components where their upstream terms differ.
