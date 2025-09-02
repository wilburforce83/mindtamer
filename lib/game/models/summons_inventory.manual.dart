part of 'summons_inventory.dart';

class SummonsInventoryItemAdapter extends TypeAdapter<SummonsInventoryItem> {
  @override
  final int typeId = 16;

  @override
  SummonsInventoryItem read(BinaryReader r) {
    final n = r.readByte();
    final f = <int, dynamic>{};
    for (var i = 0; i < n; i++) { f[r.readByte()] = r.read(); }
    return SummonsInventoryItem(
      instanceId: f[0] as String,
      slot: f[1] as int?,
      favor: (f[2] as int?) ?? 0,
    );
  }

  @override
  void write(BinaryWriter w, SummonsInventoryItem o) {
    w
      ..writeByte(3)
      ..writeByte(0)..write(o.instanceId)
      ..writeByte(1)..write(o.slot)
      ..writeByte(2)..write(o.favor);
  }
}

