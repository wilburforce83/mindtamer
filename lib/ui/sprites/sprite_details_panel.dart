import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/sprite_model.dart';
import '../../services/sprite_instance_utils.dart';

class SpriteDetailsPanel extends StatelessWidget {
  final SpriteModel? selected;
  final VoidCallback onEquip;
  final VoidCallback onFuse;
  final VoidCallback? onCancel;
  final String? seedTitle; // journal entry title
  final String? primaryTag;
  final bool fuseMode;
  final SpriteModel? fusePrimary;
  const SpriteDetailsPanel({
    super.key,
    required this.selected,
    required this.onEquip,
    required this.onFuse,
    this.onCancel,
    this.seedTitle,
    this.primaryTag,
    this.fuseMode = false,
    this.fusePrimary,
  });

  @override
  Widget build(BuildContext context) {
    if (selected == null) {
      return Container(
        height: 160,
        alignment: Alignment.center,
        child: const Text('Tap a sprite to see details'),
      );
    }
    final s = selected!;
    final extra = MediaQuery.of(context).size.height * 0.07;
    return Container(
      height: 200 + extra,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
            top: BorderSide(
                color: Theme.of(context).colorScheme.outline, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seed name (colored by sprite ramp) + tiny 'Fused' badge if applicable
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  s.seedName,
                  style: (Theme.of(context).textTheme.bodySmall ??
                          const TextStyle())
                      .copyWith(
                    color: Color(s.argbRamp.length > 2
                        ? s.argbRamp[2]
                        : s.argbRamp.first),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              if (s.fused)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        width: 1),
                    color: Theme.of(context)
                        .colorScheme
                        .surface
                        .withValues(alpha: 0.6),
                  ),
                  child: const Text('Fused', style: TextStyle(fontSize: 9)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
              'Tier: ${s.tier == 0 ? 'Base' : 'T${s.tier}'} • Rarity: ${s.rarity}'),
          const SizedBox(height: 4),
          Text('Attack: ${s.attack.name}'),
          Text(s.attack.description),
          const SizedBox(height: 4),
          if (s.element != null || s.colorHex != null)
            Row(
              children: [
                if (s.colorHex != null && s.colorHex!.isNotEmpty)
                  Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(right: 6),
                      color: _fromHex(s.colorHex!)),
                Text('Element: ${s.element ?? '—'}',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          const SizedBox(height: 4),
          Text(
            'Origin: ${SpriteInstanceUtils.sourceTypeLabel(s.sourceType)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 2),
          Builder(builder: (context) {
            final sourceDate = s.sourceDate ?? s.createdAt.toLocal();
            final dt = DateFormat('d/M/yyyy').format(sourceDate);
            final title = s.sourceTitle ?? seedTitle ?? 'Unknown';
            return Text(
              'Source: $title ($dt)',
              style: Theme.of(context).textTheme.bodySmall,
            );
          }),
          if (s.fusedFromNames.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'Lineage: ${s.fusedFromNames.join(' + ')}',
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (primaryTag != null && primaryTag!.trim().isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'Tag: ${primaryTag!.trim()}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const Spacer(),
          Builder(builder: (context) {
            if (!fuseMode) {
              return Row(children: [
                ElevatedButton(onPressed: onEquip, child: const Text('Equip')),
                const SizedBox(width: 8),
                OutlinedButton(onPressed: onFuse, child: const Text('Fuse…')),
              ]);
            } else {
              final isPrimary =
                  fusePrimary != null && selected?.id == fusePrimary!.id;
              return Row(children: [
                if (!isPrimary)
                  ElevatedButton(onPressed: onFuse, child: const Text('Fuse')),
                const SizedBox(width: 8),
                OutlinedButton(
                    onPressed: onCancel, child: const Text('Cancel')),
              ]);
            }
          }),
        ],
      ),
    );
  }
}

Color _fromHex(String hex) {
  var h = hex.startsWith('#') ? hex.substring(1) : hex;
  if (h.length == 6) h = 'FF$h';
  final v = int.tryParse(h, radix: 16) ?? 0xFFFFFFFF;
  return Color(v);
}
