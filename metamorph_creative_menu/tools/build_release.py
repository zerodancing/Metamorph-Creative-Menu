#!/usr/bin/env python3
"""Build the complete Metamorph: Creative Menu development/source archive."""

from __future__ import annotations

import argparse
import re
import sys
import zipfile
from pathlib import Path

ROOT_NAME = "metamorph_creative_menu"
EXCLUDED_DIRECTORIES = {"dist"}
EXCLUDED_DIRECTORY_NAMES = {"__pycache__", ".pytest_cache", ".git"}
EXCLUDED_FILENAMES = {".DS_Store", "Thumbs.db"}
EXCLUDED_SUFFIXES = {".pyc", ".pyo"}
REQUIRED_FILES = {
    "BUILD.txt",
    "CHANGELOG.txt",
    "VERSION.txt",
    "README.txt",
    "compatibility.xml",
    "dev_mode.lua",
    "init.lua",
    "mod.xml",
    "mod_id.txt",
    "settings.lua",
    "translations.csv",
    "NoitaPatcher/load.lua",
    "NoitaPatcher/noitapatcher.dll",
    "mcm_native_gameover.dll",
    "mcm_native_gameover.lib",
    "native_src/mcm_native_gameover.c",
    "files/diagnostics/service.lua",
    "files/qa/controller.lua",
    "tests/run_all.py",
    "tests/TESTING.txt",
    "tools/build_release.py",
}


def is_excluded(relative: Path) -> bool:
    if relative.name in EXCLUDED_FILENAMES or relative.suffix.lower() in EXCLUDED_SUFFIXES:
        return True
    if any(part in EXCLUDED_DIRECTORY_NAMES for part in relative.parts):
        return True
    normalized = relative.as_posix()
    return any(normalized == directory or normalized.startswith(directory + "/") for directory in EXCLUDED_DIRECTORIES)


def source_files(root: Path) -> list[Path]:
    files = []
    for path in root.rglob("*"):
        if path.is_symlink():
            raise RuntimeError(f"source tree contains a symlink: {path.relative_to(root)}")
        if path.is_file() and not is_excluded(path.relative_to(root)):
            files.append(path)
    return sorted(files, key=lambda path: path.relative_to(root).as_posix())


def validate(root: Path, files: list[Path]) -> str:
    relative_files = {path.relative_to(root).as_posix() for path in files}
    missing = sorted(REQUIRED_FILES - relative_files)
    if missing:
        raise RuntimeError("missing source files: " + ", ".join(missing))

    patch_dir = root / "tools" / "player_release"
    if not patch_dir.is_dir() or not any(patch_dir.glob("*.patch")):
        raise RuntimeError("missing player release cleanup patches")

    version = (root / "VERSION.txt").read_text(encoding="utf-8").strip()
    if re.fullmatch(r"[0-9]+(?:\.[0-9]+){0,2}", version) is None:
        raise RuntimeError(f"invalid VERSION.txt: {version!r}")
    if (root / "mod_id.txt").read_text(encoding="utf-8").strip() != ROOT_NAME:
        raise RuntimeError("mod_id.txt does not match the mod directory name")
    return version


def build(root: Path, output: Path) -> tuple[str, int, int]:
    files = source_files(root)
    version = validate(root, files)
    output.parent.mkdir(parents=True, exist_ok=True)
    if output.exists():
        output.unlink()

    total_bytes = 0
    with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for path in files:
            relative = path.relative_to(root).as_posix()
            data = path.read_bytes()
            total_bytes += len(data)
            info = zipfile.ZipInfo(f"{ROOT_NAME}/{relative}", (2020, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            info.create_system = 3
            archive.writestr(info, data, compress_type=zipfile.ZIP_DEFLATED, compresslevel=9)

    with zipfile.ZipFile(output) as archive:
        broken = archive.testzip()
        if broken is not None:
            raise RuntimeError(f"archive CRC verification failed: {broken}")
    return version, len(files), total_bytes


def main() -> int:
    root = Path(__file__).resolve().parent.parent
    version = (root / "VERSION.txt").read_text(encoding="utf-8").strip()
    major = version.split(".", 1)[0] if version else "source"

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", nargs="?", type=Path,
                        default=root / "dist" / f"Metamorph-Creative-Menu-v{major}.zip")
    args = parser.parse_args()
    try:
        built_version, count, total_bytes = build(root, args.output.resolve())
    except Exception as exc:
        print(f"SOURCE_BUILD=FAIL {exc}", file=sys.stderr)
        return 1
    print(
        f"SOURCE_BUILD=PASS version={built_version} files={count} "
        f"source_bytes={total_bytes} output={args.output}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
