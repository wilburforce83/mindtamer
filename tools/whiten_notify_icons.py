#!/usr/bin/env python3
"""
Whiten all non-transparent pixels in every ic_stat_notify.png and force them fully opaque.

Behavior:
- For any pixel with alpha > 0: set RGBA -> (255, 255, 255, 255)
- For alpha == 0: leave transparent (background remains transparent)

Scope:
- Only processes files under android/app/src/main/res to avoid build intermediates.
"""
from __future__ import annotations
import os
from PIL import Image


def whiten_png(path: str) -> bool:
    img = Image.open(path).convert('RGBA')
    w, h = img.size
    pixels = img.load()
    changed = False
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            if a != 0:
                # Force solid white with full opacity
                if (r, g, b, a) != (255, 255, 255, 255):
                    pixels[x, y] = (255, 255, 255, 255)
                    changed = True
    if changed:
        # Preserve original mode and metadata as much as practical.
        img.save(path)
    return changed


def main() -> None:
    root = os.getcwd()
    base = os.path.join(root, 'android', 'app', 'src', 'main', 'res')
    targets = []
    for dirpath, _, filenames in os.walk(base):
        for fn in filenames:
            if fn == 'ic_stat_notify.png':
                targets.append(os.path.join(dirpath, fn))
    if not targets:
        print('No ic_stat_notify.png files found.')
        return
    changed = 0
    for p in sorted(targets):
        try:
            if whiten_png(p):
                changed += 1
                print(f'Whitened: {p}')
            else:
                print(f'Unchanged: {p} (already white)')
        except Exception as e:
            print(f'ERROR processing {p}: {e}')
    print(f'Done. Processed {len(targets)} file(s); modified {changed}.')


if __name__ == '__main__':
    main()
