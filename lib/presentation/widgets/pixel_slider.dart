import 'package:flutter/material.dart';
import '../../core/pixel_assets.dart';
import '../../theme/colors.dart';

class PixelSlider extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const PixelSlider({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final slider = SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 8,
        overlayShape: SliderComponentShape.noOverlay,
        thumbShape: const _PixelThumbShape(size: 16),
        trackShape: const _PixelTrackShape(),
        activeTrackColor: AppColors.accentWarm,
        inactiveTrackColor: AppColors.surfaceVariant,
        disabledActiveTrackColor: AppColors.surfaceVariant,
        disabledInactiveTrackColor: AppColors.surfaceVariant,
        thumbColor: AppColors.ivory,
        disabledThumbColor: AppColors.muted,
      ),
      child: Slider(
        value: value.toDouble(),
        min: 0,
        max: 100,
        onChanged: (v) => onChanged(v.round()),
      ),
    );

    // Texture background using assets if available, without crashing if missing.
    Widget bgImage(String path) => Image.asset(
          path,
          repeat: ImageRepeat.repeatX,
          alignment: Alignment.centerLeft,
          filterQuality: FilterQuality.none,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(children: [
          // Try track tile first, fall back to knob tile silently
          Positioned.fill(child: bgImage(PixelAssets.sliderTrackTile8)),
          Positioned.fill(child: bgImage(PixelAssets.sliderKnob16)),
          slider,
        ]),
        Text('$value'),
      ],
    );
  }
}

class _PixelThumbShape extends SliderComponentShape {
  final double size;
  const _PixelThumbShape({this.size = 16});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => Size(size, size);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
      required Animation<double> activationAnimation,
      required Animation<double> enableAnimation,
      required bool isDiscrete,
      required TextPainter labelPainter,
      required RenderBox parentBox,
      required SliderThemeData sliderTheme,
      required TextDirection textDirection,
      required double value,
      required double textScaleFactor,
      required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    final rect = Rect.fromCenter(center: center, width: size, height: size);
    final r = RRect.fromRectAndRadius(rect, const Radius.circular(0));
    final fill = Paint()..color = sliderTheme.thumbColor ?? AppColors.ivory;
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.outline;
    canvas.drawRRect(r, fill);
    canvas.drawRRect(r, border);
  }
}

class _PixelTrackShape extends SliderTrackShape {
  const _PixelTrackShape();

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final trackHeight = sliderTheme.trackHeight ?? 8;
    final trackLeft = offset.dx + 8;
    final trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final trackRight = trackLeft + parentBox.size.width - 16;
    return Rect.fromLTRB(trackLeft, trackTop, trackRight, trackTop + trackHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
      required RenderBox parentBox,
      Offset? secondaryOffset,
      required SliderThemeData sliderTheme,
      required Animation<double> enableAnimation,
      required Offset thumbCenter,
      bool isDiscrete = false,
      bool isEnabled = false,
      required TextDirection textDirection,
  }) {
    final canvas = context.canvas;
    final rect = getPreferredRect(parentBox: parentBox, offset: offset, sliderTheme: sliderTheme);

    final inactivePaint = Paint()..color = sliderTheme.inactiveTrackColor ?? AppColors.surfaceVariant;
    final activePaint = Paint()..color = sliderTheme.activeTrackColor ?? AppColors.accentWarm;
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.outline;

    // Left (active) and right (inactive) segments
    final activeRect = Rect.fromLTRB(rect.left, rect.top, thumbCenter.dx, rect.bottom);
    final inactiveRect = Rect.fromLTRB(thumbCenter.dx, rect.top, rect.right, rect.bottom);
    canvas.drawRect(inactiveRect, inactivePaint);
    canvas.drawRect(activeRect, activePaint);
    canvas.drawRect(rect, border);
  }
}
