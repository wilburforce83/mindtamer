// FILE: lib/features/journal/ui/journal_editor_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../hooks/journal_events.dart';
import '../model/journal_entry.dart';
import '../state/journal_editor_controller.dart';
import 'widgets/sentiment_selector.dart';
import 'widgets/tag_selector.dart';
import '../../../data/hive/boxes.dart';
import '../../../data/models/settings.dart';
import '../../../seed/lexicon_loader.dart';
import '../../../seed/seed_generator.dart';
import '../../../game/services/seed_pipeline.dart';

class JournalEditorScreen extends StatelessWidget {
  final JournalEntry? existing;
  const JournalEditorScreen({super.key, this.existing});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final c = JournalEditorController();
        if (existing != null) c.setFrom(existing!);
        return c;
      },
      child: Builder(builder: (context) {
        final c = context.watch<JournalEditorController>();
        return Scaffold(
          appBar: AppBar(
            title: Text(existing == null ? 'New Entry' : 'Edit Entry'),
            actions: [
              TextButton(onPressed: c.isValid ? () async {
                final saved = await c.save();
                // Generate seed result for new entries
                if (existing == null) {
                  final seedResult = await _generateSeed(c);
                  // Route seed according to kind (sprite immediate, monster -> ticket)
                  final router = _makeRouter();
                  await router.onJournalSaved(
                    entryId: saved.id,
                    seed: seedResult,
                    title: c.title,
                    body: c.body,
                    tags: List.of(c.tags),
                  );
                  // Emit event for potential listeners (legacy)
                  JournalEvents.emitSaved(saved, seed: null);
                  // If debug mode is on, show modal
                  final sBox = settingsBox();
                  final settings = sBox.values.isNotEmpty ? sBox.values.first : Settings(id: 'default');
                  if (settings.debugMode && context.mounted) {
                    await showDialog(
                      context: context,
                      builder: (_) => _SeedDebugDialog(seed: seedResult),
                    );
                  }
                }
                if (context.mounted) Navigator.pop(context, saved);
              } : null, child: const Text('Save')),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              TextFormField(
                initialValue: c.title,
                decoration: const InputDecoration(labelText: 'Title (required)'),
                onChanged: c.setTitle,
                maxLength: 80,
              ),
              TextFormField(
                initialValue: c.body,
                decoration: const InputDecoration(labelText: 'Body (optional)'),
                minLines: 4,
                maxLines: 10,
                onChanged: c.setBody,
              ),
              const SizedBox(height: 12),
              const Text('Sentiment'),
              SentimentSelector(value: c.sentiment, onChanged: c.setSentiment),
              const SizedBox(height: 12),
              const Text('Tags (at least 1, up to 8)'),
              TagSelector(
                selected: c.tags,
                onToggle: (t) {
                  c.toggleTag(t);
                },
              ),
            ],
          ),
        );
      }),
    );
  }

  SeedRouter _makeRouter() {
    final encounter = EncounterServiceImpl();
    final summon = SummonServiceImpl();
    return SeedRouterImpl(encounterService: encounter, summonService: summon);
  }

  Future<SeedResult> _generateSeed(JournalEditorController c) async {
    final bundle = await LexiconLoader.load();
    final gen = SeedGenerator();
    final req = SeedRequest(
      version: bundle.version,
      title: c.title,
      body: c.body,
      tags: List.of(c.tags),
      sentiment: c.sentiment.name,
    );
    return gen.generate(req, bundle);
  }
}

class _SeedDebugDialog extends StatelessWidget {
  final SeedResult seed;
  const _SeedDebugDialog({required this.seed});
  @override
  Widget build(BuildContext context) {
    final json = _prettyJson({
      'kind': seed.kind,
      'displayName': seed.displayName,
      'baseWord': seed.baseWord,
      'secondaryWord': seed.secondaryWord,
      'element': seed.element,
      'type': seed.type,
      'colorHex': seed.colorHex,
      'rarity': seed.rarity,
      'stats': seed.stats,
      'attacks': seed.attacks,
      'hash': seed.hash,
    });
    return AlertDialog(
      title: const Text('Generated Seed (Debug)'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: SelectableText(json, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: json));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seed copied to clipboard')));
            }
          },
          child: const Text('Copy'),
        ),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    );
  }

  String _prettyJson(Map<String, dynamic> m) {
    String pp(value, [int indent = 0]) {
      final pad = '  ' * indent;
      if (value is Map) {
        final b = StringBuffer();
        b.writeln('{');
        final entries = value.entries.toList();
        for (int i = 0; i < entries.length; i++) {
          final e = entries[i];
          b.write('$pad  ');
          b.write('"${e.key}": ');
          b.write(pp(e.value, indent + 1));
          if (i < entries.length - 1) b.write(',');
          b.writeln();
        }
        b.write('$pad}');
        return b.toString();
      } else if (value is List) {
        final b = StringBuffer();
        b.writeln('[');
        for (int i = 0; i < value.length; i++) {
          b.write('$pad  ');
          b.write(pp(value[i], indent + 1));
          if (i < value.length - 1) b.write(',');
          b.writeln();
        }
        b.write('$pad]');
        return b.toString();
      } else if (value is String) {
        final esc = value.replaceAll('"', '\\"');
        return '"$esc"';
      } else {
        return value.toString();
      }
    }

    return pp(m, 0);
  }
}
