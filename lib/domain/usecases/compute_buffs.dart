class ComputeBuffs {
  const ComputeBuffs();

  // Returns simple buff multipliers based on streak and level.
  Map<String, double> call({int streak = 0, int level = 1}) {
    final focusBuff = ((streak * 0.01).clamp(0.0, 0.2) as num).toDouble();
    final xpBuff = ((level * 0.005).clamp(0.0, 0.25) as num).toDouble();
    return {
      'focus': focusBuff,
      'xp': xpBuff,
    };
  }
}
