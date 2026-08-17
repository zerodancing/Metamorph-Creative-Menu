# Metamorph: Creative Menu

**A standalone creative/developer menu for Noita with optional experimental Entangled Worlds compatibility.**

> Full source + playable mod folder. The repository includes the bundled NoitaPatcher runtime used by MCM's extended recovery, entity-serialization, player-authority and MagicNumbers features.

## Documentation

| Language | Full documentation |
|---|---|
| English | [README.en.md](docs/README.en.md) |
| Русский | [README.ru.md](docs/README.ru.md) |
| Português (Brasil) | [README.pt-BR.md](docs/README.pt-BR.md) |
| Español | [README.es-ES.md](docs/README.es-ES.md) |
| Deutsch | [README.de.md](docs/README.de.md) |
| Français | [README.fr.md](docs/README.fr.md) |
| Italiano | [README.it.md](docs/README.it.md) |
| Polski | [README.pl.md](docs/README.pl.md) |
| 简体中文 | [README.zh-CN.md](docs/README.zh-CN.md) |
| 日本語 | [README.ja.md](docs/README.ja.md) |
| 한국어 | [README.ko.md](docs/README.ko.md) |

## Quick start

1. Download a build from [Releases](https://github.com/zerodancing/Metamorph-Creative-Menu/releases) or download the repository.
2. Copy the `metamorph_creative_menu` folder into `Noita/mods/`.
3. In Noita's Mods menu, enable **Unsafe mods / unrestricted API**, then enable **Metamorph: Creative Menu**.
4. Press **TAB** in-game to open the menu. While transformed, **TAB** returns to human form.
5. The default possession key is **G** and can be changed in the mod settings.

The final folder must look like:

```text
Noita/
└─ mods/
   └─ metamorph_creative_menu/
      ├─ mod.xml
      ├─ init.lua
      ├─ mod_id.txt
      ├─ NoitaPatcher/
      └─ files/
```

## Main features

- Wand spell editing: select slots, replace, delete and drop spells.
- Item spawning and direct inventory pickup, including containers and liquids.
- Perk spawning, direct application and reversible removal where a safe inverse is known.
- Searchable creature/object catalog.
- Spawn creatures or transform into them.
- **TAB** human return and a hard recovery/death-handoff path backed by the bundled NoitaPatcher.
- Possess an existing creature under the cursor with a configurable key.
- Player companion spawning from the `PLAYER` entry.
- Status/timed effect application and removal.
- Weather presets plus advanced time/cloud/fog/wind/rain/lightning controls.
- Reversible World Rules with `NATIVE` restore semantics.
- Optional experimental integration with Entangled Worlds for shared multiplayer state.

## Important runtime note

MCM is standalone: **Entangled Worlds is not required for single-player use**. MCM ships its own NoitaPatcher copy and local Base64 codec. If Entangled Worlds is enabled and has already published a compatible NoitaPatcher API, MCM can reuse that API instead of requiring EW for core functionality.

Because NoitaPatcher is a native API extension, the full MCM feature set requires Noita's **Unsafe mods / unrestricted API** option.

## Third-party components

See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for exact upstream links, bundled files and license/status notes.

## Links

- [Repository](https://github.com/zerodancing/Metamorph-Creative-Menu)
- [Releases](https://github.com/zerodancing/Metamorph-Creative-Menu/releases)
- [Bug reports / Issues](https://github.com/zerodancing/Metamorph-Creative-Menu/issues)
- [Noita](https://noitagame.com/)
- [NoitaPatcher](https://github.com/dextercd/NoitaPatcher)
- [Entangled Worlds](https://github.com/IntQuant/noita_entangled_worlds)
- [lbase64](https://github.com/iskolbin/lbase64)

## Development

The playable mod lives in [`metamorph_creative_menu/`](https://github.com/zerodancing/Metamorph-Creative-Menu/tree/main/metamorph_creative_menu). Regression tests and architecture/behavior contracts are included in `metamorph_creative_menu/tests/`. Release builds keep `dev_mode = 0`.

No top-level license for MCM's original code has been selected yet. Third-party files remain under their respective upstream terms; see `THIRD_PARTY_NOTICES.md`.
