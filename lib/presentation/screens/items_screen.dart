import 'package:flutter/material.dart';

class ItemsScreen extends StatelessWidget {
  final String? slot;
  const ItemsScreen({super.key, this.slot});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Items')),
      body: Center(child: Text(slot == null ? 'All items (stub)' : 'Items for: $slot (stub)')),
    );
  }
}
