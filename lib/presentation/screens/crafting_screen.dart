import 'dart:async';
import 'package:flutter/material.dart';
import '../../crafting/models.dart';
import '../../crafting/asset_index_service.dart';
import '../../crafting/crafting_service.dart';
import '../../crafting/inventory_service.dart';
import '../../crafting/gear_catalog_service.dart';
import '../../data/hive/boxes.dart';
import '../../data/repos/equipment_repo.dart';
import '../../services/achievement_service.dart';
import '../../services/crafting_tutorial_service.dart';
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
  bool _introQueued = false;
  late final AssetIndexService _assets;

  @override
  void initState() {
    super.initState();
    _assets = AssetIndexService();
    _assets.init();
    // Preload gear catalog for naming/asset mapping
    GearCatalogService().init();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowCraftingIntro();
    });
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

  bool get _leftHasItem => _selItemA != null;
  bool get _rightHasEcho => _selEchoB != null;

  Future<void> _maybeShowCraftingIntro() async {
    if (!mounted || _introQueued) return;
    if (!CraftingTutorialService.shouldShowCraftingIntro()) return;
    _introQueued = true;
    await CraftingTutorialService.markIntroSeen();
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => const _CraftingTutorialDialog(),
    );
  }

  bool _canAcceptIngredient(_ForgeIngredient data, _ForgeDropSlot slot) {
    if (data.originSlot == slot) {
      return false;
    }
    if (data.echo != null) {
      final id = data.echo!.id;
      final isDuplicate =
          slot == _ForgeDropSlot.left ? _selEchoB?.id == id : _selEchoA?.id == id;
      if (isDuplicate) return false;
      if (slot == _ForgeDropSlot.right && _leftHasItem) {
        return false;
      }
      return true;
    }
    if (data.item != null) {
      final id = data.item!.id;
      final isDuplicate =
          slot == _ForgeDropSlot.left ? _selItem?.id == id : _selItemA?.id == id;
      if (isDuplicate) return false;
      if (slot == _ForgeDropSlot.left && _rightHasEcho) {
        return false;
      }
      return true;
    }
    return false;
  }

  void _acceptIngredient(_ForgeIngredient data, _ForgeDropSlot slot) {
    if (!_canAcceptIngredient(data, slot)) return;
    setState(() {
      if (data.echo != null) {
        if (slot == _ForgeDropSlot.left) {
          _selEchoA = data.echo;
          _selItemA = null;
        } else {
          _selEchoB = data.echo;
          _selItem = null;
        }
        _previewEcho = data.echo;
        _previewItem = null;
        return;
      }
      if (data.item != null) {
        if (slot == _ForgeDropSlot.left) {
          _selItemA = data.item;
          _selEchoA = null;
        } else {
          _selItem = data.item;
          _selEchoB = null;
        }
        _previewItem = data.item;
        _previewEcho = null;
      }
    });
  }

  void _clearSlot(_ForgeDropSlot slot) {
    setState(() {
      if (slot == _ForgeDropSlot.left) {
        _selEchoA = null;
        _selItemA = null;
      } else {
        _selEchoB = null;
        _selItem = null;
      }
    });
  }

  Widget _slotOccupantWidget(_ForgeDropSlot slot, double slotSize) {
    final echo = slot == _ForgeDropSlot.left ? _selEchoA : _selEchoB;
    final item = slot == _ForgeDropSlot.left ? _selItemA : _selItem;
    if (item != null) {
      final child = ItemIconBadge(
        iconPath: item.def.iconPath,
        rarity: item.rarity,
        element: item.element,
        tier: item.tier,
        size: slotSize * 0.45,
        framed: false,
      );
      return _SlottedIngredientDraggable(
        data: _ForgeIngredient.item(item, originSlot: slot),
        feedback: _ForgeFeedback(size: 72, child: child),
        onAcceptedElsewhere: () => _clearSlot(slot),
        child: child,
      );
    }
    if (echo != null) {
      final child = EchoWispIcon(
        color: _echoColor(echo),
        seed: echo.id,
        size: slotSize * 0.45,
        pixelate: true,
        pixels: 16,
      );
      return _SlottedIngredientDraggable(
        data: _ForgeIngredient.echo(echo, originSlot: slot),
        feedback: _ForgeFeedback(size: 72, child: child),
        onAcceptedElsewhere: () => _clearSlot(slot),
        child: child,
      );
    }
    return Icon(Icons.pan_tool_alt_outlined,
        size: slotSize * 0.18,
        color: Theme.of(context).colorScheme.outline);
  }

  String _forgeHintText() {
    if (_selEchoA != null && _selEchoB != null) {
      return 'Ready to forge a fresh gear piece from two echoes.';
    }
    if (_selEchoA != null && _selItem != null) {
      return 'Ready to upgrade this item with your selected echo.';
    }
    if (_selItemA != null && _selItem != null) {
      return 'Ready to fuse two crafted items into a stronger result.';
    }
    if (_selEchoA != null || _selEchoB != null) {
      return 'Drop a second echo for new gear, or pair an echo on the left with an item on the right to upgrade it.';
    }
    if (_selItemA != null || _selItem != null) {
      return 'Drop a second item to fuse gear. For upgrades, place the item on the right slot and an echo on the left.';
    }
    return 'Drag two echoes into the forge to craft your first item. Drag slotted ingredients back into their lists to remove them.';
  }

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
    String? craftMode;
    if (_selItemA == null &&
        _selItem == null &&
        _selEchoA != null &&
        _selEchoB != null) {
      craftMode = 'echo_echo';
      result = await svc.craftArmorFromEchoes(_selEchoA!, _selEchoB!,
          playerClass: playerClass);
    } else if (_selItem != null &&
        _selEchoA != null &&
        _selItemA == null &&
        _selEchoB == null) {
      craftMode = 'item_echo';
      result = await svc.upgradeWithEcho(_selItem!, _selEchoA!,
          playerClass: playerClass);
    } else if (_selItemA != null &&
        _selItem != null &&
        _selEchoA == null &&
        _selEchoB == null) {
      craftMode = 'item_item';
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
      await CraftingTutorialService.markCompleted();
      if (craftMode != null) {
        try {
          await AchievementService().recordCraft(
            mode: craftMode,
            result: result,
          );
        } catch (_) {}
      }
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
      body: LayoutBuilder(builder: (context, constraints) {
        final forgeHeight =
            (constraints.maxHeight * 0.28).clamp(180.0, 280.0).toDouble();
        final detailsMaxHeight =
            (constraints.maxHeight * 0.24).clamp(120.0, 220.0).toDouble();
        return Column(children: [
          SizedBox(
            height: forgeHeight,
            child: Stack(fit: StackFit.expand, children: [
              bg,
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: LayoutBuilder(builder: (context, cts) {
                  const spacing = 18.0;
                  final slotWidth =
                      ((cts.biggest.width - spacing) / 2).clamp(84.0, 150.0);
                  final slotHeight =
                      (cts.biggest.height * 0.55).clamp(84.0, 132.0);
                  final slotSize =
                      (slotWidth < slotHeight ? slotWidth : slotHeight)
                          .toDouble();
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ForgeSideSlot(
                            size: slotSize,
                            title: 'Slot A',
                            child: _ForgeDragTarget(
                              size: slotSize,
                              label: _selItemA == null && _selEchoA == null
                                  ? 'Drag echo or item'
                                  : null,
                              helper:
                                  'Echo = new gear or upgrades. Item = fusion.',
                              onAccept: (data) =>
                                  _acceptIngredient(data, _ForgeDropSlot.left),
                              canAccept: (data) => _canAcceptIngredient(
                                  data, _ForgeDropSlot.left),
                              child: _slotOccupantWidget(
                                  _ForgeDropSlot.left, slotSize),
                            ),
                          ),
                          const SizedBox(width: spacing),
                          _ForgeSideSlot(
                            size: slotSize,
                            title: 'Slot B',
                            child: _ForgeDragTarget(
                              size: slotSize,
                              label: _selItem == null && _selEchoB == null
                                  ? 'Drag echo or item'
                                  : null,
                              helper:
                                  'Echo = new gear. Item = upgrades or fusion.',
                              onAccept: (data) =>
                                  _acceptIngredient(data, _ForgeDropSlot.right),
                              canAccept: (data) => _canAcceptIngredient(
                                  data, _ForgeDropSlot.right),
                              child: _slotOccupantWidget(
                                  _ForgeDropSlot.right, slotSize),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.16),
                border: Border.all(
                  color: Colors.tealAccent.withValues(alpha: 0.28),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.tips_and_updates_outlined,
                      size: 14,
                      color: Colors.tealAccent.withValues(alpha: 0.9)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _forgeHintText(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize:
                                (Theme.of(context).textTheme.labelSmall?.fontSize ??
                                        11) *
                                    0.92,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(children: [
                Expanded(
                    child: _ReturningListPanel(
                        title: 'Resonant Echoes',
                        accepts: (data) =>
                            data.originSlot != null && data.echo != null,
                        onAccept: (data) {
                          setState(() {
                            _previewEcho = data.echo;
                            _previewItem = null;
                          });
                        },
                        children: [
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
                      final selected = _previewEcho?.id == e.id;
                      final inForge = _isEchoSelected(e.id);
                      final card = InkWell(
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
                                color: selected
                                    ? Colors.tealAccent
                                    : Colors.tealAccent
                                        .withValues(alpha: 0.6),
                                width: selected ? 1.5 : 1),
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
                      return Draggable<_ForgeIngredient>(
                        data: _ForgeIngredient.echo(e),
                        feedback: _ForgeFeedback(
                          size: 72,
                          child: EchoWispIcon(
                              color: _echoColor(e),
                              seed: e.id,
                              size: 28,
                              pixelate: true,
                              pixels: 16),
                        ),
                        childWhenDragging:
                            Opacity(opacity: 0.3, child: card),
                        maxSimultaneousDrags: inForge ? 0 : 1,
                        child: card,
                      );
                    },
                    ),
                  )
                ])),
                const SizedBox(width: 8),
                Expanded(
                    child: _ReturningListPanel(
                        title: 'Weapons & Armor',
                        accepts: (data) =>
                            data.originSlot != null && data.item != null,
                        onAccept: (data) {
                          setState(() {
                            _previewItem = data.item;
                            _previewEcho = null;
                          });
                        },
                        children: [
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
                      final selected = _previewItem?.id == it.id;
                      final inForge = _isItemSelected(it.id);
                      final card = InkWell(
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
                            border: Border.all(
                                color: selected ? Colors.white : border,
                                width: selected ? 1.5 : 1.2),
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
                      return Draggable<_ForgeIngredient>(
                        data: _ForgeIngredient.item(it),
                        feedback: _ForgeFeedback(
                          size: 72,
                          child: ItemIconBadge(
                              iconPath: it.def.iconPath,
                              rarity: it.rarity,
                              element: it.element,
                              tier: it.tier,
                              size: 42,
                              framed: false),
                        ),
                        childWhenDragging:
                            Opacity(opacity: 0.3, child: card),
                        maxSimultaneousDrags: inForge ? 0 : 1,
                        child: card,
                      );
                    },
                    ),
                  )
                ])),
              ]),
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: detailsMaxHeight),
            child: _CraftDetailsPanel(
              echo: _previewEcho,
              item: _previewItem,
            ),
          ),
          if (_busy) const LinearProgressIndicator(minHeight: 2),
        ]);
      }),
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
          child: LayoutBuilder(builder: (context, constraints) {
            final base = Theme.of(context).textTheme.labelLarge;
            final baseSize = base?.fontSize ?? 14;
            final fontSize = constraints.maxWidth < 170
                ? baseSize * 0.92
                : baseSize * 1.05;
            final bigger = base?.copyWith(fontSize: fontSize) ??
                TextStyle(fontSize: fontSize);
            return Text(
              title,
              style: bigger,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
              textAlign: TextAlign.center,
            );
          }),
        ),
        Expanded(child: ListView(children: children)),
      ]),
    );
  }
}

class _ReturningListPanel extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool Function(_ForgeIngredient data) accepts;
  final ValueChanged<_ForgeIngredient> onAccept;

  const _ReturningListPanel({
    required this.title,
    required this.children,
    required this.accepts,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<_ForgeIngredient>(
      onWillAcceptWithDetails: (details) => accepts(details.data),
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidateData, rejectedData) {
        final active = candidateData.isNotEmpty &&
            candidateData.any((d) => d != null && accepts(d));
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            border: Border.all(
              color: active
                  ? Colors.tealAccent
                  : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: _ListPanel(title: title, children: children),
        );
      },
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
  final Color? borderColor;
  final Color? fillColor;
  const _CraftSlotBox(
      {required this.size,
      required this.child,
      this.borderColor,
      this.fillColor});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fillColor ??
            Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.25),
        border: Border.all(
            color: borderColor ?? Theme.of(context).colorScheme.outlineVariant,
            width: 1.2),
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
  const _ForgeSideSlot(
      {required this.size,
      required this.title,
      required this.child});
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
                  style: const TextStyle(fontSize: 10),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center)),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}

enum _ForgeDropSlot { left, right }

class _ForgeIngredient {
  final Echo? echo;
  final CraftedItem? item;
  final _ForgeDropSlot? originSlot;
  const _ForgeIngredient.echo(this.echo, {this.originSlot}) : item = null;
  const _ForgeIngredient.item(this.item, {this.originSlot}) : echo = null;
}

class _ForgeDragTarget extends StatelessWidget {
  final double size;
  final String? label;
  final String helper;
  final Widget child;
  final bool Function(_ForgeIngredient data) canAccept;
  final ValueChanged<_ForgeIngredient> onAccept;

  const _ForgeDragTarget({
    required this.size,
    required this.label,
    required this.helper,
    required this.child,
    required this.canAccept,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<_ForgeIngredient>(
      onWillAcceptWithDetails: (details) => canAccept(details.data),
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidateData, rejectedData) {
        final active = candidateData.isNotEmpty &&
            candidateData.any((data) => data != null && canAccept(data));
        final borderColor = active
            ? Colors.tealAccent
            : Theme.of(context).colorScheme.outlineVariant;
        final fillColor = active
            ? Colors.tealAccent.withValues(alpha: 0.12)
            : Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.25);
        return _CraftSlotBox(
          size: size,
          borderColor: borderColor,
          fillColor: fillColor,
          child: Stack(
            alignment: Alignment.center,
            children: [
              child,
              if (label != null)
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          label!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 10),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          helper,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 8,
                            color: Theme.of(context)
                                .colorScheme
                                .outline
                                .withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SlottedIngredientDraggable extends StatelessWidget {
  final _ForgeIngredient data;
  final Widget child;
  final Widget feedback;
  final VoidCallback onAcceptedElsewhere;

  const _SlottedIngredientDraggable({
    required this.data,
    required this.child,
    required this.feedback,
    required this.onAcceptedElsewhere,
  });

  @override
  Widget build(BuildContext context) {
    return Draggable<_ForgeIngredient>(
      data: data,
      feedback: feedback,
      childWhenDragging: Opacity(opacity: 0.25, child: child),
      onDragCompleted: onAcceptedElsewhere,
      child: child,
    );
  }
}

class _ForgeFeedback extends StatelessWidget {
  final double size;
  final Widget child;
  const _ForgeFeedback({required this.size, required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.9),
          border: Border.all(color: Colors.tealAccent, width: 1.2),
        ),
        child: child,
      ),
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
  const _CraftDetailsPanel({required this.echo, required this.item});
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
      child: SingleChildScrollView(
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
              Text(
                'Drag this echo into a forge slot to craft new gear or upgrade an item.',
                style: small,
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
              Text(
                'Drag this item into a forge slot to fuse it with another item or upgrade it with an echo.',
                style: small,
              )
            ]
            ]),
      ),
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

class _CraftingTutorialDialog extends StatefulWidget {
  const _CraftingTutorialDialog();

  @override
  State<_CraftingTutorialDialog> createState() => _CraftingTutorialDialogState();
}

class _CraftingTutorialDialogState extends State<_CraftingTutorialDialog> {
  final _controller = PageController();
  int _index = 0;

  static const _pages = <({IconData icon, String title, String body})>[
    (
      icon: Icons.auto_awesome,
      title: 'Two Echoes Make New Gear',
      body:
          'Drag one echo into each forge slot, then press Forge Now. Their rarity and element help shape the item you create.'
    ),
    (
      icon: Icons.upgrade,
      title: 'Echoes Can Upgrade Items',
      body:
          'Place an echo on the left and a crafted item on the right to empower gear you already like instead of starting over.'
    ),
    (
      icon: Icons.merge_type,
      title: 'Items Can Fuse Too',
      body:
          'Drop one item into each slot to combine them. If you change your mind, use Clear under a slot and try a different recipe.'
    ),
  ];

  void _next() {
    if (_index >= _pages.length - 1) {
      Navigator.of(context).pop();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.62;
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      title: const Text('Forging Guide'),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 340,
          maxHeight: maxHeight,
        ),
        child: SizedBox(
          width: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (index) => setState(() => _index = index),
                  itemBuilder: (context, index) {
                    final step = _pages[index];
                    return SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(step.icon,
                                size: 34, color: Colors.tealAccent.shade400),
                            const SizedBox(height: 12),
                            Text(
                              step.title,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              step.body,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                children: List.generate(_pages.length, (index) {
                  final active = index == _index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: active ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active
                          ? Colors.tealAccent
                          : Colors.tealAccent.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Skip'),
        ),
        FilledButton(
          onPressed: _next,
          child: Text(_index == _pages.length - 1 ? 'Start Forging' : 'Next'),
        ),
      ],
    );
  }
}
