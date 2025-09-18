import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Renders a child into a low-resolution bitmap and scales it up
/// with nearest-neighbor filtering to achieve a pixelated look.
class Pixelate extends StatefulWidget {
  final Widget child;
  final double size; // logical size of the square content
  final int pixels; // target pixel resolution along one side (e.g., 16)
  final Object? watch; // when this changes, re-render the snapshot

  const Pixelate({
    super.key,
    required this.child,
    required this.size,
    this.pixels = 16,
    this.watch,
  });

  @override
  State<Pixelate> createState() => _PixelateState();
}

class _PixelateState extends State<Pixelate> {
  final GlobalKey _boundaryKey = GlobalKey();
  ui.Image? _image;
  Object? _lastWatch;

  @override
  void initState() {
    super.initState();
    _lastWatch = widget.watch;
    WidgetsBinding.instance.addPostFrameCallback((_) => _capture());
  }

  @override
  void didUpdateWidget(covariant Pixelate oldWidget) {
    super.didUpdateWidget(oldWidget);
    final watchChanged = widget.watch != _lastWatch;
    final sizeChanged = widget.size != oldWidget.size;
    final pxChanged = widget.pixels != oldWidget.pixels;
    if (watchChanged || sizeChanged || pxChanged) {
      _lastWatch = widget.watch;
      WidgetsBinding.instance.addPostFrameCallback((_) => _capture());
    }
  }

  Future<void> _capture() async {
    final ctx = _boundaryKey.currentContext;
    if (ctx == null || !mounted) return;
    final boundary = ctx.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final ratio = widget.pixels / widget.size;
    if (ratio <= 0) return;
    try {
      final img = await boundary.toImage(pixelRatio: ratio);
      if (!mounted) return;
      setState(() { _image = img; });
    } catch (_) {
      // Ignore capture errors (e.g., if not laid out yet)
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(fit: StackFit.expand, children: [
        // Hidden boundary used for offscreen rasterization
        Offstage(
          offstage: true,
          child: RepaintBoundary(
            key: _boundaryKey,
            child: SizedBox.square(dimension: widget.size, child: widget.child),
          ),
        ),
        if (_image != null)
          RawImage(
            image: _image,
            filterQuality: FilterQuality.none,
            fit: BoxFit.contain,
          )
        else
          // While snapshot loads, show the child directly as a fallback
          widget.child,
      ]),
    );
  }
}
