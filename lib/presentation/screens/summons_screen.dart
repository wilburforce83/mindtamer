import 'package:flutter/material.dart';
import '../../data/hive/boxes.dart';
import '../../models/sprite_model.dart';
import '../../models/sprite_attack.dart';
import '../../services/sprite_instance_utils.dart';
import '../../services/sprite_palette.dart';

class SummonsScreen extends StatelessWidget {
  const SummonsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final list = seedInstanceBox().values.toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Summons')),
      body: list.isEmpty
          ? const Center(child: Text('No sprites owned yet'))
          : ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final s = list[i];
                final name =
                    (s.seedSnapshot['displayName'] ?? 'Sprite').toString();
                final element = (s.seedSnapshot['element'] ?? '').toString();
                final rarity = (s.seedSnapshot['rarity'] ?? '').toString();
                return ListTile(
                  title: Text(name),
                  subtitle: Text('$element • $rarity'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Equip into selected sprite slot by returning a SpriteModel
                    final ramp = SpritePalette.pickRampForSeed(s.seedHash);
                    final atk = SpriteInstanceUtils.strongestAttackModel(s) ??
                        const SpriteAttack(
                          name: 'Sprite Attack',
                          description:
                              'Fires a focused burst for 30 power over 2 turns.',
                          power: 30,
                          durationTurns: 2,
                        );
                    final model = SpriteModel(
                      id: s.instanceId,
                      seedName: name,
                      tier: 0,
                      rarity: 0,
                      hue: (s.seedHash.hashCode & 0x7fffffff) % 360,
                      argbRamp: ramp,
                      attack: atk,
                      createdAt: s.createdAt,
                      element: (s.seedSnapshot['element'] ?? '').toString(),
                      colorHex: (s.seedSnapshot['colorHex'] ?? '').toString(),
                      sourceType: s.source,
                      sourceTitle: SpriteInstanceUtils.sourceTitleOf(s),
                      sourceDate: SpriteInstanceUtils.sourceDateOf(s),
                      fusedFromNames: SpriteInstanceUtils.fusedFromNamesOf(s),
                    );
                    Navigator.pop(context, model);
                  },
                );
              },
            ),
    );
  }
}
