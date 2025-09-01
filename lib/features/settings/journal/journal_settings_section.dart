// FILE: lib/features/settings/journal/journal_settings_section.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../journal/data/journal_repository.dart';
import '../../journal/data/journal_tag_rules.dart';
import '../../journal/export/journal_export_service.dart';

class _JournalSettingsModel extends ChangeNotifier {
  final repo = JournalRepository();
  List<String> custom = [];

  Future<void> refresh() async {
    custom = await repo.listCustomTags();
    notifyListeners();
  }
}

class JournalSettingsSection extends StatelessWidget {
  const JournalSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => _JournalSettingsModel()..refresh(),
      child: Builder(builder: (context) {
        final m = context.watch<_JournalSettingsModel>();
        final remaining = JournalTagRules.maxCustomTagsGlobal - m.custom.length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text('Journal Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Custom tags: ${m.custom.length} used / $remaining remaining'),
            const SizedBox(height: 12),
            Wrap(spacing: 6, children: [
              for (final t in m.custom)
                Chip(label: Text(t), onDeleted: () async { await m.repo.removeCustomTag(t); await m.refresh(); }),
              if (remaining > 0)
                ActionChip(label: const Text('Add custom tag'), onPressed: () async {
                  final controller = TextEditingController();
                  final name = await showDialog<String>(context: context, builder: (ctx){
                    return AlertDialog(title: const Text('Add custom tag'), content: TextField(controller: controller), actions: [
                      TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text('Cancel')),
                      TextButton(onPressed: ()=>Navigator.pop(ctx, controller.text), child: const Text('Add')),
                    ]);
                  });
                  if (name != null && name.trim().isNotEmpty) {
                    await m.repo.addCustomTag(name.trim());
                    await m.refresh();
                  }
                }),
            ]),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.file_upload_outlined),
                label: const Text('Export all journals'),
                onPressed: () async {
                  final svc = JournalExportService();
                  await svc.export();
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        );
      }),
    );
  }
}
