// FILE: lib/features/journal/ui/widgets/tag_selector.dart
import 'package:flutter/material.dart';
import '../../../journal/data/journal_repository.dart';
import '../../../journal/data/journal_tag_rules.dart';

class TagSelector extends StatefulWidget {
  final List<String> selected;
  final ValueChanged<String> onToggle;
  final bool allowCustom;
  const TagSelector({super.key, required this.selected, required this.onToggle, this.allowCustom = true});

  @override
  State<TagSelector> createState() => _TagSelectorState();
}

class _TagSelectorState extends State<TagSelector> {
  final repo = JournalRepository();
  List<String> custom = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    custom = await repo.listCustomTags();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    const curated = JournalTagRules.curated;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in curated)
              FilterChip(
                label: Text(t),
                selected: widget.selected.contains(t),
                onSelected: (_) => widget.onToggle(t),
              ),
            for (final t in custom)
              FilterChip(
                label: Text(t),
                selected: widget.selected.contains(t),
                onSelected: (_) => widget.onToggle(t),
              ),
          ],
        ),
        if (widget.allowCustom)
          TextButton.icon(
            onPressed: () async {
              final remaining = JournalTagRules.maxCustomTagsGlobal - custom.length;
              final controller = TextEditingController();
              final name = await showDialog<String>(context: context, builder: (ctx){
                return AlertDialog(
                  title: const Text('Add custom tag'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Remaining: $remaining'),
                      TextField(controller: controller, autofocus: true, decoration: const InputDecoration(labelText: 'Tag name')), 
                    ],
                  ),
                  actions: [
                    TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text('Cancel')),
                    TextButton(onPressed: ()=>Navigator.pop(ctx, controller.text), child: const Text('Add')),
                  ],
                );
              });
              if (name != null && name.trim().isNotEmpty) {
                final ok = await repo.addCustomTag(name.trim());
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Added' : 'Could not add tag')));
                await _refresh();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Add custom tag'),
          ),
      ],
    );
  }
}
