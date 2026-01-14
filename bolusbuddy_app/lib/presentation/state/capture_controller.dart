import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/meal_estimate.dart';
import '../../core/services/depth_bridge.dart';
import '../../core/services/image_preprocessor.dart';
import '../../domain/repositories/meal_history_repository.dart';
import '../../domain/repositories/meal_repository.dart';

enum CaptureStatus { idle, loading, loaded, error }

class CaptureState {
  const CaptureState({
    required this.status,
    required this.capabilities,
    required this.mode,
    this.meal,
    this.errorMessage,
  });

  final CaptureStatus status;
  final DepthCapabilities capabilities;
  final String mode;
  final MealEstimate? meal;
  final String? errorMessage;

  CaptureState copyWith({
    CaptureStatus? status,
    DepthCapabilities? capabilities,
    String? mode,
    MealEstimate? meal,
    String? errorMessage,
  }) {
    return CaptureState(
      status: status ?? this.status,
      capabilities: capabilities ?? this.capabilities,
      mode: mode ?? this.mode,
      meal: meal ?? this.meal,
      errorMessage: errorMessage,
    );
  }
}

class CaptureController extends StateNotifier<CaptureState> {
  CaptureController(
    this._imagePreprocessor,
    this._depthBridge,
    this._mealRepository,
    this._historyRepository,
  ) : super(
          const CaptureState(
            status: CaptureStatus.idle,
            capabilities: DepthCapabilities.none,
            mode: 'quick_photo',
          ),
        );

  final ImagePreprocessor _imagePreprocessor;
  final DepthBridge _depthBridge;
  final MealRepository _mealRepository;
  final MealHistoryRepository _historyRepository;

  Future<void> loadCapabilities() async {
    final capabilities = await _depthBridge.getCapabilities();
    final mode = capabilities.hasDepth ? 'depth_capture' : 'quick_photo';
    state = state.copyWith(capabilities: capabilities, mode: mode);
  }

  Future<void> analyzeSingleImage(File file) async {
    state = state.copyWith(status: CaptureStatus.loading, errorMessage: null);
    try {
      final processed = await _imagePreprocessor.preprocess(file);
      final estimate = await _mealRepository.analyzeMeal(
        image: processed,
        depthFrame: null,
        extraImages: const [],
        mode: 'quick_photo',
      );
      await _historyRepository.saveMeal(estimate);
      state = state.copyWith(status: CaptureStatus.loaded, meal: estimate);
    } catch (error) {
      state = state.copyWith(
        status: CaptureStatus.error,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> analyzeDepthCapture() async {
    state = state.copyWith(status: CaptureStatus.loading, errorMessage: null);
    try {
      final depthFrame = await _depthBridge.captureDepthFrame();
      if (depthFrame == null) {
        throw StateError('Depth capture failed.');
      }
      final tempFile = await File('${Directory.systemTemp.path}/depth_rgb.jpg')
          .writeAsBytes(depthFrame.rgbJpeg, flush: true);
      final processed = await _imagePreprocessor.preprocess(tempFile);
      final estimate = await _mealRepository.analyzeMeal(
        image: processed,
        depthFrame: depthFrame,
        extraImages: const [],
        mode: 'depth_capture',
      );
      await _historyRepository.saveMeal(estimate);
      state = state.copyWith(status: CaptureStatus.loaded, meal: estimate);
    } catch (error) {
      state = state.copyWith(
        status: CaptureStatus.error,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> analyzeMultiAngle(List<File> files) async {
    if (files.isEmpty) {
      return;
    }
    state = state.copyWith(status: CaptureStatus.loading, errorMessage: null);
    try {
      final primary = await _imagePreprocessor.preprocess(files.first);
      final extras = <PreprocessedImage>[];
      for (final file in files.skip(1)) {
        extras.add(await _imagePreprocessor.preprocess(file));
      }
      final estimate = await _mealRepository.analyzeMeal(
        image: primary,
        depthFrame: null,
        extraImages: extras,
        mode: 'multi_angle',
      );
      await _historyRepository.saveMeal(estimate);
      state = state.copyWith(status: CaptureStatus.loaded, meal: estimate);
    } catch (error) {
      state = state.copyWith(
        status: CaptureStatus.error,
        errorMessage: error.toString(),
      );
    }
  }

  void reset() {
    state = state.copyWith(
      status: CaptureStatus.idle,
      meal: null,
      errorMessage: null,
    );
  }
}
