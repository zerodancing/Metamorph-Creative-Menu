/*
 * Metamorph Creative Menu - adaptive native Game Over button bridge.
 * Target: 32-bit Noita PE builds whose stock Game Over / Save Replay code still
 * exposes the same semantic structures. No absolute noita.exe VAs are stored.
 *
 * The module has no CRT dependency and no fixed Lua/Win32 IAT addresses. It:
 *   - parses the running PE32 image from the PEB;
 *   - resolves Lua and Win32 imports by name from noita.exe's import table;
 *   - locates the Save Replay builder and Game Over state through strings and
 *     bounded machine-code signatures;
 *   - derives mutable globals/structure offsets from the matched stock code;
 *   - fails closed if a future build no longer matches those semantics.
 *
 * This is deliberately a compatibility scanner, not a promise that arbitrary
 * future rewrites of Noita's Game Over implementation can be patched safely.
 */

typedef unsigned char u8;
typedef unsigned short u16;
typedef unsigned int u32;
typedef int BOOL;
typedef unsigned long DWORD;
typedef void* HANDLE;
typedef void* LPVOID;
typedef const void* LPCVOID;

typedef struct lua_State lua_State;
typedef int (__cdecl *lua_CFunction)(lua_State* L);
typedef void (__cdecl *lua_createtable_t)(lua_State*, int, int);
typedef void (__cdecl *lua_pushcclosure_t)(lua_State*, lua_CFunction, int);
typedef void (__cdecl *lua_setfield_t)(lua_State*, int, const char*);
typedef void (__cdecl *lua_pushboolean_t)(lua_State*, int);
typedef void (__cdecl *lua_pushstring_t)(lua_State*, const char*);

typedef BOOL (__stdcall *VirtualProtect_t)(LPVOID, u32, DWORD, DWORD*);
typedef BOOL (__stdcall *FlushInstructionCache_t)(HANDLE, LPCVOID, u32);
typedef HANDLE (__stdcall *GetCurrentProcess_t)(void);

typedef void* (__cdecl *get_game_global_object_t)(void);
typedef void* (__thiscall *audio_handle_lookup_t)(void* audio_manager, int handle);

#define PAGE_EXECUTE_READWRITE 0x40u
#define IMAGE_SCN_MEM_EXECUTE   0x20000000u
#define IMAGE_SCN_MEM_READ      0x40000000u
#define IMAGE_SCN_MEM_WRITE     0x80000000u
#define MAX_SECTIONS            16u
#define MAX_CLICK_PATCH         64u
#define MAX_CALL_TARGETS        32u
#define MAX_SSE_CANDIDATES      16u

static volatile u8 g_revive_request = 0;
static volatile u8 g_installed = 0;
static volatile u8 g_profile_ready = 0;
static const char g_label[] = "$mcm_death_not_dead";
static const char* g_last_reason = "not_installed";

/* clang may lower small fixed-size array initialization to memset even with /Zl.
 * Keep the module CRT-free by providing the tiny intrinsic-compatible implementation. */
void* __cdecl memset(void* destination, int value, u32 size)
{
    volatile u8* p = (volatile u8*)destination;
    u32 i;
    for (i = 0; i < size; ++i) p[i] = (u8)value;
    return destination;
}

static lua_createtable_t g_lua_createtable = 0;
static lua_setfield_t g_lua_setfield = 0;
static lua_pushcclosure_t g_lua_pushcclosure = 0;
static lua_pushstring_t g_lua_pushstring = 0;
static lua_pushboolean_t g_lua_pushboolean = 0;
static VirtualProtect_t g_virtual_protect = 0;
static FlushInstructionCache_t g_flush_icache = 0;
static GetCurrentProcess_t g_current_process = 0;

#if defined(_MSC_VER)
unsigned long __readfsdword(unsigned long offset);
#pragma intrinsic(__readfsdword)
#endif

typedef struct image_section {
    u32 start;
    u32 size;
    u32 characteristics;
} image_section;

typedef struct image_layout {
    u32 base;
    u32 size;
    u32 text_start;
    u32 text_size;
    u32 optional_header;
    image_section sections[MAX_SECTIONS];
    u32 section_count;
} image_layout;

typedef struct adaptive_profile {
    u32 replay_gate;
    u32 replay_label;
    u32 replay_click;
    u32 replay_click_size;
    u32 replay_skip_target;
    u8 original_gate[5];
    u8 original_label[5];
    u8 original_click[MAX_CLICK_PATCH];

    u32 game_mode_pointer;
    u32 gameover_flag_offset;
    u32 gameover_trigger_entry;
    u32 gameover_init;
    u32 get_game_global_object;

    u32 audio_handle_lookup;
    u32 audio_manager_offset;
    u32 audio_record_active_offset;
    u32 music_root_offset;
    u32 music_manager_offset;
    u32 music_death_latch_offset;

    u32 ui_menu_music_handle;
    u32 ui_gameover_stats_handle;
    u32 ui_gameover_frame_counter;
    u32 ui_gameover_state;
    u32 ui_gameover_fade;

    u8 cleanup_ready;
} adaptive_profile;

static image_layout g_image;
static adaptive_profile g_profile;

static u32 process_image_base(void)
{
    u32 peb = (u32)__readfsdword(0x30u);
    if (!peb) return 0;
    return *(volatile const u32*)(peb + 0x08u);
}

static u16 read_u16(u32 address)
{
    volatile const u8* p = (volatile const u8*)address;
    return (u16)((u16)p[0] | ((u16)p[1] << 8));
}

static u32 read_u32(u32 address)
{
    volatile const u8* p = (volatile const u8*)address;
    return (u32)p[0] | ((u32)p[1] << 8) | ((u32)p[2] << 16) | ((u32)p[3] << 24);
}

static int read_s32(u32 address)
{
    return (int)read_u32(address);
}

static void encode_u32(u8* out, u32 value)
{
    out[0] = (u8)(value & 0xffu);
    out[1] = (u8)((value >> 8) & 0xffu);
    out[2] = (u8)((value >> 16) & 0xffu);
    out[3] = (u8)((value >> 24) & 0xffu);
}

static u32 string_length(const char* s)
{
    u32 n = 0;
    while (s && s[n]) ++n;
    return n;
}

static int string_equal(const char* a, const char* b)
{
    u32 i = 0;
    if (!a || !b) return 0;
    while (a[i] && b[i]) {
        if (a[i] != b[i]) return 0;
        ++i;
    }
    return a[i] == b[i];
}

static void copy_bytes(u8* dst, u32 src, u32 size)
{
    u32 i;
    volatile const u8* p = (volatile const u8*)src;
    for (i = 0; i < size; ++i) dst[i] = p[i];
}

static int bytes_equal(u32 address, const u8* expected, u32 size)
{
    u32 i;
    volatile const u8* p = (volatile const u8*)address;
    for (i = 0; i < size; ++i) {
        if (p[i] != expected[i]) return 0;
    }
    return 1;
}

static int parse_image_layout(void)
{
    u32 base = process_image_base();
    u32 pe_offset, pe, optional, size_of_image, section_table;
    u16 sections, optional_size;
    u32 i, kept = 0;

    if (!base) { g_last_reason = "process_image_base_unavailable"; return 0; }
    if (read_u16(base) != 0x5a4du) { g_last_reason = "noita_image_missing_mz"; return 0; }
    pe_offset = read_u32(base + 0x3cu);
    if (pe_offset < 0x40u || pe_offset > 0x2000u) { g_last_reason = "noita_pe_offset_invalid"; return 0; }
    pe = base + pe_offset;
    if (read_u32(pe) != 0x00004550u) { g_last_reason = "noita_image_missing_pe"; return 0; }
    if (read_u16(pe + 4u) != 0x014cu) { g_last_reason = "noita_not_x86"; return 0; }
    sections = read_u16(pe + 6u);
    optional_size = read_u16(pe + 20u);
    optional = pe + 24u;
    if (read_u16(optional) != 0x010bu) { g_last_reason = "noita_not_pe32"; return 0; }
    size_of_image = read_u32(optional + 56u);
    if (size_of_image < 0x10000u || size_of_image > 0x10000000u) {
        g_last_reason = "noita_image_size_invalid";
        return 0;
    }
    if (!sections || sections > 96u || optional_size < 96u) {
        g_last_reason = "noita_section_table_invalid";
        return 0;
    }

    g_image.base = base;
    g_image.size = size_of_image;
    g_image.optional_header = optional;
    g_image.text_start = 0;
    g_image.text_size = 0;
    g_image.section_count = 0;
    section_table = optional + (u32)optional_size;

    for (i = 0; i < (u32)sections; ++i) {
        u32 sh = section_table + i * 40u;
        u32 virtual_size = read_u32(sh + 8u);
        u32 virtual_address = read_u32(sh + 12u);
        u32 raw_size = read_u32(sh + 16u);
        u32 characteristics = read_u32(sh + 36u);
        u32 size = virtual_size > raw_size ? virtual_size : raw_size;
        u32 start;
        if (!size || virtual_address >= size_of_image || size > size_of_image - virtual_address) continue;
        start = base + virtual_address;
        if ((characteristics & IMAGE_SCN_MEM_EXECUTE) && !g_image.text_start) {
            g_image.text_start = start;
            g_image.text_size = size;
        }
        if (kept < MAX_SECTIONS) {
            g_image.sections[kept].start = start;
            g_image.sections[kept].size = size;
            g_image.sections[kept].characteristics = characteristics;
            ++kept;
        }
    }
    g_image.section_count = kept;
    if (!g_image.text_start || !g_image.text_size) {
        g_last_reason = "noita_text_section_missing";
        return 0;
    }
    return 1;
}

static int address_in_image(u32 address, u32 size)
{
    if (!g_image.base || !g_image.size) return 0;
    if (address < g_image.base || size > g_image.size) return 0;
    return address - g_image.base <= g_image.size - size;
}

static int address_has_characteristic(u32 address, u32 characteristic)
{
    u32 i;
    for (i = 0; i < g_image.section_count; ++i) {
        image_section* s = &g_image.sections[i];
        if (address >= s->start && address - s->start < s->size) {
            return (s->characteristics & characteristic) != 0;
        }
    }
    return 0;
}

static int address_is_writable_image(u32 address)
{
    return address_in_image(address, 1u) && address_has_characteristic(address, IMAGE_SCN_MEM_WRITE);
}

static int address_is_text(u32 address)
{
    return address >= g_image.text_start && address - g_image.text_start < g_image.text_size;
}

static u32 find_ascii_in_image(const char* needle)
{
    u32 length = string_length(needle);
    u32 s, i, j;
    if (!length) return 0;
    for (s = 0; s < g_image.section_count; ++s) {
        image_section* sec = &g_image.sections[s];
        volatile const u8* p;
        if (!(sec->characteristics & IMAGE_SCN_MEM_READ)) continue;
        if (sec->characteristics & IMAGE_SCN_MEM_EXECUTE) continue;
        if (sec->size <= length) continue;
        p = (volatile const u8*)sec->start;
        for (i = 0; i + length < sec->size; ++i) {
            if (p[i] != (u8)needle[0]) continue;
            for (j = 1; j < length; ++j) if (p[i + j] != (u8)needle[j]) break;
            if (j == length && p[i + length] == 0) return sec->start + i;
        }
    }
    return 0;
}

static u32 rel32_target(u32 instruction)
{
    return instruction + 5u + (u32)read_s32(instruction + 1u);
}

static u32 branch_target(u32 branch)
{
    volatile const u8* p = (volatile const u8*)branch;
    if (p[0] == 0x74u) {
        int rel = (int)(signed char)p[1];
        return branch + 2u + (u32)rel;
    }
    if (p[0] == 0x0fu && p[1] == 0x84u) {
        return branch + 6u + (u32)read_s32(branch + 2u);
    }
    return 0;
}

static u32 find_function_start(u32 inside, u32 max_back)
{
    u32 min = inside > max_back ? inside - max_back : g_image.text_start;
    u32 p = inside;
    if (min < g_image.text_start) min = g_image.text_start;
    while (p >= min + 3u) {
        --p;
        if (*(volatile u8*)p == 0x55u && *(volatile u8*)(p + 1u) == 0x8bu && *(volatile u8*)(p + 2u) == 0xecu) {
            return p;
        }
    }
    return 0;
}

static u32 resolve_import(const char* function_name)
{
    u32 optional = g_image.optional_header;
    u32 import_rva, import_size, descriptor;
    if (!optional) return 0;
    import_rva = read_u32(optional + 104u);
    import_size = read_u32(optional + 108u);
    if (!import_rva || import_rva >= g_image.size || import_size < 20u) return 0;
    descriptor = g_image.base + import_rva;
    while (address_in_image(descriptor, 20u)) {
        u32 original = read_u32(descriptor + 0u);
        u32 name_rva = read_u32(descriptor + 12u);
        u32 first = read_u32(descriptor + 16u);
        u32 index = 0;
        if (!original && !name_rva && !first) break;
        if (!first) { descriptor += 20u; continue; }
        if (!original) original = first;
        while (address_in_image(g_image.base + original + index * 4u, 4u)
            && address_in_image(g_image.base + first + index * 4u, 4u))
        {
            u32 thunk = read_u32(g_image.base + original + index * 4u);
            if (!thunk) break;
            if (!(thunk & 0x80000000u)) {
                u32 ibn = g_image.base + thunk;
                if (address_in_image(ibn, 3u)) {
                    const char* imported_name = (const char*)(ibn + 2u);
                    if (string_equal(imported_name, function_name)) {
                        return read_u32(g_image.base + first + index * 4u);
                    }
                }
            }
            ++index;
        }
        descriptor += 20u;
    }
    return 0;
}

static int resolve_runtime_imports(void)
{
    if (!parse_image_layout()) return 0;
    g_lua_createtable = (lua_createtable_t)resolve_import("lua_createtable");
    g_lua_setfield = (lua_setfield_t)resolve_import("lua_setfield");
    g_lua_pushcclosure = (lua_pushcclosure_t)resolve_import("lua_pushcclosure");
    g_lua_pushstring = (lua_pushstring_t)resolve_import("lua_pushstring");
    g_lua_pushboolean = (lua_pushboolean_t)resolve_import("lua_pushboolean");
    g_virtual_protect = (VirtualProtect_t)resolve_import("VirtualProtect");
    g_flush_icache = (FlushInstructionCache_t)resolve_import("FlushInstructionCache");
    g_current_process = (GetCurrentProcess_t)resolve_import("GetCurrentProcess");
    if (!g_lua_createtable || !g_lua_setfield || !g_lua_pushcclosure || !g_lua_pushstring || !g_lua_pushboolean) {
        g_last_reason = "lua_import_resolution_failed";
        return 0;
    }
    if (!g_virtual_protect || !g_flush_icache || !g_current_process) {
        g_last_reason = "win32_import_resolution_failed";
        return 0;
    }
    return 1;
}

static int write_bytes(u32 address, const u8* bytes, u32 size)
{
    volatile u8* dst = (volatile u8*)address;
    DWORD old_protect = 0, ignored = 0;
    u32 i;
    if (!g_virtual_protect || !g_flush_icache || !g_current_process) return 0;
    if (!address_is_text(address) || !address_is_text(address + size - 1u)) return 0;
    if (!g_virtual_protect((LPVOID)address, size, PAGE_EXECUTE_READWRITE, &old_protect)) return 0;
    for (i = 0; i < size; ++i) dst[i] = bytes[i];
    g_flush_icache(g_current_process(), (LPCVOID)address, size);
    g_virtual_protect((LPVOID)address, size, old_protect, &ignored);
    return bytes_equal(address, bytes, size);
}

static int locate_replay_sites(void)
{
    u32 save_string = find_ascii_in_image("$menugameover_savereplay");
    u32 p;
    if (!save_string) { g_last_reason = "save_replay_string_not_found"; return 0; }

    for (p = g_image.text_start; p + 5u < g_image.text_start + g_image.text_size; ++p) {
        u32 label, gate = 0, skip = 0, click = 0, click_size = 0;
        u32 q, begin;
        if (*(volatile u8*)p != 0x68u || read_u32(p + 1u) != save_string) continue;
        label = p;
        begin = label > 128u ? label - 128u : g_image.text_start;
        if (begin < g_image.text_start) begin = g_image.text_start;

        for (q = begin; q + 37u <= label; ++q) {
            u32 target1, target2;
            if (*(volatile u8*)q != 0xa1u || *(volatile u8*)(q + 5u) != 0xb9u) continue;
            if (read_u32(q + 1u) != read_u32(q + 6u)) continue;
            if (*(volatile u8*)(q + 10u) != 0xffu || *(volatile u8*)(q + 11u) != 0x90u) continue;
            if (*(volatile u8*)(q + 16u) != 0x85u || *(volatile u8*)(q + 17u) != 0xc0u) continue;
            if (*(volatile u8*)(q + 18u) != 0x0fu || *(volatile u8*)(q + 19u) != 0x84u) continue;
            if (*(volatile u8*)(q + 24u) != 0x80u || *(volatile u8*)(q + 25u) != 0xb8u || *(volatile u8*)(q + 30u) != 0x00u) continue;
            if (*(volatile u8*)(q + 31u) != 0x0fu || *(volatile u8*)(q + 32u) != 0x84u) continue;
            target1 = q + 24u + (u32)read_s32(q + 20u);
            target2 = q + 37u + (u32)read_s32(q + 33u);
            if (target1 != target2 || target1 <= label || target1 - label > 1024u) continue;
            gate = q;
            skip = target1;
            break;
        }
        if (!gate || !skip) continue;

        for (q = label + 5u; q + 2u < skip; ++q) {
            u32 target = 0, action_start = 0;
            if (*(volatile u8*)q != 0x84u) continue;
            if (*(volatile u8*)(q + 2u) == 0x74u) {
                target = branch_target(q + 2u);
                action_start = q + 4u;
            } else if (*(volatile u8*)(q + 2u) == 0x0fu && *(volatile u8*)(q + 3u) == 0x84u) {
                target = branch_target(q + 2u);
                action_start = q + 8u;
            }
            if (target != skip || action_start >= skip) continue;
            if (skip - action_start < 7u || skip - action_start > MAX_CLICK_PATCH) continue;
            click = action_start;
            click_size = skip - action_start;
            break;
        }
        if (!click) continue;

        g_profile.replay_gate = gate;
        g_profile.replay_label = label;
        g_profile.replay_click = click;
        g_profile.replay_click_size = click_size;
        g_profile.replay_skip_target = skip;
        copy_bytes(g_profile.original_gate, gate, 5u);
        copy_bytes(g_profile.original_label, label, 5u);
        copy_bytes(g_profile.original_click, click, click_size);
        return 1;
    }
    g_last_reason = "save_replay_builder_signature_not_found";
    return 0;
}

static u32 most_repeated_call_target(u32 start, u32 end, u32 excluded)
{
    u32 targets[MAX_CALL_TARGETS];
    u8 counts[MAX_CALL_TARGETS];
    u32 used = 0, p, i, best = 0;
    u8 best_count = 0;
    if (start < g_image.text_start) start = g_image.text_start;
    if (end > g_image.text_start + g_image.text_size) end = g_image.text_start + g_image.text_size;
    for (p = start; p + 5u <= end; ++p) {
        u32 target;
        if (*(volatile u8*)p != 0xe8u) continue;
        target = rel32_target(p);
        if (target == excluded || !address_is_text(target)) continue;
        for (i = 0; i < used; ++i) if (targets[i] == target) break;
        if (i == used) {
            if (used >= MAX_CALL_TARGETS) continue;
            targets[used] = target;
            counts[used] = 1u;
            ++used;
        } else if (counts[i] < 255u) {
            ++counts[i];
        }
    }
    for (i = 0; i < used; ++i) {
        if (counts[i] > best_count) { best_count = counts[i]; best = targets[i]; }
    }
    return best_count >= 2u ? best : 0;
}

static int decode_mov_from_eax_or_esi(u32 p, u8 base_reg, u32* offset_out)
{
    volatile const u8* b = (volatile const u8*)p;
    /* mov r32,[eax+imm8] / mov r32,[esi+imm8] common encodings used by Noita. */
    if (b[0] == 0x8bu) {
        u8 modrm = b[1];
        u8 rm = (u8)(modrm & 7u);
        u8 mod = (u8)((modrm >> 6) & 3u);
        if (rm == base_reg && mod == 1u) {
            *offset_out = (u32)(u8)b[2];
            return 3;
        }
        if (rm == base_reg && mod == 2u) {
            *offset_out = read_u32(p + 2u);
            return 6;
        }
    }
    return 0;
}

static int locate_gameover_core(void)
{
    u32 event_string = find_ascii_in_image("event_cues/game_over/create");
    u32 xref;
    if (!event_string) { g_last_reason = "gameover_event_string_not_found"; return 0; }

    for (xref = g_image.text_start; xref + 5u < g_image.text_start + g_image.text_size; ++xref) {
        u32 cmp, cmp_start, set_flag = 0, flag_offset = 0, trigger_entry, init_call = 0, get_global;
        u32 p;
        if (*(volatile u8*)xref != 0x68u || read_u32(xref + 1u) != event_string) continue;
        cmp_start = xref > 192u ? xref - 192u : g_image.text_start;
        if (cmp_start < g_image.text_start) cmp_start = g_image.text_start;
        cmp = 0;
        for (p = cmp_start; p + 7u < xref; ++p) {
            u32 q;
            if (*(volatile u8*)p != 0x80u || *(volatile u8*)(p + 1u) != 0xb9u || *(volatile u8*)(p + 6u) != 0x00u) continue;
            flag_offset = read_u32(p + 2u);
            if (flag_offset > 0x10000u) continue;
            for (q = p + 7u; q + 7u <= xref && q < p + 96u; ++q) {
                if (*(volatile u8*)q == 0xc6u && *(volatile u8*)(q + 1u) == 0x81u
                    && read_u32(q + 2u) == flag_offset && *(volatile u8*)(q + 6u) == 0x01u)
                {
                    cmp = p;
                    set_flag = q;
                    break;
                }
            }
            if (cmp) break;
        }
        if (!cmp || !set_flag) continue;
        trigger_entry = find_function_start(cmp, 256u);
        if (!trigger_entry) continue;

        for (p = set_flag + 7u; p < set_flag + 32u; ++p) {
            if (*(volatile u8*)p == 0xe8u) { init_call = rel32_target(p); break; }
        }
        if (!init_call || !address_is_text(init_call)) continue;
        get_global = most_repeated_call_target(set_flag + 7u, xref + 160u, init_call);
        if (!get_global) continue;

        g_profile.gameover_flag_offset = flag_offset;
        g_profile.gameover_trigger_entry = trigger_entry;
        g_profile.gameover_init = init_call;
        g_profile.get_game_global_object = get_global;

        /* Derive GameMode** from the stock call site that passes the global object in ECX. */
        for (p = g_image.text_start; p + 5u < g_image.text_start + g_image.text_size; ++p) {
            if (*(volatile u8*)p == 0xe8u && rel32_target(p) == trigger_entry && p >= g_image.text_start + 10u) {
                u32 s = p - 10u;
                if (*(volatile u8*)s == 0x8bu && *(volatile u8*)(s + 1u) == 0x0du
                    && *(volatile u8*)(s + 6u) == 0x85u && *(volatile u8*)(s + 7u) == 0xc9u
                    && (*(volatile u8*)(s + 8u) == 0x74u || *(volatile u8*)(s + 8u) == 0x75u))
                {
                    u32 global = read_u32(s + 2u);
                    if (address_is_writable_image(global)) { g_profile.game_mode_pointer = global; break; }
                }
            }
        }
        if (!g_profile.game_mode_pointer) continue;

        /* Music manager chain and death latch are read from the stock trigger path. */
        for (p = cmp; p + 5u < xref; ++p) {
            if (*(volatile u8*)p == 0xe8u && rel32_target(p) == get_global) {
                u32 a, root_off = 0, manager_off = 0;
                int root_len = 0, manager_len = 0;
                for (a = p + 5u; a < p + 28u; ++a) {
                    root_len = decode_mov_from_eax_or_esi(a, 0u, &root_off); /* EAX base */
                    if (root_len) break;
                }
                if (!root_len) continue;
                for (a = a + (u32)root_len; a < p + 40u; ++a) {
                    manager_len = decode_mov_from_eax_or_esi(a, 6u, &manager_off); /* ESI base */
                    if (manager_len) break;
                }
                if (!manager_len) continue;
                for (; a + 7u < p + 64u; ++a) {
                    if (*(volatile u8*)a == 0xc6u && *(volatile u8*)(a + 1u) == 0x80u && *(volatile u8*)(a + 6u) == 0x01u) {
                        u32 latch = read_u32(a + 2u);
                        if (latch <= 0x10000u) {
                            g_profile.music_root_offset = root_off;
                            g_profile.music_manager_offset = manager_off;
                            g_profile.music_death_latch_offset = latch;
                            break;
                        }
                    }
                }
                if (g_profile.music_death_latch_offset) break;
            }
        }

        /* Audio manager offset: the event builder fetches game->audio after the same string. */
        for (p = xref; p < xref + 96u; ++p) {
            if (*(volatile u8*)p == 0xe8u && rel32_target(p) == get_global) {
                u32 a, off = 0;
                int len;
                for (a = p + 5u; a < p + 28u; ++a) {
                    len = decode_mov_from_eax_or_esi(a, 0u, &off);
                    if (len && off <= 0x1000u) { g_profile.audio_manager_offset = off; break; }
                }
                if (g_profile.audio_manager_offset) break;
            }
        }
        return 1;
    }
    g_last_reason = "gameover_trigger_signature_not_found";
    return 0;
}

static int locate_gameover_init_globals(void)
{
    u32 p, end, frame = 0, state = 0, stats = 0;
    if (!g_profile.gameover_init) return 0;
    end = g_profile.gameover_init + 192u;
    if (end > g_image.text_start + g_image.text_size) end = g_image.text_start + g_image.text_size;
    for (p = g_profile.gameover_init; p + 10u <= end; ++p) {
        if (!frame && *(volatile u8*)p == 0xc7u && *(volatile u8*)(p + 1u) == 0x05u
            && read_u32(p + 6u) == 0u && address_is_writable_image(read_u32(p + 2u)))
        {
            frame = read_u32(p + 2u);
        }
        if (!state && *(volatile u8*)p == 0xc6u && *(volatile u8*)(p + 1u) == 0x05u
            && *(volatile u8*)(p + 6u) == 0x00u && address_is_writable_image(read_u32(p + 2u)))
        {
            state = read_u32(p + 2u);
        }
        if (!stats && *(volatile u8*)p == 0xc7u && *(volatile u8*)(p + 1u) == 0x05u
            && read_u32(p + 6u) == 0xffffffffu && address_is_writable_image(read_u32(p + 2u)))
        {
            stats = read_u32(p + 2u);
        }
        if (frame && state && stats) break;
    }
    if (!frame || !state || !stats) return 0;
    if ((frame > state ? frame - state : state - frame) > 0x400u) return 0;
    if ((stats > state ? stats - state : state - stats) > 0x400u) return 0;
    g_profile.ui_gameover_frame_counter = frame;
    g_profile.ui_gameover_state = state;
    g_profile.ui_gameover_stats_handle = stats;
    return 1;
}

static int match_get_global_audio_lookup_block(u32 cmp_site, u32 handle, u32* lookup_out, u32* audio_off_out)
{
    u32 p, call_global = 0, push_handle = 0, mov_audio = 0, lookup = 0, off = 0;
    for (p = cmp_site + 7u; p < cmp_site + 36u; ++p) {
        if (*(volatile u8*)p == 0xe8u && rel32_target(p) == g_profile.get_game_global_object) { call_global = p; break; }
    }
    if (!call_global) return 0;
    for (p = call_global + 5u; p < call_global + 24u; ++p) {
        if (*(volatile u8*)p == 0xffu && *(volatile u8*)(p + 1u) == 0x35u && read_u32(p + 2u) == handle) {
            push_handle = p; break;
        }
    }
    if (!push_handle) return 0;
    for (p = push_handle + 6u; p < push_handle + 18u; ++p) {
        int len = decode_mov_from_eax_or_esi(p, 0u, &off);
        if (len) { mov_audio = p; p += (u32)len; break; }
    }
    if (!mov_audio) return 0;
    for (; p < push_handle + 28u; ++p) {
        if (*(volatile u8*)p == 0xe8u) { lookup = rel32_target(p); break; }
    }
    if (!lookup || !address_is_text(lookup)) return 0;
    *lookup_out = lookup;
    *audio_off_out = off;
    return 1;
}

static int locate_audio_cleanup(void)
{
    u32 stats = g_profile.ui_gameover_stats_handle;
    u32 p;
    if (!stats || !g_profile.get_game_global_object) return 0;
    for (p = g_image.text_start; p + 7u < g_image.text_start + g_image.text_size; ++p) {
        u32 lookup = 0, audio_off = 0, menu_cmp = 0, q, menu = 0;
        if (*(volatile u8*)p != 0x83u || *(volatile u8*)(p + 1u) != 0x3du || read_u32(p + 2u) != stats || *(volatile u8*)(p + 6u) != 0xffu) continue;
        if (!match_get_global_audio_lookup_block(p, stats, &lookup, &audio_off)) continue;

        q = p;
        while (q > g_image.text_start + 7u && p - q < 96u) {
            --q;
            if (*(volatile u8*)q == 0x83u && *(volatile u8*)(q + 1u) == 0x3du && *(volatile u8*)(q + 6u) == 0xffu) {
                u32 candidate = read_u32(q + 2u), lookup2 = 0, audio2 = 0;
                if (candidate != stats && address_is_writable_image(candidate)
                    && match_get_global_audio_lookup_block(q, candidate, &lookup2, &audio2)
                    && lookup2 == lookup && audio2 == audio_off)
                {
                    menu_cmp = q;
                    menu = candidate;
                    break;
                }
            }
        }
        if (!menu_cmp) continue;

        g_profile.ui_menu_music_handle = menu;
        g_profile.audio_handle_lookup = lookup;
        g_profile.audio_manager_offset = audio_off;

        /* Derive the AudioRecord active byte from stock fade completion. */
        for (q = menu_cmp; q < p + 192u; ++q) {
            if (*(volatile u8*)q == 0xe8u && rel32_target(q) == lookup) {
                u32 r;
                for (r = q + 5u; r < q + 24u; ++r) {
                    if (*(volatile u8*)r == 0xc6u && *(volatile u8*)(r + 1u) == 0x40u && *(volatile u8*)(r + 3u) == 0x00u) {
                        g_profile.audio_record_active_offset = *(volatile u8*)(r + 2u);
                        break;
                    }
                }
                if (g_profile.audio_record_active_offset) break;
            }
        }

        /* Find the repeatedly-used writable scalar controlling this fade function. */
        {
            u32 addresses[MAX_SSE_CANDIDATES];
            u8 counts[MAX_SSE_CANDIDATES];
            u32 used = 0, r, best = 0;
            u8 best_count = 0;
            u32 scan_start = menu_cmp > 96u ? menu_cmp - 96u : g_image.text_start;
            u32 scan_end = p + 224u;
            if (scan_start < g_image.text_start) scan_start = g_image.text_start;
            if (scan_end > g_image.text_start + g_image.text_size) scan_end = g_image.text_start + g_image.text_size;
            for (r = scan_start; r + 8u <= scan_end; ++r) {
                u32 addr = 0, i;
                if (*(volatile u8*)r != 0xf3u || *(volatile u8*)(r + 1u) != 0x0fu) continue;
                if ((*(volatile u8*)(r + 2u) == 0x10u || *(volatile u8*)(r + 2u) == 0x11u
                    || *(volatile u8*)(r + 2u) == 0x58u || *(volatile u8*)(r + 2u) == 0x5cu)
                    && *(volatile u8*)(r + 3u) == 0x05u)
                {
                    addr = read_u32(r + 4u);
                }
                if (!addr || !address_is_writable_image(addr)) continue;
                for (i = 0; i < used; ++i) if (addresses[i] == addr) break;
                if (i == used) {
                    if (used >= MAX_SSE_CANDIDATES) continue;
                    addresses[used] = addr;
                    counts[used] = 1u;
                    ++used;
                } else if (counts[i] < 255u) ++counts[i];
            }
            for (r = 0; r < used; ++r) if (counts[r] > best_count) { best_count = counts[r]; best = addresses[r]; }
            if (best_count >= 2u) g_profile.ui_gameover_fade = best;
        }

        if (g_profile.audio_handle_lookup && g_profile.audio_record_active_offset
            && g_profile.music_root_offset && g_profile.music_manager_offset
            && g_profile.music_death_latch_offset && g_profile.ui_menu_music_handle
            && g_profile.ui_gameover_stats_handle && g_profile.ui_gameover_frame_counter
            && g_profile.ui_gameover_state)
        {
            g_profile.cleanup_ready = 1u;
        }
        return 1;
    }
    return 0;
}

static int resolve_adaptive_profile(void)
{
    if (g_profile_ready) return 1;
    if (!locate_replay_sites()) return 0;
    if (!locate_gameover_core()) return 0;
    locate_gameover_init_globals();
    locate_audio_cleanup();
    g_profile_ready = 1u;
    g_last_reason = g_profile.cleanup_ready ? "adaptive_profile_resolved" : "adaptive_profile_resolved_cleanup_partial";
    return 1;
}

static int install_patch(void)
{
    u8 gate_patch[5], label_patch[5], click_patch[MAX_CLICK_PATCH];
    u32 i;
    if (g_installed) { g_last_reason = "installed"; return 1; }
    if (!resolve_adaptive_profile()) return 0;

    if (!bytes_equal(g_profile.replay_gate, g_profile.original_gate, 5u)
        || !bytes_equal(g_profile.replay_label, g_profile.original_label, 5u)
        || !bytes_equal(g_profile.replay_click, g_profile.original_click, g_profile.replay_click_size))
    {
        g_last_reason = "replay_sites_changed_restart_required";
        return 0;
    }

    gate_patch[0] = 0xe9u;
    encode_u32(gate_patch + 1u, g_profile.replay_label - (g_profile.replay_gate + 5u));
    label_patch[0] = 0x68u;
    encode_u32(label_patch + 1u, (u32)g_label);
    click_patch[0] = 0xc6u;
    click_patch[1] = 0x05u;
    encode_u32(click_patch + 2u, (u32)&g_revive_request);
    click_patch[6] = 0x01u;
    for (i = 7u; i < g_profile.replay_click_size; ++i) click_patch[i] = 0x90u;

    /* Publish owned pointers/actions first; expose the formerly-hidden button last. */
    if (!write_bytes(g_profile.replay_label, label_patch, 5u)) { g_last_reason = "label_write_failed"; return 0; }
    if (!write_bytes(g_profile.replay_click, click_patch, g_profile.replay_click_size)) {
        write_bytes(g_profile.replay_label, g_profile.original_label, 5u);
        g_last_reason = "click_write_failed";
        return 0;
    }
    if (!write_bytes(g_profile.replay_gate, gate_patch, 5u)) {
        write_bytes(g_profile.replay_click, g_profile.original_click, g_profile.replay_click_size);
        write_bytes(g_profile.replay_label, g_profile.original_label, 5u);
        g_last_reason = "gate_write_failed";
        return 0;
    }
    if (!bytes_equal(g_profile.replay_gate, gate_patch, 5u)
        || !bytes_equal(g_profile.replay_label, label_patch, 5u)
        || !bytes_equal(g_profile.replay_click, click_patch, g_profile.replay_click_size))
    {
        write_bytes(g_profile.replay_gate, g_profile.original_gate, 5u);
        write_bytes(g_profile.replay_click, g_profile.original_click, g_profile.replay_click_size);
        write_bytes(g_profile.replay_label, g_profile.original_label, 5u);
        g_last_reason = "post_install_verify_failed";
        return 0;
    }

    g_revive_request = 0;
    g_installed = 1;
    g_last_reason = g_profile.cleanup_ready ? "installed_adaptive" : "installed_adaptive_cleanup_partial";
    return 1;
}

static int game_over_active(void)
{
    u32 game_mode;
    if (!g_profile_ready || !g_profile.game_mode_pointer) return 0;
    game_mode = *(volatile u32*)g_profile.game_mode_pointer;
    if (!game_mode) return 0;
    return *((volatile u8*)(game_mode + g_profile.gameover_flag_offset)) != 0;
}

static int cancel_game_over(void)
{
    u32 game_mode;
    if (!g_installed) { g_last_reason = "not_installed"; return 0; }
    if (!g_profile.game_mode_pointer) { g_last_reason = "game_mode_pointer_unresolved"; return 0; }
    game_mode = *(volatile u32*)g_profile.game_mode_pointer;
    if (!game_mode) { g_last_reason = "game_mode_unavailable"; return 0; }
    *((volatile u8*)(game_mode + g_profile.gameover_flag_offset)) = 0;
    g_last_reason = "cleared";
    return 1;
}

static void stop_tracked_gameover_audio_handle(volatile int* handle_ptr, void* audio_manager)
{
    int handle;
    void* record;
    audio_handle_lookup_t lookup;
    if (!handle_ptr) return;
    handle = *handle_ptr;
    if (handle == -1) return;
    if (audio_manager && g_profile.audio_handle_lookup) {
        lookup = (audio_handle_lookup_t)g_profile.audio_handle_lookup;
        record = lookup(audio_manager, handle);
        if (record && g_profile.audio_record_active_offset) {
            *((volatile u8*)record + g_profile.audio_record_active_offset) = 0;
        }
    }
    *handle_ptr = -1;
}

static int cleanup_post_revive_runtime(void)
{
    get_game_global_object_t get_global;
    void* game;
    void* audio_manager = 0;
    void* music_root = 0;
    void* music_manager = 0;
    int partial = 0;

    if (!g_installed) { g_last_reason = "not_installed"; return 0; }
    if (!g_profile.get_game_global_object) { g_last_reason = "game_global_unresolved"; return 0; }
    get_global = (get_game_global_object_t)g_profile.get_game_global_object;
    game = get_global();
    if (!game) { g_last_reason = "game_global_unavailable"; return 0; }

    if (g_profile.audio_manager_offset && g_profile.audio_handle_lookup
        && g_profile.ui_menu_music_handle && g_profile.ui_gameover_stats_handle)
    {
        audio_manager = *(void**)((u8*)game + g_profile.audio_manager_offset);
        stop_tracked_gameover_audio_handle((volatile int*)g_profile.ui_menu_music_handle, audio_manager);
        stop_tracked_gameover_audio_handle((volatile int*)g_profile.ui_gameover_stats_handle, audio_manager);
    } else partial = 1;

    if (g_profile.music_root_offset && g_profile.music_manager_offset && g_profile.music_death_latch_offset) {
        music_root = *(void**)((u8*)game + g_profile.music_root_offset);
        music_manager = music_root ? *(void**)((u8*)music_root + g_profile.music_manager_offset) : 0;
        if (music_manager) *((volatile u8*)music_manager + g_profile.music_death_latch_offset) = 0;
        else partial = 1;
    } else partial = 1;

    if (g_profile.ui_gameover_frame_counter) *(volatile u32*)g_profile.ui_gameover_frame_counter = 0;
    else partial = 1;
    if (g_profile.ui_gameover_state) *(volatile u8*)g_profile.ui_gameover_state = 0;
    else partial = 1;
    if (g_profile.ui_gameover_fade) *(volatile u32*)g_profile.ui_gameover_fade = 0;
    else partial = 1;

    g_last_reason = partial ? "post_revive_cleaned_partial" : "post_revive_cleaned";
    return 1;
}

static int push_bool_reason(lua_State* L, int ok, const char* reason)
{
    g_lua_pushboolean(L, ok ? 1 : 0);
    g_lua_pushstring(L, reason ? reason : "unknown");
    return 2;
}

static int __cdecl lua_install(lua_State* L)
{
    int ok = install_patch();
    return push_bool_reason(L, ok, g_last_reason);
}

static int __cdecl lua_is_installed(lua_State* L)
{
    g_lua_pushboolean(L, g_installed ? 1 : 0);
    return 1;
}

static int __cdecl lua_has_request(lua_State* L)
{
    g_lua_pushboolean(L, (g_installed && g_revive_request) ? 1 : 0);
    return 1;
}

static int __cdecl lua_clear_request(lua_State* L)
{
    g_revive_request = 0;
    g_lua_pushboolean(L, 1);
    return 1;
}

static int __cdecl lua_is_game_over_active(lua_State* L)
{
    g_lua_pushboolean(L, (g_installed && game_over_active()) ? 1 : 0);
    return 1;
}

static int __cdecl lua_cancel_game_over(lua_State* L)
{
    int ok = cancel_game_over();
    return push_bool_reason(L, ok, g_last_reason);
}

static int __cdecl lua_cleanup_post_revive(lua_State* L)
{
    int ok = cleanup_post_revive_runtime();
    return push_bool_reason(L, ok, g_last_reason);
}

static int __cdecl lua_reason(lua_State* L)
{
    g_lua_pushstring(L, g_last_reason ? g_last_reason : "unknown");
    return 1;
}

static void table_function(lua_State* L, const char* name, lua_CFunction fn)
{
    g_lua_pushcclosure(L, fn, 0);
    g_lua_setfield(L, -2, name);
}

__declspec(dllexport) int __cdecl luaopen_mcm_native_gameover(lua_State* L)
{
    /* Only PE parsing and import-table reads occur before Lua API calls. No profiled VA is
     * dereferenced, so an unknown build can fail module loading without touching code/data. */
    if (!resolve_runtime_imports()) return 0;

    g_lua_createtable(L, 0, 8);
    table_function(L, "install", lua_install);
    table_function(L, "is_installed", lua_is_installed);
    table_function(L, "has_revive_request", lua_has_request);
    table_function(L, "clear_revive_request", lua_clear_request);
    table_function(L, "is_game_over_active", lua_is_game_over_active);
    table_function(L, "cancel_game_over_state", lua_cancel_game_over);
    table_function(L, "cleanup_post_revive", lua_cleanup_post_revive);
    table_function(L, "reason", lua_reason);
    return 1;
}
