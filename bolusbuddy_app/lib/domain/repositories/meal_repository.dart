import '../../core/models/meal_estimate.dart';
import '../../core/services/depth_bridge.dart';
import '../../core/services/image_preprocessor.dart';

abstract class MealRepository {
  Future<MealEstimate> analyzeMeal({
    required PreprocessedImage image,
    DepthFrame? depthFrame,
    List<PreprocessedImage> extraImages,
    required String mode,
  });

  Future<void> confirmCorrections({
    required String imageHash,
    required List<Map<String, dynamic>> correctedItems,
  });
}
