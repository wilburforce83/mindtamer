// FILE: lib/features/settings/journal/journal_settings_state.dart
import 'package:flutter/foundation.dart';

class JournalSettings extends ChangeNotifier {
  bool generateSeedOnSave = true;
  bool titleAffectsRng = true;

  static final JournalSettings instance = JournalSettings();

  void setGenerate(bool v) { generateSeedOnSave = v; notifyListeners(); }
  void setTitleAffects(bool v) { titleAffectsRng = v; notifyListeners(); }
}

