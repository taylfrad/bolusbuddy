import '../../core/models/meal_estimate.dart';

abstract class MealHistoryRepository {
  Future<void> saveMeal(MealEstimate meal);

  Future<List<MealEstimate>> loadMeals();

  Future<void> clear();
}
