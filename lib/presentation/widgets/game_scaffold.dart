import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/pixel_assets.dart';
import 'pixel_back_button.dart';

class GameScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final EdgeInsetsGeometry? padding;
  final bool showBottomNav;
  final bool centerTitle;

  const GameScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.padding,
    this.showBottomNav = true,
    this.centerTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = padding == null ? body : Padding(padding: padding!, child: body);
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _indexForLocation(location);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: centerTitle,
        automaticallyImplyLeading: false,
        leading: Navigator.of(context).canPop() ? const PixelBackButton() : null,
        actions: actions,
      ),
      body: content,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: showBottomNav
          ? BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: (i) {
                final dest = _tabs[i].route;
                if (dest != location) context.go(dest);
              },
              showSelectedLabels: false,
              showUnselectedLabels: false,
              items: [
                for (final t in _tabs)
                  BottomNavigationBarItem(
                    icon: _png(t.asset),
                    activeIcon: _png(t.asset),
                    label: t.label,
                  ),
              ],
            )
          : null,
    );
  }
}

class _TabItem {
  final String label;
  final String route;
  final String asset;
  const _TabItem(this.label, this.route, this.asset);
}

const List<_TabItem> _tabs = <_TabItem>[
  _TabItem('Character', '/character', PixelAssets.tabHome),
  _TabItem('Mood', '/mood', PixelAssets.tabMood),
  _TabItem('Journal', '/journal', PixelAssets.tabJournal),
  _TabItem('Meds', '/meds', PixelAssets.tabMeds),
  _TabItem('Settings', '/settings', PixelAssets.tabSettings),
];

Widget _png(String assetPath) {
  return SizedBox(
    width: 56,
    height: 56,
    child: Image.asset(
      assetPath,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.none,
      errorBuilder: (context, error, stack) {
        // Keep layout stable if asset missing; avoids throwing.
        return const SizedBox(width: 56, height: 56);
      },
    ),
  );
}

int _indexForLocation(String location) {
  for (var i = 0; i < _tabs.length; i++) {
    final r = _tabs[i].route;
    if (location == r || location.startsWith('$r/')) {
      return i;
    }
  }
  return 0; // default to Character
}
