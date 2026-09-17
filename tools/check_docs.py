#!/usr/bin/env python3
"""Doküman tutarlılığı kontrolü (docs/06 §10).

Anlamı doğrulayamaz — yalnız mekanik bozulmaları yakalar:
  1. Markdown dosyalarındaki göreli bağlantılar gerçekten var mı?
  2. CLAUDE.md'nin "oturum başında oku" listesindeki dosyalar duruyor mu?
  3. NEXT_TASKS / PROJECT_STATE'te commit karşılığı olmayan durum ifadesi
     ("commit edilmedi") kaldı mı? — iş bitip commit'lendikten sonra
     güncellenmesi unutulan satırlar bu şekilde yakalanır.

Kullanım: python3 tools/check_docs.py   (hata varsa çıkış kodu 1)
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LINK = re.compile(r"\[[^\]]*\]\(([^)]+)\)")
# Durum ifadeleri: yalnız bu dosyalarda ve yalnız açık madde satırlarında
# anlamlı; kapanmış bir paketin başlığında kalırsa bayat demektir.
STALE_MARKERS = ["commit edilmedi", "commit'lenmedi"]


def markdown_files() -> list[Path]:
    return [
        p
        for p in ROOT.rglob("*.md")
        if not any(part in {"build", ".dart_tool", "ios", "android"} for part in p.parts)
    ]


def check_links(path: Path) -> list[str]:
    errors = []
    for target in LINK.findall(path.read_text(encoding="utf-8")):
        target = target.split("#", 1)[0].strip()
        if not target or target.startswith(("http://", "https://", "mailto:")):
            continue
        if not (path.parent / target).exists():
            errors.append(f"{path.relative_to(ROOT)}: bağlantı hedefi yok → {target}")
    return errors


def check_stale_status() -> list[str]:
    errors = []
    for name in ["NEXT_TASKS.md", "PROJECT_STATE.md"]:
        path = ROOT / name
        if not path.exists():
            continue
        for i, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            # Ters tırnak içi (kuralın kendisinden söz eden satırlar) ve üstü
            # çizili geçmiş kayıt serbest.
            low = re.sub(r"`[^`]*`", "", line).lower()
            for marker in STALE_MARKERS:
                if marker in low and "~~" not in line:
                    errors.append(
                        f"{name}:{i}: '{marker}' — iş commit'lendiyse güncelle "
                        f"(bkz. docs/06 §10)"
                    )
    return errors


def main() -> int:
    errors: list[str] = []
    for path in markdown_files():
        errors += check_links(path)
    errors += check_stale_status()

    for line in errors:
        print(f"HATA {line}")
    print(f"\n{len(markdown_files())} markdown dosyası tarandı · {len(errors)} sorun")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
