import 'dart:math' as math;

class DropTable {
  // Placeholder loot table; adjust later for balance
  static List<Map<String, dynamic>> roll({required int luckSeed}) {
    final rng = math.Random(luckSeed);
    final out = <Map<String, dynamic>>[];
    // Always a small potion
    out.add({'type': 'potion_small', 'qty': 1});
    if (rng.nextDouble() < 0.30) out.add({'type': 'fruit', 'qty': 1});
    if (rng.nextDouble() < 0.20) out.add({'type': 'food', 'qty': 1});
    return out;
  }
}

