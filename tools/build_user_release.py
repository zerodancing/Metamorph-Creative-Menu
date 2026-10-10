#!/usr/bin/env python3
"""Build the player-facing Metamorph: Creative Menu archive from the full source tree."""

from __future__ import annotations

import argparse
import re
import shutil
import subprocess
import tempfile
import zipfile
from pathlib import Path

ROOT_NAME = "metamorph_creative_menu"

EXCLUDED_DIRS = {
    "tests",
    "files/qa",
    "files/diagnostics",
    "native_src",
    "tools",
    "dist",
}

EXCLUDED_FILES = {
    "BUILD.txt",
    "CHANGELOG.txt",
    "VERSION.txt",
    "dev_mode.lua",
    "mcm_native_gameover.lib",
    "mod_id.txt",
    "files/core/bounded_log.lua",
    "files/features/creatures/diagnostics.lua",
    "files/integrations/ew/bridge/qa.lua",
    "files/integrations/ew/bridge/qa_reserved.lua",
}

REQUIRED_RUNTIME_FILES = {
    "mod.xml",
    "init.lua",
    "settings.lua",
    "translations.csv",
    "NoitaPatcher/load.lua",
    "NoitaPatcher/noitapatcher.dll",
    "mcm_native_gameover.dll",
}


def is_excluded(relative: Path) -> bool:
    normalized = relative.as_posix()
    if normalized in EXCLUDED_FILES:
        return True
    return any(normalized == directory or normalized.startswith(directory + "/") for directory in EXCLUDED_DIRS)


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


def strip_lua_comments(text: str) -> str:
    out: list[str] = []
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
                out.append(char)
                index += 1
                continue
            opened = long_bracket_open(text, index)
            if opened is not None:
                equals, end = opened
                out.append(text[index:end])
                index = end
                state = "long_string"
                continue
            if char == "-" and index + 1 < len(text) and text[index + 1] == "-":
                opened = long_bracket_open(text, index + 2)
                if opened is not None:
                    equals, end = opened
                    index = end
                    state = "block_comment"
                    continue
                index += 2
                while index < len(text) and text[index] not in "\r\n":
                    index += 1
                continue
            out.append(char)
            index += 1
            continue

        if state == "string":
            out.append(char)
            index += 1
            if char == "\\" and index < len(text):
                out.append(text[index])
                index += 1
            elif char == quote:
                state = "code"
            continue

        if state == "long_string":
            end = long_bracket_close(text, index, equals)
            if end is not None:
                out.append(text[index:end])
                index = end
                state = "code"
            else:
                out.append(char)
                index += 1
            continue

        end = long_bracket_close(text, index, equals)
        if end is not None:
            index = end
            state = "code"
        else:
            if char in "\r\n":
                out.append(char)
            index += 1

    lines = [line.rstrip() for line in "".join(out).splitlines()]
    compact: list[str] = []
    blank = False
    for line in lines:
        if not line:
            if blank:
                continue
            blank = True
        else:
            blank = False
        compact.append(line)
    return "\n".join(compact).strip() + "\n"


def remove_marker_guard_blocks(text: str, marker: str) -> str:
    lines = text.splitlines()
    output: list[str] = []
    index = 0
    while index < len(lines):
        line = lines[index]
        if marker not in line or not line.lstrip().startswith("if "):
            output.append(line)
            index += 1
            continue

        depth = 0
        while index < len(lines):
            current = lines[index].strip()
            if re.match(r"^(if|for|while)\b.*\bthen\b", current) or current.startswith("function "):
                depth += 1
            if current == "end" or current.startswith("end "):
                depth -= 1
            index += 1
            if depth <= 0:
                break
    return "\n".join(output).strip() + "\n"


def clean_init(text: str) -> str:
    text = re.sub(
        r'local dev_mode_value = dofile\("mods/metamorph_creative_menu/dev_mode\.lua"\)\n'
        r'local DEV_MODE = tonumber\(dev_mode_value\) == 1\n'
        r'METAMORPH_CREATIVE_MENU_DEV_MODE = DEV_MODE\n+',
        "",
        text,
        count=1,
    )
    text = re.sub(r'^local diagnostics = DEV_MODE.*\n', "", text, flags=re.MULTILINE)
    text = re.sub(r'^local qa_controller = DEV_MODE.*\n', "", text, flags=re.MULTILINE)
    text = re.sub(r'^\s*if diagnostics ~= nil then protected_call\("diagnostics\.update".*\n', "", text, flags=re.MULTILINE)
    text = re.sub(r'^\s*if qa_controller ~= nil then protected_call\("qa_controller\.update".*\n', "", text, flags=re.MULTILINE)
    text = remove_marker_guard_blocks(text, "METAMORPH_CREATIVE_MENU_DIAGNOSTICS_CAPTURE")
    text = re.sub(
        r'\s*local ok_resilience, seed_fallbacks, biome_fallbacks, crosscall_guards =\n'
        r'\s*protected_call\("ew_resilience\.post_init", ew_resilience\.post_init\)\n'
        r'\s*if not ok_resilience then.*?\n'
        r'\s*if \(tonumber\(seed_fallbacks\).*?\n'
        r'\s*or \(tonumber\(crosscall_guards\).*?\n'
        r'\s*then\n'
        r'.*?\n'
        r'.*?\n'
        r'\s*end\n',
        '\n    protected_call("ew_resilience.post_init", ew_resilience.post_init)\n',
        text,
        count=1,
        flags=re.DOTALL,
    )
    text = re.sub(r'^\s*elseif DEV_MODE and tonumber\(prepared\) ~= nil then\n\s*print\([^\n]+\)\n', "", text, flags=re.MULTILINE)
    return text


def clean_bootstrap(text: str) -> str:
    text = re.sub(
        r'local dev_mode = tonumber\(dofile\("mods/metamorph_creative_menu/dev_mode\.lua"\)\) == 1\n'
        r'local qa = dofile\(dev_mode\n'
        r'\s*and "mods/metamorph_creative_menu/files/integrations/ew/bridge/qa\.lua"\n'
        r'\s*or "mods/metamorph_creative_menu/files/integrations/ew/bridge/qa_reserved\.lua"\)\n',
        "",
        text,
        count=1,
    )
    text = re.sub(r'^if type\(forms\.set_profiling_enabled\).*\n', "", text, flags=re.MULTILINE)
    text = re.sub(r'^if type\(materials\.set_metrics_enabled\).*\n', "", text, flags=re.MULTILINE)
    text = text.replace(
        "qa.register(rpc, common)",
        "rpc.opts_reliable()\nrpc.opts_everywhere()\nfunction rpc.sync_qa_state(...) end",
    )
    text = re.sub(r'\n\s*if dev_mode then\n.*?\n\s*end\n', "\n", text, count=1, flags=re.DOTALL)
    text = re.sub(r'^\s*if dev_mode then protected_update\("qa\.update".*\n', "", text, flags=re.MULTILINE)
    return text


def clean_resilience(text: str) -> str:
    return text.replace(
        'local DEV_MODE = tonumber(dofile("mods/metamorph_creative_menu/dev_mode.lua")) == 1',
        'local DEV_MODE = false',
    )


def clean_lua(relative: str, text: str) -> str:
    text = strip_lua_comments(text)
    if relative == "init.lua":
        text = clean_init(text)
    elif relative == "files/integrations/ew/bootstrap.lua":
        text = clean_bootstrap(text)
    elif relative == "files/integrations/ew/resilience.lua":
        text = clean_resilience(text)
    elif relative == "files/integrations/ew/bridge/protocol.lua":
        namespace = re.search(r'NAMESPACE\s*=\s*"([^"]+)"', text)
        if namespace is None:
            raise RuntimeError("EW protocol namespace not found")
        text = 'return {\n    NAMESPACE = "' + namespace.group(1) + '",\n}\n'
    return strip_lua_comments(text)


def write_stage(source: Path, stage_root: Path) -> None:
    target = stage_root / ROOT_NAME
    target.mkdir(parents=True, exist_ok=True)
    for path in sorted(source.rglob("*"), key=lambda item: item.relative_to(source).as_posix()):
        if not path.is_file() or path.is_symlink():
            continue
        relative = path.relative_to(source)
        if is_excluded(relative):
            continue
        data = path.read_bytes()
        if relative.suffix.lower() == ".lua":
            data = clean_lua(relative.as_posix(), data.decode("utf-8")).encode("utf-8")
        destination = target / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes(data)

    (target / "README.txt").write_text("Creator: zerodancing\n", encoding="utf-8")


def run_patch(executable: str, patch_file: Path, stage_root: Path, *, reverse: bool, dry_run: bool) -> subprocess.CompletedProcess[str]:
    command = [executable, "-p0", "--batch", "--fuzz=0"]
    if dry_run:
        command.append("--dry-run")
    if reverse:
        command.append("--reverse")
    else:
        command.append("--forward")
    command.extend(["-i", str(patch_file.resolve())])
    return subprocess.run(
        command,
        cwd=stage_root,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
    )


def apply_release_patches(source: Path, stage_root: Path) -> None:
    patch_dir = source / "tools" / "player_release"
    patch_files = sorted(patch_dir.glob("*.patch")) if patch_dir.is_dir() else []
    if not patch_files:
        raise RuntimeError("tools/player_release/*.patch is missing from the development source")
    executable = shutil.which("patch")
    if executable is None:
        raise RuntimeError("the 'patch' utility is required to build the player release")

    for patch_file in patch_files:
        forward_check = run_patch(executable, patch_file, stage_root, reverse=False, dry_run=True)
        if forward_check.returncode == 0:
            applied = run_patch(executable, patch_file, stage_root, reverse=False, dry_run=False)
            if applied.returncode != 0:
                raise RuntimeError(
                    f"player release patch {patch_file.name} passed dry-run but failed to apply:\n"
                    + applied.stdout.strip()
                )
            continue

        # A future source version may permanently adopt a cleanup that used to be
        # release-only. If the complete patch cleanly applies in reverse, the stage
        # already contains that cleanup and no mutation is needed.
        reverse_check = run_patch(executable, patch_file, stage_root, reverse=True, dry_run=True)
        if reverse_check.returncode == 0:
            continue

        raise RuntimeError(
            f"player release patch {patch_file.name} no longer matches the source. "
            "Update or retire this cleanup rule before publishing the new version.\n"
            + forward_check.stdout.strip()
        )

    for backup in stage_root.rglob("*.orig"):
        backup.unlink()


def build(source: Path, output: Path) -> tuple[int, int]:
    if source.name != ROOT_NAME:
        raise RuntimeError(f"source directory must be named {ROOT_NAME!r}")

    missing = sorted(path for path in REQUIRED_RUNTIME_FILES if not (source / path).is_file())
    if missing:
        raise RuntimeError("missing runtime files: " + ", ".join(missing))

    with tempfile.TemporaryDirectory(prefix="mcm-player-") as temporary:
        stage_root = Path(temporary)
        write_stage(source, stage_root)
        apply_release_patches(source, stage_root)
        target = stage_root / ROOT_NAME
        files = sorted(path for path in target.rglob("*") if path.is_file())

        output.parent.mkdir(parents=True, exist_ok=True)
        if output.exists():
            output.unlink()

        total_bytes = 0
        with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
            for path in files:
                relative = path.relative_to(target).as_posix()
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
    return len(files), total_bytes


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", nargs="?", type=Path, default=Path(ROOT_NAME))
    parser.add_argument("output", nargs="?", type=Path, default=Path("Metamorph-Creative-Menu.zip"))
    args = parser.parse_args()
    count, total_bytes = build(args.source.resolve(), args.output.resolve())
    print(f"PLAYER_BUILD=PASS files={count} source_bytes={total_bytes} archive={args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
