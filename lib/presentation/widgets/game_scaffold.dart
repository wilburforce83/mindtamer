import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/pixel_assets.dart';
import '../../data/hive/boxes.dart';
import '../../game/services/player_image_service.dart';
import '../../theme/colors.dart';
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
  final bool lockNavigation;
  final String navigationLockMessage;

  const GameScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.padding,
    this.showBottomNav = true,
    this.centerTitle = false,
    this.lockNavigation = false,
    this.navigationLockMessage = 'You cannot leave this screen right now.',
  });

  void _showNavigationLocked(BuildContext context) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(content: Text(navigationLockMessage)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content =
        padding == null ? body : Padding(padding: padding!, child: body);
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _indexForLocation(location);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: centerTitle,
        automaticallyImplyLeading: false,
        leading: Navigator.of(context).canPop()
            ? PixelBackButton(
                onPressed: lockNavigation
                    ? () => _showNavigationLocked(context)
                    : null,
              )
            : null,
        actions: actions,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColors.outlineSoft.withValues(alpha: 0.65),
          ),
        ),
      ),
      body: content,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: showBottomNav
          ? _BottomDock(
              currentIndex: currentIndex,
              location: location,
              lockNavigation: lockNavigation,
              blockedMessage: navigationLockMessage,
            )
          : null,
    );
  }
}

class _TabItem {
  final String label;
  final String route;
  final String asset;
  final EdgeInsets iconPadding;
  const _TabItem(
    this.label,
    this.route,
    this.asset, {
    this.iconPadding = EdgeInsets.zero,
  });
}

const List<_TabItem> _tabs = <_TabItem>[
  _TabItem('Character', '/character', PixelAssets.tabHome),
  _TabItem(
    'Mood',
    '/mood',
    PixelAssets.tabMood,
    iconPadding: EdgeInsets.fromLTRB(4, 5, 4, 3),
  ),
  _TabItem(
    'Journal',
    '/journal',
    PixelAssets.tabJournal,
    iconPadding: EdgeInsets.fromLTRB(3, 4, 3, 2),
  ),
  _TabItem(
    'Meds',
    '/meds',
    PixelAssets.tabMeds,
    iconPadding: EdgeInsets.fromLTRB(3, 4, 3, 3),
  ),
  _TabItem(
    'Settings',
    '/settings',
    PixelAssets.tabSettings,
    iconPadding: EdgeInsets.fromLTRB(4, 4, 4, 3),
  ),
];

class _BottomDock extends StatelessWidget {
  final int currentIndex;
  final String location;
  final bool lockNavigation;
  final String blockedMessage;

  const _BottomDock({
    required this.currentIndex,
    required this.location,
    required this.lockNavigation,
    required this.blockedMessage,
  });

  void _showNavigationLocked(BuildContext context) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(content: Text(blockedMessage)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.nav.withValues(alpha: 0.96),
          border: Border.all(
            color: AppColors.outlineSoft.withValues(alpha: 0.95),
            width: 1.2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0xB3000000),
              offset: Offset(0, -2),
              blurRadius: 0,
            ),
          ],
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.surfaceRaised.withValues(alpha: 0.92),
              AppColors.nav.withValues(alpha: 0.98),
            ],
          ),
        ),
        child: Row(
          children: [
            for (var i = 0; i < _tabs.length; i++)
              Expanded(
                child: _DockTabButton(
                  item: _tabs[i],
                  active: i == currentIndex,
                  onTap: () {
                    final dest = _tabs[i].route;
                    if (dest == location) {
                      return;
                    }
                    if (lockNavigation) {
                      _showNavigationLocked(context);
                      return;
                    }
                    context.go(dest);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DockTabButton extends StatelessWidget {
  final _TabItem item;
  final bool active;
  final VoidCallback onTap;

  const _DockTabButton({
    required this.item,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final frameColor = active
        ? AppColors.outlineBright.withValues(alpha: 0.92)
        : AppColors.outlineSoft.withValues(alpha: 0.25);
    final tileColor = active
        ? AppColors.navActive.withValues(alpha: 0.78)
        : Colors.transparent;
    final iconOpacity = active ? 1.0 : 0.84;

    return Tooltip(
      message: item.label,
      child: Semantics(
        button: true,
        selected: active,
        label: item.label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.zero,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: EdgeInsets.fromLTRB(6, active ? 4 : 8, 6, 8),
            decoration: BoxDecoration(
              color: tileColor,
              border: Border.all(color: frameColor, width: active ? 1.4 : 1),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: AppColors.secondary.withValues(alpha: 0.22),
                        blurRadius: 0,
                        spreadRadius: 1,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 140),
                  opacity: active ? 1 : 0,
                  child: Container(
                    width: 18,
                    height: 3,
                    margin: const EdgeInsets.only(bottom: 5),
                    color: AppColors.accentWarm,
                  ),
                ),
                Opacity(
                  opacity: iconOpacity,
                  child: SizedBox(
                    width: 42,
                    height: 42,
                    child: item.route == '/character'
                        ? _PlayerTabIcon(size: active ? 42 : 40)
                        : _AssetTabIcon(
                            path: item.asset,
                            padding: item.iconPadding,
                            size: active ? 42 : 40,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AssetTabIcon extends StatelessWidget {
  final String path;
  final EdgeInsets padding;
  final double size;

  const _AssetTabIcon({
    required this.path,
    required this.padding,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Padding(
        padding: padding,
        child: Image.asset(
          path,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.none,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _PlayerTabIcon extends StatefulWidget {
  final double size;
  const _PlayerTabIcon({this.size = 42});
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
    setState(() {
      _img = img;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_img != null) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: RawImage(
          image: _img,
          filterQuality: FilterQuality.none,
          fit: BoxFit.contain,
        ),
      );
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
      width: widget.size,
      height: widget.size,
      child: Image.asset(
        path,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
        errorBuilder: (_, __, ___) => _AssetTabIcon(
          path: PixelAssets.tabHome,
          padding: const EdgeInsets.all(2),
          size: widget.size,
        ),
      ),
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
