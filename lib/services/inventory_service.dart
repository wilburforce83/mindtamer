import 'dart:math' as math;
import '../data/hive/boxes.dart';

class InventoryService {
  static List<Map<String, dynamic>> inventory() {
    try {
      final inv = (playerMetaBox().get('inventory') as List?)?.map((e) => Map<String, dynamic>.from(e)).toList();
      return inv ?? <Map<String, dynamic>>[];
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  static void save(List<Map<String, dynamic>> inv) {
    playerMetaBox().put('inventory', inv);
  }

  static String add(String type, {int qty = 1}) {
    final id = 'item-${DateTime.now().microsecondsSinceEpoch}-${math.Random().nextInt(999)}';
    final inv = inventory();
    inv.add({'id': id, 'type': type, 'qty': qty});
    save(inv);
    return id;
  }

  static bool consume(String id) {
    final inv = inventory();
    for (final item in inv) {
      if (item['id'] == id) {
        final q = (item['qty'] as int?) ?? 1;
        if (q <= 1) {
          inv.remove(item);
        } else {
          item['qty'] = q - 1;
        }
        save(inv);
        return true;
      }
    }
    return false;
  }

  static List<String> quickSlots() {
    try {
      final qs = (playerMetaBox().get('quickItems') as List?)?.map((e) => e.toString()).toList();
      return qs ?? <String>[];
    } catch (_) {
      return <String>[];
    }
  }

  static void setQuickSlots(List<String> ids) { playerMetaBox().put('quickItems', ids); }

  static Map<String, dynamic>? getById(String id) {
    for (final it in inventory()) { if (it['id'] == id) return it; }
    return null;
  }
}

class ItemEffects {
  // Define a small set of item effects
  static String label(String type) {
    switch (type) {
      case 'potion_small': return 'Potion +20HP';
      case 'fruit': return 'Fruit +10HP';
      case 'food': return 'Snack +15HP';
      case 'poison_small': return 'Poison -2 DEF (2T)';
      case 'buff_small': return 'Focus +1 ATK (2T)';
      default: return type;
    }
  }
}

