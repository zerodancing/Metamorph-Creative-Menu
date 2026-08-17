from pathlib import Path
import base64
import re
import zlib

ROOT = Path("metamorph_creative_menu")
TMP = Path(".github/tmp")


def decode_chunks(prefix):
    payload = "".join(path.read_text(encoding="utf-8").strip() for path in sorted(TMP.glob(prefix + ".*")))
    return zlib.decompress(base64.b64decode(payload))


# Internal developer/testing documentation is English-only.
(ROOT / "README.txt").write_bytes(decode_chunks("readme"))
(ROOT / "tests/TESTING.txt").write_bytes(decode_chunks("testing"))

# Preserve Russian case-insensitive search without hardcoded Cyrillic literals in source.
runtime = ROOT / "files/ui/runtime.lua"
text = runtime.read_text(encoding="utf-8")
start = text.index("local CYRILLIC_UPPER = {")
end = text.index("local normalized_search_cache = {}", start)
replacement = zlib.decompress(base64.b64decode(
    "eNqtVl1vmzAUfc+vuGpVCQohhqRSHpq+TM0PmLSHaZoiB5xiybUjMEuyafvt8wcQTEqapfMDEPvec8+5vr4OEylmsKl4KqngUMnNfEV4KjKy0o+toFx67Zc/AjXoBtoZeAS0nyOQOeFQEFkVHEpZUP4SpTkuOq5AeDbkbv3Nqh5v4KD9JwQBvGKZRxsmRAcZJgpjhvzQMgmgs3RnlyzvQQIxQhdReD5LQaP4YYugR0PoHO2G48X036S2fCc7Lrd3eRktLbPRf9ejtYyYW3tM7EixKgku0tz7gVlFrG7zCYtGsDHzpLA/rSGIAm5u6jxZWFHJECjPyD4ERviLzBXEr98hxCHcGidjvMspI9YOHheNZSZayTVJWpTyyGF9kMRGrmP4PftWcgg7msm8XVa1Z7E658Ypmb6nCmocFPHWjrCSOECqMDHPahkBxB0pwwEUsmchxqCPlw/3Znv0lg3p1OC+sZ8j34FtyCbDLJcuy+QKls81S12fjr0el/Kudf6jf3Je97Svu/GbXiFz2ZL8sM4rMpV8MFPT85maOZlyTNSh/XarHlrG9wawPXVltXZCNWevo30wuZyyY9i6kZ7cBX+M3ekujcfwuSpLitUFud2SIsUlgS8BmsUoivQ7Wareuy1BCtvFjMH6AAHaJyjqY2kPFE/06yEG76uYHIQPtAQuilfM6E+SaSS9Pn0Aj/iwUf3NNkYXzGH/tFBJ15zMKevccHZecTSXdDcrx+8ANFUnNScBFhYIxbrdnkwrKSf4el5J6KM626zMLvrX0VKqi6LZc7e/NqF6l6XEa0aiVPAUS09Frm+gv1hRgU0="
)).decode("utf-8")
text = text[:start] + replacement + text[end:]
runtime.write_text(text, encoding="utf-8")

# User-visible fallback strings belong in translations.csv rather than direct UI prose.
weather = ROOT / "files/ui/tabs/weather.lua"
text = weather.read_text(encoding="utf-8")
text = text.replace(
    'ui.white_text(0, 0, "Weather editing unavailable")',
    'ui.white_text(0, 0, ui.tr("$mcm_weather_unavailable", "Weather editing unavailable"))',
)
text = text.replace(
    '(mode == "ew_peer" and "EW PEER" or ui.tr("$mcm_weather_mode_local", "LOCAL"))',
    '(mode == "ew_peer" and ui.tr("$mcm_weather_mode_ew_client", "EW CLIENT") or ui.tr("$mcm_weather_mode_local", "LOCAL"))',
)
weather.write_text(text, encoding="utf-8")

rules = ROOT / "files/ui/tabs/world_rules.lua"
text = rules.read_text(encoding="utf-8")
text = text.replace(
    'ui.white_text(0, 0, "World-rule editing unavailable")',
    'ui.white_text(0, 0, ui.tr("$mcm_rules_unavailable", "World-rule editing unavailable"))',
)
text = text.replace(
    'ui.white_text(0, 0, "RULE ERROR: " .. tostring(last_action_error))',
    'ui.white_text(0, 0, ui.tr("$mcm_rules_error", "RULE ERROR") .. ": " .. tostring(last_action_error))',
)
text = text.replace(
    'local mode_label = mode == "ew_host" and "EW HOST" or (mode == "ew_peer" and "EW PEER" or "LOCAL")',
    'local mode_label = mode == "ew_host" and ui.tr("$mcm_weather_mode_ew_host", "EW HOST")\n'
    '        or (mode == "ew_peer" and ui.tr("$mcm_weather_mode_ew_client", "EW CLIENT")\n'
    '        or ui.tr("$mcm_weather_mode_local", "LOCAL"))',
)
rules.write_text(text, encoding="utf-8")

translations = ROOT / "translations.csv"
raw = translations.read_text(encoding="utf-8-sig")
rows = [
    "mcm_perk_apply_failed,Could not apply perk,Не удалось применить перк,Não foi possível aplicar o benefício,No se pudo aplicar el perk,Perk konnte nicht angewendet werden,Impossible d’appliquer l’atout,Impossibile applicare il perk,Nie udało się zastosować perka,无法应用天赋,パークを適用できませんでした,퍽을 적용하지 못했습니다,,,","[:-1],
    "mcm_weather_unavailable,Weather editing unavailable,Редактирование погоды недоступно,Edição do clima indisponível,La edición del clima no está disponible,Wetterbearbeitung nicht verfügbar,Modification de la météo indisponible,Modifica del meteo non disponibile,Edycja pogody jest niedostępna,天气编辑不可用,天候編集を利用できません,날씨 편집을 사용할 수 없습니다,,,","[:-1],
    "mcm_rules_unavailable,World-rule editing unavailable,Редактирование правил мира недоступно,Edição das regras do mundo indisponível,La edición de reglas del mundo no está disponible,Weltregel-Bearbeitung nicht verfügbar,Modification des règles du monde indisponible,Modifica delle regole del mondo non disponibile,Edycja zasad świata jest niedostępna,世界规则编辑不可用,ワールドルール編集を利用できません,세계 규칙 편집을 사용할 수 없습니다,,,","[:-1],
    "mcm_rules_error,RULE ERROR,ОШИБКА ПРАВИЛА,ERRO DE REGRA,ERROR DE REGLA,REGELFEHLER,ERREUR DE RÈGLE,ERRORE REGOLA,BŁĄD ZASADY,规则错误,ルールエラー,규칙 오류,,,","[:-1],
]
existing = {line.split(",", 1)[0].lstrip("\ufeff") for line in raw.splitlines() if line}
for row in rows:
    key = row.split(",", 1)[0]
    if key not in existing:
        raw = raw.rstrip("\r\n") + "\n" + row + "\n"
translations.write_text("\ufeff" + raw, encoding="utf-8")

# Everything except the root multilingual README and translations must be English-only.
allowed = {Path("README.md"), ROOT / "translations.csv"}
cyrillic = re.compile(r"[\u0400-\u04FF]")
violations = []
for path in Path(".").rglob("*"):
    if not path.is_file() or ".git" in path.parts or ".github" in path.parts or path in allowed:
        continue
    if path.suffix.lower() in {".dll", ".png", ".jpg", ".jpeg", ".gif", ".zip"}:
        continue
    try:
        value = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        continue
    if cyrillic.search(value):
        violations.append(str(path))
if violations:
    raise SystemExit("Cyrillic outside translations/root README: " + ", ".join(violations))

print("English source cleanup complete")
