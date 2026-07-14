from __future__ import annotations

import json
import sys
from pathlib import Path


data = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
mode = sys.argv[2]

if mode == "index":
    for name, doc in data["documents"].items():
        print(f"\n### {name} | paragraphs={len(doc['paragraphs'])} tables={len(doc['tables'])} images={doc['inline_shapes']}")
        for text in doc["paragraphs"]:
            if len(text) < 140 and (text[:1].isdigit() or text.isupper() or text.startswith(("Titre", "Objectif", "Vision", "Module", "Phase", "Acteur", "Règle", "Cas"))):
                print(text)
elif mode.startswith("doc:"):
    wanted = mode[4:]
    for name, doc in data["documents"].items():
        if wanted.lower() in name.lower():
            print(f"\n===== {name} =====")
            for text in doc["paragraphs"]:
                print(text)
            for i, table in enumerate(doc["tables"], 1):
                print(f"\n[TABLE {i}]")
                for row in table:
                    print(" | ".join(cell.replace("\n", " / ") for cell in row))
elif mode.startswith("md:"):
    wanted = mode[3:]
    for name, text in data["markdown"].items():
        if wanted.lower() in name.lower():
            print(f"\n===== {name} =====\n{text}")
