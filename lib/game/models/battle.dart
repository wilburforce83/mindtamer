import 'package:hive/hive.dart';

part 'battle.manual.dart';

@HiveType(typeId: 22)
class Battle {
  @HiveField(0) String battleId;
  @HiveField(1) String ticketId;
  @HiveField(2) String speciesId;
  @HiveField(3) String seedHash;
  @HiveField(4) DateTime startedAt;
  @HiveField(5) DateTime? endedAt;
  @HiveField(6) String? result; // win | loss | escape
  @HiveField(7) int turnCount;
  Battle({
    required this.battleId,
    required this.ticketId,
    required this.speciesId,
    required this.seedHash,
    required this.startedAt,
    this.endedAt,
    this.result,
    this.turnCount = 0,
  });
}
