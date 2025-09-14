import 'dart:math' as math;
import '../../models/sprite_attack.dart';
import '../skills/skill.dart';

class BattleStats {
  int maxHp;
  int hp;
  int atk; // small, e.g., 4–8
  int def; // small, e.g., 1–4
  // active statuses: key -> (magnitude, remaining)
  final Map<String, BattleStatus> statuses;
  BattleStats({required this.maxHp, required this.hp, required this.atk, required this.def, Map<String,BattleStatus>? statuses})
      : statuses = statuses ?? {};

  int get atkMod {
    final a = statuses['atk+']?.magnitude ?? 0;
    final s = statuses['spirit+']?.magnitude ?? 0; // small spirit buff contributes to attack
    final f = statuses['focus']?.magnitude ?? 0; // focus modeled as atk boost elsewhere
    final down = statuses['atk-']?.magnitude ?? 0; // attack down
    return (a + s + f) - down;
  }
  int get defMod => (statuses['def+']?.magnitude ?? 0) - (statuses['def-']?.magnitude ?? 0);
  int get guard => statuses['guard']?.magnitude ?? 0; // flat reduction
  int get regen => statuses['regen']?.magnitude ?? 0; // per turn heal

  void tickEndOfTurn() {
    // Regen first
    if (regen > 0) {
      hp = (hp + regen).clamp(0, maxHp);
    }
    // Damage over time (e.g., poison)
    final poison = statuses['poison']?.magnitude ?? 0;
    if (poison > 0) {
      hp = (hp - poison).clamp(0, maxHp);
    }
    // Decrement durations and remove expired
    final expired = <String>[];
    statuses.forEach((k, v) {
      if (v.duration > 0) v.duration -= 1;
      if (v.duration <= 0) expired.add(k);
    });
    for (final k in expired) {
      statuses.remove(k);
    }
  }
}

class BattleStatus { int magnitude; int duration; BattleStatus(this.magnitude, this.duration); }

class Combatant {
  final String name;
  final BattleStats stats;
  final Map<String, int> cooldowns = {}; // actionId -> remaining
  final List<Skill> skills; // class skills
  final List<BattleSpriteAction> spriteActions; // derived from inventory
  Combatant({required this.name, required this.stats, required this.skills, this.spriteActions = const []});

  bool isAlive() => stats.hp > 0;
}

class BattleSpriteAction {
  final String id; // e.g., sprite:ABC
  final String name;
  final int power;
  final int cooldown;
  const BattleSpriteAction(this.id, this.name, this.power, this.cooldown);
}

class BattleEngine {
  final Combatant player;
  final Combatant enemy;
  final math.Random _rng = math.Random();
  BattleEngine({required this.player, required this.enemy});

  // Map a SpriteAttack to a compact action compatible with our skills
  static BattleSpriteAction fromSpriteAttack(SpriteAttack atk) {
    // Map power to a small range. Example: ~6–12
    int p = (atk.power / 8).round().clamp(5, 14);
    int cd = atk.durationTurns.clamp(1, 5);
    return BattleSpriteAction('sprite:${atk.name}', atk.name, p, cd);
  }

  List<String> takeTurnBySkill(Combatant attacker, Combatant defender, Skill skill) {
    final log = <String>[];
    if (_cooldownRemaining(attacker, skill.id) > 0) {
      log.add('${attacker.name} tried ${skill.name}, but it is on cooldown.');
      return log;
    }
    // Apply support effects
    if (skill.type == SkillType.support && skill.effect != null) {
      final eff = skill.effect!;
      final target = skill.targetSelf ? attacker : defender;
      _applyEffect(target, eff);
      _setCooldown(attacker, skill.id, skill.cooldown);
      log.add('${attacker.name} used ${skill.name}.');
      return log;
    }
    // Deal damage for basic/special
    final dmg = _damage(attacker.stats, defender.stats, base: skill.power);
    defender.stats.hp = (defender.stats.hp - dmg).clamp(0, defender.stats.maxHp);
    _setCooldown(attacker, skill.id, skill.cooldown);
    log.add('${attacker.name} used ${skill.name} for $dmg damage.');
    return log;
  }

  List<String> takeTurnBySprite(Combatant attacker, Combatant defender, BattleSpriteAction action) {
    final log = <String>[];
    if (_cooldownRemaining(attacker, action.id) > 0) {
      log.add('${action.name} is on cooldown.');
      return log;
    }
    final dmg = _damage(attacker.stats, defender.stats, base: action.power);
    defender.stats.hp = (defender.stats.hp - dmg).clamp(0, defender.stats.maxHp);
    _setCooldown(attacker, action.id, action.cooldown);
    log.add('${attacker.name} summoned ${action.name} for $dmg damage.');
    return log;
  }

  void endTurn() {
    _tickCooldowns(player);
    _tickCooldowns(enemy);
    player.stats.tickEndOfTurn();
    enemy.stats.tickEndOfTurn();
  }

  // Simple AI: choose first available special, else basic
  Skill chooseEnemySkill() {
    // try special if ready
    final specials = enemy.skills.where((s) => s.type == SkillType.special).toList();
    for (final s in specials) {
      if (_cooldownRemaining(enemy, s.id) == 0) return s;
    }
    // else basic
    return enemy.skills.firstWhere((s) => s.type == SkillType.basic);
  }

  int _damage(BattleStats atkStats, BattleStats defStats, {required int base}) {
    final atk = atkStats.atk + atkStats.atkMod;
    final def = (defStats.def + defStats.defMod).clamp(0, 99);
    final swing = _rng.nextInt(3) - 1; // -1..+1
    int raw = base + atk - def + swing;
    raw = raw - defStats.guard; // flat reduction
    return raw.clamp(1, 99);
  }

  void _applyEffect(Combatant target, SkillEffect eff) {
    switch (eff.key) {
      case 'atk+':
      case 'def+':
      case 'def-':
      case 'guard':
      case 'regen':
      case 'atk-':
      case 'poison':
        target.stats.statuses[eff.key] = BattleStatus(eff.magnitude, eff.duration);
        break;
      case 'cleanse':
        // remove all negative statuses
        final negatives = ['def-', 'atk-', 'poison', 'vuln'];
        final toRemove = <String>[];
        target.stats.statuses.forEach((k, v) {
          if (negatives.contains(k)) toRemove.add(k);
        });
        for (final k in toRemove) { target.stats.statuses.remove(k); }
        break;
      case 'spirit+':
        target.stats.statuses['spirit+'] = BattleStatus(eff.magnitude, eff.duration);
        break;
      case 'focus':
        // focus = +1 atk for 2 turns modeled via atk+
        target.stats.statuses['atk+'] = BattleStatus(eff.magnitude, eff.duration);
        break;
      default:
        // no-op unknown
        break;
    }
  }

  // Public helper: apply a raw status effect (for items, etc.)
  void applyStatus(Combatant target, String key, int magnitude, int duration) {
    target.stats.statuses[key] = BattleStatus(magnitude, duration);
  }

  int _cooldownRemaining(Combatant c, String actionId) => c.cooldowns[actionId] ?? 0;
  void _setCooldown(Combatant c, String actionId, int cd) {
    if (cd <= 0) {
      c.cooldowns.remove(actionId);
    } else {
      // counts down after this turn
      c.cooldowns[actionId] = cd + 1;
    }
  }
  void _tickCooldowns(Combatant c) {
    final toRemove = <String>[];
    c.cooldowns.forEach((k, v) {
      final nv = (v - 1).clamp(0, 99);
      if (nv == 0) {
        toRemove.add(k);
      } else {
        c.cooldowns[k] = nv;
      }
    });
    for (final k in toRemove) {
      c.cooldowns.remove(k);
    }
  }
}
