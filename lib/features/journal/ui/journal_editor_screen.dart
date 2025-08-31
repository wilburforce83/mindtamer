// FILE: lib/features/journal/ui/journal_editor_screen.dart
import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../hooks/journal_events.dart';
import '../hooks/monster_seed.dart';
import 'package:mindtamer/features/settings/journal/journal_settings_state.dart';
import '../model/journal_entry.dart';
import '../state/journal_editor_controller.dart';
import 'widgets/sentiment_selector.dart';
import 'widgets/tag_selector.dart';

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
                if (existing == null) {
                  final seed = _maybeBuildSeed(saved, c);
                  JournalEvents.emitSaved(saved, seed: seed);
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

  MonsterSeed? _maybeBuildSeed(JournalEntry saved, JournalEditorController c) {
    final settings = JournalSettings.instance;
    if (!settings.generateSeedOnSave) return null;

    final sanitizedTitle = c.title.trim().replaceAll(RegExp(r'\s+'), ' ');
    final clampedTitle = sanitizedTitle.substring(0, sanitizedTitle.length.clamp(0, 80));
    final sortedTags = [...c.tags]..sort();

    final seedInput = settings.titleAffectsRng
        ? "${saved.localDate}|${c.sentiment.name}|${sortedTags.join(',')}|$clampedTitle"
        : "${saved.localDate}|${c.sentiment.name}|${sortedTags.join(',')}";
    final hash = crypto.sha256.convert(utf8.encode(seedInput)).bytes;
    // lower 8 bytes -> uint64
    int toUint64(List<int> b) {
      int v = 0;
      for (int i = 0; i < 8; i++) {
        v = (v << 8) | (b[i] & 0xFF);
      }
      return v & 0x7FFFFFFFFFFFFFFF; // keep positive
    }

    final rngSeed = toUint64(hash);
    final rarityRoll = ((hash[0] << 24) | (hash[1] << 16) | (hash[2] << 8) | (hash[3])) % 100;
    final themeCode = ((hash[4] << 24) | (hash[5] << 16) | (hash[6] << 8) | (hash[7])) % 10;

    return MonsterSeed(
      entryId: saved.id,
      dayKey: saved.localDate,
      tags: sortedTags,
      sentiment: c.sentiment,
      echoTitle: clampedTitle,
      rngSeed: rngSeed,
      rarityRoll: rarityRoll,
      themeCode: themeCode,
    );
  }
}
