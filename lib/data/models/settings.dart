import 'package:hive/hive.dart';
part 'settings.manual.dart';

@HiveType(typeId: 8)
class Settings {
  @HiveField(0) String id;
  @HiveField(1) String? pinHash;
  @HiveField(2) String? exportDir;
  @HiveField(3) bool allowOsBackup;
  @HiveField(4) String theme;
  // Medication settings
  @HiveField(5) int pillOnTimeToleranceMinutes; // how close to scheduled time counts as on-time
  @HiveField(6) int refillThresholdDays; // warn when days left <= this
  // Developer/testing
  @HiveField(7) bool debugMode; // when true, show debug modals (e.g., seeds)
  @HiveField(8) bool autoGrantEchoOnWinDebug;
  @HiveField(9) bool returnTicketOnLossDebug;
  Settings({
    required this.id,
    this.pinHash,
    this.exportDir,
    this.allowOsBackup=true,
    this.theme='dark',
    this.pillOnTimeToleranceMinutes = 60,
    this.refillThresholdDays = 5,
    this.debugMode = false,
    this.autoGrantEchoOnWinDebug = false,
    this.returnTicketOnLossDebug = false,
  });
}
