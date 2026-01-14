import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/meal_estimate.dart';
import '../../core/models/nutrition.dart';
import '../state/providers.dart';
import '../widgets/meal_item_card.dart';
import '../widgets/metric_range_tile.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({super.key, required this.meal});

  final MealEstimate meal;

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  late List<MealItemEstimate> _items;

  @override
  void initState() {
    super.initState();
    _items = widget.meal.items;
  }

  NutrientRange _sumRange(
    NutrientRange Function(MealItemEstimate item) selector,
  ) {
    var value = 0.0;
    var min = 0.0;
    var max = 0.0;
    for (final item in _items) {
      final range = selector(item);
      value += range.value;
      min += range.min;
      max += range.max;
    }
    return NutrientRange(value: value, min: min, max: max);
  }

  void _updateItem(MealItemEstimate updated) {
    setState(() {
      _items = _items.map((item) {
        if (item.id != updated.id) {
          return item;
        }
        final factor = updated.grams / item.grams;
        return updated.copyWith(
          carbs: item.carbs.scale(factor),
          netCarbs: item.netCarbs.scale(factor),
          protein: item.protein.scale(factor),
          fat: item.fat.scale(factor),
          calories: item.calories.scale(factor),
        );
      }).toList();
    });
  }

  Future<void> _sendCorrections() async {
    final repo = ref.read(mealRepositoryProvider);
    final corrected = _items
        .map((item) => {
              'id': item.id,
              'grams': item.grams,
              'unit': item.unit,
            })
        .toList();
    await repo.confirmCorrections(
      imageHash: widget.meal.imageHash,
      correctedItems: corrected,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Corrections sent.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalCarbs = _sumRange((item) => item.carbs);
    final totalNetCarbs = _sumRange((item) => item.netCarbs);
    final totalProtein = _sumRange((item) => item.protein);
    final totalFat = _sumRange((item) => item.fat);
    final totalCalories = _sumRange((item) => item.calories);
    final lowConfidence = widget.meal.confidence < 0.6;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Results'),
        actions: [
          IconButton(
            onPressed: _sendCorrections,
            icon: const Icon(Icons.check),
            tooltip: 'Send corrections',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (lowConfidence)
            Card(
              color: Colors.orange.shade100,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Low confidence. Please verify portions and foods.',
                ),
              ),
            ),
          Text(
            'Mode: ${widget.meal.mode.replaceAll('_', ' ')}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Text(
            'Overall confidence ${(widget.meal.confidence * 100).toStringAsFixed(0)}%',
          ),
          const SizedBox(height: 12),
          MetricRangeTile(label: 'Total Carbs', range: totalCarbs, unit: 'g'),
          MetricRangeTile(
            label: 'Net Carbs',
            range: totalNetCarbs,
            unit: 'g',
          ),
          MetricRangeTile(
            label: 'Protein',
            range: totalProtein,
            unit: 'g',
          ),
          MetricRangeTile(label: 'Fat', range: totalFat, unit: 'g'),
          MetricRangeTile(
            label: 'Calories',
            range: totalCalories,
            unit: 'kcal',
          ),
          const Divider(),
          Text(
            'Items',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          for (final item in _items)
            MealItemCard(
              item: item,
              onUpdate: _updateItem,
            ),
          const SizedBox(height: 24),
          const Text(
            'Decision support only. Not medical advice.',
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
