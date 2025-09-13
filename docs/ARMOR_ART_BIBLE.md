# MindTamer Armor Art Bible (32×32 Icons)

This document defines the armor and accessories icon set: head, chest, hands, legs, feet, plus necklaces and rings. Includes class armor sets and neutral accessories. Icons must be clear at 32×32 px and adhere to shared pixel art rules.

## Global Style
- Canvas: 32×32 px PNG, transparent; 1 px safe padding.
- Palette: Pineapple 32; metals (steel/iron/bronze/gold), cloth/leather, gems.
- Outline: 1 px where needed; crisp edges; minimal dithering.
- Light: top‑left; use 2–3 shades per material.
- Pose: Present single piece centered (helm front 3/4, chest front, gloves pair, greaves pair, boots pair). Necklaces and rings at 30–45°.
- Naming: `assets/images/armor/<slot>/<key>_32.png` and `assets/images/accessories/<rings|necklaces>/<key>_32.png`

## Blank Icons
Create neutral empties to match existing UI slot empties (ring/hand/chest exist). Add:
- `assets/images/ui/slots/head_empty_32.png`
- `assets/images/ui/slots/neck_empty_32.png`
- `assets/images/ui/slots/legs_empty_32.png`
- `assets/images/ui/slots/feet_empty_32.png`
- (Existing) `ring_empty_32.png`, `hand_empty_32.png`, `chest_empty_32.png`

---

## Class Armor Sets
Each class receives 3 named sets (Early, Mid, Late). Each set includes 5 pieces: Head, Chest, Hands, Legs, Feet. Accessories are mostly neutral (see below).
For each set, list: theme, materials, accent color, motif. Keep silhouettes distinct and readable at 32×32.

### Warden (plate + tabard)
- Bulwark Set (Early): steel plate + blue tabard; lion motif; rounded sallet helm; riveted gauntlets; greaves + boots.
- Keepwatch Set (Mid): heavier pauldrons; brass trims; kite textures; visor slit.
- Bastion Set (Late): gold inlay; crest on breastplate; fluted greaves; sabatons with toe caps.

### Trickster (leather + cloaks)
- Streetshade Set (Early): hooded cowl; studded leather; fingerless gloves; dark greaves; soft boots.
- Jester’s Guile (Mid): masked hood; striped trims; bracer wraps; knee guards.
- Viperstep (Late): scale‑leather mix; emerald accents; sleek boots.

### Sage (robes + arcane trims)
- Arcanist Weave (Early): circlet; robe with sash; soft gloves; layered skirts; slippers.
- Glyphsong (Mid): rune trim; shoulder mantle; wrist wraps; patterned hem.
- Starweft (Late): star inlays; high collar; glowing thread accents.

### Sentinel (mail + plate)
- Wallguard (Early): nasal helm; mail hauberk + plate chest; leather gloves; mail leggings; iron boots.
- Watchtower (Mid): visored helm; reinforced chest; braced gauntlets; plated cuisses.
- Fortitude (Late): heavy bevels; brass edging; angular greaves.

### Seer (mystic vestments)
- Veilseer (Early): veil circlet; layered robe vest; beaded gloves; silk trousers; sandals.
- Loom of Fate (Mid): eye motif mantle; bangled gloves; tassel hems.
- Oracle’s Loom (Late): silver inlays; crescent motifs; flowing sleeves.

### Artificer (leather + brass fittings)
- Tinker’s Rig (Early): goggles band; reinforced vest; tool gloves; strap leggings; steel‑toe boots.
- Gearwright (Mid): plate‑reinforced chest; gear buckles; gauntlet plates; knee braces.
- Aetherframe (Late): arcanotech trims; coil motifs; widget clasps.

### Empath (vestments + charms)
- Healer’s Habit (Early): soft coif; white tunic; bead gloves; long skirt; slippers.
- Mercywrap (Mid): padded sleeves; ribbon hems; charm tassels.
- Seraphra (Late): gold trim; haloed circlet; flowing cuffs.

### Oracle (judgement vestments)
- Edict (Early): laurel circlet; tabard chest; cuffed gloves; pleated legs; sandals.
- Tribunal (Mid): scale over‑robe; plate cuffs; greave wraps.
- Radiant Decree (Late): sun inlays; ornate chest; polished boots.

### Shadow (assassin attire)
- Duskstalk (Early): wrapped hood; shadow jerkin; leather gloves; tight greaves; softstep boots.
- Nightwisp (Mid): mask visor; ribbed chest; wrist darts; split‑leg wraps.
- Umbral Muse (Late): black silk; violet trims; talon boots.

### Alchemist (aprons + glassware)
- Workbench (Early): bandanna; apron chest; fingerless gloves; patched legs; boots.
- Retortcoat (Mid): glass vials trim; reinforced cuffs; utility pockets.
- Philosopher (Late): fine leather; gold buckles; measured hems.

---

## Accessories (Neutral)
Design 12 necklaces and 20 rings with diverse silhouettes and stones.

### Necklaces (12)
1. Sunburst Medallion — gold disk; white gem.
2. Moontear Pendant — silver crescent; blue gem.
3. Lion Crest — brass shield; red enamel.
4. Leaf Charm — bronze leaf; green stone.
5. Gear Locket — brass gear; glass window.
6. Spirit Beads — wooden strand; tassel.
7. Star Prism — crystal; rainbow glint.
8. Hex Sigil — purple rune tile.
9. Feather Tether — silver feather charm.
10. Wyrm Fang — tooth on cord.
11. Anchor Chain — iron link + anchor.
12. Heart Reliquary — gold heart; red gem.

### Rings (20)
Mix signet, bands, set stones; vary thickness and gem shapes (round/square/oval/teardrop).
1. Iron Band — plain iron; utilitarian.
2. Steel Knot — twisted band; steel.
3. Bronze Signet — square face; crest.
4. Silver Leaf — engraved leaf; silver.
5. Gold Circlet — thin gold; subtle sheen.
6. Ruby Heart — red round gem; gold prongs.
7. Sapphire Tear — teardrop blue; silver band.
8. Emerald Square — square green; brass bezel.
9. Amethyst Oval — purple oval; silver.
10. Topaz Sun — yellow round; gold rays.
11. Onyx Seal — black stone; iron.
12. Moonstone Halo — pale white; silver halo.
13. Gear Ring — tiny cog; brass.
14. Feather Wrap — etched feather; silver.
15. Wyrm Scale — scale texture; dark steel.
16. Runic Band — etched runes; glow dot.
17. Twin Bands — interlocked double rings.
18. Signet of Light — white gem; gold.
19. Signet of Shadow — violet gem; blackened steel.
20. Prism Band — tiny prism; rainbow glint.

---

## Quantity Targets
- Class Sets: 10 classes × 3 sets × 5 pieces = 150 icons.
  - Slot breakdown: Head 30, Chest 30, Hands 30, Legs 30, Feet 30.
- Necklaces: 12 icons.
- Rings: 20 icons.
- Blank placeholders: 4 new empties (head/neck/legs/feet). Existing ring/hand/chest already present.
- Total Armor/Accessory Icons ≈ 186.

## QA Checklist
- 32×32, transparent, centered piece; 1 px margin
- Silhouette reads at 1×; minimal noise
- Consistent light/shades; material ramps correct
- File path/slot correct; snake‑case keys
