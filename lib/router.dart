import 'package:go_router/go_router.dart';

import 'presentation/screens/dashboard_screen.dart';
import 'presentation/screens/journal_screen.dart';
import 'presentation/screens/mood_screen.dart';
import 'presentation/screens/meds_screen.dart';
import 'presentation/screens/charts_screen.dart';
import 'presentation/screens/battle_screen.dart';
import 'presentation/screens/settings_screen.dart';
import 'presentation/screens/login_lite_lock_screen.dart';

GoRouter buildRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/lock',
        builder: (context, state) => const LiteLockScreen(),
      ),
      GoRoute(
        path: '/journal',
        builder: (context, state) => const JournalScreen(),
      ),
      GoRoute(
        path: '/mood',
        builder: (context, state) => const MoodScreen(),
      ),
      GoRoute(
        path: '/meds',
        builder: (context, state) => const MedsScreen(),
      ),
      GoRoute(
        path: '/charts',
        builder: (context, state) => const ChartsScreen(),
      ),
      GoRoute(
        path: '/battle',
        builder: (context, state) => const BattleScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}
