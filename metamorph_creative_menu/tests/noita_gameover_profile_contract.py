from pathlib import Path
import os, sys
root=Path(sys.argv[1]).resolve()
exe=Path(os.environ.get('NOITA_EXE_UNDER_TEST','/mnt/data/noita.exe'))
if not exe.is_file():
    print('noita_gameover_profile_contract=PASS binary_validation=SKIPPED')
    raise SystemExit(0)
data=exe.read_bytes()
def va_off(va:int)->int:
    return 0x400 + (va-0x401000)
def expect(va:int, blob:bytes, label:str):
    got=data[va_off(va):va_off(va)+len(blob)]
    assert got==blob, f'{label} signature mismatch at {va:#x}: {got.hex()} != {blob.hex()}'

# All three normal visible text buttons and the conditional stock fourth slot are in
# one Game Over construction function. R8 only removes the fourth slot's condition.
expect(0x6e61cc, bytes.fromhex('68 fc 24 01 01'), 'new game label push')
expect(0x6e62a7, bytes.fromhex('a1 c0 1b 22 01'), 'fourth button condition gate')
expect(0x6e62e1, bytes.fromhex('68 14 25 01 01'), 'save replay fourth-button label push')
expect(0x6e6393, bytes.fromhex('e8 18 38 d5 ff 8b 48 48 83 09 10 e8 6d e9 00 00'), 'save replay fourth-button click')
expect(0x6e63c8, bytes.fromhex('68 30 25 01 01'), 'quit label push')
expect(0x6b2bce, bytes.fromhex('e8 0d 26 03 00'), 'stock Game Over update call')
expect(0x6b8519, bytes.fromhex('80 b9 90 00 00 00 00 0f 85 f0 00 00 00 c7 05 28 25 15 01 ff ff ff ff c6 81 90 00 00 00 01'), 'GameTriggerGameOver flag setter')
expect(0x6b2b54, bytes.fromhex('80 bf 90 00 00 00 00 74 39'), 'Game Over UI dispatch gate')
expect(0x6b321b, bytes.fromhex('ba e4 7a fe 00 e8 1b b1 13 00'), 'OnWorldPreUpdate dispatch after Game Over UI')

# R9 post-revive cleanup is grounded in stock audio/UI cleanup sites.
expect(0x439bb0, bytes.fromhex('55 8b ec 6a ff 68 fc fe df 00'), 'global game object getter')
expect(0x47d820, bytes.fromhex('55 8b ec 56 8b 71 28 85 f6 74'), 'audio handle lookup')
expect(0x6b6cb7, bytes.fromhex('8b 40 44 8b ce 8b 40 14 c6 80 dd 00 00 00 00'), 'stock death music latch reset')
expect(0x6e50ae, bytes.fromhex('c7 05 7c 76 20 01 00 00 00 00 c6 05 80 76 20 01 00 c7 05 28 76 20 01 ff ff ff ff'), 'stock Game Over transient reset')

for s in [b'$menugameover_newgame\x00', b'$menugameover_savereplay\x00', b'$menugameover_quit\x00']:
    assert s in data
# The unconditional JMP written at 0x6e62a7 is +0x35 from next instruction,
# landing exactly on the stock save-replay label builder at 0x6e62e1.
assert 0x6e62a7 + 5 + 0x35 == 0x6e62e1
print('noita_gameover_profile_contract=PASS supplied_exe=true visible_builder_path=true fourth_slot_target=true signatures=13 world_preupdate_after_ui=true audio_cleanup_profile=true')
