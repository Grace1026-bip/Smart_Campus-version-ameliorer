from pathlib import Path
from zipfile import ZipFile

root = Path(__file__).resolve().parents[1]
out = root / 'tmp' / 'media'
out.mkdir(parents=True, exist_ok=True)
for p in sorted(root.rglob('*.docx')):
    if 'tmp' in p.parts or 'output' in p.parts:
        continue
    with ZipFile(p) as z:
        for n in z.namelist():
            if n.startswith('word/media/'):
                stem = p.stem.split('–')[0].strip().replace('.', '_')
                target = out / f"{stem}_{Path(n).name}"
                target.write_bytes(z.read(n))
                print(target)
