import 'package:hive/hive.dart';

part 'seed_instance.manual.dart';

@HiveType(typeId: 15)
class SeedInstance {
  @HiveField(0) String instanceId;
  @HiveField(1) String speciesId;
  @HiveField(2) DateTime createdAt;
  @HiveField(3) String source; // journal | fusion
  @HiveField(4) String seedHash;
  @HiveField(5) Map<String, dynamic> seedSnapshot;
  @HiveField(6) Map<String, int> stats;
  @HiveField(7) List<Map<String, dynamic>> attacks;
  @HiveField(8) String state; // inventory | equipped | banished
  SeedInstance({
    required this.instanceId,
    required this.speciesId,
    required this.createdAt,
    required this.source,
    required this.seedHash,
    required this.seedSnapshot,
    required this.stats,
    required this.attacks,
    required this.state,
  });
}

