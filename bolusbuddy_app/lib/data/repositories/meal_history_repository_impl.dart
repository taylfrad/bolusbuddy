import '../../core/models/meal_estimate.dart';
import '../../domain/repositories/meal_history_repository.dart';
import '../local/meal_history_db.dart';

class MealHistoryRepositoryImpl implements MealHistoryRepository {
  MealHistoryRepositoryImpl(this._db);

  final MealHistoryDb _db;

  @override
  Future<void> saveMeal(MealEstimate meal) => _db.insertMeal(meal);

  @override
  Future<List<MealEstimate>> loadMeals() => _db.fetchMeals();

  @override
  Future<void> clear() => _db.clear();
}
