import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/services/depth_bridge.dart';
import '../../core/services/image_preprocessor.dart';
import '../../data/api/meal_api_client.dart';
import '../../data/local/meal_history_db.dart';
import '../../data/repositories/meal_history_repository_impl.dart';
import '../../data/repositories/meal_repository_impl.dart';
import '../../domain/repositories/meal_history_repository.dart';
import '../../domain/repositories/meal_repository.dart';
import 'capture_controller.dart';
import 'history_controller.dart';

final backendBaseUrlProvider = Provider<String>((_) => defaultBackendBaseUrl);

final apiClientProvider = Provider<MealApiClient>((ref) {
  final baseUrl = ref.watch(backendBaseUrlProvider);
  return MealApiClient(baseUrl: baseUrl);
});

final mealRepositoryProvider = Provider<MealRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return MealRepositoryImpl(api);
});

final mealHistoryRepositoryProvider = Provider<MealHistoryRepository>((ref) {
  return MealHistoryRepositoryImpl(MealHistoryDb());
});

final imagePreprocessorProvider = Provider<ImagePreprocessor>((_) {
  return ImagePreprocessor();
});

final depthBridgeProvider = Provider<DepthBridge>((_) => DepthBridge());

final captureControllerProvider =
    StateNotifierProvider<CaptureController, CaptureState>((ref) {
  return CaptureController(
    ref.watch(imagePreprocessorProvider),
    ref.watch(depthBridgeProvider),
    ref.watch(mealRepositoryProvider),
    ref.watch(mealHistoryRepositoryProvider),
  );
});

final historyControllerProvider =
    StateNotifierProvider<HistoryController, HistoryState>((ref) {
  return HistoryController(ref.watch(mealHistoryRepositoryProvider));
});
