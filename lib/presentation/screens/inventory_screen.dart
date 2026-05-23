import 'package:flutter/material.dart';
import '../../crafting/models.dart';
import '../../crafting/inventory_service.dart';
import '../../data/repos/equipment_repo.dart';
import '../widgets/item_icon_badge.dart';
import '../../services/achievement_service.dart';
import '../widgets/item_stats_line.dart';
import '../widgets/item_provenance_block.dart';

class InventoryScreen extends StatefulWidget {
  final String? filter; // slot name or 'weapon'
  const InventoryScreen({super.key, this.filter});
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<CraftedItem> _items = const [];
  CraftedItem? _preview;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final f = (widget.filter ?? '').toLowerCase();
    final slot = _parseSlot(widget.filter);
    if (f == 'neck' || f == 'ring') {
      final all = CraftedInventoryService.all();
      _items =
          all.where((e) => (e.def.equipSlot ?? '').toLowerCase() == f).toList();
    } else {
      _items = (slot == null)
          ? CraftedInventoryService.all()
          : CraftedInventoryService.bySlot(slot);
    }
    setState(() {});
  }

  SlotId? _parseSlot(String? s) {
    if (s == null || s.isEmpty) return null;
    for (final v in SlotId.values) {
      if (v.name == s) return v;
    }
    return null;
  }

  Future<void> _equip(CraftedItem it) async {
    final repo = EquipmentRepoImpl();
    // Choose target slot: prefer equipSlot override when present
    String target = it.def.slot.name;
    if (it.def.equipSlot != null && it.def.equipSlot!.isNotEmpty) {
      final eq = await repo.getAllSlots();
      if (it.def.equipSlot == 'neck') {
        target = 'neck';
      } else if (it.def.equipSlot == 'ring') {
        // pick first empty ring, else ringLeft
        target = (eq['ringLeft'] == null)
            ? 'ringLeft'
            : ((eq['ringRight'] == null) ? 'ringRight' : 'ringLeft');
      }
    }
    await repo.setItem(
        target,
        EquippedItem(
            id: it.id,
            name: it.displayName,
            rarity: it.rarity.name,
            element: it.element.name));
    // Achievements
    try {
      await AchievementService().recordEquip(it);
    } catch (_) {}
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Equipped ${it.displayName} to $target.')));
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      body: Column(children: [
        if ((widget.filter ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.filter!,
                style: Theme.of(context).textTheme.titleMedium,
                softWrap: true,
              ),
            ),
          ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: _items.length,
            itemBuilder: (_, i) {
              final it = _items[i];
              final border = _rarityColor(it.rarity);
              return InkWell(
                onTap: () => setState(() => _preview = it),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.15),
                    border: Border.all(color: border, width: 1.2),
                  ),
                  alignment: Alignment.center,
                  child: ItemIconBadge(
                    iconPath: it.def.iconPath,
                    rarity: it.rarity,
                    element: it.element,
                    tier: it.tier,
                    size: 56,
                    framed: false,
                  ),
                ),
              );
            },
          ),
        ),
        _InventoryDetailsPanel(
          item: _preview,
          onEquip: _preview == null ? null : () => _equip(_preview!),
          onClose: () => setState(() => _preview = null),
        )
      ]),
    );
  }

  Color _rarityColor(Rarity r) {
    switch (r) {
      case Rarity.uncommon:
        return Colors.blueAccent;
      case Rarity.rare:
        return Colors.purpleAccent;
      case Rarity.epic:
        return Colors.orangeAccent;
      case Rarity.legendary:
        return Colors.cyanAccent;
      case Rarity.common:
        return Colors.grey;
    }
  }
}

class _InventoryDetailsPanel extends StatelessWidget {
  final CraftedItem? item;
  final VoidCallback? onEquip;
  final VoidCallback? onClose;
  const _InventoryDetailsPanel(
      {required this.item, this.onEquip, this.onClose});
  @override
  Widget build(BuildContext context) {
    if (item == null) return const SizedBox.shrink();
    final small =
        Theme.of(context).textTheme.labelSmall ?? const TextStyle(fontSize: 11);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          border: Border(
              top: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant))),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              ItemIconBadge(
                  iconPath: item!.def.iconPath,
                  rarity: item!.rarity,
                  element: item!.element,
                  tier: item!.tier,
                  size: 28),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(item!.displayName,
                      style: Theme.of(context).textTheme.bodyMedium,
                      softWrap: true)),
              IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
            ]),
            const SizedBox(height: 4),
            Text(
                'Slot: ${_slotLabel(item!.def)}  Tier ${item!.tier}  Rarity: ${item!.rarity.name}',
                style: small),
            if ((item!.classAffinity ?? item!.def.classAffinity) != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                    'Class Affinity: ${(item!.classAffinity ?? item!.def.classAffinity)!}',
                    style: small),
              ),
            const SizedBox(height: 2),
            if (item!.stats.isNotEmpty)
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Stats: ', style: small),
                Expanded(
                    child: ItemStatsLine(
                        stats: item!.stats,
                        element: item!.element,
                        style: small)),
              ]),
            if ((item!.stats).isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Effects', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 2),
              ..._effectTexts(item!.stats)
                  .map((t) => Text('• $t', style: small)),
            ],
            if (item!.memorySources.isNotEmpty ||
                item!.lineageSteps.isNotEmpty) ...[
              const SizedBox(height: 8),
              ItemProvenanceBlock(
                item: item!,
                headingStyle: Theme.of(context).textTheme.labelMedium,
                bodyStyle: small,
                maxSources: 5,
                maxLineageSteps: 5,
              ),
            ],
            const SizedBox(height: 6),
            Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                    onPressed: onEquip, child: const Text('Equip'))),
          ]),
    );
  }

  List<String> _effectTexts(Map<String, num> stats) {
    final lines = <String>[];
    // Base stats
    const baseOrder = ['def', 'atk', 'hp', 'spd', 'spirit'];
    for (final k in baseOrder) {
      final v = stats[k];
      if (v != null && v != 0) {
        final iv = v.round();
        final sign = iv > 0 ? '+' : '';
        lines.add('${k.toUpperCase()} $sign$iv');
      }
    }
    // Aggregate mod_* stats
    final mods = <String, int>{};
    stats.forEach((k, v) {
      if (k.startsWith('mod_')) {
        final stat = k.substring(4);
        mods[stat] = (mods[stat] ?? 0) + v.round();
      }
    });
    for (final entry in mods.entries) {
      final k = entry.key.toUpperCase();
      final v = entry.value;
      if (v == 0) continue;
      final sign = v > 0 ? '+' : '';
      lines.add('$k $sign$v');
    }
    // Include any other unknown keys
    stats.forEach((k, v) {
      if (baseOrder.contains(k) || k.startsWith('mod_')) return;
      final iv = v.round();
      if (iv == 0) return;
      final sign = iv > 0 ? '+' : '';
      lines.add('${k.toUpperCase()} $sign$iv');
    });
    return lines;
  }

  String _slotLabel(ItemDef def) {
    final eq = (def.equipSlot ?? '').toLowerCase();
    if (eq == 'ring') return 'Ring';
    if (eq == 'neck') return 'Necklace';
    switch (def.slot) {
      case SlotId.head:
        return 'Head';
      case SlotId.chest:
        return 'Chest';
      case SlotId.hands:
        return 'Hands';
      case SlotId.legs:
        return 'Legs';
      case SlotId.feet:
        return 'Feet';
      case SlotId.weapon:
        return 'Weapon';
    }
  }
}
