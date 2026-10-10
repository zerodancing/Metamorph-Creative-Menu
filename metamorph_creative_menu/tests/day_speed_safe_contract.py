from pathlib import Path
import os, sys

root = Path(sys.argv[1]).resolve()
defs = (root / 'files/features/world_rules/definitions.lua').read_text(encoding='utf-8')
service = (root / 'files/features/world_rules/service.lua').read_text(encoding='utf-8')
weather = (root / 'files/features/weather/service.lua').read_text(encoding='utf-8')
sync = (root / 'files/integrations/ew/weather_sync.lua').read_text(encoding='utf-8')
owner = (root / 'files/features/world_rules/time_dt.lua').read_text(encoding='utf-8')
magic = (root / 'files/features/world_rules/magic_numbers.lua').read_text(encoding='utf-8')

assert 'id="day_speed"' in defs and 'kind="time_dt_multiplier"' in defs
assert 'DESIGN_DAY_CYCLE_SPEED' not in defs, 'Day Speed still depends on unsafe MagicNumbers in rule definitions'
assert 'time_dt_owner.apply_day_multiplier' in service
assert 'time_dt_owner.release_day_multiplier' in service
assert 'time_dt_owner.has_persisted_recovery' in service
assert 'original_time_dt' not in weather
assert 'time_dt_owner.set_weather_frozen(true)' in weather
assert 'time_dt_owner.set_weather_frozen(false)' in weather
assert 'write_value(component, "time_dt", 0)' not in weather
assert 'legacy_sync_value' in sync, 'weather v1 compatibility must transport baseline time_dt'
assert 'Compare-and-swap' in owner and 'external_preserved' in owner
assert 'LEGACY_RECOVERY_KEYS' in magic and 'DESIGN_DAY_CYCLE_SPEED' in magic, 'upgrade recovery for pre-safe Day Speed was lost'

# Optional executable grounding. The supplied Noita build uses:
#   xmm1 = game step
#   xmm2 = WorldStateComponent.time_dt (+0x54)
#   xmm1 *= DESIGN_DAY_CYCLE_SPEED
#   xmm1 *= xmm2
#   time (+0x4c) and time_total (+0x50) += xmm1
exe_raw = os.environ.get('NOITA_EXE_UNDER_TEST', '')
if exe_raw:
    exe = Path(exe_raw)
    assert exe.is_file(), f'NOITA_EXE_UNDER_TEST does not exist: {exe}'
    data = exe.read_bytes()
    def va_off(va: int) -> int:
        return 0x400 + (va - 0x401000)
    va = 0xC4303D
    expected = bytes.fromhex(
        'f3 0f 10 57 54 '       # movss xmm2,[edi+54]  time_dt
        'f3 0f 10 48 24 '       # movss xmm1,[eax+24]  game step
        '0f 28 c1 '
        'f3 0f 59 c2 '          # mulss xmm0,xmm2 (parallel delta)
        'f3 0f 11 44 24 10 '
        '75 28 '
        'f3 0f 59 0d 60 25 15 01 '  # mulss xmm1,[DESIGN_DAY_CYCLE_SPEED]
        'f3 0f 10 47 4c '
        'f3 0f 59 ca '          # mulss xmm1,xmm2 (time_dt)
        'f3 0f 58 c1 '
        'f3 0f 11 47 4c '
        'f3 0f 10 47 50 '
        'f3 0f 58 c1 '
        'f3 0f 11 47 50'
    )
    got = data[va_off(va):va_off(va)+len(expected)]
    assert got == expected, f'Day Speed binary signature mismatch at {va:#x}: {got.hex()} != {expected.hex()}'
    binary = 'PASS'
else:
    binary = 'SKIPPED'

print(f'day_speed_safe_contract=PASS safe_time_dt=true weather_owner=true cas=true legacy_ew_baseline=true binary_validation={binary}')
