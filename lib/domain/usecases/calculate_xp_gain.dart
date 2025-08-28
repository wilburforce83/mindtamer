class CalculateXpGain { int call({required bool battleWon, required int difficulty}) { final base = difficulty * 10; return battleWon ? base : (base ~/ 3); } }
