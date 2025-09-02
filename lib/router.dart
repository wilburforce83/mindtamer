import 'package:go_router/go_router.dart';

import 'presentation/screens/dashboard_screen.dart';
import 'presentation/screens/character_hub_screen.dart';
import 'presentation/screens/achievements_screen.dart';
import 'presentation/screens/echoes_screen.dart';
import 'presentation/screens/fusion_screen.dart';
import 'presentation/screens/monster_codex_screen.dart';
import 'presentation/screens/items_screen.dart';
import 'presentation/screens/journal_screen.dart';
import 'presentation/screens/mood_screen.dart';
import 'presentation/screens/meds_screen.dart';
import 'presentation/screens/charts_screen.dart';
import 'presentation/screens/battle_screen.dart';
import 'presentation/screens/settings_screen.dart';
import 'presentation/screens/login_lite_lock_screen.dart';

GoRouter buildRouter() {
  return GoRouter(
    initialLocation: '/character',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/character',
        builder: (context, state) => const CharacterHubScope(child: CharacterHubScreen()),
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
      GoRoute(path: '/achievements', builder: (context, state) => const AchievementsScreen()),
      GoRoute(path: '/echoes', builder: (context, state) => const EchoesScreen()),
      GoRoute(path: '/fusion', builder: (context, state) => const FusionScreen()),
      GoRoute(path: '/codex', builder: (context, state) => const MonsterCodexScreen()),
      GoRoute(path: '/items', builder: (context, state) {
        final extra = state.extra;
        String? slot;
        if (extra is Map) {
          slot = extra['slot']?.toString();
        } else if (extra is String) {
          slot = extra;
        }
        return ItemsScreen(slot: slot);
      }),
    ],
  );
}
