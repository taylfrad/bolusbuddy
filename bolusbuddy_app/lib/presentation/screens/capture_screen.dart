import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../state/capture_controller.dart';
import '../state/providers.dart';
import 'history_screen.dart';
import 'loading_screen.dart';
import 'results_screen.dart';

class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  CameraController? _cameraController;
  Future<void>? _cameraInit;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(captureControllerProvider.notifier).loadCapabilities();
      _initCamera();
    });
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        return;
      }
      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      _cameraInit = _cameraController!.initialize();
      if (mounted) {
        setState(() {});
      }
    } catch (_) {
      // Camera is optional; fall back to picker.
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      final file = await _cameraController!.takePicture();
      await ref
          .read(captureControllerProvider.notifier)
          .analyzeSingleImage(File(file.path));
      return;
    }
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      await ref
          .read(captureControllerProvider.notifier)
          .analyzeSingleImage(File(photo.path));
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.gallery);
    if (photo != null) {
      await ref
          .read(captureControllerProvider.notifier)
          .analyzeSingleImage(File(photo.path));
    }
  }

  Future<void> _captureMultiAngle() async {
    final picker = ImagePicker();
    final photos = await picker.pickMultiImage();
    if (photos.isNotEmpty) {
      await ref.read(captureControllerProvider.notifier).analyzeMultiAngle(
            photos.map((photo) => File(photo.path)).toList(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(captureControllerProvider);
    if (state.status == CaptureStatus.loading) {
      return const Scaffold(
        body: LoadingScreen(message: 'Analyzing meal...'),
      );
    }
    if (state.status == CaptureStatus.loaded && state.meal != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(captureControllerProvider.notifier).reset();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ResultsScreen(meal: state.meal!),
          ),
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('BolusBuddy'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_cameraInit != null)
            FutureBuilder(
              future: _cameraInit,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done &&
                    _cameraController != null) {
                  return AspectRatio(
                    aspectRatio: _cameraController!.value.aspectRatio,
                    child: CameraPreview(_cameraController!),
                  );
                }
                return Container(
                  height: 220,
                  color: Colors.black12,
                  alignment: Alignment.center,
                  child: const Text('Camera loading...'),
                );
              },
            )
          else
            Container(
              height: 220,
              color: Colors.black12,
              alignment: Alignment.center,
              child: const Text('Camera unavailable'),
            ),
          const SizedBox(height: 16),
          Text(
            'Depth: ${state.capabilities.depthType}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: state.capabilities.hasDepth
                ? () => ref
                    .read(captureControllerProvider.notifier)
                    .analyzeDepthCapture()
                : null,
            icon: const Icon(Icons.layers),
            label: const Text('Depth capture (preferred)'),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _capturePhoto,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Quick photo'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickPhoto,
            icon: const Icon(Icons.photo_library),
            label: const Text('Pick from gallery'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _captureMultiAngle,
            icon: const Icon(Icons.camera),
            label: const Text('Multi-angle fallback'),
          ),
          if (state.status == CaptureStatus.error &&
              state.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                state.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }
}
