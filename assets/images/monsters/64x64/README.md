Monster Sprites (64x64)
=======================

Put all 64×64 monster images here. They will be bundled by Flutter via `pubspec.yaml` (the `assets/images/` folder is already included).

Recommended structure (helps filtering by element/type):

- assets/images/monsters/64x64/<element>/...
  - File names should include the monster type for better matching.
  - Examples:
    - `assets/images/monsters/64x64/fire/fire_gremlin_01.png`
    - `assets/images/monsters/64x64/water/water_serpent_a.png`
    - `assets/images/monsters/64x64/shadow/shadow_wisp_3.webp`

If you don’t want subfolders, keep names descriptive so both the element and type are present, e.g. `goblin_fire_01.png` or `fire_goblin_a.png`.

Runtime selection rules (MonsterImageService):
- On first encounter of a generated monster display name, we deterministically pick one image from this folder that best matches its `element` and `type`.
- The chosen asset path is stored in a Hive box (`monster_image_map`), so the same name always resolves to the same image thereafter.
- Multiple names can point to the same image (intended); a name will never change its assigned image.

Supported formats: `.png` and `.webp`.

