import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/pixel_assets.dart';
import '../../data/hive/boxes.dart';
import '../../game/services/player_image_service.dart';
import 'dart:ui' as ui;
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
                    icon: t.route == '/character' ? const _PlayerTabIcon() : _png(t.asset),
                    activeIcon: t.route == '/character' ? const _PlayerTabIcon() : _png(t.asset),
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

class _PlayerTabIcon extends StatefulWidget {
  const _PlayerTabIcon();
  @override
  State<_PlayerTabIcon> createState() => _PlayerTabIconState();
}

class _PlayerTabIconState extends State<_PlayerTabIcon> {
  ui.Image? _img;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final svc = PlayerImageService();
    final img = await svc.renderCurrentPlayer();
    if (!mounted) return;
    setState(() { _img = img; });
  }

  @override
  Widget build(BuildContext context) {
    if (_img != null) {
      return SizedBox(width: 56, height: 56, child: RawImage(image: _img, filterQuality: FilterQuality.none, fit: BoxFit.contain));
    }
    // Fallback to asset path while loading
    String cls = 'Sage';
    String gender = 'm';
    try {
      final vals = profileBox().values;
      if (vals.isNotEmpty) cls = vals.first.classKey;
      final m = playerMetaBox();
      final g = m.get('gender')?.toString();
      if (g != null && g.isNotEmpty) gender = g;
    } catch (_) {}
    final path = PlayerImageService.assetPathFor(cls, gender);
    return SizedBox(
      width: 56,
      height: 56,
      child: Image.asset(path, fit: BoxFit.contain, filterQuality: FilterQuality.none, errorBuilder: (_, __, ___) => _png(PixelAssets.tabHome)),
    );
  }
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
