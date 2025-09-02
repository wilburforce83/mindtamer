part of 'seed_species.dart';

class SeedSpeciesAdapter extends TypeAdapter<SeedSpecies> {
  @override
  final int typeId = 10;

  @override
  SeedSpecies read(BinaryReader r) {
    final n = r.readByte();
    final f = <int, dynamic>{};
    for (var i = 0; i < n; i++) { f[r.readByte()] = r.read(); }
    return SeedSpecies(
      speciesId: f[0] as String,
      version: f[1] as String,
      baseWord: f[2] as String,
      element: f[3] as String,
      type: f[4] as String,
      kind: f[5] as String,
      rarity: f[6] as String,
      secondaryExamples: (f[7] as List).cast<String>(),
      colorHexExamples: (f[8] as List).cast<String>(),
      attacksCanonical: (f[9] as List).cast<String>(),
      firstSeenAt: f[10] as DateTime,
      journalRefCount: f[11] as int,
      tagsAggregate: (f[12] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter w, SeedSpecies o) {
    w
      ..writeByte(13)
      ..writeByte(0)..write(o.speciesId)
      ..writeByte(1)..write(o.version)
      ..writeByte(2)..write(o.baseWord)
      ..writeByte(3)..write(o.element)
      ..writeByte(4)..write(o.type)
      ..writeByte(5)..write(o.kind)
      ..writeByte(6)..write(o.rarity)
      ..writeByte(7)..write(o.secondaryExamples)
      ..writeByte(8)..write(o.colorHexExamples)
      ..writeByte(9)..write(o.attacksCanonical)
      ..writeByte(10)..write(o.firstSeenAt)
      ..writeByte(11)..write(o.journalRefCount)
      ..writeByte(12)..write(o.tagsAggregate);
  }
}

