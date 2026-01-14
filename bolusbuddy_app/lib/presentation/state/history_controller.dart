import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/meal_estimate.dart';
import '../../domain/repositories/meal_history_repository.dart';

class HistoryState {
  const HistoryState({
    required this.meals,
    required this.isLoading,
    this.errorMessage,
  });

  final List<MealEstimate> meals;
  final bool isLoading;
  final String? errorMessage;

  HistoryState copyWith({
    List<MealEstimate>? meals,
    bool? isLoading,
    String? errorMessage,
  }) {
    return HistoryState(
      meals: meals ?? this.meals,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class HistoryController extends StateNotifier<HistoryState> {
  HistoryController(this._repository)
      : super(const HistoryState(meals: [], isLoading: false));

  final MealHistoryRepository _repository;

  Future<void> loadMeals() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final meals = await _repository.loadMeals();
      state = state.copyWith(meals: meals, isLoading: false);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> clear() async {
    await _repository.clear();
    await loadMeals();
  }
}
