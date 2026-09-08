from pathlib import Path
import sys
root=Path(sys.argv[1]).resolve()
editor=(root/'files/ui/components/wand_editor.lua').read_text()
presets=(root/'files/ui/components/wand_presets.lua').read_text()
translations=(root/'translations.csv').read_text(encoding='utf-8-sig')
assert 'METAMORPH_CREATIVE_MENU_DEV_MODE == true and last_error ~= nil' in editor, 'wand mutation diagnostic leaks into release UI'
assert 'ui.tr("$mcm_delete", "DELETE")' in presets, 'wand preset delete still uses an unlabeled X'
assert 'ui.tr("$mcm_cancel", "CANCEL")' in presets, 'wand preset deletion has no explicit cancel action'
assert 'clicked == 4 and confirm_delete == index' in presets, 'wand preset cancel button is not handled'
assert 'mcm_cancel,CANCEL,' in translations, 'cancel localization missing'
print('release_wand_ui_contract=PASS diagnostics_gated=true delete_label=true confirm_cancel=true')
