import '../../core/models/meal_estimate.dart';
import '../../core/services/depth_bridge.dart';
import '../../core/services/image_preprocessor.dart';
import '../../domain/repositories/meal_repository.dart';
import '../api/meal_api_client.dart';

class MealRepositoryImpl implements MealRepository {
  MealRepositoryImpl(this._api);

  final MealApiClient _api;

  @override
  Future<MealEstimate> analyzeMeal({
    required PreprocessedImage image,
    DepthFrame? depthFrame,
    List<PreprocessedImage> extraImages = const [],
    required String mode,
  }) {
    return _api.analyzeMeal(
      image: image,
      depthFrame: depthFrame,
      extraImages: extraImages,
      mode: mode,
    );
  }

  @override
  Future<void> confirmCorrections({
    required String imageHash,
    required List<Map<String, dynamic>> correctedItems,
  }) {
    return _api.confirmCorrections(
      imageHash: imageHash,
      correctedItems: correctedItems,
    );
  }
}
