#!/usr/bin/env python3
"""
Clean transparency artifacts from MindTamer image assets.

What it does:
- Zeroes RGB values for fully transparent pixels so hidden matte colors do not
  bleed when Flutter scales sprites.
- Removes stray non-transparent pixels that sit too far from any solid painted
  area. This strips common export-guide lines and border ghosts without
  redrawing the sprite itself.

Usage:
  python3 tools/clean_sprite_transparency.py --dry-run
  python3 tools/clean_sprite_transparency.py --apply

Requires Pillow:
  python3 -m pip install Pillow
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
from pathlib import Path
from collections import deque

from PIL import Image


ASSET_ROOT = Path("assets/images")
RGB_SANITIZE_ROOTS = [ASSET_ROOT]
ALPHA_CLEAN_ROOTS = [
    ASSET_ROOT / "accessories",
    ASSET_ROOT / "armor",
    ASSET_ROOT / "items",
    ASSET_ROOT / "monsters",
    ASSET_ROOT / "players",
    ASSET_ROOT / "weapons",
]
CORE_ALPHA = 128
KEEP_RADIUS = 3
MATTE_BRIGHTNESS = 210
MATTE_TOLERANCE = 18


@dataclass
class ImageChange:
    path: Path
    removed_pixels: int = 0
    sanitized_pixels: int = 0

    @property
    def changed(self) -> bool:
        return self.removed_pixels > 0 or self.sanitized_pixels > 0


def iter_pngs(roots: list[Path]) -> list[Path]:
    seen: set[Path] = set()
    files: list[Path] = []
    for root in roots:
        if not root.exists():
            continue
        for path in sorted(root.rglob("*.png")):
            if path not in seen:
                seen.add(path)
                files.append(path)
    return files


def build_keep_mask(alpha: list[list[int]], core_alpha: int, radius: int) -> list[list[bool]]:
    height = len(alpha)
    width = len(alpha[0]) if height else 0
    keep = [[False] * width for _ in range(height)]

    for y, row in enumerate(alpha):
        for x, value in enumerate(row):
            if value < core_alpha:
                continue
            y0 = max(0, y - radius)
            y1 = min(height, y + radius + 1)
            x0 = max(0, x - radius)
            x1 = min(width, x + radius + 1)
            for ny in range(y0, y1):
                keep_row = keep[ny]
                for nx in range(x0, x1):
                    keep_row[nx] = True
    return keep


def sanitize_rgb(img: Image.Image) -> int:
    pixels = img.load()
    width, height = img.size
    changed = 0
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            if a == 0 and (r or g or b):
                pixels[x, y] = (0, 0, 0, 0)
                changed += 1
    return changed


def is_border_matte(r: int, g: int, b: int, a: int) -> bool:
    if a == 0:
        return False
    hi = max(r, g, b)
    lo = min(r, g, b)
    avg = (r + g + b) // 3
    return hi - lo <= MATTE_TOLERANCE and avg >= MATTE_BRIGHTNESS


def strip_border_matte(img: Image.Image) -> int:
    width, height = img.size
    pixels = img.load()
    seen = [[False] * width for _ in range(height)]
    queue: deque[tuple[int, int]] = deque()

    for x in range(width):
        for y in (0, height - 1):
            r, g, b, a = pixels[x, y]
            if not seen[y][x] and is_border_matte(r, g, b, a):
                seen[y][x] = True
                queue.append((x, y))

    for y in range(height):
        for x in (0, width - 1):
            r, g, b, a = pixels[x, y]
            if not seen[y][x] and is_border_matte(r, g, b, a):
                seen[y][x] = True
                queue.append((x, y))

    removed = 0
    while queue:
        x, y = queue.popleft()
        pixels[x, y] = (0, 0, 0, 0)
        removed += 1
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if nx < 0 or ny < 0 or nx >= width or ny >= height or seen[ny][nx]:
                continue
            r, g, b, a = pixels[nx, ny]
            if is_border_matte(r, g, b, a):
                seen[ny][nx] = True
                queue.append((nx, ny))
    return removed


def clean_alpha(img: Image.Image, core_alpha: int, radius: int) -> int:
    width, height = img.size
    pixels = img.load()
    alpha = [[pixels[x, y][3] for x in range(width)] for y in range(height)]
    keep = build_keep_mask(alpha, core_alpha, radius)

    removed = 0
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            if a > 0 and not keep[y][x]:
                pixels[x, y] = (0, 0, 0, 0)
                removed += 1
    return removed


def process_image(
    path: Path,
    *,
    sanitize_only: bool,
    core_alpha: int,
    radius: int,
    apply_changes: bool,
) -> ImageChange:
    img = Image.open(path).convert("RGBA")
    change = ImageChange(path=path)
    change.sanitized_pixels = sanitize_rgb(img)
    if not sanitize_only:
        change.removed_pixels = strip_border_matte(img)
        change.removed_pixels += clean_alpha(img, core_alpha, radius)
    if apply_changes and change.changed:
        img.save(path)
    return change


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--apply", action="store_true", help="Write cleaned files back to disk.")
    parser.add_argument("--dry-run", action="store_true", help="Report changes without writing files.")
    parser.add_argument("--verbose", action="store_true", help="Print every changed file.")
    parser.add_argument("--core-alpha", type=int, default=CORE_ALPHA)
    parser.add_argument("--radius", type=int, default=KEEP_RADIUS)
    args = parser.parse_args()

    if args.apply and args.dry_run:
        raise SystemExit("Choose either --apply or --dry-run, not both.")

    apply_changes = args.apply
    sanitize_paths = iter_pngs(RGB_SANITIZE_ROOTS)
    alpha_paths = set(iter_pngs(ALPHA_CLEAN_ROOTS))

    total = 0
    changed = 0
    removed_files = 0
    sanitized_files = 0
    removed_pixels = 0
    sanitized_pixels = 0

    for path in sanitize_paths:
        total += 1
        result = process_image(
            path,
            sanitize_only=path not in alpha_paths,
            core_alpha=args.core_alpha,
            radius=args.radius,
            apply_changes=apply_changes,
        )
        if not result.changed:
            continue
        changed += 1
        if result.removed_pixels:
            removed_files += 1
            removed_pixels += result.removed_pixels
        if result.sanitized_pixels:
            sanitized_files += 1
            sanitized_pixels += result.sanitized_pixels
        if args.verbose:
            print(
                f"{path}: removed={result.removed_pixels} "
                f"sanitized={result.sanitized_pixels}"
            )

    mode = "Applied" if apply_changes else "Would update"
    print(
        f"{mode} {changed} of {total} PNGs. "
        f"Artifact cleanup: {removed_files} files / {removed_pixels} pixels. "
        f"Transparent RGB cleanup: {sanitized_files} files / {sanitized_pixels} pixels."
    )


if __name__ == "__main__":
    main()
