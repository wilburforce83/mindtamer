import 'package:flutter/material.dart';
import '../../data/hive/boxes.dart';
import '../../models/sprite_model.dart';
import '../../models/sprite_attack.dart';
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
                final name = (s.seedSnapshot['displayName'] ?? 'Sprite').toString();
                final element = (s.seedSnapshot['element'] ?? '').toString();
                final rarity = (s.seedSnapshot['rarity'] ?? '').toString();
                return ListTile(
                  title: Text(name),
                  subtitle: Text('$element • $rarity'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Equip into selected sprite slot by returning a SpriteModel
                    final ramp = SpritePalette.pickRampForSeed(s.seedHash);
                    String atkName = 'Sprite Attack';
                    int power = 30;
                    int duration = 2;
                    if (s.attacks.isNotEmpty) {
                      final a = s.attacks.first;
                      atkName = (a['name'] ?? atkName).toString();
                      power = (a['power'] ?? power) as int;
                      duration = (a['cooldown'] ?? duration) as int; // reuse cooldown as duration
                    }
                    final atk = SpriteAttack(name: atkName, description: 'Fires a focused burst for $power power over $duration turns.', power: power, durationTurns: duration);
                    final model = SpriteModel(id: s.instanceId, seedName: name, tier: 0, rarity: 0, hue: (s.seedHash.hashCode & 0x7fffffff) % 360, argbRamp: ramp, attack: atk, createdAt: s.createdAt);
                    Navigator.pop(context, model);
                  },
                );
              },
            ),
    );
  }
}
