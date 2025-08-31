import 'package:flutter/material.dart';
import '../widgets/game_scaffold.dart';
import 'package:mindtamer/features/journal/ui/journal_tab.dart';
import 'package:mindtamer/features/journal/ui/journal_editor_screen.dart';

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'Journal',
      body: const JournalTab(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const JournalEditorScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
