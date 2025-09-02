part of 'resonant_echo.dart';

class ResonantEchoAdapter extends TypeAdapter<ResonantEcho> {
  @override
  final int typeId = 14;

  @override
  ResonantEcho read(BinaryReader r) {
    final n = r.readByte();
    final f = <int, dynamic>{};
    for (var i = 0; i < n; i++) { f[r.readByte()] = r.read(); }
    return ResonantEcho(
      echoId: f[0] as String,
      battleId: f[1] as String,
      entryId: f[2] as int,
      speciesId: f[3] as String,
      seedHash: f[4] as String,
      title: f[5] as String,
      excerpt: f[6] as String,
      element: f[7] as String,
      colorHex: f[8] as String,
      rarity: f[9] as String,
      createdAt: f[10] as DateTime,
    );
  }

  @override
  void write(BinaryWriter w, ResonantEcho o) {
    w
      ..writeByte(11)
      ..writeByte(0)..write(o.echoId)
      ..writeByte(1)..write(o.battleId)
      ..writeByte(2)..write(o.entryId)
      ..writeByte(3)..write(o.speciesId)
      ..writeByte(4)..write(o.seedHash)
      ..writeByte(5)..write(o.title)
      ..writeByte(6)..write(o.excerpt)
      ..writeByte(7)..write(o.element)
      ..writeByte(8)..write(o.colorHex)
      ..writeByte(9)..write(o.rarity)
      ..writeByte(10)..write(o.createdAt);
  }
}

