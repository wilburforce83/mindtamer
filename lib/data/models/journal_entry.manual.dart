import 'package:hive/hive.dart';
import 'journal_entry.dart';

class JournalEntryAdapter extends TypeAdapter<JournalEntry> {
  @override final int typeId = 2;
  @override JournalEntry read(BinaryReader reader) {
    final n = reader.readByte();
    final f = <int,dynamic>{};
    for (var i=0;i<n;i++){ f[reader.readByte()] = reader.read(); }
    return JournalEntry(
      id: f[0] as String,
      date: f[1] as DateTime,
      text: f[2] as String,
      tags: (f[3] as List).cast<String>(),
      sentiment: f[4] as Sentiment,
      linkedEnemies: (f[5] as List).cast<String>(),
    );
  }
  @override void write(BinaryWriter w, JournalEntry o){
    w..writeByte(6)
     ..writeByte(0)..write(o.id)
     ..writeByte(1)..write(o.date)
     ..writeByte(2)..write(o.text)
     ..writeByte(3)..write(o.tags)
     ..writeByte(4)..write(o.sentiment)
     ..writeByte(5)..write(o.linkedEnemies);
  }
}
