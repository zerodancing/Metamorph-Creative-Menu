"""Summarize exact-path MOBS review verdicts from an Metamorph: Creative Menu diagnostics log.

Usage:
    python tests/creature_review_report.py /path/to/metamorph_creative_menu_v14_1_diagnostics.log

The last explicit review verdict for each path wins. This tool never guesses that a
crash means UNSAFE; a hard exit can have unrelated causes. It separately prints the last
transform attempt so a human can inspect it after a crash.
"""
from pathlib import Path
import re
import sys

if len(sys.argv) < 2:
    raise SystemExit("usage: creature_review_report.py <diagnostics.log>")

log_path = Path(sys.argv[1])
text = log_path.read_text(encoding="utf-8", errors="replace")
review_re = re.compile(r"action=creature\.review\s+verdict=(safe|unsafe|retest)\s+path=(.*?)\s+id=")
begin_re = re.compile(r"action=creature\.transform\.begin\s+path=(.*?)\s+target=(\S+)")

verdicts = {}
for match in review_re.finditer(text):
    verdicts[match.group(2).strip()] = match.group(1)

last_begin = None
for match in begin_re.finditer(text):
    last_begin = (match.group(1).strip(), match.group(2).strip())

for verdict in ("safe", "unsafe", "retest"):
    values = sorted(path for path, value in verdicts.items() if value == verdict)
    print(f"[{verdict.upper()}] count={len(values)}")
    for path in values:
        print(path)

if last_begin is not None:
    print("[LAST_TRANSFORM_ATTEMPT]")
    print(f"requested={last_begin[0]}")
    print(f"target={last_begin[1]}")
