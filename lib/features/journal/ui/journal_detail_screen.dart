// FILE: lib/features/journal/ui/journal_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/journal_repository.dart';
import '../model/journal_entry.dart';
import 'journal_editor_screen.dart';
import 'widgets/pixel_icons.dart';

class JournalDetailScreen extends StatefulWidget {
  final int entryId;
  const JournalDetailScreen({super.key, required this.entryId});

  @override
  State<JournalDetailScreen> createState() => _JournalDetailScreenState();
}

class _JournalDetailScreenState extends State<JournalDetailScreen> {
  final repo = JournalRepository();
  JournalEntry? entry;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final e = await repo.getById(widget.entryId);
    if (mounted) setState(() => entry = e);
  }

  @override
  Widget build(BuildContext context) {
    final e = entry;
    return Scaffold(
      appBar: AppBar(
        title: Text(e?.title ?? 'Entry'),
        actions: [
          if (e != null) ...[
            IconButton(
              tooltip: 'Edit',
              icon: const PixelEditIcon(size: 24),
              onPressed: () async {
                final updated = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => JournalEditorScreen(existing: e)),
                );
                if (updated is JournalEntry) {
                  await _load();
                }
              },
            ),
            IconButton(
              tooltip: 'Delete',
              icon: const PixelDeleteIcon(size: 24),
              onPressed: () async {
                final ok = await showDialog<bool>(context: context, builder: (ctx){
                  return AlertDialog(title: const Text('Delete?'), content: const Text('This cannot be undone.'), actions: [
                    TextButton(onPressed: ()=>Navigator.pop(ctx,false), child: const Text('Cancel')),
                    TextButton(onPressed: ()=>Navigator.pop(ctx,true), child: const Text('Delete')),
                  ]);
                });
                if (ok == true) {
                  await repo.delete(e.id);
                  if (!context.mounted) return;
                  Navigator.pop(context, true);
                }
              },
            ),
          ]
        ],
      ),
      body: e == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Text(
                  DateFormat('EEE, MMM d yyyy • HH:mm').format(e.createdAtUtc.toLocal()),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                // Body first
                if ((e.body ?? '').isNotEmpty)
                  Text(e.body ?? '', style: Theme.of(context).textTheme.bodyMedium),
                if ((e.body ?? '').isNotEmpty) const SizedBox(height: 12),
                // Tags below body, rendered compact
                if (e.tags.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final t in e.tags.take(8))
                        Chip(
                          label: Text(t, style: const TextStyle(fontSize: 10)),
                          labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                          visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                    ],
                  ),
              ],
            ),
    );
  }
}
