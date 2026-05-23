import 'sprite_attack.dart';

class SpriteModel {
  final String id; // hash(seedName)
  final String seedName;
  final int tier; // 0+
  final int rarity; // 0..4
  final int hue; // 0..359
  final List<int> argbRamp; // 5 shades
  final SpriteAttack attack;
  final DateTime createdAt;
  final String? element; // e.g., fire, water, shadow, etc.
  final String? colorHex; // palette hex used during seed
  final bool fused; // whether created by fusion
  final String sourceType;
  final String? sourceTitle;
  final DateTime? sourceDate;
  final List<String> fusedFromNames;

  const SpriteModel({
    required this.id,
    required this.seedName,
    required this.tier,
    required this.rarity,
    required this.hue,
    required this.argbRamp,
    required this.attack,
    required this.createdAt,
    this.element,
    this.colorHex,
    this.fused = false,
    this.sourceType = 'unknown',
    this.sourceTitle,
    this.sourceDate,
    this.fusedFromNames = const [],
  });

  SpriteModel copyWith({
    int? tier,
    int? rarity,
    int? hue,
    List<int>? argbRamp,
    SpriteAttack? attack,
    String? element,
    String? colorHex,
    bool? fused,
    String? sourceType,
    String? sourceTitle,
    DateTime? sourceDate,
    List<String>? fusedFromNames,
  }) =>
      SpriteModel(
        id: id,
        seedName: seedName,
        tier: tier ?? this.tier,
        rarity: rarity ?? this.rarity,
        hue: hue ?? this.hue,
        argbRamp: argbRamp ?? this.argbRamp,
        attack: attack ?? this.attack,
        createdAt: createdAt,
        element: element ?? this.element,
        colorHex: colorHex ?? this.colorHex,
        fused: fused ?? this.fused,
        sourceType: sourceType ?? this.sourceType,
        sourceTitle: sourceTitle ?? this.sourceTitle,
        sourceDate: sourceDate ?? this.sourceDate,
        fusedFromNames: fusedFromNames ?? this.fusedFromNames,
      );
}
