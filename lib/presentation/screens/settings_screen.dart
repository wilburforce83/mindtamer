import 'package:flutter/material.dart';
import '../widgets/game_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/hive/boxes.dart';
import '../../data/models/settings.dart';
import '../../core/notifications.dart';
import '../../data/models/med_plan.dart';
import 'package:mindtamer/features/settings/journal/journal_settings_section.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final box = settingsBox();
    return GameScaffold(
      title: 'Settings',
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, _, __) {
          final settings = box.values.isNotEmpty ? box.values.first : Settings(id: 'default');
          _ensureDefaults(box, settings);
          if (box.values.isEmpty) {
            // Persist default to ensure stable subsequent reads
            box.put(settings.id, settings);
          }
          final onTimeCtrl = TextEditingController(text: settings.pillOnTimeToleranceMinutes.toString());
          final refillCtrl = TextEditingController(text: settings.refillThresholdDays.toString());
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
          const SizedBox(height: 8),
          const Text('Notifications'),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Medication reminders (15 min early)'),
            value: settings.medRemindersEnabled,
            onChanged: (v) async {
              settings.medRemindersEnabled = v;
              await box.put(settings.id, settings);
              if (v) {
                final plans = medPlanBox().values.where((p) => p.active).cast<MedPlan>().toList();
                final map = <String, List<String>>{};
                for (final p in plans) {
                  for (final t in p.scheduleTimes) { map.putIfAbsent(t, ()=>[]).add(p.name); }
                }
                await NotificationService.scheduleDailyPreReminders(map, offset: const Duration(minutes: 15));
              } else {
                await NotificationService.clearMedReminders();
              }
            },
          ),
          SwitchListTile(
            title: const Text('Mood reminders (10:00 & 18:00)'),
            value: settings.moodRemindersEnabled,
            onChanged: (v) async {
              settings.moodRemindersEnabled = v;
              await box.put(settings.id, settings);
              await NotificationService.scheduleMoodJournalReminders(
                moodEnabled: settings.moodRemindersEnabled,
                journalEnabled: settings.journalRemindersEnabled,
              );
            },
          ),
          SwitchListTile(
            title: const Text('Journal reminders (10:00 & 18:00)'),
            value: settings.journalRemindersEnabled,
            onChanged: (v) async {
              settings.journalRemindersEnabled = v;
              await box.put(settings.id, settings);
              await NotificationService.scheduleMoodJournalReminders(
                moodEnabled: settings.moodRemindersEnabled,
                journalEnabled: settings.journalRemindersEnabled,
              );
            },
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          const Text('Gameplay'),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Battle difficulty'),
              const SizedBox(height: 6),
              DropdownButton<String>(
                value: (settings.difficulty.isEmpty ? 'normal' : settings.difficulty),
                items: const [
                  DropdownMenuItem(value: 'relaxed', child: Text('Relaxed')),
                  DropdownMenuItem(value: 'normal', child: Text('Balanced')),
                  DropdownMenuItem(value: 'challenging', child: Text('Challenging')),
                ],
                onChanged: (v) async {
                  if (v == null) return;
                  // Avoid using context after await
                  final messenger = ScaffoldMessenger.of(context);
                  settings.difficulty = v;
                  messenger.showSnackBar(const SnackBar(content: Text('Difficulty will apply to new battles.')));
                  await box.put(settings.id, settings);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
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
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          const JournalSettingsSection(),
        ],
          );
        },
      ),
    );
  }
}

void _ensureDefaults(Box box, Settings s) {
  bool changed = false;
  // Access inside try/catch in case older objects have nulls for new non-nullable fields
  try { final _ = s.medRemindersEnabled; } catch (_) { s.medRemindersEnabled = true; changed = true; }
  try { final _ = s.moodRemindersEnabled; } catch (_) { s.moodRemindersEnabled = true; changed = true; }
  try { final _ = s.journalRemindersEnabled; } catch (_) { s.journalRemindersEnabled = true; changed = true; }
  if (changed) {
    try { box.put(s.id, s); } catch (_) {}
  }
  // Difficulty default
  try { final _ = s.difficulty; } catch (_) { s.difficulty = 'normal'; try { box.put(s.id, s); } catch (_) {} }
}
