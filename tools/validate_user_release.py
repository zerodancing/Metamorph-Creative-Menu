#!/usr/bin/env python3
"""Validate that the player archive contains runtime content only."""

from __future__ import annotations

import argparse
import re
import zipfile
from pathlib import PurePosixPath

ROOT = "metamorph_creative_menu"
FORBIDDEN_DIRS = (
    "/tests/", "/files/qa/", "/files/diagnostics/", "/native_src/", "/tools/", "/dist/",
)
FORBIDDEN_FILES = {
    f"{ROOT}/BUILD.txt",
    f"{ROOT}/CHANGELOG.txt",
    f"{ROOT}/VERSION.txt",
    f"{ROOT}/dev_mode.lua",
    f"{ROOT}/mcm_native_gameover.lib",
    f"{ROOT}/mod_id.txt",
    f"{ROOT}/files/core/bounded_log.lua",
    f"{ROOT}/files/features/creatures/diagnostics.lua",
    f"{ROOT}/files/integrations/ew/bridge/qa.lua",
    f"{ROOT}/files/integrations/ew/bridge/qa_reserved.lua",
}
REQUIRED_FILES = {
    f"{ROOT}/mod.xml",
    f"{ROOT}/init.lua",
    f"{ROOT}/README.txt",
    f"{ROOT}/NoitaPatcher/noitapatcher.dll",
    f"{ROOT}/mcm_native_gameover.dll",
}
TEXT_SUFFIXES = {".lua", ".xml", ".csv", ".txt"}
FORBIDDEN_TEXT = (
    ("QA localization/runtime residue", re.compile(r"\bmcm_qa_|\bsync_qa|\bqa_reserved\b", re.IGNORECASE)),
    ("diagnostic hook residue", re.compile(r"METAMORPH_CREATIVE_MENU_DIAGNOSTICS|\bmcm_diag_", re.IGNORECASE)),
    ("debug API residue", re.compile(r"\bdebug_state\b|\b_for_test\b")),
    ("profiling/metrics control residue", re.compile(r"\bset_profiling_enabled\b|\bset_metrics_enabled\b")),
    ("numbered development log residue", re.compile(r"\[MCM\s*\d{2,}\]", re.IGNORECASE)),
    ("numbered test chronology", re.compile(r"\bTEST\s+\d+\b", re.IGNORECASE)),
    ("AI attribution residue", re.compile(
        r"\b(?:ChatGPT|OpenAI|Claude|Gemini|Copilot|LLM|AI[- ]generated|generated\s+by\s+AI)\b",
        re.IGNORECASE,
    )),
)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("archive")
    args = parser.parse_args()

    failures: list[str] = []
    with zipfile.ZipFile(args.archive) as zf:
        broken = zf.testzip()
        if broken is not None:
            failures.append(f"CRC failure: {broken}")

        names = {name for name in zf.namelist() if not name.endswith("/")}
        roots = {PurePosixPath(name).parts[0] for name in names if PurePosixPath(name).parts}
        if roots != {ROOT}:
            failures.append(f"unexpected archive roots: {sorted(roots)}")

        missing = sorted(REQUIRED_FILES - names)
        if missing:
            failures.append("missing runtime files: " + ", ".join(missing))

        leaked = sorted(name for name in names if name in FORBIDDEN_FILES or any(part in name for part in FORBIDDEN_DIRS))
        if leaked:
            failures.append("development files leaked: " + ", ".join(leaked[:20]))

        if f"{ROOT}/README.txt" in names:
            readme = zf.read(f"{ROOT}/README.txt").decode("utf-8")
            if readme != "Creator: zerodancing\n":
                failures.append("README.txt must contain only 'Creator: zerodancing'")

        for name in sorted(names):
            suffix = PurePosixPath(name).suffix.lower()
            if suffix not in TEXT_SUFFIXES:
                continue
            try:
                text = zf.read(name).decode("utf-8")
            except UnicodeDecodeError:
                continue

            if suffix == ".lua":
                if "--" in text:
                    failures.append(f"{name}: Lua comment residue")
                if "/*" in text or re.search(r"(?m)^\s*//", text):
                    failures.append(f"{name}: embedded C/C++ comment residue")
            elif suffix == ".xml" and "<!--" in text:
                failures.append(f"{name}: XML comment residue")

            for label, pattern in FORBIDDEN_TEXT:
                if pattern.search(text):
                    failures.append(f"{name}: {label}")

    if failures:
        print("PLAYER_RELEASE_VALIDATION=FAIL")
        for failure in failures:
            print(failure)
        return 1

    print(f"PLAYER_RELEASE_VALIDATION=PASS files={len(names)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
