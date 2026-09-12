#!/usr/bin/env python3
"""Validate and import one complete MCM development-source archive."""

from __future__ import annotations

import os
import re
import shutil
import tempfile
import zipfile
from pathlib import Path, PurePosixPath

ROOT_NAME = "metamorph_creative_menu"
ARCHIVE_RE = re.compile(
    r"^Metamorph-Creative-Menu-v([0-9]+)(?:[._-][0-9A-Za-z]+)*\.zip$",
    re.IGNORECASE,
)
VERSION_RE = re.compile(r"[0-9]+(?:\.[0-9]+){0,2}")
MAX_ARCHIVE_FILES = 10_000
MAX_UNCOMPRESSED_BYTES = 256 * 1024 * 1024

REQUIRED_SOURCE_FILES = {
    "VERSION.txt",
    "LICENSE.txt",
    "NOTICE.txt",
    "mod.xml",
    "init.lua",
    "dev_mode.lua",
    "tests/run_all.py",
    "files/qa/controller.lua",
    "files/diagnostics/service.lua",
    "native_src/mcm_native_gameover.c",
    "native_src/README.md",
    "native_src/build_msvc.bat",
    "mcm_native_gameover.dll",
    "mcm_native_gameover.lib",
    "tools/build_release.py",
    "NoitaPatcher/noitapatcher.dll",
}


def write_output(key: str, value: str) -> None:
    output = os.environ.get("GITHUB_OUTPUT")
    if output:
        with open(output, "a", encoding="utf-8") as handle:
            handle.write(f"{key}={value}\n")


def discover_archive(root: Path) -> tuple[Path | None, re.Match[str] | None]:
    matches: list[tuple[Path, re.Match[str]]] = []
    for path in sorted(root.iterdir(), key=lambda item: item.name.lower()):
        if not path.is_file():
            continue
        match = ARCHIVE_RE.fullmatch(path.name)
        if match is None or "-modworkshop" in path.name.lower():
            continue
        matches.append((path, match))

    if not matches:
        return None, None
    if len(matches) != 1:
        raise RuntimeError(
            "expected exactly one full source archive, found: "
            + ", ".join(path.name for path, _ in matches)
        )
    return matches[0]


def validate_members(archive: zipfile.ZipFile) -> list[zipfile.ZipInfo]:
    members = archive.infolist()
    if len(members) > MAX_ARCHIVE_FILES:
        raise RuntimeError(f"archive contains too many entries: {len(members)}")

    total_size = sum(info.file_size for info in members)
    if total_size > MAX_UNCOMPRESSED_BYTES:
        raise RuntimeError(f"archive is too large when unpacked: {total_size} bytes")

    seen: set[str] = set()
    seen_casefolded: set[str] = set()
    for info in members:
        name = info.filename
        if "\\" in name:
            raise RuntimeError(f"unsafe archive path uses backslashes: {name}")
        path = PurePosixPath(name)
        if path.is_absolute() or ".." in path.parts:
            raise RuntimeError(f"unsafe archive path: {name}")
        if not path.parts or path.parts[0] != ROOT_NAME:
            raise RuntimeError(f"unexpected archive path outside {ROOT_NAME}/: {name}")
        if any(":" in part for part in path.parts):
            raise RuntimeError(f"Windows-incompatible archive path: {name}")

        normalized = path.as_posix().rstrip("/")
        if normalized in seen:
            raise RuntimeError(f"duplicate archive path: {name}")
        folded = normalized.casefold()
        if folded in seen_casefolded:
            raise RuntimeError(f"case-colliding archive path: {name}")
        seen.add(normalized)
        seen_casefolded.add(folded)

        file_type = (info.external_attr >> 16) & 0o170000
        if file_type == 0o120000:
            raise RuntimeError(f"symlink is not allowed in source archive: {name}")
        if file_type not in {0, 0o040000, 0o100000}:
            raise RuntimeError(f"special filesystem entry is not allowed: {name}")

    broken = archive.testzip()
    if broken is not None:
        raise RuntimeError(f"archive CRC verification failed: {broken}")
    return members


def validate_candidate(candidate: Path, archive_major: str) -> str:
    missing = sorted(
        relative for relative in REQUIRED_SOURCE_FILES
        if not (candidate / relative).is_file()
    )
    if missing:
        raise RuntimeError("missing required source files: " + ", ".join(missing))

    patch_dir = candidate / "tools" / "player_release"
    if not patch_dir.is_dir() or not any(patch_dir.glob("*.patch")):
        raise RuntimeError("missing player release cleanup patches")

    version = (candidate / "VERSION.txt").read_text(encoding="utf-8").strip()
    if VERSION_RE.fullmatch(version) is None:
        raise RuntimeError(f"invalid VERSION.txt: {version!r}")
    if version.split(".", 1)[0] != archive_major:
        raise RuntimeError(
            f"archive name says v{archive_major}, but VERSION.txt says {version}"
        )
    return version


def import_archive(repository_root: Path) -> tuple[bool, str | None]:
    archive_path, match = discover_archive(repository_root)
    if archive_path is None or match is None:
        print("No full source archive found; nothing to import.")
        return False, None

    with tempfile.TemporaryDirectory(prefix="mcm-source-import-") as temporary:
        temporary_root = Path(temporary)
        with zipfile.ZipFile(archive_path) as archive:
            validate_members(archive)
            archive.extractall(temporary_root)

        candidate = temporary_root / ROOT_NAME
        version = validate_candidate(candidate, match.group(1))

        target = repository_root / ROOT_NAME
        replacement = repository_root / f".{ROOT_NAME}.incoming"
        if replacement.exists():
            shutil.rmtree(replacement)
        shutil.copytree(candidate, replacement)

        if target.exists():
            shutil.rmtree(target)
        replacement.replace(target)

    archive_path.unlink()
    return True, version


def main() -> int:
    root = Path.cwd().resolve()
    try:
        changed, version = import_archive(root)
    except (OSError, RuntimeError, zipfile.BadZipFile, UnicodeError) as exc:
        print(f"SOURCE_IMPORT=FAIL {exc}")
        return 1

    write_output("changed", "true" if changed else "false")
    if version is not None:
        write_output("version", version)
    if changed:
        print(f"SOURCE_IMPORT=PASS version={version}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
