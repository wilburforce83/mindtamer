import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../../models/sprite_model.dart';
import '../../services/sprite_generator.dart';

class SpriteCell extends StatefulWidget {
  final SpriteModel sprite;
  final void Function() onTap;
  const SpriteCell({super.key, required this.sprite, required this.onTap});

  @override
  State<SpriteCell> createState() => _SpriteCellState();
}

class _SpriteCellState extends State<SpriteCell> {
  ui.Image? _img;
  @override
  void initState() { super.initState(); _render(); }
  Future<void> _render() async {
    final gen = SpriteGenerator();
    final r = await gen.generate(widget.sprite.seedName, widget.sprite.tier, widget.sprite.argbRamp);
    if (mounted) setState(()=>_img = r.staticFrame);
  }
  @override
  Widget build(BuildContext context) {
    final rarityColors = [
      const Color(0xFF9E9E9E),
      const Color(0xFF42A5F5),
      const Color(0xFFAB47BC),
      const Color(0xFFFFB300),
      const Color(0xFF66FFFF),
    ];
    return InkWell(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: rarityColors[widget.sprite.rarity.clamp(0,4)], width: 2),
        ),
        alignment: Alignment.center,
        child: _img == null
            ? const SizedBox(width: 32, height: 32)
            : RawImage(image: _img, filterQuality: FilterQuality.none, width: 32, height: 32),
      ),
    );
  }
}

