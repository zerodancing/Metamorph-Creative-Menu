#!/usr/bin/env python3
"""Reject development-process residue and stale public metadata from the repository."""

from __future__ import annotations

import argparse
import re
from pathlib import Path

TEXT_SUFFIXES = {".lua", ".py", ".md", ".txt", ".xml", ".yml", ".yaml", ".csv", ".c", ".h", ".patch"}
SKIP_PARTS = {".git", "__pycache__", ".pytest_cache", "dist"}
SKIP_FILES = {
    "tools/check_source_hygiene.py",
    "tools/validate_user_release.py",
}

RULES = (
    ("numbered internal test chronology", re.compile(r"\bTEST\s+\d+\b", re.IGNORECASE)),
    ("legacy test-only export", re.compile(r"\b[A-Za-z0-9_]+_for_test\b")),
    ("conversation-specific wording", re.compile(r"\b(?:the\s+)?user['’]s\s+build\b", re.IGNORECASE)),
    ("conversation-specific wording", re.compile(r"\bat\s+the\s+user['’]s\s+request\b", re.IGNORECASE)),
    ("internal numbered runtime label", re.compile(r"\[MCM\s*(?:TEST\s*)?\d{2,}\]", re.IGNORECASE)),
    ("AI tool/model attribution residue", re.compile(
        r"\b(?:ChatGPT|OpenAI|Claude|Gemini|Copilot|LLM|AI[- ]generated|generated\s+by\s+AI)\b",
        re.IGNORECASE,
    )),
)


def relative_name(root: Path, path: Path) -> str:
    return path.relative_to(root).as_posix()


def validate_metadata(root: Path, failures: list[str]) -> None:
    mod_root = root / "metamorph_creative_menu"
    version_file = mod_root / "VERSION.txt"
    readme = root / "README.md"
    source_readme = mod_root / "README.txt"

    if not version_file.is_file():
        failures.append("metamorph_creative_menu/VERSION.txt: missing")
        return

    version = version_file.read_text(encoding="utf-8").strip()
    if not re.fullmatch(r"[0-9]+(?:\.[0-9]+){0,2}", version):
        failures.append(f"metamorph_creative_menu/VERSION.txt: invalid version {version!r}")

    if readme.is_file():
        text = readme.read_text(encoding="utf-8")
        if "zerodancing" not in text:
            failures.append("README.md: creator attribution to zerodancing is missing")
        stale = re.findall(r"\bVersion\s+([0-9]+(?:\.[0-9]+){1,2})\b|\bCurrent version:\s*\*\*([^*]+)\*\*", text, re.IGNORECASE)
        for first, second in stale:
            mentioned = (first or second).strip()
            if mentioned and mentioned != version:
                failures.append(f"README.md: stale version {mentioned!r}; VERSION.txt is {version!r}")

    if source_readme.is_file() and "zerodancing" not in source_readme.read_text(encoding="utf-8"):
        failures.append("metamorph_creative_menu/README.txt: creator attribution is missing")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("root", nargs="?", type=Path, default=Path("."))
    args = parser.parse_args()
    root = args.root.resolve()

    failures: list[str] = []
    checked = 0
    for path in sorted(root.rglob("*")):
        if not path.is_file() or path.suffix.lower() not in TEXT_SUFFIXES:
            continue
        relative = relative_name(root, path)
        if relative in SKIP_FILES or any(part in SKIP_PARTS for part in path.relative_to(root).parts):
            continue
        checked += 1
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        for line_number, line in enumerate(text.splitlines(), 1):
            for label, pattern in RULES:
                if pattern.search(line):
                    failures.append(f"{relative}:{line_number}: {label}: {line.strip()[:180]}")

    validate_metadata(root, failures)

    if failures:
        print("SOURCE_HYGIENE=FAIL")
        for failure in failures:
            print(failure)
        return 1

    print(f"SOURCE_HYGIENE=PASS files={checked}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
