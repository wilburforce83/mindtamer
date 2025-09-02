// FILE: lib/features/journal/ui/journal_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/journal_repository.dart';
import '../model/journal_entry.dart';
import 'journal_editor_screen.dart';
import 'widgets/pixel_icons.dart';
import '../../../data/hive/boxes.dart';
import '../../../game/services/seed_pipeline.dart';
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
        try {
          t = encounterTicketBox().values.firstWhere(
            (x) => x.entryId == e.id && x.state == 'open');
        } catch (_) {
          t = null;
        }
        final battles = battleBox().values.where((bb) => bb.ticketId == (t?.ticketId ?? 'none')).toList();
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
      return Align(
        alignment: Alignment.centerLeft,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.sports_martial_arts, size: 16),
          label: const Text('Start Encounter'),
          onPressed: () async {
            try {
              final battleId = await BattleServiceImpl(codex: CodexServiceImpl(), echo: EchoServiceImpl()).start(t.ticketId);
              if (!mounted) return;
              await _showBattleStub(battleId);
              await _load();
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cannot start: $e')));
            }
          },
        ),
      );
    }
    if (b != null && b.result != null) {
      final echoDropped = resonantEchoBox().values.any((e) => e.battleId == b.battleId);
      return Text('Last battle: ${b.result} • ${b.turnCount} turns${echoDropped ? ' • Echo dropped!' : ''}');
    }
    return const SizedBox.shrink();
  }

  Future<void> _showBattleStub(String battleId) async {
    int turns = 3;
    String result = 'win';
    bool flawless = true;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Battle (Stub)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: result,
                items: const [
                  DropdownMenuItem(value: 'win', child: Text('Win')),
                  DropdownMenuItem(value: 'loss', child: Text('Loss')),
                  DropdownMenuItem(value: 'escape', child: Text('Escape')),
                ],
                onChanged: (v) { if (v != null) { setState(() => result = v); } },
              ),
              Row(children: [ const Text('Turns:'), const SizedBox(width: 8), Expanded(child: Slider(value: turns.toDouble(), min: 1, max: 20, divisions: 19, label: '$turns', onChanged: (v){ setState(()=>turns = v.round()); })) ]),
              Row(children: [ const Text('Flawless:'), Switch(value: flawless, onChanged: (v){ setState(()=>flawless = v); }) ]),
            ],
          ),
          actions: [
            TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(onPressed: () async {
              await BattleServiceImpl(codex: CodexServiceImpl(), echo: EchoServiceImpl()).resolve(battleId: battleId, result: result, turnCount: turns, flawless: flawless);
              if (context.mounted) Navigator.pop(ctx);
            }, child: const Text('Resolve')),
          ],
        ),
      ),
    );
  }
}
