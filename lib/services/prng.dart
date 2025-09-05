int fnv1a32(String s) {
  const int fnvPrime = 0x01000193;
  int hash = 0x811C9DC5;
  for (int i = 0; i < s.length; i++) {
    hash ^= s.codeUnitAt(i);
    hash = (hash * fnvPrime) & 0xFFFFFFFF;
  }
  return hash;
}

class XorShift32 {
  int _x;
  XorShift32(int seed) : _x = seed & 0xFFFFFFFF;
  int nextInt() {
    int x = _x;
    x ^= (x << 13) & 0xFFFFFFFF;
    x ^= (x >> 17);
    x ^= (x << 5) & 0xFFFFFFFF;
    _x = x & 0xFFFFFFFF;
    return _x;
  }
  double nextDouble() => (nextInt() & 0xFFFFFFFF) / 0x100000000;
  bool nextBool() => (nextInt() & 1) == 0;
  XorShift32 fork(String salt) => XorShift32(fnv1a32('$_x#$salt'));
}

class DP {
  final XorShift32 rng;
  DP(this.rng);
  T oneOf<T>(List<T> items) => items[(rng.nextInt().abs()) % items.length];
  int range(int min, int max) {
    if (max <= min) return min;
    final span = max - min + 1;
    return min + (rng.nextInt().abs() % span);
  }
  bool chance(double p0to1) => rng.nextDouble() < p0to1;
}
