#!/usr/bin/env python3
"""
Extract the 7-Zip SFX package (Occlusion01.exe) produced by the dataset
share, pulling out the inner .bag file.

Usage:
  python3 extract_sfx.py <sfx.exe> <output_dir>
"""

import pathlib
import sys
import tempfile

import py7zr

SIG = b"\x37\x7a\xbc\xaf\x27\x1c"


def main():
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(1)
    src = pathlib.Path(sys.argv[1])
    out_dir = pathlib.Path(sys.argv[2])
    out_dir.mkdir(parents=True, exist_ok=True)

    with src.open("rb") as f:
        head = f.read(2 * 1024 * 1024)
    off = head.find(SIG)
    if off < 0:
        print("No 7z signature found; not an SFX archive?", file=sys.stderr)
        sys.exit(1)
    print(f"7z signature at offset {off}")

    with tempfile.NamedTemporaryFile(suffix=".7z", delete=False) as tmp:
        tmp_path = pathlib.Path(tmp.name)
    with src.open("rb") as fin, tmp_path.open("wb") as fout:
        fin.seek(off)
        while True:
            chunk = fin.read(8 * 1024 * 1024)
            if not chunk:
                break
            fout.write(chunk)

    try:
        with py7zr.SevenZipFile(tmp_path) as z:
            print("archive files:", z.getnames())
            z.extractall(out_dir)
    finally:
        tmp_path.unlink(missing_ok=True)

    print("Extracted to", out_dir)
    for p in sorted(out_dir.rglob("*")):
        if p.is_file():
            print(f"  {p.name}  {p.stat().st_size} bytes")


if __name__ == "__main__":
    main()
