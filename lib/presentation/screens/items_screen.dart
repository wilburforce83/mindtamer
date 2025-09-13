import 'package:flutter/material.dart';
import '../../services/inventory_service.dart';

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

  void _unassign(int slot) {
    if (slot >= 0 && slot < _quickSlots.length) {
      _quickSlots[slot] = '';
      InventoryService.setQuickSlots(_quickSlots);
      _reload();
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
            Row(children: [
              for (int i = 0; i < 4; i++) ...[
                Expanded(
                  child: _QuickSlot(
                    index: i,
                    item: (i < _quickSlots.length && _quickSlots[i].isNotEmpty)
                        ? InventoryService.getById(_quickSlots[i])
                        : null,
                    onClear: () => _unassign(i),
                  ),
                ),
                if (i != 3) const SizedBox(width: 8),
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
                  return ListTile(
                    title: Text(ItemEffects.label(it['type'] as String)),
                    subtitle: Text('x${it['qty']}'),
                    trailing: TextButton(onPressed: () => _assignToSlot(it['id'] as String), child: const Text('Equip')),
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
  final VoidCallback onClear;
  const _QuickSlot({required this.index, required this.item, required this.onClear});
  @override
  Widget build(BuildContext context) {
    final label = item == null ? 'Empty' : ItemEffects.label(item!['type'] as String);
    final qty = (item == null) ? '' : ' x${item!['qty']}';
    return Container(
      height: 44,
      decoration: BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('S${index + 1}: $label$qty'),
          const SizedBox(width: 8),
          if (item != null) IconButton(onPressed: onClear, icon: const Icon(Icons.clear, size: 16)),
        ],
      ),
    );
  }
}
