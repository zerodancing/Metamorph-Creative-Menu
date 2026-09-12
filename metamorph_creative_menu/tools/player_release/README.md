# Player release cleanup rules

This directory contains the release-only diffs applied after the full development tree has been copied into the temporary player-build stage.

The repository keeps QA, diagnostics, tests, profiling hooks and other development support in the full source tree. The ready-to-install player archive intentionally removes that support without making the development checkout less useful.

## Ordering

Patch names define their application order:

- `00-runtime-*` — general runtime cleanup and dev-only hooks;
- `10-ew-*` — Entangled Worlds instrumentation and development surfaces;
- `20-ui-*` — UI-only audit/debug plumbing;
- `30-data-*` — player-facing data and localization cleanup.

The order is significant. A later patch may assume that an earlier cleanup has already changed the staged file.

## What belongs here

A release patch may remove development-only behavior that must remain available in the full source, for example:

- QA or diagnostic wiring;
- profiling and metrics controls;
- test-only accessors;
- audit fields used only by development tools;
- localization strings used only by those development features.

Release patches must not be used to hide ordinary gameplay fixes. A gameplay fix belongs in the source file itself so tests, development builds and player builds execute the same behavior.

## Builder behavior

`tools/build_user_release.py` first excludes development-only files/directories and strips Lua comments. It then applies the patches in this directory with zero fuzz.

Before applying a patch, the builder performs a dry run. If the forward patch no longer applies but the complete patch applies cleanly in reverse, the builder treats that cleanup as already integrated into the source and skips the patch. This lets a later source revision permanently adopt a former release-only cleanup without requiring a dummy patch.

If neither direction matches, the build stops. Do not make the patch command permissive just to get a release out: inspect the changed source and either port the cleanup to the new code or retire the patch when the source has genuinely absorbed it.

## Updating a cleanup after source changes

1. Run the complete source regression suite first.
2. Build the player archive with `tools/build_user_release.py`.
3. If a patch no longer matches, inspect the affected source and the intended player result.
4. Update or retire only that cleanup rule.
5. Run `tools/validate_user_release.py` on the resulting archive.
6. Re-run the full repository release workflow before publishing.

For Entangled Worlds changes, preserve RPC registration order and protocol compatibility. A release cleanup may neutralize development-only protocol behavior, but it must not shift an existing reserved slot or silently reorder RPC allocation.

## Final validation

The patch set is not the final authority on cleanliness. `tools/validate_user_release.py` also rejects development directories and build artifacts, checks the minimal player `README.txt`, scans runtime text for known QA/debug residue, verifies archive-path safety and compiles every packaged Lua file with `texlua`.

The release workflow publishes only after that validation succeeds.
