import 'package:flutter/material.dart';
import '../../services/inventory_service.dart';
import '../../data/hive/boxes.dart';

class ItemsScreen extends StatefulWidget {
  final String? slot; // equipment slot if navigated from a gear slot
  const ItemsScreen({super.key, this.slot});
  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  late List<Map<String, dynamic>> _inventory;
  late List<String> _quickSlots;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _inventory = InventoryService.inventory();
    _quickSlots = InventoryService.quickSlots();
    setState(() {});
  }

  void _assignToSlot(String itemId) async {
    final slot = await showDialog<int>(context: context, builder: (ctx) {
      return SimpleDialog(title: const Text('Assign to Quick Slot'), children: [
        for (int i = 0; i < 4; i++)
          SimpleDialogOption(onPressed: () => Navigator.pop(ctx, i), child: Text('Slot ${i + 1}')),
      ]);
    });
    if (slot == null) return;
    // ensure list length 4
    while (_quickSlots.length < 4) { _quickSlots.add(''); }
    _quickSlots[slot] = itemId;
    InventoryService.setQuickSlots(_quickSlots);
    _reload();
  }

  // Quick slots are indicators only here; no unassign action in this view.

  bool _isHealing(String type) =>
      type == 'potion_small' || type == 'fruit' || type == 'food';

  int _healAmount(String type) {
    switch (type) {
      case 'potion_small': return 20;
      case 'fruit': return 10;
      case 'food': return 15;
      default: return 0;
    }
  }

  Future<void> _useItem(Map<String, dynamic> item) async {
    final id = item['id'] as String;
    final type = item['type']?.toString() ?? '';
    if (!_isHealing(type)) return;
    final amt = _healAmount(type);
    // Compute current and max HP similar to battle init
    try {
      final meta = playerMetaBox();
      int hp = (meta.get('hp') as int?) ?? 0;
      const int baseHp = 60;
      // Class HP perk
      int classHp = 12;
      int level = 1;
      try {
        final vals = profileBox().values;
        if (vals.isNotEmpty) {
          final cls = vals.first.classKey; level = vals.first.level;
          switch (cls) {
            case 'Warden': classHp = 20; break;
            case 'Trickster': classHp = 10; break;
            case 'Sage': classHp = 12; break;
            case 'Sentinel': classHp = 16; break;
            case 'Seer': classHp = 12; break;
            case 'Artificer': classHp = 14; break;
            case 'Empath': classHp = 14; break;
            case 'Oracle': classHp = 12; break;
            case 'Shadow': classHp = 13; break;
            case 'Alchemist': classHp = 15; break;
            default: classHp = 12; break;
          }
        }
      } catch (_) {}
      final hpLv = ((level - 1).clamp(0, 999)) * 3;
      // Sprite HP from equipped slots
      int spriteHp = 0;
      try {
        final raw = (equipmentBox().get('sprite_slots') as Map?)?.map((k, v) => MapEntry(k.toString(), v?.toString())) ?? const <String, String?>{};
        for (final sid in ['sprite1','sprite2']) {
          final sidv = raw[sid];
          if (sidv == null || sidv.isEmpty) continue;
          try { final inst = seedInstanceBox().values.firstWhere((e) => e.instanceId == sidv); spriteHp += (inst.stats['hp'] ?? 0); } catch (_) {}
        }
      } catch (_) {}
      final maxHp = baseHp + classHp + hpLv + spriteHp;
      final newHp = (hp + amt).clamp(0, maxHp);
      await meta.put('hp', newHp);
      // Consume from inventory
      InventoryService.consume(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Healed +$amt HP')),
        );
      }
      _reload();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to use item')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Items')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quick Items (4 slots)'),
            const SizedBox(height: 8),
            // Small, non-interactive indicators for quick slots
            Row(children: [
              for (int i = 0; i < 4; i++) ...[
                Expanded(
                  child: _QuickSlot(
                    index: i,
                    item: (i < _quickSlots.length && _quickSlots[i].isNotEmpty)
                        ? InventoryService.getById(_quickSlots[i])
                        : null,
                  ),
                ),
                if (i != 3) const SizedBox(width: 6),
              ]
            ]),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            const Text('Inventory'),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: _inventory.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final it = _inventory[i];
                  final type = it['type'] as String;
                  final isHealing = _isHealing(type);
                  return ListTile(
                    title: Text(ItemEffects.label(type)),
                    subtitle: Text('x${it['qty']}'),
                    trailing: Wrap(spacing: 8, children: [
                      if (isHealing)
                        TextButton(
                          onPressed: (it['qty'] as int) > 0 ? () => _useItem(it) : null,
                          child: const Text('Use'),
                        ),
                      TextButton(
                        onPressed: () => _assignToSlot(it['id'] as String),
                        child: const Text('Equip'),
                      ),
                    ]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickSlot extends StatelessWidget {
  final int index;
  final Map<String, dynamic>? item;
  const _QuickSlot({required this.index, required this.item});
  @override
  Widget build(BuildContext context) {
    final label = item == null ? 'Empty' : ItemEffects.label(item!['type'] as String);
    final qty = (item == null) ? '' : ' x${item!['qty']}';
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)),
      alignment: Alignment.center,
      child: Text('S${index + 1}: $label$qty', style: Theme.of(context).textTheme.labelSmall),
    );
  }
}
