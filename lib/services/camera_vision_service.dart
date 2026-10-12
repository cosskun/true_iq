import 'dart:async';
import 'package:camera/camera.dart';
import 'proctor_service.dart';

// Koşullu importlar veya Web / Mobile ayrımı
import 'camera_vision_web.dart' if (dart.library.io) 'camera_vision_mobile.dart';

abstract class PlatformVisionTracker {
  Future<void> startTracking({
    required CameraController controller,
    required ProctorService proctorService,
  });
  void stopTracking();
}

class CameraVisionService {
  static CameraVisionService? _instance;
  static CameraVisionService get instance => _instance ??= CameraVisionService._();
  CameraVisionService._();

  CameraController? _controller;
  CameraController? get controller => _controller;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized && _controller != null && _controller!.value.isInitialized;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  PlatformVisionTracker? _platformTracker;

  Future<bool> initializeCamera({required ProctorService proctorService}) async {
    try {
      _errorMessage = null;
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _errorMessage = 'Cihazda kullanılabilir kamera bulunamadı.';
        return false;
      }

      // Ön kamerayı bul, yoksa ilk kamerayı seç
      CameraDescription selectedCamera = cameras.first;
      for (final cam in cameras) {
        if (cam.lensDirection == CameraLensDirection.front) {
          selectedCamera = cam;
          break;
        }
      }

      _controller = CameraController(
        selectedCamera,
        ResolutionPreset.low, // Düşük gecikme ve hızlı analiz için
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _controller!.initialize();
      _isInitialized = true;

      // Platforma özel otomatik yüz & göz takibini başlat
      _platformTracker = createPlatformVisionTracker();
      await _platformTracker?.startTracking(
        controller: _controller!,
        proctorService: proctorService,
      );

      return true;
    } catch (e) {
      _errorMessage = 'Kamera başlatılamadı: $e';
      _isInitialized = false;
      return false;
    }
  }

  void stop() {
    _platformTracker?.stopTracking();
    _platformTracker = null;
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }
}
