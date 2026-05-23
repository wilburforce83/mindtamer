import 'package:flutter/material.dart';

class AchievementBadgeIcon extends StatelessWidget {
  final Map<String, dynamic> definition;
  final bool earned;
  final double size;

  const AchievementBadgeIcon({
    super.key,
    required this.definition,
    required this.earned,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    final category = definition['category']?.toString() ?? '';
    final family = definition['icon_family']?.toString() ?? category;
    final points =
        int.tryParse((definition['points'] ?? '0').toString()) ?? 0;
    final milestone = definition['milestone'];
    final accent = _accentFor(category);
    final bg = earned
        ? accent.withValues(alpha: 0.16)
        : Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.12);
    final border = earned
        ? accent
        : Theme.of(context).colorScheme.outline.withValues(alpha: 0.5);
    final iconColor = earned ? accent : Colors.white70;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border, width: 1.4),
        boxShadow: earned
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.22),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.all(size * 0.14),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: border.withValues(alpha: 0.65),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: Icon(
              _iconFor(family),
              size: size * 0.42,
              color: iconColor,
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(_pipCount(points), (index) {
                return Container(
                  width: 4,
                  height: 4,
                  margin: EdgeInsets.only(left: index == 0 ? 0 : 2),
                  decoration: BoxDecoration(
                    color: earned ? accent : Colors.white24,
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          ),
          if (milestone != null)
            Positioned(
              left: 3,
              right: 3,
              bottom: 3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.72),
                  border: Border.all(
                    color: earned
                        ? accent.withValues(alpha: 0.8)
                        : Colors.white24,
                    width: 0.8,
                  ),
                ),
                child: Text(
                  _milestoneLabel(milestone),
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: size * 0.14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  int _pipCount(int points) {
    if (points >= 30) return 4;
    if (points >= 20) return 3;
    if (points >= 10) return 2;
    return 1;
  }

  String _milestoneLabel(dynamic raw) {
    final n = int.tryParse(raw.toString());
    if (n == null) return raw.toString();
    if (n >= 1000) return '${(n / 1000).round()}K';
    return '$n';
  }

  Color _accentFor(String category) {
    switch (category.toLowerCase()) {
      case 'journal':
        return const Color(0xFFF0B95B);
      case 'mood':
        return const Color(0xFF57D6E9);
      case 'medication':
        return const Color(0xFF69D48A);
      case 'combat':
        return const Color(0xFFFF7C7C);
      case 'crafting':
        return const Color(0xFFFFB347);
      case 'items':
        return const Color(0xFF43D9C1);
      case 'echoes':
        return const Color(0xFFD27CFF);
      case 'sprites':
        return const Color(0xFF9FA8FF);
      case 'equipment':
        return const Color(0xFF8FC6FF);
      case 'progress':
        return const Color(0xFFFFD96A);
      default:
        return const Color(0xFFE8E2D0);
    }
  }

  IconData _iconFor(String family) {
    switch (family.toLowerCase()) {
      case 'journal':
        return Icons.edit_note;
      case 'mood':
        return Icons.favorite;
      case 'med':
        return Icons.medication;
      case 'battle':
        return Icons.flash_on;
      case 'craft':
        return Icons.handyman;
      case 'items':
        return Icons.backpack;
      case 'echo':
        return Icons.blur_circular;
      case 'sprite':
        return Icons.auto_awesome;
      case 'gear':
        return Icons.shield_outlined;
      case 'progress':
        return Icons.north_east;
      default:
        return Icons.emoji_events;
    }
  }
}
