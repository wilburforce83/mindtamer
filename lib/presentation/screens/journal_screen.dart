import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/journaling/journal_notifier.dart';
import '../../data/models/journal_entry.dart';
import '../widgets/game_scaffold.dart';
import '../widgets/pixel_button.dart';
class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});
  @override ConsumerState<JournalScreen> createState()=>_JournalScreenState();
}
class _JournalScreenState extends ConsumerState<JournalScreen> {
  final _text=TextEditingController(); final _tags=TextEditingController(); Sentiment _sentiment=Sentiment.neutral;
  @override Widget build(BuildContext context){
    final entries = ref.watch(journalListProvider);
    return GameScaffold(title: 'Journal', body: Column(children: [
      Padding(padding: const EdgeInsets.all(12), child: Column(children:[
        TextField(controller:_text, decoration: const InputDecoration(labelText: "Today's entry")),
        const SizedBox(height:8),
        TextField(controller:_tags, decoration: const InputDecoration(labelText: 'Tags (comma separated)')),
        const SizedBox(height:8),
        DropdownButton<Sentiment>(value:_sentiment, items: Sentiment.values.map((s)=>DropdownMenuItem(value:s,child:Text(s.name))).toList(),
          onChanged:(v)=>setState(()=>_sentiment=v??Sentiment.neutral)),
        const SizedBox(height:8),
        PixelButton(onPressed: () async {
          final tags=_tags.text.split(',').map((e)=>e.trim()).where((e)=>e.isNotEmpty).toList();
          await ref.read(journalListProvider.notifier).add(_text.text.trim(), tags, _sentiment);
          _text.clear(); _tags.clear();
        }, label: 'Save'),
      ])),
      const Divider(),
      Expanded(child: ListView.builder(itemCount: entries.length, itemBuilder:(context,i){
        final e=entries[i];
        return ListTile(title: Text(e.text), subtitle: Text('${e.date.toLocal()}  •  ${e.tags.join(', ')}  •  ${e.sentiment.name}'));
      }))
    ]));
  }
}
