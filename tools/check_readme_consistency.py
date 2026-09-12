#!/usr/bin/env python3
"""Validate the synchronized multilingual GitHub README set."""

from __future__ import annotations

import re
import sys
from pathlib import Path


README_FILES = [
    "README.md",
    "README.ru.md",
    "README.pt-BR.md",
    "README.es.md",
    "README.de.md",
    "README.fr.md",
    "README.it.md",
    "README.pl.md",
    "README.zh-CN.md",
    "README.ja.md",
    "README.ko.md",
]

REQUIRED_MARKERS = [
    "zerodancing",
    "latest-build",
    "Unsafe Mods",
    "NoitaPatcher",
    "Entangled Worlds",
    "Game Over",
    "ALWAYS CAST",
    "metamorph_creative_menu/mod.xml",
    "metamorph_creative_menu/tests/",
    "Metamorph-Creative-Menu-v...zip",
    "THIRD_PARTY_NOTICES.md",
]

# Root README files describe the current mod, not a numbered release. Release
# numbers belong in VERSION.txt / CHANGELOG.txt and release metadata instead.
SEMVER_RE = re.compile(r"(?<![A-Za-z0-9])(?:v\s*)?\d+\.\d+(?:\.\d+)?(?![A-Za-z0-9])", re.IGNORECASE)
HEADING_RE = re.compile(r"^(#{1,6})\s+\S", re.MULTILINE)


def fail(message: str) -> None:
    print(f"README consistency: {message}", file=sys.stderr)
    raise SystemExit(1)


def heading_shape(text: str) -> list[int]:
    return [len(match.group(1)) for match in HEADING_RE.finditer(text)]


def main() -> None:
    root = Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()

    missing = [name for name in README_FILES if not (root / name).is_file()]
    if missing:
        fail("missing files: " + ", ".join(missing))

    docs = {
        name: (root / name).read_text(encoding="utf-8-sig")
        for name in README_FILES
    }

    english_shape = heading_shape(docs["README.md"])
    if not english_shape:
        fail("README.md has no Markdown section headings")

    for name, text in docs.items():
        version = SEMVER_RE.search(text)
        if version:
            fail(f"{name} contains a release number: {version.group(0)!r}")

        for marker in REQUIRED_MARKERS:
            if marker not in text:
                fail(f"{name} is missing required topic marker {marker!r}")

        for linked_name in README_FILES:
            if linked_name not in text:
                fail(f"{name} is missing language link {linked_name!r}")

        shape = heading_shape(text)
        if shape != english_shape:
            fail(
                f"{name} heading structure differs from README.md "
                f"({len(shape)} headings vs {len(english_shape)})"
            )

    print(
        "README consistency: PASS "
        f"({len(README_FILES)} languages, {len(english_shape)} headings each)"
    )


if __name__ == "__main__":
    main()
