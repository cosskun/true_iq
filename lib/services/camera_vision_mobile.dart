import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'camera_vision_service.dart';
import 'proctor_service.dart';

PlatformVisionTracker createPlatformVisionTracker() => MobileVisionTracker();

class MobileVisionTracker implements PlatformVisionTracker {
  FaceDetector? _faceDetector;
  bool _isProcessing = false;
  CameraController? _controller;
  ProctorService? _proctorService;

  @override
  Future<void> startTracking({
    required CameraController controller,
    required ProctorService proctorService,
  }) async {
    _controller = controller;
    _proctorService = proctorService;

    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        enableTracking: true,
        performanceMode: FaceDetectorMode.fast,
        minFaceSize: 0.15,
      ),
    );

    try {
      await controller.startImageStream((CameraImage image) {
        if (_isProcessing) return;
        _processFrame(image);
      });
    } catch (e) {
      debugPrint('Mobile startImageStream hatası: $e');
    }
  }

  Future<void> _processFrame(CameraImage image) async {
    if (_isProcessing || _faceDetector == null || _proctorService == null) return;
    _isProcessing = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) {
        _isProcessing = false;
        return;
      }

      final faces = await _faceDetector!.processImage(inputImage);
      if (faces.isEmpty) {
        _proctorService?.updateFacePose(
          faceDetected: false,
          yaw: 0,
          pitch: 0,
          leftEyeOpen: false,
          rightEyeOpen: false,
        );
      } else {
        final face = faces.first;
        final double yaw = face.headEulerAngleY ?? 0.0;
        final double pitch = face.headEulerAngleX ?? 0.0;
        final bool leftEye = (face.leftEyeOpenProbability ?? 1.0) > 0.15;
        final bool rightEye = (face.rightEyeOpenProbability ?? 1.0) > 0.15;

        _proctorService?.updateFacePose(
          faceDetected: true,
          yaw: yaw,
          pitch: pitch,
          leftEyeOpen: leftEye,
          rightEyeOpen: rightEye,
        );
      }
    } catch (e) {
      debugPrint('ML Kit yüz analizi hatası: $e');
    } finally {
      _isProcessing = false;
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_controller == null) return null;
    final camera = _controller!.description;
    final sensorOrientation = camera.sensorOrientation;

    InputImageRotation? rotation;
    if (defaultTargetPlatform == TargetPlatform.android) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    }
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    final bytes = Uint8List.fromList(
      image.planes.fold<List<int>>([], (list, plane) => list..addAll(plane.bytes)),
    );

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  @override
  void stopTracking() {
    try {
      _controller?.stopImageStream();
    } catch (_) {}
    _faceDetector?.close();
    _faceDetector = null;
    _controller = null;
    _proctorService = null;
  }
}
