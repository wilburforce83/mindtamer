import 'package:flutter/foundation.dart';
import '../models/sprite_model.dart';
// Removed unused imports related to seed-based creation helpers

class SpritesState extends ChangeNotifier {
  final List<SpriteModel> inventory = [];
  String? equippedSpriteId;
  SpriteModel? selected;

  void seedDemo() {}

  Future<void> loadFromInventory() async {
    // Convert seed_instances Hive data into SpriteModel for rendering
    try {
      // Implementation pending: integrate with Hive boxes if needed
      await Future.value();
    } catch (_) {}
  }

  // Seed-based creation helpers were unused and removed to satisfy lints.

  void select(SpriteModel s) { selected = s; notifyListeners(); }
  void add(SpriteModel s) { inventory.add(s); notifyListeners(); }
  void removeById(String id) { inventory.removeWhere((e)=>e.id==id); notifyListeners(); }
  void equipSelected() { if (selected!=null) { equippedSpriteId = selected!.id; notifyListeners(); } }
}
