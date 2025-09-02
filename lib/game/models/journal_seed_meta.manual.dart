part of 'journal_seed_meta.dart';

class JournalSeedMetaAdapter extends TypeAdapter<JournalSeedMeta> {
  @override
  final int typeId = 9;

  @override
  JournalSeedMeta read(BinaryReader r) {
    final n = r.readByte();
    final f = <int, dynamic>{};
    for (var i = 0; i < n; i++) { f[r.readByte()] = r.read(); }
    return JournalSeedMeta(
      entryId: f[0] as int,
      seedHash: f[1] as String,
      seedVersion: f[2] as String,
      seedSnapshot: Map<String, dynamic>.from(f[3] as Map),
      seedRouting: f[4] as String,
    );
  }

  @override
  void write(BinaryWriter w, JournalSeedMeta o) {
    w
      ..writeByte(5)
      ..writeByte(0)..write(o.entryId)
      ..writeByte(1)..write(o.seedHash)
      ..writeByte(2)..write(o.seedVersion)
      ..writeByte(3)..write(o.seedSnapshot)
      ..writeByte(4)..write(o.seedRouting);
  }
}

