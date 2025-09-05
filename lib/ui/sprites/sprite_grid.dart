import 'package:flutter/material.dart';
import '../../models/sprite_model.dart';
import 'sprite_cell.dart';

class SpriteGrid extends StatelessWidget {
  final List<SpriteModel> sprites;
  final void Function(SpriteModel) onSelect;
  const SpriteGrid({super.key, required this.sprites, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final cross = w ~/ 72; // cell ~72px
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cross.clamp(2, 6)),
      itemCount: sprites.length,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.all(6),
        child: SpriteCell(sprite: sprites[i], onTap: ()=>onSelect(sprites[i])),
      ),
    );
  }
}

