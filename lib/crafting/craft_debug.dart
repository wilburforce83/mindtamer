class CraftDebug {
  static int total = 0;
  static int armor = 0;
  static int weapon = 0;
  static int accessory = 0;
  static int lastRoll = -1; // 0..99
  static String lastRoute = '-'; // armor | weapon | accessory

  static void record({required int roll, required String route}) {
    lastRoll = roll;
    lastRoute = route;
    total++;
    switch (route) {
      case 'weapon':
        weapon++;
        break;
      case 'accessory':
        accessory++;
        break;
      default:
        armor++;
        break;
    }
  }

  static void reset() {
    total = 0;
    armor = 0;
    weapon = 0;
    accessory = 0;
    lastRoll = -1;
    lastRoute = '-';
  }
}

