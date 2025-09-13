# MindTamer Item Art Bible (32×32 Icons)

This document defines the complete set of non‑equipment items (no weapons or armor) and the visual rules for icon production. These icons are used in inventories, loot, quick slots, and battle items. Style is consistent with the existing player/monster art bibles: crisp SNES‑era pixel art at 32×32 px, transparent background, readable silhouettes at 1× scale.

## Art Direction
- Canvas: 32×32 px PNG, transparent background.
- Palette: Same base palette as player/monster bibles (Pineapple 32). Use 3–5 shade ramps per material.
- Outline: 1 px outline where needed for clarity; avoid pillow shading.
- Readability: Strong silhouette + a single focal read (shape + label/trim).
- AA/Dither: Minimal to none; only to smooth 45° diagonals when necessary.
- Lighting: Single top‑left key light; consistent across set.
- Effects: Use element glow ramps from Monster Art Bible for magical VFX (swap_vfx_1/2/3).
- Safe area: Leave 1 px padding; avoid touching edges.

## Export & Naming
- Path: `assets/images/items/<category>/<key>_32.png`
- Snake‑case keys; sizes/tiers as suffixes, e.g. `healing_potion_minor_32.png`.
- Provide neutral (non‑elemental) and elemental variants where applicable using suffixes `_fire|_water|_earth|_air|_light|_shadow|_arcane`.

## Blank Icons (Placeholders)
Create neutral empties for UI slots and generic item placeholders:
- `assets/images/ui/slots/item_empty_32.png` — generic bag/bottle silhouette.
- `assets/images/ui/slots/scroll_empty_32.png` — rolled parchment.
- `assets/images/ui/slots/food_empty_32.png` — apple/slice silhouette.
- `assets/images/ui/slots/bomb_empty_32.png` — round bomb silhouette.

Match existing ring/hand/chest empties’ line weight and border color.

---

## Categories & Production Plan
Below are the item families with visual guidance, game effect, and target counts. Variants should be visually distinct (shape, color, trim) even within a family.

### 1) Potions (Healing & Recovery)
Bottle shapes: round, square, conical, long vial, bulbous flask. Cork with seal/wax. Liquid with 2–3 tone gradient and specular highlight arc.

- Instant Heal Potions (Minor → Mega)
  - Keys: `healing_potion_minor|standard|greater|superior|mega`
  - Color: red glass/liquid, gold/white label band.
  - Effect: Restore 20/40/60/80/120 HP instantly.
  - Count: 5 (+7 elemental alt labels optional).
- Regeneration Tonics (HoT over N turns)
  - Keys: `regen_tonic_2t|4t|6t|8t`
  - Color: pink/magenta with tiny sparkle pixels; hourglass glyph on label.
  - Effect: Heal 8/16/24/36 over 2/4/6/8 turns.
  - Count: 4.
- Spirit/Focus Draughts (resource/skill accel)
  - Keys: `spirit_draught_minor|major`, `cooldown_tonic`
  - Color: cyan/teal; faint glow.
  - Effect: Small spirit restore or reduce cooldowns by 1.
  - Count: 3.
- Cleanse/Antidote
  - Keys: `antidote`, `cleanse_elixir`
  - Color: green (antidote), white with blue cap (cleanse).
  - Effect: Remove poison/burn/slow; cleanse removes all debuffs.
  - Count: 2 (+elemental themed labels optional).

### 2) Elixirs & Buffs (Player Buffs)
Tall vials with metallic bands and sigils. Use trim colors to telegraph buff.

- Attack Up (`elixir_of_might_minor|major`): orange/red trim; +ATK for 2/4 turns.
- Defense Up (`elixir_of_guard_minor|major`): steel/blue trim; +DEF for 2/4 turns.
- Speed Up (`elixir_of_swiftness_minor|major`): lime/teal trim; +SPD for 2/4 turns.
- Crit Up (`elixir_of_precision`): purple trim; +CRIT for 3 turns.
- Evasion Up (`elixir_of_veil`): gray/azure trim; +EVA for 3 turns.
- Element Shields (`elixir_fireguard|waterguard|earthguard|airguard|lightguard|shadowguard|arcaneguard`): colored gem inset.
- Count: 2×3 core elixirs + 2 special + 7 element shields = 15.

### 3) Debuff Flasks (Enemy Debuffs)
Angular bottles that look hazardous. Sloshing bubbles/skull glyphs.

- Poison Flask (`poison_small|poison_standard|poison_greater`): sickly green; apply poison.
- Acid Flask (`acid_vial`): neon green; reduces DEF for 2 turns.
- Soot Bomb (`soot_bomb`): dark gray; applies blind.
- Frost Phial (`frost_phial`): ice blue; slows (SPD‑).
- Hex Ink (`hex_ink`): violet; applies curse (SPIRIT‑/weaken).
- Count: 7.

### 4) Bombs & Grenades (Offense)
Round bomb, stick bomb, satchel, rune bomb. Burning fuse pixels where applicable.

- Fire Bomb (`fire_bomb_minor|major`): red/orange; burn.
- Ice Bomb (`ice_bomb_minor|major`): blue/white shards; chill/slow.
- Storm Bomb (`storm_bomb_minor|major`): yellow arcs; shock.
- Void Bomb (`void_bomb`): purple core; shadow damage.
- Smoke Bomb (`smoke_bomb`): gray; escape/evade buff.
- Count: 7.

### 5) Food (Single‑Use Consumables)
Readable silhouettes: fruit, bread, meats, sweets, drinks. Simple highlight and bite marks where needed.

- Fruit: `apple_red`, `pear_green`, `grapes_purple`, `orange`, `banana`, `pomegranate`, `berry_mixture`.
  - Effects: small HP restore (5–12), some give +SPD small for 1 turn.
  - Count: 7.
- Breads/Snacks: `bread_loaf`, `hardtack`, `cheese_wedge`, `jerky_strip`, `nut_mix`.
  - Effects: medium HP (10–18) or +DEF small for 1–2 turns.
  - Count: 5.
- Meals: `stew_bowl`, `roast_slice`, `herb_salad`, `fish_skewer`, `noodle_bowl`.
  - Effects: 15–25 HP + small regen 2 turns.
  - Count: 5.
- Sweets/Drinks: `honey_candy`, `sweet_roll`, `tonic_tea`, `coffee_cup`, `herbal_brew`.
  - Effects: tiny HP + SPD/FOCUS small.
  - Count: 5.

### 6) Scrolls (One‑Shot Spells)
Rolled parchment with band color indicating school; an emblem in the center.

- Element Scrolls: `scroll_flame`, `scroll_frost`, `scroll_storm`, `scroll_stone`, `scroll_gale`, `scroll_light`, `scroll_shadow`, `scroll_arcane_missile`.
- Support Scrolls: `scroll_mend` (heal), `scroll_barrier` (guard), `scroll_dispel` (cleanse), `scroll_haste`, `scroll_taunt`, `scroll_reveal` (codex/scan), `scroll_hex`.
- Count: 8 + 7 = 15.

### 7) Talismans & Sigils (Trigger Items)
Small trinket icons: coin, charm, rune tile, bell, feather, fang. Metallic trim + colored inlay.

- Keys: `talisman_lion`, `talisman_feather`, `rune_tile`, `spirit_bell`, `lucky_coin`, `moon_charm`, `sun_seal`, `wyrm_fang`.
- Effects: situational buffs or on‑use skills (e.g., barrier, attract, repel).
- Count: 8.

### 8) Traps & Tools
- Traps: `snare_trap`, `spike_trap`, `frost_trap`, `hex_trap`.
- Tools: `lockpick_set`, `camp_kit`, `fishing_rod`, `torch`, `shovel`.
- Count: 9.

### 9) Echo Components (Meta‑Progression)
Tie into Resonant Echoes systems.

- `echo_shard_<element>`: crystal shard with element glow.
- `echo_core`: larger core with internal swirl.
- `echo_prism`: refined multi‑facet; used in fusion.
- Count: 9 (7 shards + core + prism).

---

## Totals (Target)
- Potions/Recovery: 14
- Buff Elixirs/Shields: 15
- Debuff Flasks: 7
- Bombs: 7
- Food: 22
- Scrolls: 15
- Talismans: 8
- Traps/Tools: 9
- Echo Components: 9
- Blank placeholders: 4
- Grand Total (icons): ~100–110

## QA Checklist per Icon
- 32×32, transparent, 1 px safe padding
- Single strong silhouette; readable at 1× scale
- Consistent light from top‑left, shadows opposite
- Minimal dithering; no blurry AA
- File path + name matches spec; correct category folder
- If elemental, uses the correct glow ramp

