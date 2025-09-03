import 'package:flutter/material.dart';

class BusyOverlay extends StatelessWidget {
  final String? label;
  const BusyOverlay({super.key, this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.45),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _PixelBusy(),
            if (label != null) ...[
              const SizedBox(height: 10),
              Text(label!, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white)),
            ],
          ],
        ),
      ),
    );
  }
}

class _PixelBusy extends StatefulWidget {
  const _PixelBusy();
  @override
  State<_PixelBusy> createState() => _PixelBusyState();
}

class _PixelBusyState extends State<_PixelBusy> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    const color = Colors.white;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = _c.value; // 0..1
        int active = (t * 3).floor() % 3;
        Widget box(bool on){
          return Container(width: 12, height: 12, margin: const EdgeInsets.symmetric(horizontal: 4), color: on ? color : color.withValues(alpha: 0.35));
        }
        return Row(mainAxisSize: MainAxisSize.min, children: [
          box(active==0), box(active==1), box(active==2)
        ]);
      },
    );
  }
}
