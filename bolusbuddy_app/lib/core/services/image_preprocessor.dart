import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class PreprocessedImage {
  const PreprocessedImage({
    required this.file,
    required this.bytes,
    required this.hash,
    required this.width,
    required this.height,
  });

  final File file;
  final Uint8List bytes;
  final String hash;
  final int width;
  final int height;
}

class ImagePreprocessor {
  Future<PreprocessedImage> preprocess(File file) async {
    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw StateError('Unable to decode image.');
    }

    final oriented = img.bakeOrientation(decoded);
    final resized = _resizeIfNeeded(oriented, maxEdge: 1024);
    final jpegBytes = Uint8List.fromList(img.encodeJpg(resized, quality: 85));
    final hash = sha256.convert(jpegBytes).toString();
    final tempDir = await getTemporaryDirectory();
    final fileName = '${path.basenameWithoutExtension(file.path)}_$hash.jpg';
    final outFile = File(path.join(tempDir.path, fileName));
    await outFile.writeAsBytes(jpegBytes, flush: true);

    return PreprocessedImage(
      file: outFile,
      bytes: jpegBytes,
      hash: hash,
      width: resized.width,
      height: resized.height,
    );
  }

  img.Image _resizeIfNeeded(img.Image source, {required int maxEdge}) {
    final width = source.width;
    final height = source.height;
    final maxDim = width > height ? width : height;
    if (maxDim <= maxEdge) {
      return source;
    }
    final scale = maxEdge / maxDim;
    return img.copyResize(
      source,
      width: (width * scale).round(),
      height: (height * scale).round(),
      interpolation: img.Interpolation.average,
    );
  }
}
