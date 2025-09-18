import 'package:flutter/material.dart';
import '../../services/achievement_service.dart';
import '../../data/hive/boxes.dart';
import '../../data/models/achievement.dart' as model;

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final box = achievementBox();
    final earned = box.values.toList()..sort((a,b)=> b.earnedAt.compareTo(a.earnedAt));
    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: FutureBuilder(
        future: AchievementService().init(),
        builder: (context, snap) {
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: earned.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final model.Achievement a = earned[i];
              final def = AchievementService().defOf(a.id);
              final title = def?['title']?.toString() ?? a.key;
              final desc = def?['description']?.toString() ?? '';
              final pts = int.tryParse((def?['points'] ?? '0').toString()) ?? 0;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                title: Text(title, overflow: TextOverflow.ellipsis),
                subtitle: Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: pts > 0 ? Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.outline)), child: Text('+$pts')) : null,
              );
            },
          );
        },
      ),
    );
  }
}
