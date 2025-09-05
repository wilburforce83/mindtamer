class SpriteAttack {
  final String name;
  final String description;
  final int power; // 0–100
  final int durationTurns; // 1–5
  const SpriteAttack({
    required this.name,
    required this.description,
    required this.power,
    required this.durationTurns,
  });
}

