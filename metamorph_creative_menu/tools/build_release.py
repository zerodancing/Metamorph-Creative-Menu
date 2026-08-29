#!/usr/bin/env python3
"""Build a deterministic full Metamorph: Creative Menu distribution archive."""

from __future__ import annotations

import argparse
import re
import sys
import zipfile
from pathlib import Path


VERSION = "2.0.0"
ROOT_NAME = "metamorph_creative_menu"
EXCLUDED_DIRECTORIES = {
    "dist",
}
EXCLUDED_DIRECTORY_NAMES = {"__pycache__", ".pytest_cache"}
EXCLUDED_FILENAMES = {".DS_Store", "Thumbs.db"}
EXCLUDED_SUFFIXES = {".pyc", ".pyo"}
REQUIRED_FILES = {
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
    "files/diagnostics/service.lua",
    "files/qa/controller.lua",
    "tests/run_all.py",
    "tests/TESTING.txt",
    "tools/build_release.py",
}


def is_excluded(relative: Path) -> bool:
    if relative.name in EXCLUDED_FILENAMES:
        return True
    if relative.suffix.lower() in EXCLUDED_SUFFIXES:
        return True
    if any(part in EXCLUDED_DIRECTORY_NAMES for part in relative.parts):
        return True
    normalized = relative.as_posix()
    return any(normalized == directory or normalized.startswith(directory + "/")
               for directory in EXCLUDED_DIRECTORIES)


def release_files(root: Path) -> list[Path]:
    result = []
    for path in root.rglob("*"):
        if path.is_symlink():
            raise RuntimeError(f"release input contains a symlink: {path.relative_to(root)}")
        if path.is_file() and not is_excluded(path.relative_to(root)):
            result.append(path)
    return sorted(result, key=lambda path: path.relative_to(root).as_posix())


def validate(root: Path, files: list[Path]) -> None:
    relative_files = {path.relative_to(root).as_posix() for path in files}
    missing = sorted(REQUIRED_FILES - relative_files)
    if missing:
        raise RuntimeError("missing required release files: " + ", ".join(missing))
    version = (root / "VERSION.txt").read_text(encoding="utf-8").strip()
    if version != VERSION:
        raise RuntimeError(f"VERSION.txt is {version!r}, expected {VERSION!r}")
    mod_id = (root / "mod_id.txt").read_text(encoding="utf-8").strip()
    if mod_id != ROOT_NAME:
        raise RuntimeError(f"mod id changed: {mod_id!r}")
    dev_mode = (root / "dev_mode.lua").read_text(encoding="utf-8")
    if re.search(r"\bdev_mode\s*=\s*0\b", dev_mode) is None or re.search(r"\breturn\s+dev_mode\b", dev_mode) is None:
        raise RuntimeError("dev_mode.lua is not locked to the release default")


def build(root: Path, output: Path) -> tuple[int, int]:
    files = release_files(root)
    validate(root, files)
    output.parent.mkdir(parents=True, exist_ok=True)
    if output.exists():
        output.unlink()
    source_bytes = 0
    with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for path in files:
            relative = path.relative_to(root).as_posix()
            data = path.read_bytes()
            source_bytes += len(data)
            info = zipfile.ZipInfo(f"{ROOT_NAME}/{relative}", (2020, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            info.create_system = 3
            archive.writestr(info, data, compress_type=zipfile.ZIP_DEFLATED, compresslevel=9)
    with zipfile.ZipFile(output, "r") as archive:
        bad = archive.testzip()
        if bad is not None:
            raise RuntimeError(f"archive CRC verification failed: {bad}")
    return len(files), source_bytes


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", nargs="?", type=Path,
                        help="output ZIP (default: dist/metamorph_creative_menu_v2.0.0.zip)")
    args = parser.parse_args()
    root = Path(__file__).resolve().parent.parent
    output = (args.output or root / "dist" / f"{ROOT_NAME}_v{VERSION}.zip").resolve()
    try:
        count, source_bytes = build(root, output)
    except Exception as exc:
        print(f"release_build=FAIL {exc}", file=sys.stderr)
        return 1
    print(f"release_build=PASS version={VERSION} files={count} source_bytes={source_bytes} "
          f"archive_bytes={output.stat().st_size} output={output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
