import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PoseService {
  late PoseDetector _poseDetector;
  bool _isBusy = false;

  Future<void> init(
      {required PoseDetectionModel model,
      required PoseDetectionMode mode}) async {
    final options = PoseDetectorOptions(model: model, mode: mode);
    _poseDetector = PoseDetector(options: options);
  }

  Future<void> dispose() async {
    await _poseDetector.close();
  }

  // ใช้ในหน้า SaveGesturePage (Upload/Capture)
  Future<List<Pose>> processImage(InputImage inputImage) async {
    if (_isBusy) return [];
    _isBusy = true;
    try {
      final poses = await _poseDetector.processImage(inputImage);
      return poses;
    } catch (e) {
      debugPrint("PoseService file error: $e");
      return [];
    } finally {
      _isBusy = false;
    }
  }

  // ใช้ในหน้า StartCamPage (Live Stream)
  Future<List<Pose>> processCameraImage(CameraImage image,
      {required InputImageRotation rotation}) async {
    if (_isBusy) return [];
    _isBusy = true;
    try {
      final inputImage = _inputImageFromCameraImage(image, rotation);
      if (inputImage == null) return [];

      final poses = await _poseDetector.processImage(inputImage);
      return poses;
    } catch (e) {
      debugPrint("PoseService stream error: $e");
      return [];
    } finally {
      _isBusy = false;
    }
  }

  // Helper
  InputImage? _inputImageFromCameraImage(
      CameraImage image, InputImageRotation rotation) {
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) {
      // Fallback for Android if rawValue doesn't map directly
      if (defaultTargetPlatform == TargetPlatform.android) {
        return null;
      }
      return null;
    }

    if (image.planes.isEmpty) return null;
    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }
}
