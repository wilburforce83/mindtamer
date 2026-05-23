import '../crafting/inventory_service.dart';
import '../data/hive/boxes.dart';

class CraftingTutorialService {
  static const _introSeenKey = 'craftingTutorialIntroSeen';
  static const _completedKey = 'craftingTutorialCompleted';

  static bool hasEnoughEchoes() {
    try {
      return resonantEchoBox().length >= 2;
    } catch (_) {
      return false;
    }
  }

  static bool hasForgedBefore() {
    try {
      return CraftedInventoryService.all().isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static bool introSeen() {
    try {
      return (playerMetaBox().get(_introSeenKey) as bool?) ?? false;
    } catch (_) {
      return false;
    }
  }

  static bool completed() {
    try {
      return (playerMetaBox().get(_completedKey) as bool?) ?? false;
    } catch (_) {
      return false;
    }
  }

  static bool shouldShowHubCoach() {
    return hasEnoughEchoes() && !hasForgedBefore() && !completed();
  }

  static bool shouldShowCraftingIntro() {
    return hasEnoughEchoes() &&
        !hasForgedBefore() &&
        !completed() &&
        !introSeen();
  }

  static Future<void> markIntroSeen() async {
    try {
      await playerMetaBox().put(_introSeenKey, true);
    } catch (_) {}
  }

  static Future<void> markCompleted() async {
    try {
      await playerMetaBox().putAll({
        _introSeenKey: true,
        _completedKey: true,
      });
    } catch (_) {}
  }
}
