#!/usr/bin/env python3
"""Validate that the player archive contains runtime content only."""

from __future__ import annotations

import argparse
import re
import shutil
import subprocess
import tempfile
import zipfile
from pathlib import Path, PurePosixPath

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
FORBIDDEN_SUFFIXES = {
    ".c", ".h", ".py", ".pyc", ".pyo", ".bat", ".cmd", ".ps1", ".sh",
    ".md", ".lib", ".obj", ".pdb", ".exp", ".ilk", ".map",
}
REQUIRED_FILES = {
    f"{ROOT}/mod.xml",
    f"{ROOT}/init.lua",
    f"{ROOT}/README.txt",
    f"{ROOT}/LICENSE.txt",
    f"{ROOT}/NOTICE.txt",
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


def long_bracket_open(text: str, index: int) -> tuple[int, int] | None:
    if index >= len(text) or text[index] != "[":
        return None
    cursor = index + 1
    while cursor < len(text) and text[cursor] == "=":
        cursor += 1
    if cursor < len(text) and text[cursor] == "[":
        return cursor - index - 1, cursor + 1
    return None


def long_bracket_close(text: str, index: int, equals: int) -> int | None:
    if index >= len(text) or text[index] != "]":
        return None
    cursor = index + 1
    for _ in range(equals):
        if cursor >= len(text) or text[cursor] != "=":
            return None
        cursor += 1
    if cursor < len(text) and text[cursor] == "]":
        return cursor + 1
    return None


def contains_lua_comment(text: str) -> bool:
    index = 0
    state = "code"
    quote = ""
    equals = 0
    while index < len(text):
        char = text[index]
        if state == "code":
            if char in {"'", '"'}:
                quote = char
                state = "string"
                index += 1
                continue
            opened = long_bracket_open(text, index)
            if opened is not None:
                equals, index = opened
                state = "long_string"
                continue
            if char == "-" and index + 1 < len(text) and text[index + 1] == "-":
                return True
            index += 1
            continue
        if state == "string":
            index += 1
            if char == "\\" and index < len(text):
                index += 1
            elif char == quote:
                state = "code"
            continue
        end = long_bracket_close(text, index, equals)
        if end is not None:
            index = end
            state = "code"
        else:
            index += 1
    return False


def validate_lua_syntax(lua_sources: list[tuple[str, bytes]], failures: list[str]) -> None:
    texlua = shutil.which("texlua")
    if texlua is None:
        failures.append("texlua is required to validate player Lua syntax")
        return
    if not lua_sources:
        failures.append("player archive contains no Lua files")
        return

    with tempfile.TemporaryDirectory(prefix="mcm-player-lua-") as temporary:
        root = Path(temporary)
        checker = root / "check.lua"
        checker.write_text(
            "for i=1,#arg do "
            "local f,e=loadfile(arg[i]); "
            "if not f then io.stderr:write(arg[i]..': '..tostring(e)..'\\n'); os.exit(1) end "
            "end\n",
            encoding="utf-8",
        )
        paths: list[str] = []
        names: list[str] = []
        for index, (name, data) in enumerate(lua_sources):
            path = root / f"{index:04d}.lua"
            path.write_bytes(data)
            paths.append(str(path))
            names.append(name)

        result = subprocess.run(
            [texlua, "--luaonly", str(checker), *paths],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
        )
        if result.returncode != 0:
            output = result.stdout.strip()
            for index, path in enumerate(paths):
                output = output.replace(path, names[index])
            failures.append("Lua syntax validation failed: " + output[:2000])


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("archive")
    args = parser.parse_args()

    failures: list[str] = []
    lua_sources: list[tuple[str, bytes]] = []
    with zipfile.ZipFile(args.archive) as zf:
        broken = zf.testzip()
        if broken is not None:
            failures.append(f"CRC failure: {broken}")

        infos = [info for info in zf.infolist() if not info.is_dir()]
        raw_names = [info.filename for info in infos]
        if len(raw_names) != len(set(raw_names)):
            failures.append("archive contains duplicate file names")

        for info in infos:
            name = info.filename
            path = PurePosixPath(name)
            if "\\" in name or path.is_absolute() or ".." in path.parts:
                failures.append(f"unsafe archive path: {name}")
            mode = (info.external_attr >> 16) & 0o170000
            if mode == 0o120000:
                failures.append(f"symlink is not allowed in player archive: {name}")

        names = set(raw_names)
        roots = {PurePosixPath(name).parts[0] for name in names if PurePosixPath(name).parts}
        if roots != {ROOT}:
            failures.append(f"unexpected archive roots: {sorted(roots)}")

        missing = sorted(REQUIRED_FILES - names)
        if missing:
            failures.append("missing runtime files: " + ", ".join(missing))

        leaked = sorted(
            name for name in names
            if name in FORBIDDEN_FILES
            or PurePosixPath(name).suffix.lower() in FORBIDDEN_SUFFIXES
            or any(part in name for part in FORBIDDEN_DIRS)
        )
        if leaked:
            failures.append("development files leaked: " + ", ".join(leaked[:20]))

        if f"{ROOT}/README.txt" in names:
            readme = zf.read(f"{ROOT}/README.txt").decode("utf-8")
            if readme != "Creator: zerodancing\n":
                failures.append("README.txt must contain only 'Creator: zerodancing'")

        if f"{ROOT}/NOTICE.txt" in names:
            notice = zf.read(f"{ROOT}/NOTICE.txt").decode("utf-8")
            if "Original developer: zerodancing" not in notice:
                failures.append("NOTICE.txt must preserve zerodancing attribution")
            if "https://github.com/zerodancing/Metamorph-Creative-Menu" not in notice:
                failures.append("NOTICE.txt must preserve the original GitHub project link")

        for name in sorted(names):
            suffix = PurePosixPath(name).suffix.lower()
            if suffix not in TEXT_SUFFIXES:
                continue
            data = zf.read(name)
            try:
                text = data.decode("utf-8")
            except UnicodeDecodeError:
                continue

            if suffix == ".lua":
                lua_sources.append((name, data))
                if contains_lua_comment(text):
                    failures.append(f"{name}: Lua comment residue")
                if "/*" in text or re.search(r"(?m)^\s*//", text):
                    failures.append(f"{name}: embedded C/C++ comment residue")
            elif suffix == ".xml" and "<!--" in text:
                failures.append(f"{name}: XML comment residue")

            for label, pattern in FORBIDDEN_TEXT:
                if pattern.search(text):
                    failures.append(f"{name}: {label}")

    validate_lua_syntax(lua_sources, failures)

    if failures:
        print("PLAYER_RELEASE_VALIDATION=FAIL")
        for failure in failures:
            print(failure)
        return 1

    print(f"PLAYER_RELEASE_VALIDATION=PASS files={len(names)} lua={len(lua_sources)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
