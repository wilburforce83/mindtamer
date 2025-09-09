# MindTamer Monster Art Bible (v1.0)

This document defines all gameplay-relevant monster families, their melee/magic variants, and the color-mapping system used to programmatically generate elemental variants from a single 64×64 base sprite (SNES-like, pixel art). It is intended as the single source of truth for art production and runtime palette swaps.

---

## Sprite Specification

- Resolution: 64×64 px, axis-aligned, no rotation or sub-pixel moves.
- Style: 16-bit SNES-era, crisp pixels, no sub-pixel AA.
- Line/outline: 1 px where used; internal lines may be 1 px with selective breaks.
- Shading: 3–4 tones per material (base, mid, shadow, highlight). Dither when helpful; avoid banding.
- Canvas: Keep ~2 px padding from the edges to allow hit-flash/outlines.
- Orientation: Face slightly right (¾ front) unless noted.
- Background: Transparent; avoid stray pixels.

---

## Element System

MindTamer uses 7 elements. Each elemental variant is a palette swap layered over a neutral base. The element primarily affects energy/glow/emissive parts, accents, and VFX (and may tint cloth/trim), while core material/skin stays within its neutral base palette so variants remain cohesive.

Elements:
- Fire
- Water
- Air
- Nature
- Metal
- Light
- Shadow

### Element Color Ramps (5 steps)
The following ramps are derived from the app palette (see `lib/theme/PALETTE.md`/`lib/theme/colors.dart`) and are intended for glow/VFX/accent swaps. Steps go from dark → highlight.

- Fire: `#993649`, `#F25565`, `#F27961`, `#F09C60`, `#F7C93E`
- Water: `#2469B3`, `#0B8BE6`, `#0BAFE6`, `#A3CCD9`, `#F0EDD8`
- Air: `#4D7A99`, `#A3CCD9`, `#96E3C9`, `#F0EDD8`, `#FFFFFF`
- Nature: `#17735F`, `#119955`, `#1BA683`, `#47CCA9`, `#96E3C9`
- Metal: `#1C284D`, `#4D7A99`, `#A3CCD9`, `#F0EDD8`, `#FFFFFF`
- Light: `#343473`, `#A3CCD9`, `#F0EDD8`, `#F7C93E`, `#FFFFFF`
- Shadow: `#00021C`, `#1C284D`, `#343473`, `#4D7A99`, `#A6216E`

Notes:
- Use the 3 middle steps for accents; reserve the darkest for self-shadow and the brightest for glows/edge hits.
- You can subtly tint cloth/leather with step 2; keep skin/metal base in neutral ranges.

### Palette Swap Slots
Every monster uses the following logical slots. Base slots rarely change between elements; Swap slots are recolored per element.

- Base slots (neutral; do not swap):
  - `base_skin_1/2/3` (creature skin/fur/chitin; 2–3 tones)
  - `base_metal_1/2` (blades/armor; neutral steel/iron)
  - `base_cloth_1/2` (pants, wraps, sashes; browns/greys)
  - `base_bone_1/2` (undead/masks/horns)
- Swap slots (elemental):
  - `swap_accent_1/2` (trim, small sigils, runes, stitching)
  - `swap_emissive_1/2` (eyes, gem cores, runes, vents)
  - `swap_vfx_1/2/3` (glows, trails, small particles)

At runtime, we recolor `swap_*` slots with the selected element ramp.

---

## Families & Variants

Each family lists core silhouette, key forms, suggested base neutrals, which swap slots to expose for elements, and how to differentiate Melee vs Magic variants.

For every family, produce 2 variants:
- Melee: grounded, weapon/limb focused, minimal emissives.
- Magic: channeling/scroll/staff/gem, visible emissives and VFX.

### 1) Slime
- Silhouette: rounded blob; wobble implied with shading; face central.
- Base: gel body in 3 tones (teal-grey neutrals: `#A3CCD9`, `#4D7A99`, `#1C284D`); eyes `#F0EDD8`.
- Swap: fill interior highlights and small bubbles (`swap_emissive`), rim sheen (`swap_accent`).
- Melee: thicker lower mass, blunt rim “punch”; tiny debris on impact.
- Magic: inner core gem + halo; more emissive bubbles (use `swap_vfx`).

### 2) Wisp
- Silhouette: small floating flare; trailing tail; central core.
- Base: neutral body `#A3CCD9` to `#F0EDD8` with soft edge.
- Swap: core, tail tip, spark motes (`swap_emissive`/`swap_vfx`).
- Melee: denser core, short tail.
- Magic: longer trail and spark ring.

### 3) Shade
- Silhouette: hooded or featureless humanoid bust; shroud.
- Base: shroud greys `#1C284D`, `#343473`; inner void `#00021C`.
- Swap: eye slit/glow, sigils on shroud (`swap_accent`, `swap_emissive`).
- Melee: spectral blade; compact cloak.
- Magic: hands together channeling; rimlighting.

### 4) Imp
- Silhouette: small biped, horns/tail.
- Base: skin `#B36159/#993649`; loincloth `#4D7A99`.
- Swap: horn tips, eyes, tail spade (`swap_accent`), hand-glow (`swap_vfx`).
- Melee: claws/dagger.
- Magic: staff or orb.

### 5) Goblin
- Silhouette: hunched, long ears.
- Base: skin olives `#B3B324/#17735F`; cloth browns.
- Swap: eye glint, weapon edge, sash trim.
- Melee: hooked blade/club.
- Magic: charm totem/scroll.

### 6) Beast (Wolf/Cat)
- Silhouette: quadruped, strong head/shoulder.
- Base: fur greys `#1C284D/#4D7A99/#A3CCD9`.
- Swap: eye glow, claw sheen, breath VFX.
- Melee: lunge posture.
- Magic: breath/roar aura.

### 7) Drake
- Silhouette: small winged dragon; wings folded (static sprite).
- Base: scales `#4D7A99/#A3CCD9`, belly `#F0EDD8`.
- Swap: wing veins, eyes, nostril plume.
- Melee: neck forward, bite.
- Magic: head back, aura plume.

### 8) Serpent
- Silhouette: coiled S; head at ¾.
- Base: scales `#1C284D/#4D7A99` with belly `#A3CCD9`.
- Swap: eyes, hood edge (if cobra), tongue tip.
- Melee: fangs bared.
- Magic: hood flare + aura.

### 9) Insectoid (Mantis/Beetle)
- Silhouette: mantis arms or beetle shell.
- Base: chitin `#4D7A99/#A3CCD9`; soft underbelly `#F0EDD8`.
- Swap: eye facets, shell lines, limb edges.
- Melee: scythe-arm raised.
- Magic: wing case open, small motes.

### 10) Myconid (Mushroom)
- Silhouette: cap/head; short body.
- Base: cap `#A3CCD9/#F0EDD8`; stem `#F0EDD8/#4D7A99`.
- Swap: gill glow, spores (`swap_vfx`).
- Melee: cap-ram.
- Magic: spore puff.

### 11) Spriggan (Wood Fae)
- Silhouette: twiggy humanoid; leaf mantle.
- Base: wood `#B36159/#B38F24`; leaf `#7497A6` neutral.
- Swap: leaf runes, eye/sap glow.
- Melee: thorn arm.
- Magic: wreath halo.

### 12) Golem (Stone/Metal)
- Silhouette: blocky; core gem.
- Base: stone `#1C284D/#4D7A99`; metal plates `#A3CCD9`.
- Swap: core gem, seam glows, cracks.
- Melee: hammer fist.
- Magic: chest-core beam (implied with glows).

### 13) Gargoyle
- Silhouette: perched, wings tucked.
- Base: stone greys.
- Swap: eye slits, wing rune trims.
- Melee: clawed pounce.
- Magic: wing-edge glow.

### 14) Harpy
- Silhouette: winged humanoid; top-down wing arcs.
- Base: feathers greys; leather straps.
- Swap: feather tips, eye, claw edge.
- Melee: talon strike.
- Magic: gust ring (`swap_vfx`).

### 15) Undead (Skeleton/Revenant)
- Silhouette: bones + tattered cloth.
- Base: bone `#F0EDD8/#A3CCD9`; cloth `#4D7A99`.
- Swap: eye sockets, rune trims on cloth, blade sheen.
- Melee: rust blade.
- Magic: soul flame.

### 16) Construct (Automaton)
- Silhouette: compact robot; rune plate.
- Base: metal `#A3CCD9/#4D7A99`; joints `#1C284D`.
- Swap: visor, runes, exhaust plumes.
- Melee: riveted punch.
- Magic: chest plate focus.

---

## Melee vs Magic Differentiators
- Melee: forward-weighted silhouettes, weapon/limb emphasis, limited emissive use (mostly `swap_accent`), dust/punch puffs (`swap_vfx` step 1–2).
- Magic: upright or back-lean, clear channeling point (hands/gem/eyes), larger emissive areas (use step 3–5 of ramp), small spark/streak VFX.

---

## Neutral Base Palettes (Per Material)
- Skin/Fur/Chitin: `#F0EDD8`, `#A3CCD9`, `#4D7A99`, `#1C284D`
- Bone/Horn: `#F0EDD8`, `#A3CCD9`
- Cloth/Leather: `#B36159`, `#4D7A99`, `#1C284D`
- Metal (steel/iron): `#A3CCD9`, `#4D7A99`, edge hits `#F0EDD8`

Keep these consistent across elements to avoid palette fighting; all “magic” comes from the swap slots.

---

## Element Application Guide (What to Recolor)
For each element, map `swap_accent_*`, `swap_emissive_*`, `swap_vfx_*` to that element’s ramp. Suggested placements:

- Fire: eyes, inner-core gems, weapon edge hits, breath/sparks, runes.
- Water: eyes, scallop lines, droplet motes, low-intensity rimlights.
- Air: wing tips, feather/cloth trim, gust rings, misty hand glow.
- Nature: leaf trims, sap veins, thorn tips, spores.
- Metal: runes on armor, vent lines, blade energy; keep metal mass neutral steel.
- Light: eyes/halo, fabric trim, beacon orbs, tiny star motes.
- Shadow: eye slits, negative-space auras, crack interiors.

---

## Production Checklist (per Monster)
1) Create neutral 64×64 base (melee and magic) with base palettes.
2) Mark pixels for `swap_accent`, `swap_emissive`, `swap_vfx` (use consistent layers or indices).
3) Export as PNG with transparency; keep a palette guide swatch in the file margin (can be removed post-export).
4) Validate at 1× and 2×; no stray pixels; silhouette strong.
5) Test quick element swaps using the ramps above.

---

## Delivery & File Naming
- `family_variant_element.png`
  - family: slime, wisp, shade, imp, goblin, beast, drake, serpent, insectoid, myconid, spriggan, golem, gargoyle, harpy, undead, construct
  - variant: melee | magic
  - element: neutral (for base), fire|water|air|nature|metal|light|shadow (runtime swaps will generate these programmatically; provide at least neutral for painting reference)
- Example: `golem_melee_neutral.png`, `shade_magic_neutral.png`

---

## Notes on Runtime Integration
- The engine keeps material/skin as provided and replaces `swap_*` slots with the element ramp.
- For hits/charging, we can temporarily push 1 step brighter along the ramp.
- Fused monsters (future) can adopt blended naming (e.g., “Twilight Revenant”) while retaining the underlying family art with element ramp.

---

If you need additional families (e.g., boss-only forms) or deeper per-family callouts (horn variants, alternate heads), add them here under a `### 17+` section and keep the same structure.

