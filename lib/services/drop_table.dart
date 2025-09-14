import 'dart:math' as math;

class DropTable {
  // Placeholder loot table; adjust later for balance
  static List<Map<String, dynamic>> roll({required int luckSeed}) {
    final rng = math.Random(luckSeed);
    final out = <Map<String, dynamic>>[];
    // Always a minor healing potion
    out.add({'type': 'healing_potion_minor', 'qty': 1});
    // 30% chance of a fruit or snack
    const fruits = ['apple_red','orange','banana','plum','blueberries','blackberries'];
    const snacks = ['cracker_stack','jerky_strip','sweet_roll','nut_mix'];
    if (rng.nextDouble() < 0.30) {
      final pool = rng.nextBool() ? fruits : snacks;
      out.add({'type': pool[rng.nextInt(pool.length)], 'qty': 1});
    }
    // 15% chance of a debuff flask
    const debuffs = ['acid_vial','poison_small','soot_bomb'];
    if (rng.nextDouble() < 0.15) out.add({'type': debuffs[rng.nextInt(debuffs.length)], 'qty': 1});
    return out;
  }
}
