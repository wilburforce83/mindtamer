import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../data/hive/boxes.dart';
import '../../data/models/achievement.dart' as model;
import '../../services/achievement_service.dart';
import '../widgets/achievement_badge_icon.dart';
import '../widgets/game_scaffold.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  static const _categoryOrder = <String>[
    'Progress',
    'Journal',
    'Mood',
    'Medication',
    'Combat',
    'Crafting',
    'Items',
    'Echoes',
    'Sprites',
    'Equipment',
  ];

  @override
  Widget build(BuildContext context) {
    final service = AchievementService();
    return FutureBuilder(
      future: service.init(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const GameScaffold(
            title: 'Achievements',
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return ValueListenableBuilder(
          valueListenable: achievementBox().listenable(),
          builder: (context, Box<model.Achievement> box, _) {
            final earnedMap = {
              for (final item in box.values) item.id: item,
            };
            final defs = service.allDefinitions().toList()
              ..sort((a, b) {
                final catA = _categoryOrder.indexOf(a['category']?.toString() ?? '');
                final catB = _categoryOrder.indexOf(b['category']?.toString() ?? '');
                if (catA != catB) return catA.compareTo(catB);
                final earnedA = earnedMap.containsKey(a['id']) ? 0 : 1;
                final earnedB = earnedMap.containsKey(b['id']) ? 0 : 1;
                if (earnedA != earnedB) return earnedA.compareTo(earnedB);
                final targetA = service.progressTargetFor(a);
                final targetB = service.progressTargetFor(b);
                if (targetA != targetB) return targetA.compareTo(targetB);
                return (a['title']?.toString() ?? '')
                    .compareTo(b['title']?.toString() ?? '');
              });

            final earnedCount = earnedMap.length;
            final totalCount = defs.length;
            final earnedPoints = earnedMap.keys.fold<int>(0, (sum, id) {
              final def = service.defOf(id);
              return sum +
                  (int.tryParse((def?['points'] ?? '0').toString()) ?? 0);
            });

            return GameScaffold(
              title: 'Achievements',
              padding: const EdgeInsets.all(12),
              body: ListView(
                children: [
                  _SummaryCard(
                    earnedCount: earnedCount,
                    totalCount: totalCount,
                    earnedPoints: earnedPoints,
                  ),
                  const SizedBox(height: 12),
                  for (final category in _categoryOrder) ...[
                    _CategorySection(
                      title: category,
                      tiles: defs
                          .where((d) => d['category']?.toString() == category)
                          .map((def) {
                        final earned = earnedMap[def['id']];
                        return _AchievementTile(
                          definition: def,
                          earned: earned,
                          progressCurrent: service.progressCurrentFor(def),
                          progressTarget: service.progressTargetFor(def),
                          progressFraction: service.progressFractionFor(def),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int earnedCount;
  final int totalCount;
  final int earnedPoints;

  const _SummaryCard({
    required this.earnedCount,
    required this.totalCount,
    required this.earnedPoints,
  });

  @override
  Widget build(BuildContext context) {
    final pct =
        totalCount == 0 ? 0.0 : (earnedCount / totalCount).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.18),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progress',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text('$earnedCount of $totalCount unlocked'),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: pct),
          const SizedBox(height: 8),
          Text('$earnedPoints achievement points earned'),
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final String title;
  final List<Widget> tiles;

  const _CategorySection({
    required this.title,
    required this.tiles,
  });

  @override
  Widget build(BuildContext context) {
    if (tiles.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...tiles,
      ],
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final Map<String, dynamic> definition;
  final model.Achievement? earned;
  final int progressCurrent;
  final int progressTarget;
  final double progressFraction;

  const _AchievementTile({
    required this.definition,
    required this.earned,
    required this.progressCurrent,
    required this.progressTarget,
    required this.progressFraction,
  });

  @override
  Widget build(BuildContext context) {
    final unlocked = earned != null;
    final title = definition['title']?.toString() ?? definition['id'].toString();
    final description = definition['description']?.toString() ?? '';
    final points =
        int.tryParse((definition['points'] ?? '0').toString()) ?? 0;
    final earnedAt = earned?.earnedAt.toLocal();
    final bodyStyle = Theme.of(context).textTheme.bodySmall;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: unlocked
            ? Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.18)
            : Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.08),
        border: Border.all(
          color: unlocked
              ? Theme.of(context).colorScheme.outlineVariant
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AchievementBadgeIcon(
            definition: definition,
            earned: unlocked,
            size: 58,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: Text('+$points'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: bodyStyle,
                ),
                const SizedBox(height: 8),
                if (unlocked && earnedAt != null)
                  Text(
                    'Unlocked ${_dateLabel(earnedAt)}',
                    style: bodyStyle?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                else if (progressTarget > 0)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$progressCurrent / $progressTarget',
                        style: bodyStyle,
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(value: progressFraction),
                    ],
                  )
                else
                  Text(
                    'Not unlocked yet',
                    style: bodyStyle,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _dateLabel(DateTime date) {
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '${date.year}-$mm-$dd';
  }
}
