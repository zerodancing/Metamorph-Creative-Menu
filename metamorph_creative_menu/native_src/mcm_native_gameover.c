/*
 * Metamorph Creative Menu - native Game Over button bridge.
 * Target: the exact 32-bit noita.exe profiled by MCM v3 development.
 *
 * This DLL intentionally has no imports and no CRT dependency. It resolves the
 * few Win32 and Lua C API functions it needs through noita.exe's own IAT.
 * That keeps native ownership tiny and avoids LuaJIT FFI memory patching.
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

/* Exact noita.exe VAs for the supplied 2025-01-25 build. */
#define NOITA_BASE                    0x00400000u
#define REPLAY_GATE                   0x006e62a7u
#define REPLAY_LABEL                  0x006e62e1u
#define REPLAY_CLICK                  0x006e6393u
#define GAMEOVER_UPDATE_CALL          0x006b2bceu
#define GAMEOVER_TRIGGER              0x006b8519u
#define GAMEOVER_DISPATCH             0x006b2b54u
#define WORLD_PREUPDATE_DISPATCH      0x006b321bu
#define GAME_MODE_POINTER             0x01204bc0u
#define GAMEOVER_FLAG_OFFSET          0x90u

/* Stock runtime state touched by the Game Over audio/UI path. */
#define GET_GAME_GLOBAL_OBJECT        0x00439bb0u
#define AUDIO_HANDLE_LOOKUP           0x0047d820u
#define STOCK_MUSIC_LATCH_RESET       0x006b6cb7u
#define UI_MENU_MUSIC_HANDLE          0x01207624u
#define UI_GAMEOVER_STATS_HANDLE      0x01207628u
#define UI_GAMEOVER_FRAME_COUNTER     0x0120767cu
#define UI_GAMEOVER_STATE             0x01207680u
#define UI_GAMEOVER_FADE              0x01207684u

#define GAME_OBJECT_AUDIO_OFFSET      0x24u
#define GAME_OBJECT_MUSIC_ROOT_OFFSET 0x44u
#define MUSIC_ROOT_MANAGER_OFFSET     0x14u
#define MUSIC_DEATH_LATCH_OFFSET      0xddu
#define AUDIO_RECORD_ACTIVE_OFFSET    0x15u

#define IAT_GET_CURRENT_PROCESS       0x00f07028u
#define IAT_FLUSH_INSTRUCTION_CACHE   0x00f07034u
#define IAT_VIRTUAL_PROTECT           0x00f0703cu

#define IAT_LUA_CREATETABLE           0x00f077a4u
#define IAT_LUA_SETFIELD              0x00f0781cu
#define IAT_LUA_PUSHCLOSURE           0x00f07820u
#define IAT_LUA_PUSHSTRING            0x00f0795cu
#define IAT_LUA_PUSHBOOLEAN           0x00f079b4u

#define PAGE_EXECUTE_READWRITE        0x40u

static volatile u8 g_revive_request = 0;
static volatile u8 g_installed = 0;
static const char g_label[] = "$mcm_death_not_dead";
static const char* g_last_reason = "not_installed";

static const u8 STOCK_REPLAY_GATE[5] = { 0xa1, 0xc0, 0x1b, 0x22, 0x01 };
static const u8 PATCH_REPLAY_GATE[5] = { 0xe9, 0x35, 0x00, 0x00, 0x00 };
static const u8 STOCK_REPLAY_LABEL[5] = { 0x68, 0x14, 0x25, 0x01, 0x01 };
static const u8 STOCK_REPLAY_CLICK[16] = {
    0xe8, 0x18, 0x38, 0xd5, 0xff,
    0x8b, 0x48, 0x48,
    0x83, 0x09, 0x10,
    0xe8, 0x6d, 0xe9, 0x00, 0x00
};
static const u8 STOCK_GAMEOVER_UPDATE_CALL[5] = { 0xe8, 0x0d, 0x26, 0x03, 0x00 };
static const u8 STOCK_GAMEOVER_TRIGGER[30] = {
    0x80, 0xb9, 0x90, 0x00, 0x00, 0x00, 0x00,
    0x0f, 0x85, 0xf0, 0x00, 0x00, 0x00,
    0xc7, 0x05, 0x28, 0x25, 0x15, 0x01, 0xff, 0xff, 0xff, 0xff,
    0xc6, 0x81, 0x90, 0x00, 0x00, 0x00, 0x01
};
static const u8 STOCK_GAMEOVER_DISPATCH[9] = {
    0x80, 0xbf, 0x90, 0x00, 0x00, 0x00, 0x00, 0x74, 0x39
};
static const u8 STOCK_WORLD_PREUPDATE_DISPATCH[10] = {
    0xba, 0xe4, 0x7a, 0xfe, 0x00,
    0xe8, 0x1b, 0xb1, 0x13, 0x00
};
static const u8 STOCK_GET_GAME_GLOBAL_OBJECT[10] = {
    0x55, 0x8b, 0xec, 0x6a, 0xff, 0x68, 0xfc, 0xfe, 0xdf, 0x00
};
static const u8 STOCK_AUDIO_HANDLE_LOOKUP[10] = {
    0x55, 0x8b, 0xec, 0x56, 0x8b, 0x71, 0x28, 0x85, 0xf6, 0x74
};
static const u8 STOCK_MUSIC_LATCH_RESET_CODE[15] = {
    0x8b, 0x40, 0x44, 0x8b, 0xce, 0x8b, 0x40, 0x14,
    0xc6, 0x80, 0xdd, 0x00, 0x00, 0x00, 0x00
};

static lua_createtable_t l_createtable(void) { return *(lua_createtable_t*)IAT_LUA_CREATETABLE; }
static lua_setfield_t l_setfield(void) { return *(lua_setfield_t*)IAT_LUA_SETFIELD; }
static lua_pushcclosure_t l_pushcclosure(void) { return *(lua_pushcclosure_t*)IAT_LUA_PUSHCLOSURE; }
static lua_pushstring_t l_pushstring(void) { return *(lua_pushstring_t*)IAT_LUA_PUSHSTRING; }
static lua_pushboolean_t l_pushboolean(void) { return *(lua_pushboolean_t*)IAT_LUA_PUSHBOOLEAN; }

static VirtualProtect_t p_virtual_protect(void) { return *(VirtualProtect_t*)IAT_VIRTUAL_PROTECT; }
static FlushInstructionCache_t p_flush_icache(void) { return *(FlushInstructionCache_t*)IAT_FLUSH_INSTRUCTION_CACHE; }
static GetCurrentProcess_t p_current_process(void) { return *(GetCurrentProcess_t*)IAT_GET_CURRENT_PROCESS; }

/* Read the main executable base from the 32-bit PEB instead of dereferencing the
 * profiled 0x00400000 address first.  A future/alternate noita.exe may be relocated;
 * in that case the optional module must fail closed rather than fault during require(). */
#if defined(_MSC_VER)
unsigned long __readfsdword(unsigned long offset);
#pragma intrinsic(__readfsdword)
#endif

static u32 process_image_base(void)
{
    u32 peb = (u32)__readfsdword(0x30u);
    if (peb == 0) return 0;
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

static int profiled_image_layout_is_safe(void)
{
    u32 base = process_image_base();
    u32 pe_offset, pe, optional, size_of_image, required_end;

    if (base == 0) { g_last_reason = "process_image_base_unavailable"; return 0; }
    if (base != NOITA_BASE) { g_last_reason = "profiled_exe_base_mismatch"; return 0; }
    if (read_u16(base) != 0x5a4du) { g_last_reason = "profiled_exe_missing_mz"; return 0; }

    pe_offset = read_u32(base + 0x3cu);
    /* The supplied executable's PE header is near the beginning.  Bound the value before
     * following it so malformed/different images cannot turn validation into a wild read. */
    if (pe_offset < 0x40u || pe_offset > 0x1000u) {
        g_last_reason = "profiled_exe_pe_offset_invalid";
        return 0;
    }
    pe = base + pe_offset;
    if (read_u32(pe) != 0x00004550u) { g_last_reason = "profiled_exe_missing_pe"; return 0; }
    if (read_u16(pe + 4u) != 0x014cu) { g_last_reason = "profiled_exe_machine_mismatch"; return 0; }
    optional = pe + 24u;
    if (read_u16(optional) != 0x010bu) { g_last_reason = "profiled_exe_not_pe32"; return 0; }
    size_of_image = read_u32(optional + 56u);
    required_end = UI_GAMEOVER_FADE + 4u;
    if (size_of_image < (required_end - base) || size_of_image > 0x10000000u) {
        g_last_reason = "profiled_exe_image_range_mismatch";
        return 0;
    }
    return 1;
}

static int bytes_equal(u32 address, const u8* expected, u32 size)
{
    volatile const u8* p = (volatile const u8*)address;
    u32 i;
    for (i = 0; i < size; ++i) {
        if (p[i] != expected[i]) return 0;
    }
    return 1;
}

static void encode_u32(u8* out, u32 value)
{
    out[0] = (u8)(value & 0xffu);
    out[1] = (u8)((value >> 8) & 0xffu);
    out[2] = (u8)((value >> 16) & 0xffu);
    out[3] = (u8)((value >> 24) & 0xffu);
}

static int write_bytes(u32 address, const u8* bytes, u32 size)
{
    VirtualProtect_t vp = p_virtual_protect();
    FlushInstructionCache_t flush = p_flush_icache();
    GetCurrentProcess_t current = p_current_process();
    volatile u8* dst = (volatile u8*)address;
    DWORD old_protect = 0;
    DWORD ignored = 0;
    u32 i;

    if (!vp || !flush || !current) return 0;
    if (!vp((LPVOID)address, size, PAGE_EXECUTE_READWRITE, &old_protect)) return 0;
    for (i = 0; i < size; ++i) dst[i] = bytes[i];
    flush(current(), (LPCVOID)address, size);
    vp((LPVOID)address, size, old_protect, &ignored);
    return bytes_equal(address, bytes, size);
}

static int pe_profile_is_stock(void)
{
    if (!profiled_image_layout_is_safe()) return 0;
    if (!bytes_equal(GAMEOVER_UPDATE_CALL, STOCK_GAMEOVER_UPDATE_CALL, 5)) {
        g_last_reason = "gameover_update_call_not_stock";
        return 0;
    }
    if (!bytes_equal(GAMEOVER_TRIGGER, STOCK_GAMEOVER_TRIGGER, 30)) {
        g_last_reason = "gameover_trigger_signature_mismatch";
        return 0;
    }
    if (!bytes_equal(GAMEOVER_DISPATCH, STOCK_GAMEOVER_DISPATCH, 9)) {
        g_last_reason = "gameover_dispatch_signature_mismatch";
        return 0;
    }
    if (!bytes_equal(WORLD_PREUPDATE_DISPATCH, STOCK_WORLD_PREUPDATE_DISPATCH, 10)) {
        g_last_reason = "world_preupdate_signature_mismatch";
        return 0;
    }
    if (!bytes_equal(GET_GAME_GLOBAL_OBJECT, STOCK_GET_GAME_GLOBAL_OBJECT, 10)) {
        g_last_reason = "game_global_signature_mismatch";
        return 0;
    }
    if (!bytes_equal(AUDIO_HANDLE_LOOKUP, STOCK_AUDIO_HANDLE_LOOKUP, 10)) {
        g_last_reason = "audio_handle_lookup_signature_mismatch";
        return 0;
    }
    if (!bytes_equal(STOCK_MUSIC_LATCH_RESET, STOCK_MUSIC_LATCH_RESET_CODE, 15)) {
        g_last_reason = "music_latch_reset_signature_mismatch";
        return 0;
    }
    return 1;
}

static int install_patch(void)
{
    u8 label_patch[5];
    u8 click_patch[16];
    u32 i;

    if (g_installed) {
        g_last_reason = "installed";
        return 1;
    }

    if (!pe_profile_is_stock()) return 0;

    if (bytes_equal(REPLAY_GATE, PATCH_REPLAY_GATE, 5)) {
        /* Old R5-R7 Lua patch may contain pointers to a dead LuaJIT heap. */
        g_last_reason = "stale_previous_patch_restart_required";
        return 0;
    }
    if (!bytes_equal(REPLAY_GATE, STOCK_REPLAY_GATE, 5)) {
        g_last_reason = "replay_gate_signature_mismatch";
        return 0;
    }
    if (!bytes_equal(REPLAY_LABEL, STOCK_REPLAY_LABEL, 5)) {
        g_last_reason = "replay_label_signature_mismatch";
        return 0;
    }
    if (!bytes_equal(REPLAY_CLICK, STOCK_REPLAY_CLICK, 16)) {
        g_last_reason = "replay_click_signature_mismatch";
        return 0;
    }

    label_patch[0] = 0x68;
    encode_u32(label_patch + 1, (u32)g_label);

    click_patch[0] = 0xc6;
    click_patch[1] = 0x05;
    encode_u32(click_patch + 2, (u32)&g_revive_request);
    click_patch[6] = 0x01;
    for (i = 7; i < 16; ++i) click_patch[i] = 0x90;

    /* Publish pointers first, gate last. Until the gate changes this code path is unreachable. */
    if (!write_bytes(REPLAY_LABEL, label_patch, 5)) {
        g_last_reason = "label_write_failed";
        return 0;
    }
    if (!write_bytes(REPLAY_CLICK, click_patch, 16)) {
        write_bytes(REPLAY_LABEL, STOCK_REPLAY_LABEL, 5);
        g_last_reason = "click_write_failed";
        return 0;
    }
    if (!write_bytes(REPLAY_GATE, PATCH_REPLAY_GATE, 5)) {
        write_bytes(REPLAY_CLICK, STOCK_REPLAY_CLICK, 16);
        write_bytes(REPLAY_LABEL, STOCK_REPLAY_LABEL, 5);
        g_last_reason = "gate_write_failed";
        return 0;
    }

    if (!bytes_equal(REPLAY_GATE, PATCH_REPLAY_GATE, 5)
        || !bytes_equal(REPLAY_LABEL, label_patch, 5)
        || !bytes_equal(REPLAY_CLICK, click_patch, 16))
    {
        write_bytes(REPLAY_GATE, STOCK_REPLAY_GATE, 5);
        write_bytes(REPLAY_CLICK, STOCK_REPLAY_CLICK, 16);
        write_bytes(REPLAY_LABEL, STOCK_REPLAY_LABEL, 5);
        g_last_reason = "post_install_verify_failed";
        return 0;
    }

    g_revive_request = 0;
    g_installed = 1;
    g_last_reason = "installed";
    return 1;
}

static int game_over_active(void)
{
    u32 game_mode = *(volatile u32*)GAME_MODE_POINTER;
    if (!game_mode) return 0;
    return *((volatile u8*)(game_mode + GAMEOVER_FLAG_OFFSET)) != 0;
}

static int cancel_game_over(void)
{
    u32 game_mode = *(volatile u32*)GAME_MODE_POINTER;
    if (!g_installed) {
        g_last_reason = "not_installed";
        return 0;
    }
    if (!game_mode) {
        g_last_reason = "game_mode_unavailable";
        return 0;
    }
    *((volatile u8*)(game_mode + GAMEOVER_FLAG_OFFSET)) = 0;
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

    if (audio_manager) {
        lookup = (audio_handle_lookup_t)AUDIO_HANDLE_LOOKUP;
        record = lookup(audio_manager, handle);
        if (record) {
            /* This is exactly what stock UI-audio fade completion does at
             * 0x006c5f99/0x006c5fb4: mark the tracked audio record inactive.
             * The normal audio-system update then performs the FMOD teardown. */
            *((volatile u8*)record + AUDIO_RECORD_ACTIVE_OFFSET) = 0;
        }
    }
    *handle_ptr = -1;
}

static int cleanup_post_revive_runtime(void)
{
    get_game_global_object_t get_global;
    void* game;
    void* audio_manager;
    void* music_root;
    void* music_manager;

    if (!g_installed) {
        g_last_reason = "not_installed";
        return 0;
    }
    if (!pe_profile_is_stock()) return 0;

    get_global = (get_game_global_object_t)GET_GAME_GLOBAL_OBJECT;
    game = get_global();
    if (!game) {
        g_last_reason = "game_global_unavailable";
        return 0;
    }

    audio_manager = *(void**)((u8*)game + GAME_OBJECT_AUDIO_OFFSET);
    stop_tracked_gameover_audio_handle((volatile int*)UI_MENU_MUSIC_HANDLE, audio_manager);
    stop_tracked_gameover_audio_handle((volatile int*)UI_GAMEOVER_STATS_HANDLE, audio_manager);

    music_root = *(void**)((u8*)game + GAME_OBJECT_MUSIC_ROOT_OFFSET);
    music_manager = music_root ? *(void**)((u8*)music_root + MUSIC_ROOT_MANAGER_OFFSET) : 0;
    if (music_manager) {
        /* Game Over sets this byte to 1 at 0x006e5137/0x006b8577. Stock
         * game-state reset clears it at 0x006b6cbf. While it stays set the
         * normal biome music selector refuses to start gameplay tracks. */
        *((volatile u8*)music_manager + MUSIC_DEATH_LATCH_OFFSET) = 0;
    }

    /* These are transient Game Over presentation values initialized at
     * 0x006e50ae..0x006e50bf. Reset them so a later real death starts from
     * a clean stock UI state instead of inheriting the revived screen. */
    *(volatile u32*)UI_GAMEOVER_FRAME_COUNTER = 0;
    *(volatile u8*)UI_GAMEOVER_STATE = 0;
    *(volatile u32*)UI_GAMEOVER_FADE = 0;

    g_last_reason = "post_revive_cleaned";
    return 1;
}

static int push_bool_reason(lua_State* L, int ok, const char* reason)
{
    l_pushboolean()(L, ok ? 1 : 0);
    l_pushstring()(L, reason ? reason : "unknown");
    return 2;
}

static int __cdecl lua_install(lua_State* L)
{
    int ok = install_patch();
    return push_bool_reason(L, ok, g_last_reason);
}

static int __cdecl lua_is_installed(lua_State* L)
{
    l_pushboolean()(L, g_installed ? 1 : 0);
    return 1;
}

static int __cdecl lua_has_request(lua_State* L)
{
    l_pushboolean()(L, (g_installed && g_revive_request) ? 1 : 0);
    return 1;
}

static int __cdecl lua_clear_request(lua_State* L)
{
    g_revive_request = 0;
    l_pushboolean()(L, 1);
    return 1;
}

static int __cdecl lua_is_game_over_active(lua_State* L)
{
    l_pushboolean()(L, (g_installed && game_over_active()) ? 1 : 0);
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
    l_pushstring()(L, g_last_reason ? g_last_reason : "unknown");
    return 1;
}

static void table_function(lua_State* L, const char* name, lua_CFunction fn)
{
    l_pushcclosure()(L, fn, 0);
    l_setfield()(L, -2, name);
}

__declspec(dllexport) int __cdecl luaopen_mcm_native_gameover(lua_State* L)
{
    /* CRITICAL: validate the executable before the first dereference of a profiled Lua
     * IAT slot.  Returning zero makes Lua's loader reject the module harmlessly; pcall
     * in the Lua facade can then disable only this optional singleplayer feature. */
    if (!pe_profile_is_stock()) return 0;

    l_createtable()(L, 0, 8);
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
