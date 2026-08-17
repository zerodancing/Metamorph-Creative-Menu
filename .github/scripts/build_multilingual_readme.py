from pathlib import Path

DOCS = Path("docs")
LANGS = [
    ("en", "English", "README.en.md"),
    ("ru", "Русский", "README.ru.md"),
    ("pt-br", "Português (Brasil)", "README.pt-BR.md"),
    ("es", "Español", "README.es-ES.md"),
    ("de", "Deutsch", "README.de.md"),
    ("fr", "Français", "README.fr.md"),
    ("it", "Italiano", "README.it.md"),
    ("pl", "Polski", "README.pl.md"),
    ("zh-cn", "简体中文", "README.zh-CN.md"),
    ("ja", "日本語", "README.ja.md"),
    ("ko", "한국어", "README.ko.md"),
]


def section_blocks(text):
    lines = text.splitlines()
    starts = [i for i, line in enumerate(lines) if line.startswith("## ")]
    blocks = []
    for number, start in enumerate(starts):
        end = starts[number + 1] if number + 1 < len(starts) else len(lines)
        blocks.append("\n".join(lines[start:end]).strip())
    return blocks


def demote(block):
    result = []
    for line in block.splitlines():
        if line.startswith("### ") or line.startswith("## "):
            line = "#" + line
        result.append(line)
    return "\n".join(result)


head = [
    "# Metamorph: Creative Menu",
    "",
    '<a id="languages"></a>',
    "",
    "## Choose your language",
    "",
    "| Language | Open guide |",
    "|---|---|",
]
for code, label, _ in LANGS:
    head.append(f"| {label} | [{label}](#{code}) |")
head.extend([
    "",
    "> Choose your language above. The first section in every language is **Installation**, with the exact folder path, the required **Unsafe mods** setting, and a final TAB check.",
    "",
    "### Folder check before starting Noita",
    "",
    "The final installation must contain:",
    "",
    "```text",
    "Noita/",
    "└─ mods/",
    "   └─ metamorph_creative_menu/",
    "      ├─ mod.xml",
    "      ├─ init.lua",
    "      ├─ mod_id.txt",
    "      ├─ NoitaPatcher/",
    "      └─ files/",
    "```",
    "",
    "If you see `metamorph_creative_menu/metamorph_creative_menu/mod.xml`, the archive was extracted one folder too deep.",
    "",
    "---",
])

output = ["\n".join(head)]
for code, label, filename in LANGS:
    text = (DOCS / filename).read_text(encoding="utf-8")
    parts = section_blocks(text)
    if len(parts) < 3:
        raise RuntimeError(f"Unexpected README structure: {filename}")

    # Existing full guides use About, Requirements, Installation, then features.
    # In the combined README, installation intentionally comes first.
    ordered = [parts[2], parts[1], parts[0]] + parts[3:]
    body = "\n\n".join(demote(part) for part in ordered)
    body = body.replace("../THIRD_PARTY_NOTICES.md", "THIRD_PARTY_NOTICES.md")
    output.append(
        f'<a id="{code}"></a>\n\n## {label}\n\n{body}\n\n'
        f'[↑ Back to language selection](#languages)\n\n---'
    )

Path("README.md").write_text("\n\n".join(output).rstrip() + "\n", encoding="utf-8")

for _, _, filename in LANGS:
    (DOCS / filename).unlink()
try:
    DOCS.rmdir()
except OSError:
    pass
