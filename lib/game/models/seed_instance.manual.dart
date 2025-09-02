part of 'seed_instance.dart';

class SeedInstanceAdapter extends TypeAdapter<SeedInstance> {
  @override
  final int typeId = 15;

  @override
  SeedInstance read(BinaryReader r) {
    final n = r.readByte();
    final f = <int, dynamic>{};
    for (var i = 0; i < n; i++) { f[r.readByte()] = r.read(); }
    return SeedInstance(
      instanceId: f[0] as String,
      speciesId: f[1] as String,
      createdAt: f[2] as DateTime,
      source: f[3] as String,
      seedHash: f[4] as String,
      seedSnapshot: Map<String, dynamic>.from(f[5] as Map),
      stats: Map<String, int>.from(f[6] as Map),
      attacks: (f[7] as List).map((e) => Map<String, dynamic>.from(e)).toList(),
      state: f[8] as String,
    );
  }

  @override
  void write(BinaryWriter w, SeedInstance o) {
    w
      ..writeByte(9)
      ..writeByte(0)..write(o.instanceId)
      ..writeByte(1)..write(o.speciesId)
      ..writeByte(2)..write(o.createdAt)
      ..writeByte(3)..write(o.source)
      ..writeByte(4)..write(o.seedHash)
      ..writeByte(5)..write(o.seedSnapshot)
      ..writeByte(6)..write(o.stats)
      ..writeByte(7)..write(o.attacks)
      ..writeByte(8)..write(o.state);
  }
}

