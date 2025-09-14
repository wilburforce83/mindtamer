import 'package:flutter/material.dart';
import '../../services/inventory_service.dart';
import '../../services/item_catalog.dart';
import '../../data/hive/boxes.dart';
import '../../core/pixel_assets.dart';

class ItemsScreen extends StatefulWidget {
  final String? slot; // equipment slot if navigated from a gear slot
  const ItemsScreen({super.key, this.slot});
  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  late List<Map<String, dynamic>> _inventory;

  @override
  void initState() {
    super.initState();
    // Load asset manifest so we can gate image loads on availability
    PixelAssets.init().then((_) { if (mounted) setState((){}); });
    _reload();
  }

  void _reload() {
    _inventory = InventoryService.inventory();
    setState(() {});
  }

  // Quick slots are indicators only here; no unassign action in this view.

  bool _isHealing(String type) {
    final def = ItemCatalog.defOf(type);
    if (def == null) return false;
    return def.fullHealOutOfBattle || (def.outOfBattleHealAmount() != null);
  }

  int _healAmount(String type) {
    final def = ItemCatalog.defOf(type);
    if (def == null) return 0;
    return def.outOfBattleHealAmount() ?? 0;
  }

  Future<void> _useItem(Map<String, dynamic> item) async {
    final id = item['id'] as String;
    final type = item['type']?.toString() ?? '';
    if (!_isHealing(type)) return;
    final def = ItemCatalog.defOf(type);
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
      final newHp = (def?.fullHealOutOfBattle == true) ? maxHp : (hp + amt).clamp(0, maxHp);
      await meta.put('hp', newHp);
      // Consume from inventory
      InventoryService.consume(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(def?.fullHealOutOfBattle == true ? 'Fully healed' : 'Healed +$amt HP')),
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
            // Quick slots removed
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
                  final asset = ItemCatalog.assetOf(type);
                  final hasAsset = asset != null && PixelAssets.has(asset);
                  final label = ItemEffects.label(type);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        if (hasAsset)
                          Image.asset(
                            asset,
                            width: 20,
                            height: 20,
                            filterQuality: FilterQuality.none,
                            errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2_outlined, size: 18),
                          )
                        else
                          const Icon(Icons.inventory_2_outlined, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(label, style: Theme.of(context).textTheme.labelSmall, overflow: TextOverflow.ellipsis),
                              Text('x${it['qty']}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.8))),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Wrap(spacing: 6, children: [
                          if (isHealing)
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                visualDensity: VisualDensity.compact,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                minimumSize: const Size(0, 0),
                              ),
                              onPressed: (it['qty'] as int) > 0 ? () => _useItem(it) : null,
                              child: const Text('Use', style: TextStyle(fontSize: 11)),
                            ),
                        ]),
                      ],
                    ),
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
