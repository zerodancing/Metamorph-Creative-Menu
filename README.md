<h1 align="center">Metamorph: Creative Menu</h1>

<p align="center">
  A creative toolkit for Noita: spells, wands, items, materials, perks, creatures, effects, teleportation, weather and world rules.
</p>

<a id="languages"></a>

[**English**](README.md) · [Русский](README.ru.md) · [Português (Brasil)](README.pt-BR.md) · [Español](README.es.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Italiano](README.it.md) · [Polski](README.pl.md) · [简体中文](README.zh-CN.md) · [日本語](README.ja.md) · [한국어](README.ko.md)

## Download

Current version: **2.0.0**

| Package | Download |
|---|---|
| **Latest ready-to-install build** | **[⬇️ Download Metamorph-Creative-Menu.zip](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/download/latest-build/Metamorph-Creative-Menu.zip)** |
| Build page | [Latest ready-to-install build](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/tag/latest-build) |

> The ZIP already contains the complete `metamorph_creative_menu` folder, including the bundled NoitaPatcher runtime. Extract that folder directly into `Noita/mods/`.

Correct final path:

```text
Noita/mods/metamorph_creative_menu/mod.xml
```

If you end up with `metamorph_creative_menu/metamorph_creative_menu/mod.xml`, the archive was extracted one folder too deep.

---

<a id="en"></a>

## English

### Installation

1. [Download the latest ready-to-install ZIP](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/download/latest-build/Metamorph-Creative-Menu.zip).
2. Close Noita before installing or updating the mod.
3. On Steam, open **Library → right-click Noita → Manage → Browse local files**.
4. Open the game's `mods` folder and copy the complete **`metamorph_creative_menu`** folder into it.
5. Verify that `Noita/mods/metamorph_creative_menu/mod.xml` exists. Do not rename the mod folder.
6. Start Noita, enable **Metamorph: Creative Menu**, allow **Unsafe mods / unrestricted API** when required, and restart Noita after enabling the mod.
7. Start a run and press **TAB**. If the menu opens, installation is complete.

**Updating:** close Noita, remove the old `metamorph_creative_menu` folder, then copy the new one into `mods`. Replacing the whole folder avoids stale files from older builds.

### Controls

- **F4 or TAB**: open or close the Creative Menu.
- **TAB while transformed**: return to the human player form.
- **G** by default: possess a supported creature under the cursor.
- **Middle mouse button**: paint with the selected material.
- Bindings can be changed in the CONTROLS section or in the mod settings. Available LMB/RMB actions are shown in the interface.

### What MCM can do

- Get and place spells, and move them between wands, Always Cast slots, the inventory and the world.
- Edit wand stats, appearance and locks; save wand presets and create copies.
- Spawn items near the player or at a selected world position, and place supported items directly into the inventory.
- Create flasks with selected liquids.
- Select materials and paint them into the world.
- Spawn, add and remove perks.
- Spawn creatures near the player or at a selected world position.
- Transform into creatures, possess creatures in the world and return to human form.
- Spawn a separate PLAYER entity.
- Apply and remove game effects.
- Change weather, time of day, gravity and other world rules.
- Teleport to game locations.
- With Entangled Worlds, teleport to other players or bring them to you.
- Change key bindings and search the spell, item, material, perk and creature catalogs.
- Move and resize the menu window; its position and size persist between game launches.

<details>
<summary><strong>Transformations, compatibility and recovery</strong></summary>

MCM uses exact XML-path compatibility data and narrow safe-routing exceptions for entities that are known to be unsafe or unsuitable for direct native polymorph. Player-controlled forms try to retain useful native movement, attacks, visuals and physics while disabling AI that would fight player input. Complex bosses, scripted entities and physics objects can require dedicated adapters and may not reproduce every AI behavior exactly.

NoitaPatcher is used for hard recovery capabilities such as entity serialization/deserialization, player handoff and other extended runtime functions. This is why the complete standalone build requests unrestricted/unsafe mod access.

</details>

<details>
<summary><strong>Entangled Worlds multiplayer integration</strong></summary>

**Entangled Worlds is optional.** MCM is designed to work as a complete standalone single-player mod without EW.

When `quant.ew` is enabled, MCM activates experimental integration for shared items, perks, weather, World Rules, forms/possession, companion requests and related authority/synchronization behavior. Use the same MCM version on every peer. Multiplayer support is intentionally considered experimental because not every Noita/EW edge case can be guaranteed to synchronize perfectly.

</details>

### Requirements & third-party components

- **Noita** — required game, by Nolla Games.
- **NoitaPatcher** by dextercd — bundled with MCM and used for extended runtime/recovery functionality.
- **lbase64** by Ilya Kolbin — bundled local Base64 implementation.
- **Entangled Worlds / Noita Proxy** by IntQuant and contributors — optional multiplayer integration; not required for single player.

Exact upstream links, bundled paths and third-party license/status notes are in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

### Troubleshooting

- **TAB does nothing:** verify the exact `mod.xml` path, make sure MCM is enabled, allow Unsafe mods/unrestricted API, then restart Noita.
- **Extended recovery or World Rules functionality is missing:** verify `metamorph_creative_menu/NoitaPatcher/noitapatcher.dll` is present and unrestricted API access is allowed.
- **A form fails to return correctly:** report the exact creature name/XML and whether normal TAB return or fatal-death return failed.
- **EW mismatch/desync:** verify that every peer uses the same MCM build and a compatible EW build.

### Links

- [Latest build](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/tag/latest-build)
- [Report a bug](https://github.com/zerodancing/Metamorph-Creative-Menu/issues)
- [Third-party notices](THIRD_PARTY_NOTICES.md)
- [Noita](https://noitagame.com/)
- [NoitaPatcher](https://github.com/dextercd/NoitaPatcher)
- [NoitaPatcher documentation](https://dexter.döpping.eu/NoitaPatcher/)
- [Entangled Worlds](https://github.com/IntQuant/noita_entangled_worlds)
- [lbase64](https://github.com/iskolbin/lbase64)

[↑ Back to language selection](#languages)

---

## For developers

The playable mod lives in `metamorph_creative_menu/`.

- Architecture/developer notes: `metamorph_creative_menu/README.txt`
- Regression suite: `metamorph_creative_menu/tests/`
- Test instructions: `metamorph_creative_menu/tests/TESTING.txt`
- Third-party notices: [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)

The repository's automatic `latest-build` workflow packages the playable `metamorph_creative_menu` folder into a ready-to-install ZIP and updates the stable download URL above.