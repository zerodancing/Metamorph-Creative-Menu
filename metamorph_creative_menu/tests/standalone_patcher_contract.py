from pathlib import Path
import sys

root = Path(sys.argv[1]).resolve()
bridge = (root / 'files/platform/noita/patcher_bridge.lua').read_text(encoding='utf-8')
serialization = (root / 'files/integrations/ew/serialization.lua').read_text(encoding='utf-8')

local_loader = 'mods/metamorph_creative_menu/NoitaPatcher/load.lua'
assert local_loader in bridge, 'patcher bridge is not bootstrapping MCM-owned NoitaPatcher'
assert 'mods/quant.ew/NoitaPatcher/load.lua' not in bridge, 'core patcher bridge still depends on quant.ew'
assert (root / 'NoitaPatcher/load.lua').is_file(), 'bundled NoitaPatcher load.lua missing'
assert (root / 'NoitaPatcher/noitapatcher.dll').is_file(), 'bundled NoitaPatcher DLL missing'
assert (root / 'NoitaPatcher/noitapatcher/nsew/world_ffi.lua').is_file(), 'bundled standalone world_ffi missing'
assert 'mods/metamorph_creative_menu/files/lib/base64.lua' in serialization, 'form serialization is not using local base64'
assert 'mods/quant.ew/files/resource/base64.lua' not in serialization, 'form serialization still depends on EW base64'
assert (root / 'files/lib/base64.lua').is_file(), 'local base64 codec missing'

# EW references are allowed only in the optional EW integration layer and QA helpers.
for path in (root / 'files').rglob('*.lua'):
    rel = path.relative_to(root).as_posix()
    if rel.startswith('files/integrations/ew/') or rel.startswith('files/qa/'):
        continue
    text = path.read_text(encoding='utf-8', errors='replace')
    assert 'mods/quant.ew/' not in text, f'standalone runtime leaked an EW filesystem dependency: {rel}'

print('standalone_patcher_contract=PASS local_noitapatcher=true local_base64=true core_quant_ew_refs=0')
