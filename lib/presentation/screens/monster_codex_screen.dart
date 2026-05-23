import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/hive/boxes.dart';
import '../../game/services/monster_image_service.dart';
import '../../theme/colors.dart';

class _MonsterUi {
  final String speciesId;
  final String displayName;
  final String element;
  final String type;
  final String rarity; // common|uncommon|rare|epic
  final int level;
  final String? sourceTitle;
  final DateTime? sourceDate;
  _MonsterUi({
    required this.speciesId,
    required this.displayName,
    required this.element,
    required this.type,
    required this.rarity,
    required this.level,
    this.sourceTitle,
    this.sourceDate,
  });
}

class MonsterCodexScreen extends StatefulWidget {
  const MonsterCodexScreen({super.key});
  @override
  State<MonsterCodexScreen> createState() => _MonsterCodexScreenState();
}

class _MonsterCodexScreenState extends State<MonsterCodexScreen> {
  final _service = MonsterImageService();
  List<_MonsterUi> _items = [];
  int _selected = -1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final codex = monsterCodexBox().values.toList();
    if (codex.isEmpty) {
      setState(() {
        _items = [];
        _selected = -1;
      });
      return;
    }
    final sBox = seedSpeciesBox();
    final tBox = encounterTicketBox();
    final bBox = battleBox();

    int levelFromStats(Map<String, dynamic>? stats) {
      if (stats == null) return 10;
      int v(String k) => (stats[k] is int)
          ? stats[k] as int
          : int.tryParse('${stats[k]}') ?? 0;
      final sum = v('hp') + v('atk') + v('spd') + v('spirit');
      return (sum / 10).round().clamp(1, 99);
    }

    String rarityFor(String speciesId) =>
        sBox.get(speciesId)?.rarity ?? 'common';

    final items = <_MonsterUi>[];
    for (final c in codex) {
      final parts = c.speciesId.split(':');
      final element = parts.length > 1 ? parts[1] : 'neutral';
      final type = parts.length > 2 ? parts[2] : 'wisp';
      final rarity = rarityFor(c.speciesId);

      // Find earliest win battle for this species to extract source + stats
      final wins = bBox.values
          .where((b) => b.speciesId == c.speciesId && b.result == 'win')
          .toList()
        ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
      String? title;
      DateTime? date;
      Map<String, dynamic>? stats;
      if (wins.isNotEmpty) {
        final t = tBox.get(wins.first.ticketId);
        if (t != null) {
          final m = Map<String, dynamic>.from(t.seedSnapshot);
          stats = (m['stats'] is Map)
              ? Map<String, dynamic>.from(m['stats'])
              : null;
          title = (m['sourceTitle'] ?? '').toString();
          final raw = (m['sourceDate'] ?? '').toString();
          try {
            date = DateTime.parse(raw).toLocal();
          } catch (_) {
            date = t.createdAt.toLocal();
          }
        }
      }

      final level = levelFromStats(stats);
      items.add(_MonsterUi(
        speciesId: c.speciesId,
        displayName: (c.displayName != null && c.displayName!.isNotEmpty)
            ? c.displayName!
            : c.speciesId,
        element: element,
        type: type,
        rarity: rarity,
        level: level,
        sourceTitle: title,
        sourceDate: date,
      ));
    }
    setState(() {
      _items = items;
      _selected = items.isNotEmpty ? 0 : -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Monster Codex')),
      body: _items.isEmpty
          ? const Center(child: Text('Defeat a monster to discover it.'))
          : Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, cts) {
                      final cross = (cts.maxWidth ~/ 72).clamp(2, 6);
                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cross),
                        itemCount: _items.length,
                        itemBuilder: (_, i) => Padding(
                          padding: const EdgeInsets.all(6),
                          child: FutureBuilder<String?>(
                            future: _service.resolveImagePath(
                              displayName: _items[i].displayName,
                              element: _items[i].element,
                              type: _items[i].type,
                              debug: true,
                            ),
                            builder: (context, snap) {
                              final path = snap.data;
                              return InkWell(
                                onTap: () async {
                                  setState(() => _selected = i);
                                  if (path != null) {
                                    await _showMonsterModal(
                                        context, path, _items[i].displayName);
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: AppColors.rarityColorByName(
                                          _items[i].rarity),
                                      width: 2,
                                    ),
                                  ),
                                  clipBehavior: Clip.hardEdge,
                                  child: path == null
                                      ? const SizedBox.shrink()
                                      : SizedBox.expand(
                                          child: Image.asset(
                                            path,
                                            fit: BoxFit.contain,
                                            filterQuality: FilterQuality.none,
                                          ),
                                        ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                _MonsterDetailsPanel(
                    item: _selected >= 0 ? _items[_selected] : null),
              ],
            ),
    );
  }

  Future<void> _showMonsterModal(
      BuildContext context, String path, String title) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(ctx).pop(),
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: () => Navigator.of(ctx).pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surface
                      .withValues(alpha: 0.9),
                  border: Border.all(
                      color: Theme.of(context).colorScheme.outline, width: 2),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    // Large crisp pixel render
                    SizedBox(
                      width: 256,
                      height: 256,
                      child: Image.asset(
                        path,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MonsterDetailsPanel extends StatelessWidget {
  final _MonsterUi? item;
  const _MonsterDetailsPanel({required this.item});
  @override
  Widget build(BuildContext context) {
    if (item == null) {
      return Container(
          height: 160,
          alignment: Alignment.center,
          child: const Text('Tap a monster to see details'));
    }
    final m = item!;
    final rarityText = m.rarity[0].toUpperCase() + m.rarity.substring(1);
    final dateStr = m.sourceDate != null
        ? DateFormat('d/M/yyyy').format(m.sourceDate!)
        : '—';
    final extra = MediaQuery.of(context).size.height * 0.05;
    final rarityColor = AppColors.rarityColorByName(m.rarity);
    return Container(
      height: 180 + extra,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          border: Border(
              top: BorderSide(
                  color: Theme.of(context).colorScheme.outline, width: 1))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(m.displayName, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: rarityColor.withValues(alpha: 0.15),
              border: Border.all(color: rarityColor),
            ),
            child: Text('Rarity: $rarityText • Level: ${m.level}',
                style: Theme.of(context).textTheme.bodySmall),
          ),
          const SizedBox(height: 8),
          Text('Type: ${_titleCase(m.type)} • Element: ${m.element}',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Text('Source: ${m.sourceTitle ?? 'Unknown'} ($dateStr)',
              style: Theme.of(context).textTheme.bodySmall),
          const Spacer(),
        ],
      ),
    );
  }
}

String _titleCase(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
