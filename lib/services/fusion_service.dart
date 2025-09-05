import '../models/sprite_model.dart';
import '../models/sprite_attack.dart';
import 'sprite_palette.dart';

class FusionService {
  SpriteModel fuse(SpriteModel a, SpriteModel b) {
    final tier = (a.tier > b.tier ? a.tier : b.tier) + 1;
    // Average hue (short-arc not strictly needed for demo)
    final hue = ((a.hue + b.hue) ~/ 2) % 360;
    final ramp = SpritePalette.rampFromHue(hue);
    final power = ((a.attack.power + b.attack.power) / 2).round() + 10;
    final dur = (a.attack.durationTurns + b.attack.durationTurns) ~/ 2 + 1;
    final attack = SpriteAttack(
      name: '${a.attack.name}+',
      description: 'Ascended form of ${a.seedName}',
      power: power,
      durationTurns: dur.clamp(1, 4),
    );
    final rarity = (a.rarity > b.rarity ? a.rarity : b.rarity);
    return a.copyWith(tier: tier, hue: hue, argbRamp: ramp, attack: attack, rarity: rarity);
  }
}
