from pathlib import Path
from zipfile import ZipFile

root = Path(__file__).resolve().parents[1]
for p in sorted(root.rglob('*.docx')):
    if 'tmp' in p.parts or 'output' in p.parts:
        continue
    with ZipFile(p) as z:
        media = [n for n in z.namelist() if n.startswith('word/media/')]
    print(f"{p.relative_to(root)}: {len(media)} image(s) {media}")
