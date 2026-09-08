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

# R9 native ownership lives in a real x86 Lua C module, never in LuaJIT pointers.
assert native_dll.is_file(), 'native Game Over DLL missing'
dll=native_dll.read_bytes()
assert dll[:2] == b'MZ', 'native bridge is not a PE DLL'
assert b'luaopen_mcm_native_gameover' in dll, 'Lua C-module export missing'
assert 'native_x86_lua_c_module' in patch
assert 'require, MODULE_NAME' in patch
assert 'MODULE_NAME = "mcm_native_gameover"' in patch
assert 'require("ffi")' not in patch and 'ffi.' not in patch, 'Lua executable-memory FFI patch survived R9'
assert 'write_bytes' not in patch, 'Lua still owns executable-memory writes'

# C module owns the exact stock fourth button builder and request byte.
for token in [
    '#define REPLAY_GATE                   0x006e62a7u',
    '#define REPLAY_LABEL                  0x006e62e1u',
    '#define REPLAY_CLICK                  0x006e6393u',
    '#define GAMEOVER_UPDATE_CALL          0x006b2bceu',
    '#define WORLD_PREUPDATE_DISPATCH      0x006b321bu',
    'static volatile u8 g_revive_request = 0;',
    'static const char g_label[] = "$mcm_death_not_dead";',
    'PATCH_REPLAY_GATE',
    'click_patch[0] = 0xc6;',
    'encode_u32(click_patch + 2, (u32)&g_revive_request);',
    'write_bytes(REPLAY_GATE, PATCH_REPLAY_GATE, 5)',
    '#define UI_MENU_MUSIC_HANDLE          0x01207624u',
    '#define UI_GAMEOVER_STATS_HANDLE      0x01207628u',
    '#define MUSIC_DEATH_LATCH_OFFSET      0xddu',
    'stop_tracked_gameover_audio_handle',
    'cleanup_post_revive_runtime',
    'table_function(L, "cleanup_post_revive", lua_cleanup_post_revive);',
]:
    assert token in native_src, token
assert 'pause' not in native_src.lower(), 'native bridge must not own pause-state'
assert 'OnPlayerDied' not in native_src
assert 'process_image_base' in native_src and 'profiled_image_layout_is_safe' in native_src
luaopen=native_src.index('__declspec(dllexport) int __cdecl luaopen_mcm_native_gameover')
preflight=native_src.index('if (!pe_profile_is_stock()) return 0;', luaopen)
first_lua=native_src.index('l_createtable()(L, 0, 8);', luaopen)
assert preflight < first_lua, 'native DLL touches profiled Lua IAT before executable validation'
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
print('death_recovery_native_contract=PASS death_hook=false native_dll=true lua_ffi=false button_builder=stock_save_replay authority_before_release=true post_cleanup=true locales=11')
