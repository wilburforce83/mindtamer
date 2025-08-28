import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/med_plan.dart';
import '../../data/repositories/medication_repository.dart';
import '../providers.dart';
final medPlansProvider = StateNotifierProvider<MedPlansNotifier, List<MedPlan>>((ref) => MedPlansNotifier(ref.read(medRepoProvider)));
class MedPlansNotifier extends StateNotifier<List<MedPlan>> {
  final IMedicationRepository _repo;
  MedPlansNotifier(this._repo) : super(_repo.plans());
  Future<void> addPlan(String name, String dose, List<String> times) async { await _repo.addPlan(name, dose, times); state = _repo.plans(); }
}
