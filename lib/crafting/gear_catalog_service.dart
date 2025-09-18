import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class GearCatalogService {
  static final GearCatalogService _instance = GearCatalogService._();
  factory GearCatalogService() => _instance;
  GearCatalogService._();

  bool _loaded = false;
  late final Map<String, dynamic> _json;

  Future<void> init() async {
    if (_loaded) return;
    final raw = await rootBundle.loadString('assets/data/gear_catalog.json');
    _json = json.decode(raw) as Map<String, dynamic>;
    _loaded = true;
  }

  bool get isLoaded => _loaded;

  // Map tier to an era according to catalog expectations.
  String eraForTier(int tier) {
    // Default mapping: 1-6 early, 7-10 mid, 11-13 late
    if (tier <= 6) return 'early';
    if (tier <= 10) return 'mid';
    return 'late';
  }

  Map<String, dynamic>? _findSet(String classKey, String era) {
    if (!_loaded) return null;
    final sets = (_json['armor_sets'] as List?) ?? const [];
    for (final e in sets) {
      final m = e as Map<String, dynamic>;
      if ((m['class']?.toString().toLowerCase() ?? '') == classKey.toLowerCase() &&
          (m['era']?.toString().toLowerCase() ?? '') == era.toLowerCase()) {
        return m;
      }
    }
    return null;
  }

  String? setName(String classKey, int tier) {
    final era = eraForTier(tier);
    final m = _findSet(classKey, era);
    return m?['set_name']?.toString();
  }

  String connector(String classKey, int tier) {
    final era = eraForTier(tier);
    final m = _findSet(classKey, era);
    final c = m?['name_connector']?.toString();
    if (c == 'possessive' || c == 'of') return c!;
    // fallback to 'of'
    return 'of';
  }

  String? imageFor(String classKey, int tier, String slot) {
    final era = eraForTier(tier);
    final m = _findSet(classKey, era);
    if (m == null) return null;
    final pieces = (m['pieces'] as List?) ?? const [];
    for (final p in pieces) {
      final mp = p as Map<String, dynamic>;
      if ((mp['slot']?.toString() ?? '').toLowerCase() == slot.toLowerCase()) {
        final path = mp['image_path']?.toString() ?? mp['image_path_pattern']?.toString();
        if (path != null && path.isNotEmpty) return path;
      }
    }
    return null;
  }
}

