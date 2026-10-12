import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'package:camera/camera.dart';
import 'camera_vision_service.dart';
import 'proctor_service.dart';

PlatformVisionTracker createPlatformVisionTracker() => WebVisionTracker();

class WebVisionTracker implements PlatformVisionTracker {
  Timer? _analysisTimer;
  ProctorService? _proctorService;
  web.HTMLCanvasElement? _canvas;
  web.CanvasRenderingContext2D? _ctx;

  @override
  Future<void> startTracking({
    required CameraController controller,
    required ProctorService proctorService,
  }) async {
    _proctorService = proctorService;

    // Offscreen Canvas oluştur
    _canvas = web.document.createElement('canvas') as web.HTMLCanvasElement;
    _canvas!.width = 160;
    _canvas!.height = 120;
    _ctx = _canvas!.getContext('2d') as web.CanvasRenderingContext2D?;

    // 120ms periyodik gerçek zamanlı web kamera yüz ve dikkat analizi
    _analysisTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      _analyzeWebFrame();
    });
  }

  void _analyzeWebFrame() {
    if (_proctorService == null || _ctx == null || _canvas == null) return;

    // DOM'daki aktif video öğesini bul
    final videos = web.document.querySelectorAll('video');
    if (videos.length == 0) {
      _proctorService?.updateFacePose(
        faceDetected: false,
        yaw: 0,
        pitch: 0,
        leftEyeOpen: false,
        rightEyeOpen: false,
      );
      return;
    }

    final video = videos.item(0) as web.HTMLVideoElement;
    if (video.videoWidth == 0 || video.videoHeight == 0) return;

    try {
      // Kareyi 160x120 çözünürlükte analiz tuvaline çek
      _ctx!.drawImage(video, 0, 0, 160, 120);
      final imageData = _ctx!.getImageData(0, 0, 160, 120);
      final data = imageData.data.toDart;

      // Piksel tabanlı ten ve yüz ağırlık merkezi (Centroid) analizi
      int totalFacePixels = 0;
      double sumX = 0;
      double sumY = 0;

      final int len = data.length;
      for (int i = 0; i < len; i += 16) { // Hız için 4'er piksel atlamalı
        final r = data[i];
        final g = data[i + 1];
        final b = data[i + 2];

        // İnsan ten rengi ve aydınlık yüz bölgesi tespiti (YCrCb / RGB filtreleme)
        final bool isSkinTone = (r > 60 && g > 40 && b > 20) &&
            (r > g && r > b) &&
            ((r - g).abs() > 10) &&
            (r < 250);

        if (isSkinTone) {
          final pixelIndex = i ~/ 4;
          final px = pixelIndex % 160;
          final py = pixelIndex ~/ 160;

          sumX += px;
          sumY += py;
          totalFacePixels++;
        }
      }

      // Karedeki ten/yüz piksel oranı eşiği
      const int minFacePixels = 120; // Kadrajda yüz olması için asgari miktar
      if (totalFacePixels < minFacePixels) {
        // Yüz kadrajda yok veya kamera kapatılmış
        _proctorService?.updateFacePose(
          faceDetected: false,
          yaw: 0,
          pitch: 0,
          leftEyeOpen: false,
          rightEyeOpen: false,
        );
      } else {
        // Yüzün merkez koordinatı
        final avgX = sumX / totalFacePixels; // 0..160
        final avgY = sumY / totalFacePixels; // 0..120

        // Merkeze göre sapma (-1.0 .. +1.0)
        final normX = (avgX - 80.0) / 80.0;
        final normY = (avgY - 60.0) / 60.0;

        // Açısal tahmin (Euler Yaw & Pitch)
        final double yaw = normX * 42.0;  // Sağa/Sola bakış açısı
        final double pitch = normY * 35.0; // Yukarı/Aşağı bakış açısı

        _proctorService?.updateFacePose(
          faceDetected: true,
          yaw: yaw,
          pitch: pitch,
          leftEyeOpen: true,
          rightEyeOpen: true,
        );
      }
    } catch (_) {
      // Frame okuma hatasında mevcut durumu koru
    }
  }

  @override
  void stopTracking() {
    _analysisTimer?.cancel();
    _analysisTimer = null;
    _proctorService = null;
    _canvas = null;
    _ctx = null;
  }
}
