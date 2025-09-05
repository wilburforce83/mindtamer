import 'dart:ui' as ui;

class SpriteCacheKey {
  final String id;
  final int? frame;
  const SpriteCacheKey(this.id, [this.frame]);
  @override
  bool operator==(Object other) => other is SpriteCacheKey && other.id==id && other.frame==frame;
  @override
  int get hashCode => Object.hash(id, frame);
}

class SpriteCache {
  final int capacity;
  final _map = <SpriteCacheKey, ui.Image>{};
  final _order = <SpriteCacheKey>[];
  SpriteCache({this.capacity = 128});

  ui.Image? get(SpriteCacheKey k) => _map[k];
  void put(SpriteCacheKey k, ui.Image img) {
    _map[k] = img;
    _order.remove(k);
    _order.add(k);
    if (_order.length > capacity) {
      final oldest = _order.removeAt(0);
      _map.remove(oldest);
    }
  }
}

