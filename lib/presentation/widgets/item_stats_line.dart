import 'package:flutter/material.dart';
import '../../crafting/models.dart';

/// Displays item stats as inline labels, coloring non-DEF mods
/// (e.g., HP +1) by the item's element color.
class ItemStatsLine extends StatelessWidget {
  final Map<String, num> stats;
  final ElementType element;
  final TextStyle? style;
  const ItemStatsLine({super.key, required this.stats, required this.element, this.style});

  @override
  Widget build(BuildContext context) {
    final base = style ?? (Theme.of(context).textTheme.labelSmall ?? const TextStyle(fontSize: 11));
    final elColor = _elementColor(element);
    final chips = <InlineSpan>[];

    void addSpan(String text, {Color? color}) {
      chips.add(TextSpan(text: text, style: color == null ? base : base.copyWith(color: color)));
    }

    final baseKeys = ['def', 'atk', 'hp', 'spd', 'spirit'];
    final mods = <String, int>{};
    // Base stats first
    for (final k in baseKeys) {
      final v = stats[k];
      if (v != null && v > 0) {
        if (chips.isNotEmpty) addSpan(', ');
        addSpan('${k.toUpperCase()} ${v.round()}');
      }
    }
    // Collect mods (mod_*)
    stats.forEach((k, v) {
      if (k.startsWith('mod_')) {
        final stat = k.substring(4);
        mods[stat] = (mods[stat] ?? 0) + v.round();
      }
    });
    for (final entry in mods.entries) {
      final stat = entry.key.toLowerCase();
      final v = entry.value;
      if (v == 0) continue;
      if (chips.isNotEmpty) addSpan(', ');
      // non-DEF mods colored by element
      final color = stat == 'def' ? null : elColor;
      addSpan('${stat.toUpperCase()} +$v', color: color);
    }

    return RichText(text: TextSpan(children: chips));
  }

  Color _elementColor(ElementType e) {
    switch (e) {
      case ElementType.fire: return Colors.deepOrange;
      case ElementType.water: return Colors.lightBlueAccent;
      case ElementType.air: return Colors.cyanAccent;
      case ElementType.nature: return Colors.greenAccent;
      case ElementType.metal: return Colors.grey;
      case ElementType.light: return Colors.amberAccent;
      case ElementType.shadow: return Colors.purpleAccent;
    }
  }
}

