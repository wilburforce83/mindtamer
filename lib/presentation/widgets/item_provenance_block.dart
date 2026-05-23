import 'package:flutter/material.dart';

import '../../crafting/item_provenance_service.dart';
import '../../crafting/models.dart';

class ItemProvenanceBlock extends StatelessWidget {
  final CraftedItem item;
  final TextStyle? headingStyle;
  final TextStyle? bodyStyle;
  final int maxSources;
  final int maxLineageSteps;

  const ItemProvenanceBlock({
    super.key,
    required this.item,
    this.headingStyle,
    this.bodyStyle,
    this.maxSources = 4,
    this.maxLineageSteps = 4,
  });

  @override
  Widget build(BuildContext context) {
    final headings = headingStyle ?? Theme.of(context).textTheme.labelMedium;
    final body = bodyStyle ??
        Theme.of(context).textTheme.labelSmall ??
        const TextStyle(fontSize: 11);
    if (item.memorySources.isEmpty && item.lineageSteps.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.lineageSteps.isNotEmpty) ...[
          Text('Lineage', style: headings),
          const SizedBox(height: 2),
          ...item.lineageSteps.take(maxLineageSteps).map((step) =>
              Text('• ${_formatLineage(step)}', style: body, softWrap: true)),
          if (item.lineageSteps.length > maxLineageSteps)
            Text(
              '• +${item.lineageSteps.length - maxLineageSteps} more steps',
              style: body,
            ),
        ],
        if (item.lineageSteps.isNotEmpty && item.memorySources.isNotEmpty)
          const SizedBox(height: 6),
        if (item.memorySources.isNotEmpty) ...[
          Text('Memory Sources', style: headings),
          const SizedBox(height: 2),
          ...item.memorySources.take(maxSources).map((source) =>
              Text('• ${_formatSource(source)}', style: body, softWrap: true)),
          if (item.memorySources.length > maxSources)
            Text(
              '• +${item.memorySources.length - maxSources} more memories',
              style: body,
            ),
        ],
      ],
    );
  }

  String _formatLineage(ItemLineageStep step) {
    final date = _formatDate(step.at);
    if (date == null) return step.summary;
    return '${step.summary} ($date)';
  }

  String _formatSource(ItemMemorySource source) {
    final headline = ItemProvenanceService.sourceHeadline(source);
    final date = _formatDate(ItemProvenanceService.sourceDisplayDate(source));
    final element = source.element?.name;
    final rarity = source.rarity?.name;
    final tags = <String>[];
    if (date != null) tags.add(date);
    if (element != null && element.isNotEmpty) tags.add(element);
    if (rarity != null && rarity.isNotEmpty) tags.add(rarity);
    if (tags.isEmpty) return headline;
    return '$headline [${tags.join(' • ')}]';
  }

  String? _formatDate(DateTime? raw) {
    if (raw == null) return null;
    final dt = raw.toLocal();
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final yyyy = dt.year.toString();
    return '$dd/$mm/$yyyy';
  }
}
