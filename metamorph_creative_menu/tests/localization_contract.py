from pathlib import Path
import csv
import re
import sys

root = Path(sys.argv[1] if len(sys.argv) > 1 else '.').resolve()
translation_path = root / 'translations.csv'
rows = list(csv.reader(translation_path.open(encoding='utf-8-sig', newline='')))
if not rows or len(rows[0]) != 15:
    raise SystemExit('localization_contract=FAIL invalid translations.csv header width')

by_key = {row[0]: row for row in rows[1:] if row and row[0]}
if len(by_key) != len([row for row in rows[1:] if row and row[0]]):
    raise SystemExit('localization_contract=FAIL duplicate translation keys')

# Find localization references across the whole runtime rather than freezing one UI file.
# This is semantic source analysis: moving a tab or refactoring a helper does not matter;
# introducing a new untranslated key does.
referenced = set()
for path in root.rglob('*'):
    if not path.is_file() or path.suffix not in {'.lua', '.xml'} or 'tests' in path.parts:
        continue
    referenced.update(
        key for key in re.findall(r'\$([A-Za-z0-9_]+)', path.read_text(errors='replace'))
        if key.startswith('mcm_')
    )

missing = sorted(referenced - set(by_key))
if missing:
    raise SystemExit('localization_contract=FAIL missing referenced keys: ' + ','.join(missing))

invalid_rows = []
blank_game_languages = []
for key in sorted(referenced & set(by_key)):
    row = by_key[key]
    if len(row) != 15:
        invalid_rows.append(f'{key}:{len(row)}')
        continue
    blanks = [index for index, value in enumerate(row[1:12], 1) if not value.strip()]
    if blanks:
        blank_game_languages.append(f'{key}:{blanks}')

if invalid_rows:
    raise SystemExit('localization_contract=FAIL invalid row widths: ' + ','.join(invalid_rows))
if blank_game_languages:
    raise SystemExit('localization_contract=FAIL blank game languages: ' + ','.join(blank_game_languages))

print(
    'localization_contract=PASS '
    f'referenced={len(referenced)} translated={len(referenced & set(by_key))} '
    'fallback_only=0 languages=11'
)
