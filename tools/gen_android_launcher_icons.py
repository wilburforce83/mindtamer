#!/usr/bin/env python3
from pathlib import Path
from PIL import Image

def main():
    root = Path(__file__).resolve().parents[1]
    src = root / 'assets/images/app_icon.png'
    res_dir = root / 'android/app/src/main/res'

    if not src.exists():
        raise SystemExit(f"Source icon not found: {src}")

    sizes = {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192,
    }

    img = Image.open(src).convert('RGBA')

    updated = []
    for folder, px in sizes.items():
        out_dir = res_dir / folder
        out_dir.mkdir(parents=True, exist_ok=True)
        # Standard icon
        out_png = out_dir / 'ic_launcher.png'
        icon = img.copy().resize((px, px), Image.LANCZOS)
        icon.save(out_png)
        updated.append(str(out_png))
        # Round variant (if present, update it too)
        out_png_round = out_dir / 'ic_launcher_round.png'
        if out_png_round.exists():
            icon_round = img.copy().resize((px, px), Image.LANCZOS)
            icon_round.save(out_png_round)
            updated.append(str(out_png_round))

    print("Updated icons:\n" + "\n".join(updated))

if __name__ == '__main__':
    main()

