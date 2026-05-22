import 'dart:convert';
import 'package:flutter/services.dart' show AssetManifest, rootBundle;

class GearCatalogService {
  static final GearCatalogService _instance = GearCatalogService._();
  factory GearCatalogService() => _instance;
  GearCatalogService._();

  bool _loaded = false;
  late final Map<String, dynamic> _json;
  Set<String> _assetPaths = const {};

  Future<void> init() async {
    if (_loaded) return;
    final raw = await rootBundle.loadString('assets/data/gear_catalog.json');
    _json = json.decode(raw) as Map<String, dynamic>;
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      _assetPaths = manifest.listAssets().toSet();
    } catch (_) {
      _assetPaths = const {};
    }
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
      if ((m['class']?.toString().toLowerCase() ?? '') ==
              classKey.toLowerCase() &&
          (m['era']?.toString().toLowerCase() ?? '') == era.toLowerCase()) {
        return m;
      }
    }
    return null;
  }

  List<String> _eraFallbackOrder(String era) {
    switch (era.toLowerCase()) {
      case 'late':
        return const ['late', 'mid', 'early'];
      case 'mid':
        return const ['mid', 'early', 'late'];
      case 'early':
        return const ['early', 'mid', 'late'];
      default:
        return const ['early', 'mid', 'late'];
    }
  }

  String? _piecePath(Map<String, dynamic> piece) {
    final path = piece['image_path']?.toString() ??
        piece['image_path_pattern']?.toString();
    if (path == null || path.isEmpty) return null;
    return path;
  }

  bool _assetExists(String path) {
    if (_assetPaths.isEmpty) return true;
    return _assetPaths.contains(path);
  }

  String? _fallbackAssetFor(String classKey, String era, String slot) {
    if (_assetPaths.isEmpty) return null;
    final prefix =
        'assets/images/armor/${classKey.toLowerCase()}/${era.toLowerCase()}/';
    final suffix = '_${slot.toLowerCase()}_32.png';
    final matches = _assetPaths
        .where((path) => path.startsWith(prefix) && path.endsWith(suffix))
        .toList()
      ..sort();
    return matches.isEmpty ? null : matches.first;
  }

  bool _setHasUsablePiece(
    Map<String, dynamic> set,
    String classKey, {
    String? slot,
  }) {
    final era = set['era']?.toString() ?? '';
    final pieces = (set['pieces'] as List?) ?? const [];
    for (final piece in pieces) {
      final map = piece as Map<String, dynamic>;
      final pieceSlot = map['slot']?.toString() ?? '';
      if (slot != null && pieceSlot.toLowerCase() != slot.toLowerCase()) {
        continue;
      }
      final declaredPath = _piecePath(map);
      if (declaredPath != null && _assetExists(declaredPath)) {
        return true;
      }
      if (_fallbackAssetFor(classKey, era, pieceSlot) != null) {
        return true;
      }
    }
    return false;
  }

  Map<String, dynamic>? _resolvedSet(
    String classKey,
    String era, {
    String? slot,
  }) {
    for (final candidateEra in _eraFallbackOrder(era)) {
      final set = _findSet(classKey, candidateEra);
      if (set != null && _setHasUsablePiece(set, classKey, slot: slot)) {
        return set;
      }
    }
    final sets = (_json['armor_sets'] as List?) ?? const [];
    for (final entry in sets) {
      final set = entry as Map<String, dynamic>;
      final entryClass = set['class']?.toString().toLowerCase() ?? '';
      if (entryClass != classKey.toLowerCase()) continue;
      if (_setHasUsablePiece(set, classKey, slot: slot)) {
        return set;
      }
    }
    return null;
  }

  String? setName(String classKey, int tier) {
    final era = eraForTier(tier);
    final m = _resolvedSet(classKey, era);
    return m?['set_name']?.toString();
  }

  String connector(String classKey, int tier) {
    final era = eraForTier(tier);
    final m = _resolvedSet(classKey, era);
    final c = m?['name_connector']?.toString();
    if (c == 'possessive' || c == 'of') return c!;
    // fallback to 'of'
    return 'of';
  }

  String? imageFor(String classKey, int tier, String slot) {
    final era = eraForTier(tier);
    final m = _resolvedSet(classKey, era, slot: slot);
    if (m == null) return null;
    final pieces = (m['pieces'] as List?) ?? const [];
    for (final p in pieces) {
      final mp = p as Map<String, dynamic>;
      if ((mp['slot']?.toString() ?? '').toLowerCase() == slot.toLowerCase()) {
        final path = _piecePath(mp);
        if (path != null && path.isNotEmpty && _assetExists(path)) {
          return path;
        }
        final fallbackPath =
            _fallbackAssetFor(classKey, m['era']?.toString() ?? era, slot);
        if (fallbackPath != null) return fallbackPath;
      }
    }
    return null;
  }
}
