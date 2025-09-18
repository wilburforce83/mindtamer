#!/usr/bin/env python3
"""
Pixelate images to a fixed 16x16 (or custom) grid and optionally scale up.

Examples:
  python3 tools/pixelate_images.py assets/images/echoes --out-dir assets/images/echoes_16 --size 16 --scale 8
  python3 tools/pixelate_images.py assets/images/items --out-dir assets/images/items_pixel --size 16 --scale 4 --square

Requires Pillow: pip install pillow
"""
from __future__ import annotations
import argparse
from pathlib import Path
from PIL import Image


def process_image(src: Path, dst: Path, size: int, scale: int, square: bool) -> None:
    dst.parent.mkdir(parents=True, exist_ok=True)
    img = Image.open(src).convert('RGBA')
    if square:
        w, h = img.size
        m = min(w, h)
        left = (w - m) // 2
        top = (h - m) // 2
        img = img.crop((left, top, left + m, top + m))
    # Downscale to small grid, then upscale with NEAREST to get crisp pixels
    small = img.resize((size, size), resample=Image.NEAREST)
    if scale > 1:
        small = small.resize((size * scale, size * scale), resample=Image.NEAREST)
    small.save(dst.with_suffix('.png'))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('input', type=str, help='Input file or directory')
    ap.add_argument('--out-dir', type=str, default='assets/images/pixelated', help='Output directory root')
    ap.add_argument('--size', type=int, default=16, help='Target pixel size, e.g., 16')
    ap.add_argument('--scale', type=int, default=4, help='Upscale factor for output previews')
    ap.add_argument('--square', action='store_true', help='Center-crop to square before pixelation')
    args = ap.parse_args()

    in_path = Path(args.input)
    out_root = Path(args.out_dir)

    if in_path.is_file():
        rel = in_path.name
        out = out_root / rel
        process_image(in_path, out, args.size, args.scale, args.square)
        print(f'Pixelated {in_path} -> {out.with_suffix(".png")}')
        return

    if in_path.is_dir():
        exts = {'.png', '.jpg', '.jpeg', '.webp'}
        files = [p for p in in_path.rglob('*') if p.suffix.lower() in exts]
        if not files:
            print('No images found.')
            return
        for p in files:
            rel = p.relative_to(in_path)
            out = out_root / rel
            process_image(p, out, args.size, args.scale, args.square)
            print(f'Pixelated {p} -> {out.with_suffix(".png")}')
        return

    print(f'Input path not found: {in_path}')


if __name__ == '__main__':
    main()

