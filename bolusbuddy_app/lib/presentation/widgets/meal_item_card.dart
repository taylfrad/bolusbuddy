import 'package:flutter/material.dart';

import '../../core/models/meal_estimate.dart';
import '../../core/utils/units.dart';

class MealItemCard extends StatelessWidget {
  const MealItemCard({
    super.key,
    required this.item,
    required this.onUpdate,
  });

  final MealItemEstimate item;
  final ValueChanged<MealItemEstimate> onUpdate;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.name, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: item.grams.toStringAsFixed(0),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Grams',
                    ),
                    onSubmitted: (value) {
                      final parsed = double.tryParse(value);
                      if (parsed != null) {
                        onUpdate(item.copyWith(grams: parsed));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: item.unit,
                  items: unitOptions
                      .map(
                        (unit) => DropdownMenuItem(
                          value: unit,
                          child: Text(unit),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      onUpdate(item.copyWith(unit: value));
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Confidence ${(item.confidence * 100).toStringAsFixed(0)}%',
            ),
            const SizedBox(height: 8),
            Text(
              'Carbs ${item.carbs.value.toStringAsFixed(0)}g '
              '(${item.carbs.min.toStringAsFixed(0)}–${item.carbs.max.toStringAsFixed(0)})',
            ),
            Text(
              'Net ${item.netCarbs.value.toStringAsFixed(0)}g '
              '(${item.netCarbs.min.toStringAsFixed(0)}–${item.netCarbs.max.toStringAsFixed(0)})',
            ),
            Text(
              'Protein ${item.protein.value.toStringAsFixed(0)}g '
              '(${item.protein.min.toStringAsFixed(0)}–${item.protein.max.toStringAsFixed(0)})',
            ),
            Text(
              'Fat ${item.fat.value.toStringAsFixed(0)}g '
              '(${item.fat.min.toStringAsFixed(0)}–${item.fat.max.toStringAsFixed(0)})',
            ),
          ],
        ),
      ),
    );
  }
}
