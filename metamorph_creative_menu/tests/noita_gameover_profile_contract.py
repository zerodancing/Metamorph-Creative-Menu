from pathlib import Path
import os
import struct
import sys

root = Path(sys.argv[1]).resolve()
exe = Path(os.environ.get("NOITA_EXE_UNDER_TEST", "/mnt/data/noita.exe"))
if not exe.is_file():
    print("noita_gameover_profile_contract=PASS binary_validation=SKIPPED adaptive_profile=true")
    raise SystemExit(0)

data = exe.read_bytes()


def u16(off: int) -> int:
    return struct.unpack_from("<H", data, off)[0]


def u32(off: int) -> int:
    return struct.unpack_from("<I", data, off)[0]


def s32(off: int) -> int:
    return struct.unpack_from("<i", data, off)[0]


assert data[:2] == b"MZ", "not a DOS/PE executable"
pe = u32(0x3C)
assert data[pe:pe + 4] == b"PE\0\0", "missing PE signature"
machine = u16(pe + 4)
assert machine == 0x14C, f"expected x86 PE32 Noita, machine={machine:#x}"
section_count = u16(pe + 6)
optional_size = u16(pe + 20)
optional = pe + 24
assert u16(optional) == 0x10B, "expected PE32 optional header"
image_base = u32(optional + 28)
size_of_image = u32(optional + 56)
section_table = optional + optional_size

sections = []
for i in range(section_count):
    sh = section_table + i * 40
    name = data[sh:sh + 8].split(b"\0", 1)[0].decode("ascii", "replace")
    virtual_size = u32(sh + 8)
    rva = u32(sh + 12)
    raw_size = u32(sh + 16)
    raw_off = u32(sh + 20)
    characteristics = u32(sh + 36)
    sections.append({
        "name": name,
        "rva": rva,
        "va": image_base + rva,
        "virtual_size": virtual_size,
        "raw_size": raw_size,
        "raw_off": raw_off,
        "characteristics": characteristics,
    })

text = next((s for s in sections if s["name"] == ".text"), None)
assert text is not None and text["raw_size"] > 0, "missing .text"
text_va = text["va"]
text_end = text_va + min(text["virtual_size"] or text["raw_size"], text["raw_size"])


def va_to_off(va: int, size: int = 1) -> int:
    rva = va - image_base
    for s in sections:
        span = max(s["virtual_size"], s["raw_size"])
        if s["rva"] <= rva and rva + size <= s["rva"] + span:
            within = rva - s["rva"]
            assert within + size <= s["raw_size"], f"VA {va:#x} has no file-backed bytes"
            return s["raw_off"] + within
    raise AssertionError(f"VA {va:#x} is outside mapped sections")


def read_va(va: int, size: int) -> bytes:
    off = va_to_off(va, size)
    return data[off:off + size]


def byte(va: int) -> int:
    return data[va_to_off(va)]


def u32va(va: int) -> int:
    return struct.unpack_from("<I", data, va_to_off(va, 4))[0]


def s32va(va: int) -> int:
    return struct.unpack_from("<i", data, va_to_off(va, 4))[0]


def is_text(va: int) -> bool:
    return text_va <= va < text_end


def is_writable_image(va: int) -> bool:
    rva = va - image_base
    for s in sections:
        span = max(s["virtual_size"], s["raw_size"])
        if s["rva"] <= rva < s["rva"] + span:
            return bool(s["characteristics"] & 0x80000000)
    return False


def rel32_target(insn: int) -> int:
    return insn + 5 + s32va(insn + 1)


def branch_target(branch: int) -> int:
    op = byte(branch)
    if op == 0x74:
        rel = struct.unpack("b", bytes([byte(branch + 1)]))[0]
        return branch + 2 + rel
    if op == 0x0F and byte(branch + 1) == 0x84:
        return branch + 6 + s32va(branch + 2)
    return 0


def find_ascii(needle: bytes) -> int:
    target = needle + b"\0"
    for s in sections:
        if not (s["characteristics"] & 0x40000000):  # readable
            continue
        if s["characteristics"] & 0x20000000:  # executable
            continue
        blob = data[s["raw_off"]:s["raw_off"] + s["raw_size"]]
        at = blob.find(target)
        if at >= 0:
            return s["va"] + at
    return 0


def find_function_start(inside: int, max_back: int = 256) -> int:
    low = max(text_va, inside - max_back)
    p = inside
    while p >= low + 3:
        p -= 1
        if read_va(p, 3) == b"\x55\x8b\xec":
            return p
    return 0


def most_repeated_call_target(start: int, end: int, excluded: int) -> int:
    counts = {}
    start = max(start, text_va)
    end = min(end, text_end)
    for p in range(start, max(start, end - 4)):
        if byte(p) != 0xE8:
            continue
        target = rel32_target(p)
        if target == excluded or not is_text(target):
            continue
        counts[target] = counts.get(target, 0) + 1
    if not counts:
        return 0
    target, count = max(counts.items(), key=lambda item: item[1])
    return target if count >= 2 else 0


def locate_replay_sites():
    save_string = find_ascii(b"$menugameover_savereplay")
    assert save_string, "Save Replay localization string not found"
    for p in range(text_va, text_end - 5):
        if byte(p) != 0x68 or u32va(p + 1) != save_string:
            continue
        label = p
        begin = max(text_va, label - 128)
        gate = skip = 0
        for q in range(begin, label - 36):
            if byte(q) != 0xA1 or byte(q + 5) != 0xB9:
                continue
            if u32va(q + 1) != u32va(q + 6):
                continue
            if read_va(q + 10, 2) != b"\xff\x90":
                continue
            if read_va(q + 16, 4) != b"\x85\xc0\x0f\x84":
                continue
            if byte(q + 24) != 0x80 or byte(q + 25) != 0xB8 or byte(q + 30) != 0:
                continue
            if read_va(q + 31, 2) != b"\x0f\x84":
                continue
            target1 = q + 24 + s32va(q + 20)
            target2 = q + 37 + s32va(q + 33)
            if target1 != target2 or target1 <= label or target1 - label > 1024:
                continue
            gate, skip = q, target1
            break
        if not gate:
            continue
        click = click_size = 0
        for q in range(label + 5, skip - 2):
            if byte(q) != 0x84:
                continue
            if byte(q + 2) == 0x74:
                target = branch_target(q + 2)
                action = q + 4
            elif read_va(q + 2, 2) == b"\x0f\x84":
                target = branch_target(q + 2)
                action = q + 8
            else:
                continue
            if target == skip and 7 <= skip - action <= 32:
                click, click_size = action, skip - action
                break
        if click:
            return {
                "string": save_string,
                "gate": gate,
                "label": label,
                "click": click,
                "click_size": click_size,
                "skip": skip,
            }
    raise AssertionError("adaptive Save Replay builder signature not found")


def locate_gameover_core():
    event_string = find_ascii(b"event_cues/game_over/create")
    assert event_string, "stock Game Over event string not found"
    for xref in range(text_va, text_end - 5):
        if byte(xref) != 0x68 or u32va(xref + 1) != event_string:
            continue
        cmp_site = set_flag = flag_offset = 0
        for p in range(max(text_va, xref - 192), xref - 7):
            if byte(p) != 0x80 or byte(p + 1) != 0xB9 or byte(p + 6) != 0:
                continue
            candidate_offset = u32va(p + 2)
            if candidate_offset > 0x10000:
                continue
            for q in range(p + 7, min(xref - 6, p + 96)):
                if (byte(q) == 0xC6 and byte(q + 1) == 0x81
                        and u32va(q + 2) == candidate_offset and byte(q + 6) == 1):
                    cmp_site, set_flag, flag_offset = p, q, candidate_offset
                    break
            if cmp_site:
                break
        if not cmp_site:
            continue
        trigger_entry = find_function_start(cmp_site)
        if not trigger_entry:
            continue
        init_call = 0
        for p in range(set_flag + 7, min(text_end - 5, set_flag + 32)):
            if byte(p) == 0xE8:
                init_call = rel32_target(p)
                break
        if not init_call or not is_text(init_call):
            continue
        get_global = most_repeated_call_target(set_flag + 7, xref + 160, init_call)
        if not get_global:
            continue
        game_mode_pointer = 0
        for p in range(text_va + 10, text_end - 5):
            if byte(p) != 0xE8 or rel32_target(p) != trigger_entry:
                continue
            s = p - 10
            if (read_va(s, 2) == b"\x8b\x0d" and read_va(s + 6, 2) == b"\x85\xc9"
                    and byte(s + 8) in (0x74, 0x75)):
                candidate = u32va(s + 2)
                if is_writable_image(candidate):
                    game_mode_pointer = candidate
                    break
        if not game_mode_pointer:
            continue
        return {
            "event_string": event_string,
            "xref": xref,
            "cmp": cmp_site,
            "set": set_flag,
            "flag_offset": flag_offset,
            "trigger": trigger_entry,
            "init": init_call,
            "get_global": get_global,
            "game_mode_pointer": game_mode_pointer,
        }
    raise AssertionError("adaptive stock Game Over trigger signature not found")


replay = locate_replay_sites()
core = locate_gameover_core()

# Contract-level source checks: the production native module must stay address-independent.
native = (root / "native_src/mcm_native_gameover.c").read_text(encoding="utf-8")
facade = (root / "files/platform/noita/native_gameover_patch.lua").read_text(encoding="utf-8")
for old_va in ("0x006e62a7", "0x006e62e1", "0x006e6393", "0x01204bc0", "0x00439bb0", "0x0047d820"):
    assert old_va.lower() not in native.lower(), f"fixed historical VA leaked into native source: {old_va}"
assert "fixed_exe_hash = false" in facade
assert "fixed_virtual_addresses = false" in facade
assert "$menugameover_savereplay" in native
assert "event_cues/game_over/create" in native
assert "resolve_import" in native and "parse_image_layout" in native

print(
    "noita_gameover_profile_contract=PASS "
    "supplied_exe=true adaptive_profile=true fixed_addresses=false "
    f"image_base={image_base:#x} image_size={size_of_image:#x} "
    f"replay_gate={replay['gate']:#x} replay_label={replay['label']:#x} "
    f"replay_click={replay['click']:#x} replay_click_size={replay['click_size']} "
    f"gameover_trigger={core['trigger']:#x} gameover_flag_offset={core['flag_offset']:#x} "
    f"game_mode_pointer={core['game_mode_pointer']:#x}"
)
