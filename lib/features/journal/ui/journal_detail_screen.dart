// FILE: lib/features/journal/ui/journal_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../data/journal_repository.dart';
import '../model/journal_entry.dart';
import 'journal_editor_screen.dart';
import 'widgets/pixel_icons.dart';
import '../../../data/hive/boxes.dart';
import '../../../game/services/seed_pipeline.dart';
import '../../../game/services/monster_image_service.dart';
import '../../../seed/seed_generator.dart';
import '../../../game/models/journal_seed_meta.dart';
import '../../../game/models/encounter_ticket.dart';
import '../../../game/models/battle.dart';

class JournalDetailScreen extends StatefulWidget {
  final int entryId;
  const JournalDetailScreen({super.key, required this.entryId});

  @override
  State<JournalDetailScreen> createState() => _JournalDetailScreenState();
}

class _JournalDetailScreenState extends State<JournalDetailScreen> {
  final repo = JournalRepository();
  JournalEntry? entry;
  JournalSeedMeta? meta;
  EncounterTicket? ticket;
  Battle? lastBattle;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final e = await repo.getById(widget.entryId);
    JournalSeedMeta? jm;
    EncounterTicket? t;
    Battle? b;
    if (e != null) {
      jm = journalSeedMetaBox().get(e.id);
      if (jm?.seedRouting == 'monster') {
        final tickets = encounterTicketBox()
            .values
            .where((x) => x.entryId == e.id)
            .toList();
        try {
          t = tickets.firstWhere((x) => x.state == 'open');
        } catch (_) {
          t = null;
        }
        final ticketIds = tickets.map((x) => x.ticketId).toSet();
        final battles = battleBox()
            .values
            .where((bb) => ticketIds.contains(bb.ticketId))
            .toList();
        if (battles.isNotEmpty) { battles.sort((a,b)=> b.startedAt.compareTo(a.startedAt)); b = battles.first; }
      }
    }
    if (mounted) setState(() { entry = e; meta = jm; ticket = t; lastBattle = b; });
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
                const SizedBox(height: 16),
                if (meta != null) ...[
                  Text('Routing: ${meta!.seedRouting}', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  if (meta!.seedRouting == 'monster') _monsterActions(),
                  if (meta!.seedRouting == 'sprite') const Text('Sprite added to inventory.'),
                ],
              ],
            ),
    );
  }

  Widget _monsterActions() {
    final t = ticket;
    final b = lastBattle;
    if (t != null && t.state == 'open') {
      final seed = SeedResultSerialize.fromMap(Map<String, dynamic>.from(t.seedSnapshot));
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FutureBuilder<String?>(
            future: MonsterImageService().resolveImagePath(
              displayName: seed.displayName,
              element: seed.element,
              type: seed.type,
            ),
            builder: (context, snap) {
              final path = snap.data;
              return Row(children: [
                if (path != null) Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Image.asset(path, width: 64, height: 64, filterQuality: FilterQuality.none),
                ),
                Expanded(child: Text(seed.displayName, style: Theme.of(context).textTheme.titleMedium)),
              ]);
            },
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.sports_martial_arts, size: 16),
              label: const Text('Start Encounter'),
              onPressed: () async {
                try {
                  final battleId = await BattleServiceImpl(codex: CodexServiceImpl(), echo: EchoServiceImpl()).start(t.ticketId);
                  if (!mounted) return;
                  await context.push('/battle', extra: {'battleId': battleId});
                  await _load();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cannot start: $e')));
                }
              },
            ),
          ),
        ],
      );
    }
    if (b != null && b.result != null) {
      final echoDropped = resonantEchoBox().values.any((e) => e.battleId == b.battleId);
      return Text('Last battle: ${b.result} • ${b.turnCount} turns${echoDropped ? ' • Echo dropped!' : ''}');
    }
    return const SizedBox.shrink();
  }
}
