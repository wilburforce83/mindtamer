Monster Sprites (64x64)
=======================

Place your static 64×64 monster images here. The game will scan this directory (and also `assets/images/monsters/` for compatibility) to select images.

Recommended layout for best matching:
- `assets/monsters/<element>/...`
  - Include the monster type in filenames.
  - Examples:
    - `assets/monsters/fire/fire_gremlin_01.png`
    - `assets/monsters/water/water_serpent_a.webp`

Selection rules:
- On first encounter of a generated monster display name, a deterministic pick is made from images that best match its `element` and `type`.
- The chosen asset path is stored in Hive (`monster_image_map`), keeping the name → image mapping stable across sessions.
- Many names may map to the same image, but a name maps to exactly one image.

Formats supported: `.png`, `.webp`.

