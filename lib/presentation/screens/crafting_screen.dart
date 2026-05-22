import 'dart:async';
import 'package:flutter/material.dart';
import '../../crafting/models.dart';
import '../../crafting/asset_index_service.dart';
import '../../crafting/crafting_service.dart';
import '../../crafting/inventory_service.dart';
import '../../crafting/gear_catalog_service.dart';
import '../../data/hive/boxes.dart';
import '../../data/repos/equipment_repo.dart';
import '../widgets/echo_wisp_icon.dart';
import '../widgets/item_icon_badge.dart';
import '../widgets/pixel_button.dart';
import '../widgets/item_stats_line.dart';

class CraftingScreen extends StatefulWidget {
  const CraftingScreen({super.key});
  @override
  State<CraftingScreen> createState() => _CraftingScreenState();
}

class _CraftingScreenState extends State<CraftingScreen> {
  Echo? _selEchoA;
  Echo? _selEchoB;
  CraftedItem? _selItemA; // left item slot for item+item
  CraftedItem? _selItem; // right item slot for upgrade or item+item
  Echo? _previewEcho; // selected from list for details
  CraftedItem? _previewItem; // selected from list for details
  bool _busy = false;
  late final AssetIndexService _assets;

  @override
  void initState() {
    super.initState();
    _assets = AssetIndexService();
    _assets.init();
    // Preload gear catalog for naming/asset mapping
    GearCatalogService().init();
  }

  Color _echoColor(Echo e) {
    switch (e.element) {
      case ElementType.fire:
        return Colors.deepOrange;
      case ElementType.water:
        return Colors.lightBlueAccent;
      case ElementType.air:
        return Colors.cyanAccent;
      case ElementType.nature:
        return Colors.greenAccent;
      case ElementType.metal:
        return Colors.grey;
      case ElementType.light:
        return Colors.amberAccent;
      case ElementType.shadow:
        return Colors.purpleAccent;
    }
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

  List<Echo> _loadEchoes() {
    try {
      final list = resonantEchoBox().values.toList();
      return list.map((r) {
        final el = _parseElement(r.element);
        final rar = _parseRarity(r.rarity);
        return Echo(
            id: r.echoId,
            element: el,
            rarity: rar,
            createdAt: r.createdAt,
            journalTitles: [r.title],
            entryId: r.entryId);
      }).toList();
    } catch (_) {
      return const <Echo>[];
    }
  }

  ElementType _parseElement(String s) {
    final key = s.toLowerCase();
    for (final e in ElementType.values) {
      if (e.name == key) return e;
    }
    return ElementType.shadow;
  }

  Rarity _parseRarity(String s) {
    final key = s.toLowerCase();
    for (final r in Rarity.values) {
      if (r.name == key) return r;
    }
    return Rarity.common;
  }

  bool _isEchoSelected(String echoId) =>
      _selEchoA?.id == echoId || _selEchoB?.id == echoId;

  bool _isItemSelected(String itemId) =>
      _selItemA?.id == itemId || _selItem?.id == itemId;

  Future<void> _forge() async {
    if (_busy) return;
    if ((_selEchoA != null && _selEchoA!.id == _selEchoB?.id) ||
        (_selItemA != null && _selItemA!.id == _selItem?.id)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Each forging slot needs a different ingredient.'),
        ),
      );
      return;
    }
    if (!mounted) return;
    setState(() {
      _busy = true;
    });
    await Future.delayed(const Duration(seconds: 2));
    final svc = CraftingService(_assets);
    final String playerClass = _playerClass();
    CraftedItem? result;
    if (_selItemA == null &&
        _selItem == null &&
        _selEchoA != null &&
        _selEchoB != null) {
      result = await svc.craftArmorFromEchoes(_selEchoA!, _selEchoB!,
          playerClass: playerClass);
    } else if (_selItem != null &&
        _selEchoA != null &&
        _selItemA == null &&
        _selEchoB == null) {
      result = await svc.upgradeWithEcho(_selItem!, _selEchoA!,
          playerClass: playerClass);
    } else if (_selItemA != null &&
        _selItem != null &&
        _selEchoA == null &&
        _selEchoB == null) {
      result = await svc.craftFromItems(_selItemA!, _selItem!,
          playerClass: playerClass);
    }
    if (result != null) {
      // Consume inputs
      try {
        if (_selItemA == null &&
            _selItem == null &&
            _selEchoA != null &&
            _selEchoB != null) {
          // Echo + Echo → remove both echoes
          await resonantEchoBox().delete(_selEchoA!.id);
          await resonantEchoBox().delete(_selEchoB!.id);
        } else if (_selItem != null &&
            _selEchoA != null &&
            _selItemA == null &&
            _selEchoB == null) {
          // Item + Echo → consume echo only; item is upgraded in-place (same id)
          await resonantEchoBox().delete(_selEchoA!.id);
        } else if (_selItemA != null &&
            _selItem != null &&
            _selEchoA == null &&
            _selEchoB == null) {
          // Item + Item → consume both items
          CraftedInventoryService.remove(_selItemA!.id);
          CraftedInventoryService.remove(_selItem!.id);
          // If consumed items were equipped, auto-equip the result
          await _autoEquipReplacement(
              consumedIds: {_selItemA!.id, _selItem!.id}, replacement: result);
        }
      } catch (_) {}
      // Save result
      CraftedInventoryService.upsert(result);
      if (!mounted) return;
      await showDialog(
          context: context, builder: (_) => _ResultDialog(item: result!));
      // Clear selection after crafting
      setState(() {
        _selEchoA = null;
        _selEchoB = null;
        _selItemA = null;
        _selItem = null;
      });
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
    });
  }

  String _playerClass() {
    try {
      final v = profileBox().values;
      if (v.isNotEmpty) return v.first.classKey;
    } catch (_) {}
    return 'Sage';
  }

  Future<void> _autoEquipReplacement(
      {required Set<String> consumedIds,
      required CraftedItem replacement}) async {
    try {
      final repo = EquipmentRepoImpl();
      final slots = await repo.getAllSlots();
      Future<String> resolveTarget(
          Map<String, EquippedItem?> eq, String? preferRingSide) async {
        if (replacement.def.equipSlot == 'neck') return 'neck';
        if (replacement.def.equipSlot == 'ring') {
          if (preferRingSide == 'ringLeft' || preferRingSide == 'ringRight') {
            return preferRingSide!;
          }
          if (eq['ringLeft'] == null) return 'ringLeft';
          if (eq['ringRight'] == null) return 'ringRight';
          return 'ringLeft';
        }
        return replacement.def.slot.name;
      }

      for (final entry in slots.entries) {
        final slotKey = entry.key;
        final equipped = entry.value;
        if (equipped == null) continue;
        if (!consumedIds.contains(equipped.id)) continue;
        await repo.setItem(slotKey, null);
        final target = await resolveTarget(slots,
            (slotKey == 'ringLeft' || slotKey == 'ringRight') ? slotKey : null);
        await repo.setItem(
            target,
            EquippedItem(
              id: replacement.id,
              name: replacement.displayName,
              rarity: replacement.rarity.name,
              element: replacement.element.name,
            ));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final bg = Image.asset('assets/images/crafting/crafting_background.png',
        fit: BoxFit.cover,
        filterQuality: FilterQuality.none,
        errorBuilder: (_, __, ___) => const SizedBox.shrink());
    final echoes = _loadEchoes();
    final items = CraftedInventoryService.all();

    final canForge = (!_busy) &&
        ((_selItemA == null &&
                _selItem == null &&
                _selEchoA != null &&
                _selEchoB != null) ||
            (_selItem != null &&
                _selEchoA != null &&
                _selItemA == null &&
                _selEchoB == null) ||
            (_selItemA != null &&
                _selItem != null &&
                _selEchoA == null &&
                _selEchoB == null));

    return Scaffold(
      appBar: AppBar(title: const Text('Crafting')),
      body: Column(children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(fit: StackFit.expand, children: [
            bg,
            Padding(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(builder: (context, cts) {
                // Make slots as large as possible side-by-side, with fixed spacing
                const spacing = 24.0;
                final maxSlotByWidth = (cts.biggest.width - spacing) / 2.0;
                final maxSlotByHeight =
                    cts.biggest.height * 0.55; // leave room for button
                final base = maxSlotByWidth < maxSlotByHeight
                    ? maxSlotByWidth
                    : maxSlotByHeight;
                final slotSize = base * 0.75; // scale down to avoid overflow
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _ForgeSideSlot(
                          size: slotSize,
                          title: '',
                          onClear: (_selItemA != null || _selEchoA != null)
                              ? () => setState(() {
                                    _selItemA = null;
                                    _selEchoA = null;
                                  })
                              : null,
                          child: _CraftSlotBox(
                            size: slotSize,
                            child: _selItemA != null
                                ? ItemIconBadge(
                                    iconPath: _selItemA!.def.iconPath,
                                    rarity: _selItemA!.rarity,
                                    element: _selItemA!.element,
                                    tier: _selItemA!.tier,
                                    size: slotSize * 0.45,
                                    framed: false)
                                : (_selEchoA == null
                                    ? const Text('Select',
                                        style: TextStyle(fontSize: 5))
                                    : EchoWispIcon(
                                        color: _echoColor(_selEchoA!),
                                        seed: _selEchoA!.id,
                                        size: slotSize * 0.45,
                                        pixelate: true,
                                        pixels: 16)),
                          ),
                        ),
                        const SizedBox(width: spacing),
                        _ForgeSideSlot(
                          size: slotSize,
                          title: '',
                          onClear: (_selItem != null || _selEchoB != null)
                              ? () => setState(() {
                                    _selItem = null;
                                    _selEchoB = null;
                                  })
                              : null,
                          child: _CraftSlotBox(
                            size: slotSize,
                            child: _selItem != null
                                ? ItemIconBadge(
                                    iconPath: _selItem!.def.iconPath,
                                    rarity: _selItem!.rarity,
                                    element: _selItem!.element,
                                    tier: _selItem!.tier,
                                    size: slotSize * 0.45,
                                    framed: false)
                                : (_selEchoB == null
                                    ? const Text('Select',
                                        style: TextStyle(fontSize: 5))
                                    : EchoWispIcon(
                                        color: _echoColor(_selEchoB!),
                                        seed: _selEchoB!.id,
                                        size: slotSize * 0.45,
                                        pixelate: true,
                                        pixels: 16)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    PixelButton(
                        label: 'Forge Now',
                        onPressed: canForge ? _forge : null,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6)),
                  ],
                );
              }),
            ),
          ]),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(children: [
              Expanded(
                  child: _ListPanel(title: 'Resonant Echoes', children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 1),
                    itemCount: echoes.length,
                    itemBuilder: (_, i) {
                      final e = echoes[i];
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _previewEcho = e;
                            _previewItem = null;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.2),
                            border: Border.all(
                                color:
                                    Colors.tealAccent.withValues(alpha: 0.6)),
                          ),
                          alignment: Alignment.center,
                          child: EchoWispIcon(
                              color: _echoColor(e),
                              seed: e.id,
                              size: 24,
                              pixelate: true,
                              pixels: 16),
                        ),
                      );
                    },
                  ),
                )
              ])),
              const SizedBox(width: 8),
              Expanded(
                  child: _ListPanel(title: 'Weapons & Armor', children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 1),
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final it = items[i];
                      final border = _rarityColor(it.rarity);
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _previewItem = it;
                            _previewEcho = null;
                          });
                        },
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
                              framed: false),
                        ),
                      );
                    },
                  ),
                )
              ])),
            ]),
          ),
        ),
        _CraftDetailsPanel(
          echo: _previewEcho,
          item: _previewItem,
          onAddA: _previewEcho == null || _isEchoSelected(_previewEcho!.id)
              ? null
              : () {
                  setState(() {
                    _selEchoA = _previewEcho;
                    _previewEcho = null;
                  });
                },
          onAddB: _previewEcho == null || _isEchoSelected(_previewEcho!.id)
              ? null
              : () {
                  setState(() {
                    _selEchoB = _previewEcho;
                    _previewEcho = null;
                  });
                },
          onAddItemA: _previewItem == null || _isItemSelected(_previewItem!.id)
              ? null
              : () {
                  setState(() {
                    _selItemA = _previewItem;
                    _selEchoA = null;
                    _previewItem = null;
                  });
                },
          onAddItemB: _previewItem == null || _isItemSelected(_previewItem!.id)
              ? null
              : () {
                  setState(() {
                    _selItem = _previewItem;
                    _selEchoB = null;
                    _previewItem = null;
                  });
                },
        ),
        if (_busy) const LinearProgressIndicator(minHeight: 2),
      ]),
    );
  }
}

class _ListPanel extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _ListPanel({required this.title, required this.children});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          border:
              Border.all(color: Theme.of(context).colorScheme.outlineVariant)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: double.infinity,
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.25),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Builder(builder: (context) {
            final base = Theme.of(context).textTheme.labelLarge;
            final baseSize = base?.fontSize ?? 14;
            final bigger = base?.copyWith(fontSize: baseSize * 1.25) ??
                TextStyle(fontSize: (baseSize * 1.25));
            return Text(title, style: bigger, textAlign: TextAlign.center);
          }),
        ),
        Expanded(child: ListView(children: children)),
      ]),
    );
  }
}

// Legacy chips removed (grids and bottom panel now handle details)

class _ResultDialog extends StatelessWidget {
  final CraftedItem item;
  const _ResultDialog({required this.item});
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Forged!'),
      content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.displayName),
            const SizedBox(height: 4),
            Text('Slot: ${_prettySlotLabel(item.def)}  Tier ${item.tier}'),
            Text('Rarity: ${item.rarity.name}  Element: ${item.element.name}'),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Stats: ', style: TextStyle(fontSize: 12)),
              Expanded(
                  child:
                      ItemStatsLine(stats: item.stats, element: item.element)),
            ]),
            if (item.classAffinity != null)
              Text('Affinity: ${item.classAffinity}'),
          ]),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue Crafting')),
      ],
    );
  }
}

class _CraftSlotBox extends StatelessWidget {
  final double size;
  final Widget child;
  const _CraftSlotBox({required this.size, required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.25),
        border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant, width: 1.2),
      ),
      child: child,
    );
  }
}

// Legacy slot previews removed in favor of _ForgeSideSlot + _CraftSlotBox

class _ForgeSideSlot extends StatelessWidget {
  final double size;
  final String title;
  final Widget child;
  final VoidCallback? onClear;
  const _ForgeSideSlot(
      {required this.size,
      required this.title,
      required this.child,
      this.onClear});
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (title.isNotEmpty)
          SizedBox(
              width: size,
              child: Text(title,
                  style: const TextStyle(fontSize: 5),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center)),
        const SizedBox(height: 4),
        child,
        const SizedBox(height: 4),
        if (onClear != null)
          SizedBox(
            width: size,
            child: TextButton(
                onPressed: onClear,
                child: const Text('Clear', style: TextStyle(fontSize: 11))),
          )
      ],
    );
  }
}

String _prettySlotLabel(ItemDef def) {
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

class _CraftDetailsPanel extends StatelessWidget {
  final Echo? echo;
  final CraftedItem? item;
  final VoidCallback? onAddA;
  final VoidCallback? onAddB;
  final VoidCallback? onAddItemA;
  final VoidCallback? onAddItemB;
  const _CraftDetailsPanel(
      {required this.echo,
      required this.item,
      this.onAddA,
      this.onAddB,
      this.onAddItemA,
      this.onAddItemB});
  @override
  Widget build(BuildContext context) {
    if (echo == null && item == null) return const SizedBox.shrink();
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
            if (echo != null) ...[
              Row(children: [
                EchoWispIcon(
                    color: _colorForEcho(echo!),
                    seed: echo!.id,
                    size: 20,
                    pixelate: true,
                    pixels: 16),
                const SizedBox(width: 8),
                _pill(
                    text: echo!.rarity.name.toUpperCase(),
                    color: _rarityColor(echo!.rarity)),
                const SizedBox(width: 6),
                _pill(
                    text: echo!.element.name,
                    color: _elementColor(echo!.element)),
              ]),
              const SizedBox(height: 4),
              _echoMeta(context, echo!, small),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(spacing: 8, children: [
                  if (onAddA != null)
                    OutlinedButton(
                        onPressed: onAddA,
                        child: const Text('Add to A',
                            style: TextStyle(fontSize: 12))),
                  if (onAddB != null)
                    OutlinedButton(
                        onPressed: onAddB,
                        child: const Text('Add to B',
                            style: TextStyle(fontSize: 12))),
                ]),
              )
            ],
            if (item != null) ...[
              Text(item!.displayName, style: small),
              const SizedBox(height: 2),
              Text(
                  'Slot: ${_prettySlotLabel(item!.def)}  Tier ${item!.tier}  Rarity: ${item!.rarity.name}',
                  style: small),
              const SizedBox(height: 2),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Stats: ', style: small),
                Expanded(
                    child: ItemStatsLine(
                        stats: item!.stats,
                        element: item!.element,
                        style: small)),
              ]),
              if (item!.dnaJournalTitles.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('Echo Titles', style: small),
                const SizedBox(height: 2),
                ...item!.dnaJournalTitles
                    .take(3)
                    .map((t) => Text('• $t', style: small)),
              ],
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(spacing: 8, children: [
                  if (onAddItemA != null)
                    OutlinedButton(
                        onPressed: onAddItemA,
                        child: const Text('Add to A',
                            style: TextStyle(fontSize: 12))),
                  if (onAddItemB != null)
                    OutlinedButton(
                        onPressed: onAddItemB,
                        child: const Text('Add to B',
                            style: TextStyle(fontSize: 12))),
                ]),
              )
            ]
          ]),
    );
  }

  Color _colorForEcho(Echo e) {
    switch (e.element) {
      case ElementType.fire:
        return Colors.deepOrange;
      case ElementType.water:
        return Colors.lightBlueAccent;
      case ElementType.air:
        return Colors.cyanAccent;
      case ElementType.nature:
        return Colors.greenAccent;
      case ElementType.metal:
        return Colors.grey;
      case ElementType.light:
        return Colors.amberAccent;
      case ElementType.shadow:
        return Colors.purpleAccent;
    }
  }

  // UI helpers
  Widget _pill({required String text, required Color color}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          border: Border.all(color: color, width: 1),
        ),
        child: Text(text, style: const TextStyle(fontSize: 10)),
      );

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

  Color _elementColor(ElementType e) => _colorForEcho(Echo(
      id: '',
      element: e,
      rarity: Rarity.common,
      createdAt: DateTime.now(),
      journalTitles: const []));

  Widget _echoMeta(BuildContext context, Echo e, TextStyle small) {
    // Pull JournalSeedMeta where available for extra info
    String? primaryTag;
    String? title = e.journalTitles.isNotEmpty ? e.journalTitles.first : null;
    try {
      if (e.entryId != null) {
        final m = journalSeedMetaBox().get(e.entryId!);
        if (m != null) {
          final mt = (m.title ?? '');
          title = mt.isNotEmpty ? mt : title;
          primaryTag = m.primaryTag;
        }
      }
    } catch (_) {}
    final dateStr =
        '${e.createdAt.year}-${e.createdAt.month.toString().padLeft(2, '0')}-${e.createdAt.day.toString().padLeft(2, '0')}';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (title != null && title.isNotEmpty) Text(title, style: small),
      Row(children: [
        Text(dateStr, style: small),
        if (primaryTag != null && primaryTag.isNotEmpty) ...[
          const SizedBox(width: 6),
          _pill(text: primaryTag, color: Theme.of(context).colorScheme.outline),
        ]
      ])
    ]);
  }
}
