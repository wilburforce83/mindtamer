import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'presentation/screens/dashboard_screen.dart';
import 'presentation/screens/character_hub_screen.dart';
import 'presentation/screens/achievements_screen.dart';
import 'presentation/screens/echoes_screen.dart';
import 'presentation/screens/crafting_screen.dart';
import 'presentation/screens/inventory_screen.dart';
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
        try {
          done = (playerMetaBox().get('onboardingComplete') as bool?) ?? false;
        } catch (_) {}
        if (loc == '/setup' || loc == '/onboarding') {
          // Skip setup/onboarding when a profile exists and mark as completed.
          try {
            playerMetaBox().put('onboardingComplete', true);
          } catch (_) {}
          return '/character';
        }
        if (loc != '/onboarding' && !done) {
          // If user navigates normally with profile present, ensure completion flag is set once.
          try {
            playerMetaBox().put('onboardingComplete', true);
          } catch (_) {}
        }
      }
      return null;
    },
    routes: [
      _retroRoute(
        path: '/',
        builder: (context, state) => const DashboardScreen(),
      ),
      _retroRoute(
        path: '/setup',
        builder: (context, state) => const CharacterSetupScreen(),
      ),
      _retroRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      _retroRoute(
        path: '/character',
        builder: (context, state) =>
            const CharacterHubScope(child: CharacterHubScreen()),
      ),
      _retroRoute(
        path: '/lock',
        builder: (context, state) => const LiteLockScreen(),
      ),
      _retroRoute(
        path: '/journal',
        builder: (context, state) => const JournalScreen(),
      ),
      _retroRoute(
        path: '/mood',
        builder: (context, state) => const MoodScreen(),
      ),
      _retroRoute(
        path: '/meds',
        builder: (context, state) => const MedsScreen(),
      ),
      _retroRoute(
        path: '/charts',
        builder: (context, state) => const ChartsScreen(),
      ),
      _retroRoute(
        path: '/battle',
        builder: (context, state) {
          final extra = state.extra;
          String? battleId;
          if (extra is Map) {
            battleId = extra['battleId']?.toString();
          } else if (extra is String) {
            battleId = extra;
          }
          return BattleScreen(battleId: battleId);
        },
      ),
      _retroRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      _retroRoute(
        path: '/achievements',
        builder: (context, state) => const AchievementsScreen(),
      ),
      _retroRoute(
        path: '/echoes',
        builder: (context, state) => const EchoesScreen(),
      ),
      _retroRoute(
        path: '/crafting',
        builder: (context, state) => const CraftingScreen(),
      ),
      _retroRoute(
        path: '/inventory',
        builder: (context, state) {
          final extra = state.extra;
          String? filter;
          if (extra is Map) {
            filter = extra['filter']?.toString();
          }
          if (extra is String) {
            filter = extra;
          }
          return InventoryScreen(filter: filter);
        },
      ),
      _retroRoute(
        path: '/codex',
        builder: (context, state) => const MonsterCodexScreen(),
      ),
      _retroRoute(
        path: '/items',
        builder: (context, state) {
          final extra = state.extra;
          String? slot;
          if (extra is Map) {
            slot = extra['slot']?.toString();
          } else if (extra is String) {
            slot = extra;
          }
          return ItemsScreen(slot: slot);
        },
      ),
      _retroRoute(
        path: '/sprites',
        builder: (context, state) => const SpritesPage(),
      ),
      _retroRoute(
        path: '/summons',
        builder: (context, state) => const SummonsScreen(),
      ),
    ],
  );
}

GoRoute _retroRoute({
  required String path,
  required Widget Function(BuildContext context, GoRouterState state) builder,
}) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) => CustomTransitionPage<void>(
      key: state.pageKey,
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      child: builder(context, state),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final steppedFade = CurvedAnimation(
          parent: animation,
          curve: const _PixelStepCurve(6),
        );
        final slide = Tween<Offset>(
          begin: const Offset(0.03, 0.025),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        );
        final scale = Tween<double>(
          begin: 0.988,
          end: 1.0,
        ).animate(
          CurvedAnimation(parent: animation, curve: const _PixelStepCurve(7)),
        );
        return FadeTransition(
          opacity: steppedFade,
          child: SlideTransition(
            position: slide,
            child: ScaleTransition(
              scale: scale,
              child: child,
            ),
          ),
        );
      },
    ),
  );
}

class _PixelStepCurve extends Curve {
  final int steps;
  const _PixelStepCurve(this.steps);

  @override
  double transformInternal(double t) {
    if (t <= 0) return 0;
    if (t >= 1) return 1;
    return ((t * steps).ceil()) / steps;
  }
}
