part of 'monster_codex.dart';

class MonsterCodexAdapter extends TypeAdapter<MonsterCodex> {
  @override
  final int typeId = 13;

  @override
  MonsterCodex read(BinaryReader r) {
    final n = r.readByte();
    final f = <int, dynamic>{};
    for (var i = 0; i < n; i++) { f[r.readByte()] = r.read(); }
    return MonsterCodex(
      speciesId: f[0] as String,
      discoveredAt: f[1] as DateTime,
      defeatedCount: (f[2] as int?) ?? 0,
      notes: f[3] as String?,
    );
  }

  @override
  void write(BinaryWriter w, MonsterCodex o) {
    w
      ..writeByte(4)
      ..writeByte(0)..write(o.speciesId)
      ..writeByte(1)..write(o.discoveredAt)
      ..writeByte(2)..write(o.defeatedCount)
      ..writeByte(3)..write(o.notes);
  }
}

