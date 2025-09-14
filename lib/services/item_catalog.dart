// No Flutter imports needed here

/// Item effect definition and catalog utilities.
/// Keys match asset filenames without the trailing `_32.png`.
class ItemDef {
  final String key; // e.g. healing_potion_minor
  final String category; // potions, elixirs, food, bombs, debuffs, scrolls, talismans
  final String name; // user-facing label
  final int? healInstant; // immediate heal amount
  final int? regenPerTurn; // heal per turn
  final int? regenTurns; // duration for regen
  final String? buffKey; // e.g., 'atk+', 'def+', 'guard', 'regen', 'spirit+'
  final int? buffMagnitude;
  final int? buffDuration;
  final bool buffTargetsEnemy; // true for enemy debuffs (ebuff)
  final bool cleanseAll; // remove all negative statuses from self
  final bool antidote; // remove poison from self
  final int? reduceCooldowns; // reduce player cooldowns by N (min 0)
  final int? damage; // direct flat damage to enemy (bypass engine calc)
  final bool fullHealOutOfBattle; // outside battle: set HP to full

  const ItemDef({
    required this.key,
    required this.category,
    required this.name,
    this.healInstant,
    this.regenPerTurn,
    this.regenTurns,
    this.buffKey,
    this.buffMagnitude,
    this.buffDuration,
    this.buffTargetsEnemy = false,
    this.cleanseAll = false,
    this.antidote = false,
    this.reduceCooldowns,
    this.damage,
    this.fullHealOutOfBattle = false,
  });

  String get assetPath => 'assets/images/items/$category/${key}_32.png';

  /// For use outside of battle, return the amount of HP to restore immediately.
  int? outOfBattleHealAmount() {
    if (fullHealOutOfBattle) return null; // Handled specially by UI
    if (healInstant != null) return healInstant;
    if (regenPerTurn != null && regenTurns != null) {
      return (regenPerTurn! * regenTurns!).clamp(1, 999);
    }
    return null;
  }
}

class ItemCatalog {
  static final Map<String, ItemDef> _defs = {
    // Potions: instant heals
    'healing_potion_minor': const ItemDef(key: 'healing_potion_minor', category: 'potions', name: 'Healing Potion (Minor)', healInstant: 20),
    'healing_potion_standard': const ItemDef(key: 'healing_potion_standard', category: 'potions', name: 'Healing Potion', healInstant: 40),
    'healing_potion_greater': const ItemDef(key: 'healing_potion_greater', category: 'potions', name: 'Healing Potion (Greater)', healInstant: 60),
    'healing_potion_superior': const ItemDef(key: 'healing_potion_superior', category: 'potions', name: 'Healing Potion (Superior)', healInstant: 80),
    'healing_potion_mega': const ItemDef(key: 'healing_potion_mega', category: 'potions', name: 'Healing Potion (Mega)', healInstant: 120),
    // Tonics: regen over turns (total 8/16/24/36 => 4 per turn with durations 2/4/6/8)
    'regen_tonic_2t': const ItemDef(key: 'regen_tonic_2t', category: 'potions', name: 'Regen Tonic (2T)', regenPerTurn: 4, regenTurns: 2),
    'regen_tonic_4t': const ItemDef(key: 'regen_tonic_4t', category: 'potions', name: 'Regen Tonic (4T)', regenPerTurn: 4, regenTurns: 4),
    'regen_tonic_6t': const ItemDef(key: 'regen_tonic_6t', category: 'potions', name: 'Regen Tonic (6T)', regenPerTurn: 4, regenTurns: 6),
    'regen_tonic_8t': const ItemDef(key: 'regen_tonic_8t', category: 'potions', name: 'Regen Tonic (8T)', regenPerTurn: 4, regenTurns: 8),
    // Spirit/cooldown/cleanse
    'spirit_draught_minor': const ItemDef(key: 'spirit_draught_minor', category: 'potions', name: 'Spirit Draught (Minor)', buffKey: 'spirit+', buffMagnitude: 1, buffDuration: 2),
    'spirit_draught_major': const ItemDef(key: 'spirit_draught_major', category: 'potions', name: 'Spirit Draught (Major)', buffKey: 'spirit+', buffMagnitude: 2, buffDuration: 3),
    'cooldown_tonic': const ItemDef(key: 'cooldown_tonic', category: 'potions', name: 'Cooldown Tonic', reduceCooldowns: 1),
    'antidote': const ItemDef(key: 'antidote', category: 'potions', name: 'Antidote', antidote: true),
    'cleanse_elixir': const ItemDef(key: 'cleanse_elixir', category: 'potions', name: 'Cleanse Elixir', cleanseAll: true),

    // Elixirs (buffs)
    'elixir_of_might_minor': const ItemDef(key: 'elixir_of_might_minor', category: 'elixirs', name: 'Elixir of Might (Minor)', buffKey: 'atk+', buffMagnitude: 1, buffDuration: 2),
    'elixir_of_might_major': const ItemDef(key: 'elixir_of_might_major', category: 'elixirs', name: 'Elixir of Might (Major)', buffKey: 'atk+', buffMagnitude: 2, buffDuration: 4),
    'elixir_of_guard_minor': const ItemDef(key: 'elixir_of_guard_minor', category: 'elixirs', name: 'Elixir of Guard (Minor)', buffKey: 'def+', buffMagnitude: 1, buffDuration: 2),
    'elixir_of_guard_major': const ItemDef(key: 'elixir_of_guard_major', category: 'elixirs', name: 'Elixir of Guard (Major)', buffKey: 'def+', buffMagnitude: 2, buffDuration: 4),
    'elixir_of_swiftness_minor': const ItemDef(key: 'elixir_of_swiftness_minor', category: 'elixirs', name: 'Elixir of Swiftness (Minor)', reduceCooldowns: 1),
    'elixir_of_swiftness_major': const ItemDef(key: 'elixir_of_swiftness_major', category: 'elixirs', name: 'Elixir of Swiftness (Major)', reduceCooldowns: 1, buffKey: 'guard', buffMagnitude: 1, buffDuration: 4),
    'elixir_of_precision': const ItemDef(key: 'elixir_of_precision', category: 'elixirs', name: 'Elixir of Precision', buffKey: 'focus', buffMagnitude: 1, buffDuration: 3),
    'elixir_of_veil': const ItemDef(key: 'elixir_of_veil', category: 'elixirs', name: 'Elixir of Veil', buffKey: 'guard', buffMagnitude: 2, buffDuration: 3),
    // Element guard elixirs (map to guard buff for now)
    'elixir_fireguard': const ItemDef(key: 'elixir_fireguard', category: 'elixirs', name: 'Elixir of Fireguard', buffKey: 'guard', buffMagnitude: 2, buffDuration: 3),
    'elixir_waterguard': const ItemDef(key: 'elixir_waterguard', category: 'elixirs', name: 'Elixir of Waterguard', buffKey: 'guard', buffMagnitude: 2, buffDuration: 3),
    'elixir_earthguard': const ItemDef(key: 'elixir_earthguard', category: 'elixirs', name: 'Elixir of Earthguard', buffKey: 'guard', buffMagnitude: 2, buffDuration: 3),
    'elixir_airguard': const ItemDef(key: 'elixir_airguard', category: 'elixirs', name: 'Elixir of Airguard', buffKey: 'guard', buffMagnitude: 2, buffDuration: 3),
    'elixir_lightguard': const ItemDef(key: 'elixir_lightguard', category: 'elixirs', name: 'Elixir of Lightguard', buffKey: 'guard', buffMagnitude: 2, buffDuration: 3),
    'elixir_shadowguard': const ItemDef(key: 'elixir_shadowguard', category: 'elixirs', name: 'Elixir of Shadowguard', buffKey: 'guard', buffMagnitude: 2, buffDuration: 3),
    'elixir_arcaneguard': const ItemDef(key: 'elixir_arcaneguard', category: 'elixirs', name: 'Elixir of Arcaneguard', buffKey: 'guard', buffMagnitude: 2, buffDuration: 3),

    // Debuffs (enemy targeting by default)
    'poison_small': const ItemDef(key: 'poison_small', category: 'debuffs', name: 'Poison Flask (Small)', buffKey: 'poison', buffMagnitude: 2, buffDuration: 3, buffTargetsEnemy: true),
    'poison_standard': const ItemDef(key: 'poison_standard', category: 'debuffs', name: 'Poison Flask', buffKey: 'poison', buffMagnitude: 3, buffDuration: 3, buffTargetsEnemy: true),
    'poison_greater': const ItemDef(key: 'poison_greater', category: 'debuffs', name: 'Poison Flask (Greater)', buffKey: 'poison', buffMagnitude: 4, buffDuration: 3, buffTargetsEnemy: true),
    'acid_vial': const ItemDef(key: 'acid_vial', category: 'debuffs', name: 'Acid Vial', buffKey: 'def-', buffMagnitude: 2, buffDuration: 2, buffTargetsEnemy: true),
    'soot_bomb': const ItemDef(key: 'soot_bomb', category: 'debuffs', name: 'Soot Bomb', buffKey: 'atk-', buffMagnitude: 1, buffDuration: 3, buffTargetsEnemy: true),
    'frost_phial': const ItemDef(key: 'frost_phial', category: 'debuffs', name: 'Frost Phial', buffKey: 'def-', buffMagnitude: 1, buffDuration: 3, buffTargetsEnemy: true),
    'hex_ink': const ItemDef(key: 'hex_ink', category: 'debuffs', name: 'Hex Ink', buffKey: 'atk-', buffMagnitude: 2, buffDuration: 2, buffTargetsEnemy: true),

    // Bombs (flat damage; smoke is defensive)
    'fire_bomb_minor': const ItemDef(key: 'fire_bomb_minor', category: 'bombs', name: 'Fire Bomb (Minor)', damage: 12),
    'fire_bomb_major': const ItemDef(key: 'fire_bomb_major', category: 'bombs', name: 'Fire Bomb (Major)', damage: 18),
    'ice_bomb_minor': const ItemDef(key: 'ice_bomb_minor', category: 'bombs', name: 'Ice Bomb (Minor)', damage: 10),
    'ice_bomb_major': const ItemDef(key: 'ice_bomb_major', category: 'bombs', name: 'Ice Bomb (Major)', damage: 16),
    'storm_bomb_minor': const ItemDef(key: 'storm_bomb_minor', category: 'bombs', name: 'Storm Bomb (Minor)', damage: 11),
    'storm_bomb_major': const ItemDef(key: 'storm_bomb_major', category: 'bombs', name: 'Storm Bomb (Major)', damage: 17),
    'void_bomb': const ItemDef(key: 'void_bomb', category: 'bombs', name: 'Void Bomb', damage: 14),
    'smoke_bomb': const ItemDef(key: 'smoke_bomb', category: 'bombs', name: 'Smoke Bomb', buffKey: 'guard', buffMagnitude: 2, buffDuration: 2),

    // Scrolls (simple mapping)
    'scroll_flame': const ItemDef(key: 'scroll_flame', category: 'scrolls', name: 'Scroll of Flame', damage: 14),
    'scroll_frost': const ItemDef(key: 'scroll_frost', category: 'scrolls', name: 'Scroll of Frost', damage: 12),
    'scroll_storm': const ItemDef(key: 'scroll_storm', category: 'scrolls', name: 'Scroll of Storms', damage: 16),
    'scroll_stone': const ItemDef(key: 'scroll_stone', category: 'scrolls', name: 'Scroll of Stone', damage: 13),
    'scroll_gale': const ItemDef(key: 'scroll_gale', category: 'scrolls', name: 'Scroll of Gale', damage: 12),
    'scroll_light': const ItemDef(key: 'scroll_light', category: 'scrolls', name: 'Scroll of Light', damage: 12),
    'scroll_shadow': const ItemDef(key: 'scroll_shadow', category: 'scrolls', name: 'Scroll of Shadow', damage: 14),
    'scroll_arcane_missile': const ItemDef(key: 'scroll_arcane_missile', category: 'scrolls', name: 'Scroll of Arcane Missile', damage: 15),
    'scroll_mend': const ItemDef(key: 'scroll_mend', category: 'scrolls', name: 'Scroll of Mend', healInstant: 24),
    'scroll_barrier': const ItemDef(key: 'scroll_barrier', category: 'scrolls', name: 'Scroll of Barrier', buffKey: 'guard', buffMagnitude: 3, buffDuration: 3),
    'scroll_dispel': const ItemDef(key: 'scroll_dispel', category: 'scrolls', name: 'Scroll of Dispel', cleanseAll: true),
    'scroll_haste': const ItemDef(key: 'scroll_haste', category: 'scrolls', name: 'Scroll of Haste', reduceCooldowns: 2),
    'scroll_hex': const ItemDef(key: 'scroll_hex', category: 'scrolls', name: 'Scroll of Hex', buffKey: 'atk-', buffMagnitude: 2, buffDuration: 3, buffTargetsEnemy: true),
    'scroll_taunt': const ItemDef(key: 'scroll_taunt', category: 'scrolls', name: 'Scroll of Taunt', buffKey: 'def+', buffMagnitude: 1, buffDuration: 2),
    'scroll_reveal': const ItemDef(key: 'scroll_reveal', category: 'scrolls', name: 'Scroll of Reveal', buffKey: 'focus', buffMagnitude: 1, buffDuration: 1),

    // Food: heal small or medium; big meals/breads full heal outside battle
    'apple_red': const ItemDef(key: 'apple_red', category: 'food', name: 'Apple', healInstant: 6),
    'pear_green': const ItemDef(key: 'pear_green', category: 'food', name: 'Pear', healInstant: 6),
    'grapes_purple': const ItemDef(key: 'grapes_purple', category: 'food', name: 'Grapes', healInstant: 6),
    'orange': const ItemDef(key: 'orange', category: 'food', name: 'Orange', healInstant: 7),
    'banana': const ItemDef(key: 'banana', category: 'food', name: 'Banana', healInstant: 7),
    'pomegranate': const ItemDef(key: 'pomegranate', category: 'food', name: 'Pomegranate', healInstant: 8),
    'berry_mixture': const ItemDef(key: 'berry_mixture', category: 'food', name: 'Berry Mix', healInstant: 8),

    'bread_loaf': const ItemDef(key: 'bread_loaf', category: 'food', name: 'Bread Loaf', healInstant: 14, fullHealOutOfBattle: true),
    'butter_croissant': const ItemDef(key: 'butter_croissant', category: 'food', name: 'Butter Croissant', healInstant: 12, fullHealOutOfBattle: true),
    'baguette_piece': const ItemDef(key: 'baguette_piece', category: 'food', name: 'Baguette Piece', healInstant: 10, fullHealOutOfBattle: true),
    'pretzel': const ItemDef(key: 'pretzel', category: 'food', name: 'Pretzel', healInstant: 10, fullHealOutOfBattle: true),
    'hardtack': const ItemDef(key: 'hardtack', category: 'food', name: 'Hardtack', healInstant: 10, fullHealOutOfBattle: true),
    'cheese_wedge': const ItemDef(key: 'cheese_wedge', category: 'food', name: 'Cheese Wedge', healInstant: 12, fullHealOutOfBattle: true),

    'stew_bowl': const ItemDef(key: 'stew_bowl', category: 'food', name: 'Hearty Stew', healInstant: 20, regenPerTurn: 3, regenTurns: 2, fullHealOutOfBattle: true),
    'roast_slice': const ItemDef(key: 'roast_slice', category: 'food', name: 'Roast Slice', healInstant: 16, regenPerTurn: 2, regenTurns: 2, fullHealOutOfBattle: true),
    'herb_salad': const ItemDef(key: 'herb_salad', category: 'food', name: 'Herb Salad', healInstant: 12, regenPerTurn: 2, regenTurns: 2),
    'fish_skewer': const ItemDef(key: 'fish_skewer', category: 'food', name: 'Fish Skewer', healInstant: 14, regenPerTurn: 2, regenTurns: 2),
    'noodle_bowl': const ItemDef(key: 'noodle_bowl', category: 'food', name: 'Noodle Bowl', healInstant: 18, regenPerTurn: 3, regenTurns: 2, fullHealOutOfBattle: true),

    'honey_candy': const ItemDef(key: 'honey_candy', category: 'food', name: 'Honey Candy', healInstant: 6),
    'sweet_roll': const ItemDef(key: 'sweet_roll', category: 'food', name: 'Sweet Roll', healInstant: 8),
    'tonic_tea': const ItemDef(key: 'tonic_tea', category: 'food', name: 'Tonic Tea', healInstant: 8, buffKey: 'focus', buffMagnitude: 1, buffDuration: 1),
    'coffee_cup': const ItemDef(key: 'coffee_cup', category: 'food', name: 'Coffee', healInstant: 6, reduceCooldowns: 1),
    'herbal_brew': const ItemDef(key: 'herbal_brew', category: 'food', name: 'Herbal Brew', healInstant: 8, buffKey: 'regen', buffMagnitude: 2, buffDuration: 2),
    'fruit_juice': const ItemDef(key: 'fruit_juice', category: 'food', name: 'Fruit Juice', healInstant: 10),
    'milk_bottle': const ItemDef(key: 'milk_bottle', category: 'food', name: 'Milk', healInstant: 10),
    'lemonade_glass': const ItemDef(key: 'lemonade_glass', category: 'food', name: 'Lemonade', healInstant: 8),
    'hot_cocoa': const ItemDef(key: 'hot_cocoa', category: 'food', name: 'Hot Cocoa', healInstant: 10, buffKey: 'guard', buffMagnitude: 1, buffDuration: 1),

    // More fruits etc.
    'blackberries': const ItemDef(key: 'blackberries', category: 'food', name: 'Blackberries', healInstant: 6),
    'blueberries': const ItemDef(key: 'blueberries', category: 'food', name: 'Blueberries', healInstant: 6),
    'cherries': const ItemDef(key: 'cherries', category: 'food', name: 'Cherries', healInstant: 6),
    'cracker_stack': const ItemDef(key: 'cracker_stack', category: 'food', name: 'Crackers', healInstant: 8),
    'curry_bowl': const ItemDef(key: 'curry_bowl', category: 'food', name: 'Curry Bowl', healInstant: 16, regenPerTurn: 3, regenTurns: 2, fullHealOutOfBattle: true),
    'dumpling_basket': const ItemDef(key: 'dumpling_basket', category: 'food', name: 'Dumpling Basket', healInstant: 14, regenPerTurn: 2, regenTurns: 2, fullHealOutOfBattle: true),
    
    'jerky_strip': const ItemDef(key: 'jerky_strip', category: 'food', name: 'Jerky', healInstant: 10),
    'kiwi_half': const ItemDef(key: 'kiwi_half', category: 'food', name: 'Kiwi', healInstant: 6),
    'lemon_wedge': const ItemDef(key: 'lemon_wedge', category: 'food', name: 'Lemon Wedge', healInstant: 4),
    'lime_wedge': const ItemDef(key: 'lime_wedge', category: 'food', name: 'Lime Wedge', healInstant: 4),
    'mango_slice': const ItemDef(key: 'mango_slice', category: 'food', name: 'Mango Slice', healInstant: 6),
    'nut_mix': const ItemDef(key: 'nut_mix', category: 'food', name: 'Nut Mix', healInstant: 10),
    'omelette': const ItemDef(key: 'omelette', category: 'food', name: 'Omelette', healInstant: 12),
    'peach': const ItemDef(key: 'peach', category: 'food', name: 'Peach', healInstant: 6),
    // duplicate pear_green removed (already defined above)
    'pineapple_ring': const ItemDef(key: 'pineapple_ring', category: 'food', name: 'Pineapple Ring', healInstant: 6),
    'plum': const ItemDef(key: 'plum', category: 'food', name: 'Plum', healInstant: 6),
    'rice_ball': const ItemDef(key: 'rice_ball', category: 'food', name: 'Rice Ball', healInstant: 10),
    'sushi_roll': const ItemDef(key: 'sushi_roll', category: 'food', name: 'Sushi Roll', healInstant: 10),
    
    'spiced_cider': const ItemDef(key: 'spiced_cider', category: 'food', name: 'Spiced Cider', healInstant: 8),
    'watermelon_slice': const ItemDef(key: 'watermelon_slice', category: 'food', name: 'Watermelon', healInstant: 6),

    // Talismans: small buffs
    'talisman_lion': const ItemDef(key: 'talisman_lion', category: 'talismans', name: 'Lion Talisman', buffKey: 'atk+', buffMagnitude: 1, buffDuration: 2),
    'talisman_feather': const ItemDef(key: 'talisman_feather', category: 'talismans', name: 'Feather Talisman', reduceCooldowns: 1),
    'rune_tile': const ItemDef(key: 'rune_tile', category: 'talismans', name: 'Rune Tile', buffKey: 'guard', buffMagnitude: 1, buffDuration: 2),
    'spirit_bell': const ItemDef(key: 'spirit_bell', category: 'talismans', name: 'Spirit Bell', buffKey: 'spirit+', buffMagnitude: 1, buffDuration: 2),
    'lucky_coin': const ItemDef(key: 'lucky_coin', category: 'talismans', name: 'Lucky Coin', buffKey: 'focus', buffMagnitude: 1, buffDuration: 2),
    'moon_charm': const ItemDef(key: 'moon_charm', category: 'talismans', name: 'Moon Charm', buffKey: 'guard', buffMagnitude: 1, buffDuration: 2),
    'sun_seal': const ItemDef(key: 'sun_seal', category: 'talismans', name: 'Sun Seal', buffKey: 'atk+', buffMagnitude: 1, buffDuration: 2),
    'wyrm_fang': const ItemDef(key: 'wyrm_fang', category: 'talismans', name: 'Wyrm Fang', buffKey: 'atk+', buffMagnitude: 1, buffDuration: 2),
  };

  static ItemDef? defOf(String type) => _defs[type];
  static String labelOf(String type) => _defs[type]?.name ?? type;
  static String? assetOf(String type) => _defs[type]?.assetPath;
}
