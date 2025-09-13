# MindTamer Player Character Art Bible (v1.0)

This document defines the requirements for the player character art set. It focuses on a clean, consistent static sprite for each class (male and female variants), with strict palette usage to enable runtime color-swaps for hair and armor trim.

---

## Canvas & Style

- Resolution: 64×64 px per character, static (no animation for now).
- Orientation: ¾ front, facing slightly right (same as monsters), centered.
- Padding: Keep ~2 px safe padding from edges (for hit flashes, outlines).
- Pixel style: SNES‑like, crisp pixels, no sub‑pixel anti‑aliasing.
- Line/outline: Prefer 1 px lines; break lines where it helps readability.
- Shading: 3–4 tones per material (base, mid, shadow, highlight). Use light dithering when helpful; avoid banding.

---

## Palette Policy (3‑Tone Authoring Keys)

Author sprites with Pineapple 32 for all base materials, except the three runtime‑swappable areas, which MUST use the exact 3‑tone keys below. These keys let the engine remap hair/skin choices and weapon element glow.

Rules
- Use only the exact hexes for each key ramp (3 tones each).
- Linework uses INK only.
- All non‑key areas (clothing, armor, metal, fabric, etc.) use Pineapple 32.
- Weapon glows/VFX use WEAPON_GLOW only.

Authoring Key Ramps (Exact Hexes, 3 tones dark→mid→light)
- INK: ["#111111"]
- HAIR: ["#FF007F", "#FF3399", "#FF66B2"]
- SKIN: ["#6E00FF", "#8C33FF", "#A966FF"]
- WEAPON_GLOW: ["#11BEA3", "#1FD9BC", "#33FFE2"]

Tip: you may keep a small 1‑px swatch strip for these keys at the bottom margin during review; remove before ship.

---

## Materials & Key Usage

- Hair/beards: HAIR ramp only (3 tones). Keep clusters contiguous.
- Skin (face/neck/hands if bare): SKIN ramp only (3 tones). If hands are gloved, paint with normal Pineapple 32 materials instead.
- Weapon magical accents (runes/edge glows/cores/VFX): WEAPON_GLOW only (3 tones). Weapon mass (metal/wood) uses Pineapple 32.
- All other surfaces: Pineapple 32.

Do
- Keep keys isolated; no HAIR/SKIN/WEAPON_GLOW in non‑target areas.
- Use INK for outlines and interior linework.

Don’t
- Don’t introduce additional off‑palette ramps.
- Don’t anti‑alias key edges with non‑key colors; blend inside the key ramp.

---

## Classes & Variants (Use In‑Game Classes)

For each class below (matching the game), ship two variants: Male (M) and Female (F). Class silhouettes should be distinct; M vs F differences are subtle proportion changes. Equipment silhouettes stay the same across genders.

General character framing (all classes):
- Feet planted and readable; slight contrapposto is fine.
- Head/face readable at 1×; avoid micro‑details.
- Weapon in hand(s), readable silhouette.

Classes (exact keys used in the game):
1) Sage
   - Read: contemplative caster; layered robe + sash with subtle talismans.
   - Weapon: long staff with faceted crystal or open grimoire held forward.
   - Styling: flowing sleeves, ribboned sash motion; inscribed sigils on staff.
   - Paint: Robes/hem/headgear in Pineapple 32; hair uses HAIR keys; staff mass in Pineapple 32; crystal and runes use WEAPON_GLOW.

2) Warden
   - Read: stalwart defender in plate + tabard/banner.
   - Weapon: sword + kite/heater shield; shield dominates silhouette.
   - Styling: hammered plate, bold heraldry, cape clasp.
   - Paint: Armor/tabard/helm/boots in Pineapple 32; hair uses HAIR; sword/shield mass in Pineapple 32; faint warding lines use WEAPON_GLOW.

3) Trickster
   - Read: agile rogue; light leathers; hood or mask variant.
   - Weapon: twin daggers (one forward, one back) or dagger + throwing blade.
   - Styling: asymmetry, straps, dangling charm.
   - Paint: Leathers/hood/boots in Pineapple 32; hair uses HAIR; blade mass in Pineapple 32; trick runes use WEAPON_GLOW.

4) Seer
   - Read: farsighted mystic; layered robes, calm stance.
   - Weapon: scrying orb or short wand; off‑hand open palm.
   - Styling: eye motif, constellation pins.
   - Paint: Robes/diadem in Pineapple 32; hair uses HAIR; wand mass in Pineapple 32; orb aura uses WEAPON_GLOW.

5) Artificer
   - Read: inventive maker; leather apron with inset plates; goggles.
   - Weapon: smith’s hammer or wrench‑staff hybrid.
   - Styling: rivets, pockets, vials; subtle steam vents.
   - Paint: Apron/plates/goggles/boots in Pineapple 32; hair uses HAIR; tool mass in Pineapple 32; energized runes use WEAPON_GLOW.

6) Empath
   - Read: heart‑led healer; soft robe with flowing sash, beads/rope.
   - Weapon: charm‑topped staff or small focus.
   - Styling: soft arcs, pendant talisman.
   - Paint: Robe/sash/headpiece in Pineapple 32; hair uses HAIR; staff mass in Pineapple 32; charm light uses WEAPON_GLOW.

7) Sentinel
   - Read: disciplined guard; brigandine/chain with short cloak.
   - Weapon: polearm (spear/halberd) to distinguish from Warden.
   - Styling: squared stance, tidy insignia.
   - Paint: Brigandine/cloak/tassets/greaves/helmet in Pineapple 32; hair uses HAIR; polearm mass in Pineapple 32; oathmark lines use WEAPON_GLOW.

8) Oracle
   - Read: ordered scholar; clean robe lines and layered collar.
   - Weapon: runic tablet/book or scepter.
   - Styling: geometric trims, symmetric motifs.
   - Paint: Robes/coronet in Pineapple 32; hair uses HAIR; scepter/tablet mass in Pineapple 32; glyphs use WEAPON_GLOW.

9) Shadow
   - Read: assassin; deep hood, layered cloth, wrapped limbs.
   - Weapon: short sword or dagger + thrown blade.
   - Styling: strong negative space, banding.
   - Paint: Wraps/leggings/boots/hood in Pineapple 32; hair uses HAIR; blade mass in Pineapple 32; umbral edge uses WEAPON_GLOW.

10) Alchemist
   - Read: nimble tinkerer with satchel and vials.
   - Weapon: flask/bomb in throwing pose; off‑hand steadies satchel.
   - Styling: swinging straps, liquid slosh highlights.
   - Paint: Coat/apron/trousers/boots/cap/goggles in Pineapple 32; hair uses HAIR; flask mass in Pineapple 32; liquid/glass glints use WEAPON_GLOW.

Optional future classes can follow this same structure.

---

## Male vs Female Guidelines

- Silhouette: F slightly narrower shoulders/waist taper; M slightly broader torso. Keep feet/height consistent.
- Armor: identical coverage and readability; do not remove protection for F variants.
- Faces/hair: allow different hair shapes per variant; keep hair ramp usage consistent.

---

## Color Compliance QA

- Verify only the three key ramps (HAIR, SKIN, WEAPON_GLOW) appear in key areas; all other pixels are Pineapple 32 or INK.
- Outline uses INK only.
- Use at least two steps of each key ramp for readability.
- Optional: keep a key swatch strip at the bottom for review builds.

---

## File Naming & Folders

Place files under `assets/images/characters/` using the following naming:

- `assets/images/characters/<class>/<class>_<gender>_base.png`
  - `<class>`: warrior, ranger, rogue, mage, cleric, paladin, monk, artificer
  - `<gender>`: m | f
  - Example: `assets/images/characters/warrior/warrior_m_base.png`

Notes:
- Keep hair and trim key swatch strips in the image margin during review: add two 3‑pixel‑tall horizontal strips at the bottom (Hair above Trim), aligned right. These can be removed pre‑ship.
- Transparent background; no stray pixels.

---

## Delivery Checklist (Per Class, M & F)

1) 64×64 PNG, transparent background.
2) Only the defined Authoring Key Ramps used; no other colors.
3) Hair uses HAIR ramp only; hands use HANDS; boots FEET; etc.
4) Weapons: WEAPON_BODY for mass, WEAPON_GLOW for all magic/glints.
5) Weapon held and readable; class silhouette clear at 1×.
6) 2 px safe padding respected.
7) Optional zone swatch strip included for review.

---

## Future Notes

- Runtime will map these keys to Pineapple 32/material palettes and user options (hair and outfit themes).
- Future upgrades may recolor CHEST_ARMS/LEGS/HEADGEAR independently; keeping zones clean enables this.
- Full armor piece swapping may come later; for now, show default class gear and keep silhouettes iconic.
- If animation is added, keep keys/ramp steps stable; no new colors.
