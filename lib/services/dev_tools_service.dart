import '../data/hive/boxes.dart';
import '../game/models/resonant_echo.dart';

class DevToolsService {
  static const List<String> _elements = ['fire','water','air','nature','metal','light','shadow'];
  static const List<String> _rarities = ['common','uncommon','rare','epic','legendary'];

  static String _colorHexFor(String el) {
    switch (el) {
      case 'fire': return 'FF5722';
      case 'water': return '03A9F4';
      case 'air': return '00BCD4';
      case 'nature': return '4CAF50';
      case 'metal': return '9E9E9E';
      case 'light': return 'FFC107';
      case 'shadow': return '9C27B0';
      default: return 'FFFFFF';
    }
  }

  static Future<int> grantTestEchoes({int count = 30}) async {
    final box = resonantEchoBox();
    final now = DateTime.now().toUtc();
    for (int i = 0; i < count; i++) {
      final el = _elements[i % _elements.length];
      final rar = _rarities[i % _rarities.length];
      final id = 'echo-${now.microsecondsSinceEpoch}-$i';
      final e = ResonantEcho(
        echoId: id,
        battleId: 'dev',
        entryId: 0,
        speciesId: 'spec-$el-$i',
        seedHash: 'hash-$id',
        title: '${el[0].toUpperCase()}${el.substring(1)} Resonance',
        excerpt: 'Debug echo #$i',
        element: el,
        colorHex: _colorHexFor(el),
        rarity: rar,
        createdAt: now.add(Duration(seconds: i)),
      );
      await box.put(id, e);
    }
    return count;
  }
}

