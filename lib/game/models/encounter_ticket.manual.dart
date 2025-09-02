part of 'encounter_ticket.dart';

class EncounterTicketAdapter extends TypeAdapter<EncounterTicket> {
  @override
  final int typeId = 21;

  @override
  EncounterTicket read(BinaryReader r) {
    final n = r.readByte();
    final f = <int, dynamic>{};
    for (var i = 0; i < n; i++) { f[r.readByte()] = r.read(); }
    return EncounterTicket(
      ticketId: f[0] as String,
      entryId: f[1] as int,
      speciesId: f[2] as String,
      seedHash: f[3] as String,
      seedSnapshot: Map<String, dynamic>.from(f[4] as Map),
      state: f[5] as String,
      createdAt: f[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter w, EncounterTicket o) {
    w
      ..writeByte(7)
      ..writeByte(0)..write(o.ticketId)
      ..writeByte(1)..write(o.entryId)
      ..writeByte(2)..write(o.speciesId)
      ..writeByte(3)..write(o.seedHash)
      ..writeByte(4)..write(o.seedSnapshot)
      ..writeByte(5)..write(o.state)
      ..writeByte(6)..write(o.createdAt);
  }
}
