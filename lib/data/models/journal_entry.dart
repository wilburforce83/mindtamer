import 'package:hive/hive.dart';
part 'journal_entry.manual.dart';

@HiveType(typeId: 1)
enum Sentiment { @HiveField(0) positive, @HiveField(1) negative, @HiveField(2) mixed, @HiveField(3) neutral }

class SentimentAdapter extends TypeAdapter<Sentiment> {
  @override final int typeId = 0;
  @override Sentiment read(BinaryReader reader) => Sentiment.values[reader.readByte()];
  @override void write(BinaryWriter writer, Sentiment obj) => writer.writeByte(obj.index);
}

@HiveType(typeId: 2)
class JournalEntry {
  @HiveField(0) String id;
  @HiveField(1) DateTime date;
  @HiveField(2) String text;
  @HiveField(3) List<String> tags;
  @HiveField(4) Sentiment sentiment;
  @HiveField(5) List<String> linkedEnemies;
  JournalEntry({required this.id, required this.date, required this.text, required this.tags, required this.sentiment, required this.linkedEnemies});
}
