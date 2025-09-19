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
  Map<String, dynamic>? _preview;

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
      body: Column(children: [
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: _inventory.length,
            itemBuilder: (_, i) {
              final it = _inventory[i];
              final type = it['type'] as String;
              final asset = ItemCatalog.assetOf(type);
              final hasAsset = asset != null && PixelAssets.has(asset);
              return InkWell(
                onTap: () => setState(() => _preview = it),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant, width: 1.2),
                  ),
                  alignment: Alignment.center,
                  child: hasAsset
                      ? Image.asset(asset, width: 40, height: 40, filterQuality: FilterQuality.none, errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2_outlined, size: 24))
                      : const Icon(Icons.inventory_2_outlined, size: 24),
                ),
              );
            },
          ),
        ),
        _ItemDetailsPanel(item: _preview, onUse: _preview == null ? null : () => _useItem(_preview!)),
      ]),
    );
  }
}

class _ItemDetailsPanel extends StatelessWidget {
  final Map<String, dynamic>? item;
  final VoidCallback? onUse;
  const _ItemDetailsPanel({required this.item, this.onUse});
  @override
  Widget build(BuildContext context) {
    if (item == null) return const SizedBox.shrink();
    final type = item!['type']?.toString() ?? '';
    final label = ItemEffects.label(type);
    final def = ItemCatalog.defOf(type);
    final qty = item!['qty'] ?? 0;
    final small = Theme.of(context).textTheme.labelSmall ?? const TextStyle(fontSize: 11);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant))),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium, softWrap: true),
          const SizedBox(height: 4),
          Text('Qty: $qty', style: small),
          if (def != null) ...[
            const SizedBox(height: 2),
          Text('Type: ${_prettyCategory(def.category)}', style: small),
            ...(() {
              final effects = _effectTexts(def);
              if (effects.isEmpty) return <Widget>[];
              return <Widget>[
                const SizedBox(height: 6),
                Text('Effects', style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 2),
                ...effects.map((t) => Text('• $t', style: small)),
              ];
            })(),
          ],
        ])),
        FilledButton(onPressed: onUse, child: const Text('Use')),
      ]),
    );
  }

  String _prettyCategory(String c) {
    if (c.isEmpty) return c;
    return c[0].toUpperCase() + c.substring(1);
  }

  List<String> _effectTexts(ItemDef def) {
    final lines = <String>[];
    // Healing
    if (def.healInstant != null && def.healInstant! > 0) {
      lines.add('Heals ${def.healInstant} HP instantly');
    }
    if (def.regenPerTurn != null && def.regenTurns != null && def.regenPerTurn! > 0 && def.regenTurns! > 0) {
      final total = def.regenPerTurn! * def.regenTurns!;
      lines.add('Regenerates ${def.regenPerTurn} HP/turn for ${def.regenTurns} turns (total $total)');
    }
    // Buffs / Debuffs / Status
    if (def.buffKey != null) {
      final k = def.buffKey!;
      final mag = def.buffMagnitude;
      final dur = def.buffDuration;
      final enemy = def.buffTargetsEnemy;
      final tgt = enemy ? ' (enemy)' : '';
      String text;
      switch (k) {
        case 'atk+':
          text = 'ATK +${mag ?? 1} for ${dur ?? 1} turns$tgt';
          break;
        case 'def+':
          text = 'DEF +${mag ?? 1} for ${dur ?? 1} turns$tgt';
          break;
        case 'atk-':
          text = 'ATK -${mag ?? 1} for ${dur ?? 1} turns$tgt';
          break;
        case 'def-':
          text = 'DEF -${mag ?? 1} for ${dur ?? 1} turns$tgt';
          break;
        case 'guard':
          text = 'Guard +${mag ?? 1} for ${dur ?? 1} turns$tgt';
          break;
        case 'spirit+':
          text = 'SPIRIT +${mag ?? 1} for ${dur ?? 1} turns$tgt';
          break;
        case 'focus':
          text = 'Focus +${mag ?? 1} for ${dur ?? 1} turns$tgt';
          break;
        case 'regen':
          text = 'Regen +${mag ?? 1} for ${dur ?? 1} turns$tgt';
          break;
        default:
          String magStr = '';
          if (mag != null) {
            final sign = mag > 0 ? '+' : '';
            magStr = ' $sign$mag';
          }
          final durStr = (dur != null) ? ' for $dur turns' : '';
          text = '${k.toUpperCase()}$magStr$durStr$tgt';
      }
      lines.add(text);
    }
    // Utility effects
    if (def.cleanseAll) lines.add('Cleanses all negative statuses');
    if (def.antidote) lines.add('Cures poison');
    if (def.reduceCooldowns != null && def.reduceCooldowns! > 0) {
      lines.add('Reduces cooldowns by ${def.reduceCooldowns}');
    }
    if (def.damage != null && def.damage! > 0) {
      lines.add('Deals ${def.damage} damage');
    }
    if (def.fullHealOutOfBattle) {
      lines.add('Fully restores HP outside battle');
    }
    return lines;
  }
}
