import 'package:go_router/go_router.dart';

import 'presentation/screens/dashboard_screen.dart';
import 'presentation/screens/character_hub_screen.dart';
import 'presentation/screens/achievements_screen.dart';
import 'presentation/screens/echoes_screen.dart';
import 'presentation/screens/fusion_screen.dart';
import 'presentation/screens/monster_codex_screen.dart';
import 'presentation/screens/items_screen.dart';
import 'ui/sprites/sprites_page.dart';
import 'presentation/screens/summons_screen.dart';
import 'presentation/screens/journal_screen.dart';
import 'presentation/screens/mood_screen.dart';
import 'presentation/screens/meds_screen.dart';
import 'presentation/screens/charts_screen.dart';
import 'presentation/screens/battle_screen.dart';
import 'presentation/screens/settings_screen.dart';
import 'data/hive/boxes.dart';
import 'presentation/screens/setup/character_setup_screen.dart';
import 'presentation/screens/setup/onboarding_screen.dart';
import 'presentation/screens/login_lite_lock_screen.dart';

GoRouter buildRouter() {
  return GoRouter(
    initialLocation: '/character',
    redirect: (context, state) {
      final hasProfile = profileBox().isNotEmpty;
      final loc = state.matchedLocation;
      if (!hasProfile && loc != '/setup') {
        return '/setup';
      }
      if (hasProfile) {
        bool done = false;
        try { done = (playerMetaBox().get('onboardingComplete') as bool?) ?? false; } catch (_) {}
        if (loc == '/setup' || loc == '/onboarding') {
          // Skip setup/onboarding when a profile exists and mark as completed.
          try { playerMetaBox().put('onboardingComplete', true); } catch (_) {}
          return '/character';
        }
        if (loc != '/onboarding' && !done) {
          // If user navigates normally with profile present, ensure completion flag is set once.
          try { playerMetaBox().put('onboardingComplete', true); } catch (_) {}
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/setup',
        builder: (context, state) => const CharacterSetupScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
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
      GoRoute(path: '/sprites', builder: (context, state) => const SpritesPage()),
      GoRoute(path: '/summons', builder: (context, state) => const SummonsScreen()),
    ],
  );
}
