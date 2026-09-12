#!/usr/bin/env python3
"""Verify that redistributable MCM packages carry the project license and attribution."""

from __future__ import annotations

import sys
from pathlib import Path


def main() -> int:
    root = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path(__file__).resolve().parent.parent
    license_path = root / "LICENSE.txt"
    notice_path = root / "NOTICE.txt"

    missing = [path.name for path in (license_path, notice_path) if not path.is_file()]
    if missing:
        raise SystemExit("license_contract=FAIL missing=" + ",".join(missing))

    license_text = license_path.read_text(encoding="utf-8")
    notice_text = notice_path.read_text(encoding="utf-8")

    required_license_terms = (
        "Metamorph Creative Menu Attribution License 1.0",
        "commercial or non-commercial purpose",
        "Original developer: zerodancing",
        "https://github.com/zerodancing/Metamorph-Creative-Menu",
    )
    for text in required_license_terms:
        if text not in license_text:
            raise SystemExit(f"license_contract=FAIL LICENSE.txt missing {text!r}")

    required_notice_terms = (
        "Original developer: zerodancing",
        "https://github.com/zerodancing",
        "https://github.com/zerodancing/Metamorph-Creative-Menu",
    )
    for text in required_notice_terms:
        if text not in notice_text:
            raise SystemExit(f"license_contract=FAIL NOTICE.txt missing {text!r}")

    print("license_contract=PASS attribution=zerodancing commercial_use=true")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
