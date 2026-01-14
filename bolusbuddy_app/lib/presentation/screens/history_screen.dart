import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';
import 'results_screen.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(historyControllerProvider.notifier).loadMeals(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(historyControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal History'),
        actions: [
          IconButton(
            onPressed: () =>
                ref.read(historyControllerProvider.notifier).clear(),
            icon: const Icon(Icons.delete),
            tooltip: 'Clear history',
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: state.meals.length,
              itemBuilder: (context, index) {
                final meal = state.meals[index];
                return ListTile(
                  title: Text('Meal ${index + 1}'),
                  subtitle: Text(
                    'Carbs ${meal.totalCarbs.value.toStringAsFixed(0)}g '
                    '(${meal.mode.replaceAll('_', ' ')})',
                  ),
                  trailing: Text(
                    '${(meal.confidence * 100).toStringAsFixed(0)}%',
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ResultsScreen(meal: meal),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
