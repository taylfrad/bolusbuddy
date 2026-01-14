import 'dart:typed_data';

import 'package:flutter/services.dart';

class DepthCapabilities {
  const DepthCapabilities({
    required this.hasDepth,
    required this.depthType,
    required this.supportsConfidence,
  });

  final bool hasDepth;
  final String depthType;
  final bool supportsConfidence;

  static const none =
      DepthCapabilities(hasDepth: false, depthType: 'none', supportsConfidence: false);
}

class DepthFrame {
  const DepthFrame({
    required this.rgbJpeg,
    required this.depthPng16,
    required this.depthF32,
    required this.depthEncoding,
    required this.confidencePng,
    required this.intrinsicsJson,
    required this.width,
    required this.height,
  });

  final Uint8List rgbJpeg;
  final Uint8List? depthPng16;
  final Uint8List? depthF32;
  final String? depthEncoding;
  final Uint8List? confidencePng;
  final String intrinsicsJson;
  final int width;
  final int height;
}

class DepthBridge {
  static const MethodChannel _channel = MethodChannel('bolusbuddy/depth');

  Future<DepthCapabilities> getCapabilities() async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'getDepthCapabilities',
    );
    if (result == null) {
      return DepthCapabilities.none;
    }
    return DepthCapabilities(
      hasDepth: result['hasDepth'] == true,
      depthType: (result['depthType'] as String?) ?? 'none',
      supportsConfidence: result['supportsConfidence'] == true,
    );
  }

  Future<DepthFrame?> captureDepthFrame() async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'captureDepthFrame',
    );
    if (result == null) {
      return null;
    }
    return DepthFrame(
      rgbJpeg: result['rgbJpeg'] as Uint8List,
      depthPng16: result['depthPng16'] as Uint8List?,
      depthF32: result['depthF32'] as Uint8List?,
      depthEncoding: result['depthEncoding'] as String?,
      confidencePng: result['confidencePng'] as Uint8List?,
      intrinsicsJson: result['intrinsicsJson'] as String,
      width: (result['width'] as num?)?.toInt() ?? 0,
      height: (result['height'] as num?)?.toInt() ?? 0,
    );
  }
}
