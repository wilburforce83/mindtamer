import 'package:hive/hive.dart';

part 'encounter_ticket.manual.dart';

@HiveType(typeId: 21)
class EncounterTicket {
  @HiveField(0) String ticketId;
  @HiveField(1) int entryId;
  @HiveField(2) String speciesId;
  @HiveField(3) String seedHash;
  @HiveField(4) Map<String, dynamic> seedSnapshot;
  @HiveField(5) String state; // open | consumed | expired
  @HiveField(6) DateTime createdAt;
  EncounterTicket({
    required this.ticketId,
    required this.entryId,
    required this.speciesId,
    required this.seedHash,
    required this.seedSnapshot,
    required this.state,
    required this.createdAt,
  });
}
