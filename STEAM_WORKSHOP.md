# Steam Workshop release guide

This branch is the Steam Workshop edition of **Metamorph: Creative Menu**.

The full standalone build remains on `main` and includes the bundled NoitaPatcher runtime. The Workshop edition intentionally does **not** request unrestricted API access and does **not** contain the bundled native NoitaPatcher DLL, because Noita Workshop does not support mods that require `request_no_api_restrictions="1"`, and the Workshop uploader only accepts its documented file types.

## Files prepared for Workshop

Inside `metamorph_creative_menu/`:

- `mod.xml` — Workshop-safe metadata; no `request_no_api_restrictions`.
- `workshop.xml` — Workshop title, tags and upload exclusions.
- `workshop_preview_image.png` — 1280×720, 16:9 preview image.
- `NoitaPatcher/` — intentionally absent from this branch.
- `tests/`, `files/qa/`, `files/diagnostics/` and `README.txt` remain available in the repository where applicable for development/review, but are excluded by `workshop.xml` from the Steam upload.
- Release runtime ships with `dev_mode = 0`.

The Workshop validation workflow parses both XML files, checks the mod ID and release dev-mode flag, verifies that no DLL or unrestricted-API request is present, validates the actual PNG header/dimensions/size, simulates the upload exclusions and extension whitelist, scans the uploaded runtime for unrestricted Lua API usage, and runs the Workshop regression suite.

## First publication

1. Check out/download the `workshop` branch.
2. If a full standalone MCM copy is already installed locally, **delete the old `Noita/mods/metamorph_creative_menu` folder first**. Do not copy the Workshop build over it: otherwise a stale `NoitaPatcher/noitapatcher.dll` can remain on disk and invalidate the Workshop-only test.
3. Copy the complete `metamorph_creative_menu` folder from the `workshop` branch into `Noita/mods/`.
4. Start Noita once and test the Workshop build with **Unsafe mods disabled**.
5. Verify the menu opens with **TAB**. Smoke-test an item spawn, a wand/spell edit, perk apply/remove, weather, a supported World Rule, a normal transformation and **TAB return**.
6. Do not use transformed-form death as a Workshop acceptance test: the hard serialized death handoff is a NoitaPatcher-powered standalone feature and is not guaranteed in this build.
7. Close Noita.
8. From the Noita installation directory run `workshop_upload.bat`, or run `noita_dev.exe -workshop_upload`.
9. Select `metamorph_creative_menu` in the uploader and create the Workshop item.
10. After the first upload, keep the generated `workshop_id.txt`. It identifies the existing Workshop item for future updates. Do not replace it with another item's ID.
11. Open the new Steam Workshop page, add the full description/screenshots, then set visibility to Public when ready.

## Suggested Workshop description

**Metamorph: Creative Menu (MCM)** is a creative toolkit for Noita: edit wands and spells, spawn items and liquids, manage perks/effects, transform into supported creatures, possess existing creatures, control weather, use reversible World Rules and spawn a PLAYER-style companion.

### Steam Workshop edition

This Workshop build is intentionally compatible with Noita's Workshop restrictions. It does not bundle the native NoitaPatcher DLL and does not request unrestricted API access.

Most normal menu/editor functionality remains available, but some advanced recovery, player-authority, exact entity serialization and other NoitaPatcher-powered paths are only available in the **Full Standalone Version**. Rules that require an unavailable native capability are presented as unsupported instead of pretending to work.

**Full Standalone Version:**
https://github.com/zerodancing/Metamorph-Creative-Menu/releases/tag/latest-build

**Source / Issues:**
https://github.com/zerodancing/Metamorph-Creative-Menu

### Controls

- **TAB** — open/close Creative Menu.
- **TAB while transformed** — request return to human form through the normal native polymorph path.
- **G** by default — possess a supported creature under the cursor.
- LMB/RMB actions are shown in the menu for each catalog entry.

### Entangled Worlds

Entangled Worlds integration is experimental. For multiplayer, use the same MCM build on every peer and a compatible EW setup. If another enabled environment exposes a compatible NoitaPatcher bridge, MCM can reuse capabilities that are actually present, but the Workshop package itself does not include or require that native provider.

## Updating the Workshop item

For updates, work from the `workshop` branch, preserve the Workshop item's `workshop_id.txt`, replace the local Noita mod folder with the updated Workshop folder and run the uploader again. Keep `description=""` in `workshop.xml` if you want Steam's manually edited Workshop description to remain untouched by uploads.

## Branch policy

- `main` = full standalone GitHub build.
- `workshop` = Steam Workshop-safe build.
- Do not merge the Workshop removal of NoitaPatcher back into `main`.
- When syncing future gameplay changes from `main` into `workshop`, re-check `mod.xml`, `workshop.xml`, the absence of `NoitaPatcher/`, `dev_mode = 0`, and test with Unsafe mods disabled before uploading.
