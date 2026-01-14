import 'package:flutter/material.dart';

import '../../core/models/nutrition.dart';

class MetricRangeTile extends StatelessWidget {
  const MetricRangeTile({
    super.key,
    required this.label,
    required this.range,
    required this.unit,
  });

  final String label;
  final NutrientRange range;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      title: Text(label, style: theme.textTheme.titleMedium),
      subtitle: Text(
        '${range.value.toStringAsFixed(0)}$unit '
        '(${range.min.toStringAsFixed(0)}–${range.max.toStringAsFixed(0)}$unit)',
      ),
    );
  }
}
