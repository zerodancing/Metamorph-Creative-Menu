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
- **License/status note:** the NoitaPatcher upstream repository and documentation are authoritative for its licensing and redistribution terms. It is a third-party component and is not relicensed by MCM.

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

Original MCM material for which **zerodancing** has the right to grant permissions is licensed under the **Metamorph Creative Menu Attribution License 1.0** in the top-level `LICENSE` file. Redistributed and modified versions may be used commercially, but must preserve the required attribution to `zerodancing` and the original GitHub project as specified by that license.

The player/source package also carries `metamorph_creative_menu/LICENSE.txt` and `metamorph_creative_menu/NOTICE.txt` so the license and required attribution travel with downloaded builds.

The MCM project license does **not** relicense third-party components. Third-party code, libraries, binaries, game resources and trademarks remain subject to their own licenses and terms described above or in their original notices.
