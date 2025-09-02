part of 'battle.dart';

class BattleAdapter extends TypeAdapter<Battle> {
  @override
  final int typeId = 22;

  @override
  Battle read(BinaryReader r) {
    final n = r.readByte();
    final f = <int, dynamic>{};
    for (var i = 0; i < n; i++) { f[r.readByte()] = r.read(); }
    return Battle(
      battleId: f[0] as String,
      ticketId: f[1] as String,
      speciesId: f[2] as String,
      seedHash: f[3] as String,
      startedAt: f[4] as DateTime,
      endedAt: f[5] as DateTime?,
      result: f[6] as String?,
      turnCount: (f[7] as int?) ?? 0,
    );
  }

  @override
  void write(BinaryWriter w, Battle o) {
    w
      ..writeByte(8)
      ..writeByte(0)..write(o.battleId)
      ..writeByte(1)..write(o.ticketId)
      ..writeByte(2)..write(o.speciesId)
      ..writeByte(3)..write(o.seedHash)
      ..writeByte(4)..write(o.startedAt)
      ..writeByte(5)..write(o.endedAt)
      ..writeByte(6)..write(o.result)
      ..writeByte(7)..write(o.turnCount);
  }
}
