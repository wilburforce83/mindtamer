import 'package:flutter/foundation.dart';

import '../../data/repos/encounters_repo.dart';
import '../../data/repos/equipment_repo.dart';

class CharacterHubState {
  final int openTickets;
  final Map<String, EquippedItem?> gear;
  const CharacterHubState({required this.openTickets, required this.gear});
}

class CharacterHubVM extends ChangeNotifier {
  final EncountersRepo encounters;
  final EquipmentRepo equipment;

  CharacterHubVM({required this.encounters, required this.equipment});

  CharacterHubState _state = const CharacterHubState(openTickets: 0, gear: {});
  CharacterHubState get state => _state;

  Future<void> load() async {
    final open = await encounters.getOpenTicketsCount();
    final gear = await equipment.getAllSlots();
    _state = CharacterHubState(openTickets: open, gear: gear);
    notifyListeners();
  }

  Future<void> refreshTickets() async {
    final open = await encounters.getOpenTicketsCount();
    _state = CharacterHubState(openTickets: open, gear: _state.gear);
    notifyListeners();
  }
}

