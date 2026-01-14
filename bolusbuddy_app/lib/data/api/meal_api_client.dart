import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../core/models/meal_estimate.dart';
import '../../core/services/depth_bridge.dart';
import '../../core/services/image_preprocessor.dart';

class MealApiClient {
  MealApiClient({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<MealEstimate> analyzeMeal({
    required PreprocessedImage image,
    DepthFrame? depthFrame,
    List<PreprocessedImage> extraImages = const [],
    required String mode,
  }) async {
    final uri = Uri.parse('$baseUrl/analyzeMeal');
    final depthWidth = depthFrame?.width ?? image.width;
    final depthHeight = depthFrame?.height ?? image.height;
    final request = http.MultipartRequest('POST', uri)
      ..fields['image_hash'] = image.hash
      ..fields['mode'] = mode
      ..fields['width'] = depthWidth.toString()
      ..fields['height'] = depthHeight.toString();

    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        image.bytes,
        filename: 'image.jpg',
        contentType: ContentType('image', 'jpeg'),
      ),
    );

    for (var i = 0; i < extraImages.length; i++) {
      final extra = extraImages[i];
      request.files.add(
        http.MultipartFile.fromBytes(
          'extra_images',
          extra.bytes,
          filename: 'extra_$i.jpg',
          contentType: ContentType('image', 'jpeg'),
        ),
      );
    }

    if (depthFrame != null) {
      if (depthFrame.depthPng16 != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'depth_png16',
            depthFrame.depthPng16!,
            filename: 'depth.png',
            contentType: ContentType('image', 'png'),
          ),
        );
      } else if (depthFrame.depthF32 != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'depth_f32',
            depthFrame.depthF32!,
            filename: 'depth.bin',
            contentType: ContentType('application', 'octet-stream'),
          ),
        );
        if (depthFrame.depthEncoding != null) {
          request.fields['depth_encoding'] = depthFrame.depthEncoding!;
        }
      }
      if (depthFrame.confidencePng != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'confidence_png',
            depthFrame.confidencePng!,
            filename: 'confidence.png',
            contentType: ContentType('image', 'png'),
          ),
        );
      }
      request.fields['intrinsics_json'] = depthFrame.intrinsicsJson;
    }

    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 200) {
      throw HttpException(
        'Analyze failed: ${response.statusCode} ${response.body}',
      );
    }
    final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
    return MealEstimate.fromJson(jsonMap);
  }

  Future<void> confirmCorrections({
    required String imageHash,
    required List<Map<String, dynamic>> correctedItems,
  }) async {
    final uri = Uri.parse('$baseUrl/confirmCorrections');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'image_hash': imageHash,
        'items': correctedItems,
      }),
    );
    if (response.statusCode != 200) {
      throw HttpException(
        'Confirm failed: ${response.statusCode} ${response.body}',
      );
    }
  }
}
