import 'package:hive/hive.dart';
part 'settings.manual.dart';

@HiveType(typeId: 8)
class Settings {
  @HiveField(0) String id;
  @HiveField(1) String? pinHash;
  @HiveField(2) String? exportDir;
  @HiveField(3) bool allowOsBackup;
  @HiveField(4) String theme;
  Settings({required this.id, this.pinHash, this.exportDir, this.allowOsBackup=true, this.theme='dark'});
}
