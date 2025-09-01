import 'package:flutter/material.dart';
import '../widgets/game_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/hive/boxes.dart';
import '../../data/models/settings.dart';
import 'package:mindtamer/features/settings/journal/journal_settings_section.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final box = settingsBox();
    final settings = box.values.isNotEmpty ? box.values.first : Settings(id: 'default');
    final onTimeCtrl = TextEditingController(text: settings.pillOnTimeToleranceMinutes.toString());
    final refillCtrl = TextEditingController(text: settings.refillThresholdDays.toString());
    return GameScaffold(
      title: 'Settings',
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const Text('• Local-only data (no servers)'),
          const SizedBox(height: 12),
          const Text('• Export your data any time (CSV + ZIP)'),
          const SizedBox(height: 12),
          const Text('• Safety: Not a medical device; supportive companion only.'),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          const Text('Medication Settings'),
          const SizedBox(height: 12),
          TextField(
            controller: onTimeCtrl,
            decoration: const InputDecoration(
              labelText: 'On-time tolerance (minutes)',
            ),
            keyboardType: TextInputType.number,
            onSubmitted: (_) async {
              settings.pillOnTimeToleranceMinutes = int.tryParse(onTimeCtrl.text) ?? settings.pillOnTimeToleranceMinutes;
              await box.put(settings.id, settings);
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: refillCtrl,
            decoration: const InputDecoration(
              labelText: 'Refill threshold (days left)',
            ),
            keyboardType: TextInputType.number,
            onSubmitted: (_) async {
              settings.refillThresholdDays = int.tryParse(refillCtrl.text) ?? settings.refillThresholdDays;
              await box.put(settings.id, settings);
            },
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          const JournalSettingsSection(),
        ],
      ),
    );
  }
}
