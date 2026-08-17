# Steam Workshop release guide

This branch is the Steam Workshop edition of **Metamorph: Creative Menu**.

The full standalone build remains on `main` and includes the bundled NoitaPatcher runtime. The Workshop edition intentionally does **not** request unrestricted API access and does **not** contain the bundled native NoitaPatcher DLL, because Noita Workshop does not support mods that require `request_no_api_restrictions="1"`, and the Workshop uploader only accepts its documented file types.

## Files prepared for Workshop

Inside `metamorph_creative_menu/`:

- `mod.xml` — Workshop-safe metadata; no `request_no_api_restrictions`.
- `workshop.xml` — Workshop title, tags and upload exclusions.
- `workshop_preview_image.png` — 1280×720, 16:9 preview image.
- `NoitaPatcher/` — intentionally absent from this branch.
- `tests/` and `README.txt` remain in the repository for development but are excluded by `workshop.xml` from the Steam upload.

## First publication

1. Check out/download the `workshop` branch.
2. Copy the complete `metamorph_creative_menu` folder into `Noita/mods/`.
3. Start Noita once and test the Workshop build with **Unsafe mods disabled**.
4. Verify the menu opens with **TAB** and test the features that do not require the standalone NoitaPatcher runtime.
5. Close Noita.
6. From the Noita installation directory run `workshop_upload.bat`, or run `noita_dev.exe -workshop_upload`.
7. Select `metamorph_creative_menu` in the uploader and create the Workshop item.
8. After the first upload, keep the generated `workshop_id.txt`. It identifies the existing Workshop item for future updates. Do not replace it with another item's ID.
9. Open the new Steam Workshop page, add the full description/screenshots, then set visibility to Public when ready.

## Suggested Workshop description

**Metamorph: Creative Menu (MCM)** is a creative toolkit for Noita: edit wands and spells, spawn items and liquids, manage perks/effects, transform into supported creatures, possess existing creatures, control weather, use reversible World Rules and spawn a PLAYER-style companion.

### Steam Workshop edition

This Workshop build is intentionally compatible with Noita's Workshop restrictions. It does not bundle the native NoitaPatcher DLL and does not request unrestricted API access.

Most normal menu/editor functionality remains available, but some advanced recovery, player-authority, exact entity serialization and other NoitaPatcher-powered paths are only available in the **Full Standalone Version**.

**Full Standalone Version:**
https://github.com/zerodancing/Metamorph-Creative-Menu/releases/tag/latest-build

**Source / Issues:**
https://github.com/zerodancing/Metamorph-Creative-Menu

### Controls

- **TAB** — open/close Creative Menu.
- **TAB while transformed** — request return to human form.
- **G** by default — possess a supported creature under the cursor.
- LMB/RMB actions are shown in the menu for each catalog entry.

### Entangled Worlds

Entangled Worlds integration is experimental. For multiplayer, use the same MCM build on every peer and a compatible EW setup.

## Updating the Workshop item

For updates, work from the `workshop` branch, preserve the Workshop item's `workshop_id.txt`, copy the updated mod folder into the local Noita `mods` directory and run the uploader again. Keep `description=""` in `workshop.xml` if you want Steam's manually edited Workshop description to remain untouched by uploads.

## Branch policy

- `main` = full standalone GitHub build.
- `workshop` = Steam Workshop-safe build.
- Do not merge the Workshop removal of NoitaPatcher back into `main`.
- When syncing future gameplay changes from `main` into `workshop`, re-check `mod.xml`, `workshop.xml`, the absence of `NoitaPatcher/`, and test with Unsafe mods disabled before uploading.
