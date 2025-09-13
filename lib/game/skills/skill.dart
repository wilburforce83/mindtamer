enum SkillType { basic, special, support }

class Skill {
  final String id; // unique per class, e.g., Sage.basic
  final String name;
  final String description;
  final SkillType type;
  final int power; // small scale 4–16
  final int cooldown; // in turns; 0 for basic
  final bool targetSelf; // support can be self or enemy
  final SkillEffect? effect; // optional buff/debuff
  final bool melee; // whether the action is melee (lunge anim)

  const Skill({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.power,
    required this.cooldown,
    this.targetSelf = false,
    this.effect,
    this.melee = false,
  });
}

class SkillEffect {
  final String key; // 'atk+', 'def-', 'regen', 'vuln', etc.
  final int magnitude; // small integers (e.g., +2 atk)
  final int duration; // turns
  const SkillEffect({required this.key, required this.magnitude, required this.duration});
}
