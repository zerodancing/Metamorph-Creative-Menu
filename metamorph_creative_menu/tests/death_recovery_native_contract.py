from pathlib import Path
import csv, io, sys
root=Path(sys.argv[1]).resolve()
init=(root/'init.lua').read_text(encoding='utf-8')
patch=(root/'files/platform/noita/native_gameover_patch.lua').read_text(encoding='utf-8')
service=(root/'files/features/death_recovery/service.lua').read_text(encoding='utf-8')
native_src=(root/'native_src/mcm_native_gameover.c').read_text(encoding='utf-8')
native_dll=root/'mcm_native_gameover.dll'

# The abandoned fake/death-boundary paths must stay gone.
assert 'death_recovery_screen.lua' not in init
assert not (root/'files/ui/death_recovery_screen.lua').exists()
assert not (root/'files/features/death_recovery/death_snapshot_hook.lua').exists()
assert 'DEATH_SNAPSHOT_HOOK' not in init
assert 'OnPlayerDied' not in service
assert 'GameTriggerGameOver' not in service
assert 'GameDestroyInventoryItems' not in service
assert 'SetPauseState' not in service

# Native ownership lives in a real x86 Lua C module, never in LuaJIT pointers.
assert native_dll.is_file(), 'native Game Over DLL missing'
dll=native_dll.read_bytes()
assert dll[:2] == b'MZ', 'native bridge is not a PE DLL'
assert b'luaopen_mcm_native_gameover' in dll, 'Lua C-module export missing'
assert 'native_x86_lua_c_module_adaptive' in patch
assert 'require, MODULE_NAME' in patch
assert 'MODULE_NAME = "mcm_native_gameover"' in patch
assert 'require("ffi")' not in patch and 'ffi.' not in patch, 'Lua executable-memory FFI patch survived'
assert 'write_bytes' not in patch, 'Lua still owns executable-memory writes'
assert 'fixed_exe_hash = false' in patch and 'fixed_virtual_addresses = false' in patch
assert '808d2a0ab51e' not in patch, 'Lua facade still pins one noita.exe hash'

# R10 resolves the running PE/import table and discovers stock Game Over semantics.
for token in [
    'parse_image_layout',
    'resolve_import("lua_createtable")',
    'resolve_import("VirtualProtect")',
    'find_ascii_in_image("$menugameover_savereplay")',
    'find_ascii_in_image("event_cues/game_over/create")',
    'locate_replay_sites',
    'locate_gameover_core',
    'locate_gameover_init_globals',
    'locate_audio_cleanup',
    'resolve_adaptive_profile',
    'static volatile u8 g_revive_request = 0;',
    'static const char g_label[] = "$mcm_death_not_dead";',
    'encode_u32(gate_patch + 1u, g_profile.replay_label - (g_profile.replay_gate + 5u));',
    'encode_u32(click_patch + 2u, (u32)&g_revive_request);',
    'write_bytes(g_profile.replay_gate, gate_patch, 5u)',
    'stop_tracked_gameover_audio_handle',
    'cleanup_post_revive_runtime',
    'table_function(L, "cleanup_post_revive", lua_cleanup_post_revive);',
]:
    assert token in native_src, token

# Old build-specific addresses/signatures must not return as compatibility policy.
for forbidden in [
    '#define NOITA_BASE', '#define REPLAY_GATE', '#define REPLAY_LABEL', '#define REPLAY_CLICK',
    '#define GAME_MODE_POINTER', '#define IAT_LUA_CREATETABLE', '#define UI_MENU_MUSIC_HANDLE',
    '0x006e62a7', '0x006e62e1', '0x006e6393', '0x01204bc0', '0x00f077a4',
]:
    assert forbidden not in native_src, forbidden
assert 'pause' not in native_src.lower(), 'native bridge must not own pause-state'
assert 'OnPlayerDied' not in native_src
luaopen=native_src.index('__declspec(dllexport) int __cdecl luaopen_mcm_native_gameover')
preflight=native_src.index('if (!resolve_runtime_imports()) return 0;', luaopen)
first_lua=native_src.index('g_lua_createtable(L, 0, 8);', luaopen)
assert preflight < first_lua, 'native DLL calls Lua before PE/import preflight'
assert 'disabled_in_entangled_worlds' in patch and 'disabled_in_entangled_worlds' in service

# Recovery ordering remains: player authority first, Game Over release second.
assert 'BACKUP_INTERVAL_FRAMES = 60' in service
assert 'LOW_HP_INTERVAL_FRAMES = 10' in service
assert 'INVINCIBILITY_FRAMES = 30 * 60' in service
assert 'make_authoritative(bridge, entity)' in service
assert service.index('make_authoritative(bridge, entity)') < service.index('native_gameover.cancel_game_over_state()')
assert 'native_gameover.clear_revive_request()' in service
assert 'post_revive_cleanup.apply(entity)' in service
assert service.index('native_gameover.cancel_game_over_state()') < service.index('post_revive_cleanup.apply(entity)') < service.index('native_gameover.clear_revive_request()')
cleanup=(root/'files/features/death_recovery/post_revive_cleanup.lua').read_text(encoding='utf-8')
assert 'native_gameover.cleanup_post_revive()' in cleanup
assert 'GameTriggerMusicFadeOutAndDequeueAll' not in cleanup
assert 'protected_call("death_recovery.update", death_recovery.update)' in init
assert 'protected_call("death_recovery.install", death_recovery.install)' not in init
assert 'function native_gameover_patch.is_installed()' in patch
assert service.index('track_live_player()') < service.index('if not native_gameover.is_installed() then\n        return false')

rows=list(csv.reader(io.StringIO((root/'translations.csv').read_text(encoding='utf-8-sig'))))
row=next((r for r in rows if r and r[0]=='mcm_death_not_dead'),None)
assert row is not None and len(row)>=12
assert all(str(value).strip() for value in row[1:12])
assert 'native Game Over button patch: installed' in service
print('death_recovery_native_contract=PASS death_hook=false native_dll=true lua_ffi=false adaptive_pe32=true fixed_va=false authority_before_release=true post_cleanup=true locales=11')
