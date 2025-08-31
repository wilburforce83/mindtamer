// FILE: lib/features/journal/model/user_tag.dart
import 'package:isar/isar.dart';

part 'user_tag.g.dart';

@Collection()
class UserTag {
  Id id = Isar.autoIncrement;

  @Index(unique: true, caseSensitive: true)
  late String name; // stored normalized lower_snake_case

  late DateTime createdAtUtc;
}

