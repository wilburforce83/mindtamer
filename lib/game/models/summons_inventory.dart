import 'package:hive/hive.dart';

part 'summons_inventory.manual.dart';

@HiveType(typeId: 16)
class SummonsInventoryItem {
  @HiveField(0) String instanceId; // FK to SeedInstance
  @HiveField(1) int? slot;
  @HiveField(2) int favor;
  SummonsInventoryItem({required this.instanceId, this.slot, this.favor = 0});
}

