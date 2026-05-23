import '../game/models/seed_instance.dart';
import '../models/sprite_attack.dart';

class SpriteInstanceUtils {
  static Map<String, dynamic>? strongestAttackRaw(
    List<Map<String, dynamic>> attacks,
  ) {
    if (attacks.isEmpty) {
      return null;
    }
    Map<String, dynamic>? best;
    for (final raw in attacks) {
      final candidate = Map<String, dynamic>.from(raw);
      if (best == null) {
        best = candidate;
        continue;
      }
      final power = _powerOf(candidate);
      final bestPower = _powerOf(best);
      final cooldown = _cooldownOf(candidate);
      final bestCooldown = _cooldownOf(best);
      if (power > bestPower ||
          (power == bestPower && cooldown < bestCooldown)) {
        best = candidate;
      }
    }
    return best;
  }

  static Map<String, dynamic>? strongestAttackForInstance(SeedInstance? inst) {
    if (inst == null) {
      return null;
    }
    return strongestAttackRaw(inst.attacks);
  }

  static SpriteAttack? strongestAttackModel(SeedInstance? inst) {
    final best = strongestAttackForInstance(inst);
    if (best == null) {
      return null;
    }
    final name = _attackName(best, fallback: 'Sprite Attack');
    final power = _powerOf(best);
    final duration = _cooldownOf(best);
    return SpriteAttack(
      name: name,
      description:
          'Fires a focused burst for $power power over $duration turns.',
      power: power,
      durationTurns: duration,
    );
  }

  static String attackNameForInstance(SeedInstance? inst) {
    final best = strongestAttackForInstance(inst);
    return _attackName(best, fallback: 'Sprite Attack');
  }

  static int attackPowerForInstance(SeedInstance? inst, {int fallback = 30}) {
    final best = strongestAttackForInstance(inst);
    return best == null ? fallback : _powerOf(best);
  }

  static int attackCooldownForInstance(
    SeedInstance? inst, {
    int fallback = 2,
  }) {
    final best = strongestAttackForInstance(inst);
    return best == null ? fallback : _cooldownOf(best);
  }

  static String? sourceTitleOf(SeedInstance? inst) {
    final raw = inst?.seedSnapshot['sourceTitle']?.toString().trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return raw;
  }

  static DateTime? sourceDateOf(SeedInstance? inst) {
    final raw = inst?.seedSnapshot['sourceDate']?.toString().trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw)?.toLocal();
  }

  static List<String> fusedFromNamesOf(SeedInstance? inst) {
    final raw = inst?.seedSnapshot['fusedFrom'];
    if (raw is List) {
      return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    return const <String>[];
  }

  static String sourceTypeLabel(String? source) {
    switch ((source ?? '').toLowerCase()) {
      case 'journal':
        return 'Journal';
      case 'fusion':
        return 'Fusion';
      case 'mood':
        return 'Mood';
      case 'summon':
        return 'Summon';
      case 'random':
        return 'Random Encounter';
      default:
        return 'Unknown';
    }
  }

  static int _powerOf(Map<String, dynamic>? raw) {
    if (raw == null) {
      return 0;
    }
    final value = raw['power'];
    if (value is num) {
      return value.round();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _cooldownOf(Map<String, dynamic>? raw) {
    if (raw == null) {
      return 2;
    }
    final value = raw['cooldown'] ?? raw['duration'] ?? raw['durationTurns'];
    if (value is num) {
      return value.round().clamp(1, 99);
    }
    return (int.tryParse(value?.toString() ?? '') ?? 2).clamp(1, 99);
  }

  static String _attackName(
    Map<String, dynamic>? raw, {
    required String fallback,
  }) {
    var name = raw?['name']?.toString().trim();
    if (name == null || name.isEmpty) {
      name = fallback;
    }
    if (name.toLowerCase().contains('shield')) {
      return 'Shield Bash';
    }
    return name;
  }
}
