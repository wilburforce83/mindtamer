import '../../data/hive/boxes.dart';

abstract class EncountersRepo {
  Future<int> getOpenTicketsCount();
  Future<String?> getFirstOpenTicketId();
}

class EncountersRepoImpl implements EncountersRepo {
  @override
  Future<int> getOpenTicketsCount() async {
    try {
      final box = encounterTicketBox();
      int count = 0;
      for (final t in box.values) {
        if (t.state == 'open') count++;
      }
      return count;
    } catch (_) {
      return 0; // box may not be open in tests
    }
  }

  @override
  Future<String?> getFirstOpenTicketId() async {
    try {
      final box = encounterTicketBox();
      for (final t in box.values) {
        if (t.state == 'open') return t.ticketId;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
