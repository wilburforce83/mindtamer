// FILE: lib/features/journal/ui/journal_tab.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/journal_repository.dart';
import '../data/journal_tag_rules.dart';
import '../model/journal_entry.dart';
import '../model/sentiment.dart' as jm;
import '../state/journal_controller.dart';
import 'journal_detail_screen.dart';
import 'widgets/pixel_icons.dart';

class JournalTab extends StatelessWidget {
  const JournalTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => JournalController(),
      child: const _JournalTabBody(),
    );
  }
}

class _JournalTabBody extends StatefulWidget {
  const _JournalTabBody();
  @override
  State<_JournalTabBody> createState() => _JournalTabBodyState();
}

class _JournalTabBodyState extends State<_JournalTabBody> {
  final repo = JournalRepository();
  final dateFmt = DateFormat('MMM d, HH:mm');
  final TextEditingController _searchCtrl = TextEditingController();
  List<String> _customTags = [];
  List<String> _suggestions = [];

  @override
  Widget build(BuildContext context) {
    final c = context.watch<JournalController>();
    return Column(
      children: [
        // Header + single search field
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(children: [Expanded(child: Text('Your Journal'))]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search titles, body, or tags',
              prefixIcon: const PixelSearchIcon(size: 20),
              suffixIcon: _searchCtrl.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear',
                      icon: const PixelCloseIcon(size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        _suggestions = const [];
                        c.setText('');
                        setState(() {});
                      },
                    ),
            ),
            onChanged: (q) async {
              c.setText(q);
              final allTags = [...JournalTagRules.curated, ..._customTags];
              final ql = q.trim().toLowerCase();
              setState(() {
                _suggestions = ql.isEmpty
                    ? const []
                    : allTags.where((t) => t.contains(ql)).take(10).toList();
              });
            },
          ),
        ),
        if (_suggestions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                for (final s in _suggestions)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      label: Text(s),
                      onPressed: () {
                        _searchCtrl.text = s;
                        c.setText(s);
                        setState(() => _suggestions = const []);
                      },
                    ),
                  ),
              ]),
            ),
          ),
        const SizedBox(height: 8),
        // Insights (simple bar chart)
        _Insights(repo: repo),
        const Divider(),
        Expanded(
          child: StreamBuilder<List<JournalEntry>>(
            stream: c.stream(),
            builder: (context, snap) {
              final items = snap.data ?? const <JournalEntry>[];
              if (items.isEmpty) {
                return const Center(child: Text('No entries yet'));
              }
              return ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final e = items[i];
                  return ListTile(
                    title: Text(e.title),
                    subtitle: Text(
                        '${dateFmt.format(e.createdAtUtc.toLocal())} • ${e.sentiment.name} • ${e.tags.take(3).join(', ')}'),
                    onTap: () async {
                      await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  JournalDetailScreen(entryId: e.id)));
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Insights extends StatefulWidget {
  final JournalRepository repo;
  const _Insights({required this.repo});
  @override
  State<_Insights> createState() => _InsightsState();
}

class _InsightsState extends State<_Insights> {
  Map<String, int> map = {};

  @override
  void initState() {
    super.initState();
    _loadTags();
    _load();
  }

  Future<void> _loadTags() async {
    final custom = await widget.repo.listCustomTags();
    // Access the parent state to update suggestions list source
    final st = context.findAncestorStateOfType<_JournalTabBodyState>();
    if (st != null && mounted) {
      st._customTags = custom;
    }
  }

  Future<void> _load() async {
    final end = DateTime.now();
    final start = end.subtract(const Duration(days: 30));
    final m = await widget.repo.countsByDay(start, end);
    if (mounted) setState(() => map = m);
  }

  @override
  Widget build(BuildContext context) {
    if (map.isEmpty) return const SizedBox.shrink();
    final entries = map.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final barGroups = <BarChartGroupData>[];
    int x = 0;
    for (final e in entries) {
      barGroups.add(BarChartGroupData(x: x++, barRods: [
        BarChartRodData(toY: e.value.toDouble(), color: Colors.teal, width: 6)
      ]));
    }
    return SizedBox(
      height: 140,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: BarChart(BarChartData(
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: barGroups,
        )),
      ),
    );
  }
}
