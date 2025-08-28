import '../../data/repositories/medication_repository.dart';
class RecordMedIntake {
  final IMedicationRepository repo;
  RecordMedIntake(this.repo);
  Future<void> call(String planId, DateTime date, String time, bool taken) => repo.logIntake(planId, date, time, taken);
}
