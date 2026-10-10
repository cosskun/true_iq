import 'dart:async';
import 'package:flutter/material.dart';

enum ProctorViolationType {
  gazeLostExceeded,    // Gözler ekrandan ayrıldı (tolerans süresi aşıldı)
  appBackgrounded,     // Uygulamadan çıkıldı / arkaya atıldı
  faceNotDetected,     // Kadrajda yüz bulunamadı
  multipleFaces,       // Kadrajda birden fazla kişi var
}

class GazeState {
  final bool isFaceDetected;
  final bool isAttentive; // Gözler ekrana odaklı mı?
  final double yawAngle;  // Kafa sağ/sol açısı (-30..+30)
  final double pitchAngle; // Kafa yukarı/aşağı açısı (-30..+30)
  final double gazeLostSeconds;
  final double maxToleranceSeconds;
  final String statusMessage;

  const GazeState({
    required this.isFaceDetected,
    required this.isAttentive,
    required this.yawAngle,
    required this.pitchAngle,
    required this.gazeLostSeconds,
    this.maxToleranceSeconds = 2.5,
    required this.statusMessage,
  });

  double get attentionPercent =>
      (1.0 - (gazeLostSeconds / maxToleranceSeconds)).clamp(0.0, 1.0);
}

class ProctorService with WidgetsBindingObserver {
  final double maxToleranceSeconds;
  final Function(ProctorViolationType type, String reason) onViolation;
  final Function(GazeState state)? onGazeStateChanged;

  Timer? _tickerTimer;
  double _gazeLostDuration = 0.0;
  bool _isAttentive = true;
  bool _isFaceDetected = true;
  double _currentYaw = 0.0;
  double _currentPitch = 0.0;
  bool _isActive = false;

  ProctorService({
    this.maxToleranceSeconds = 2.5,
    required this.onViolation,
    this.onGazeStateChanged,
  });

  void startMonitoring() {
    _isActive = true;
    _gazeLostDuration = 0.0;
    _isAttentive = true;
    _isFaceDetected = true;
    WidgetsBinding.instance.addObserver(this);

    // 100ms periyodik denetleyici
    _tickerTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isActive) return;

      if (!_isAttentive || !_isFaceDetected) {
        _gazeLostDuration += 0.1;
        if (_gazeLostDuration >= maxToleranceSeconds) {
          _isActive = false;
          final reason = !_isFaceDetected
              ? 'Yüzünüz kamera açısında tespit edilemedi!'
              : 'Gözleriniz $maxToleranceSeconds saniyeden uzun süre ekrandan ayrıldı!';
          onViolation(
            !_isFaceDetected
                ? ProctorViolationType.faceNotDetected
                : ProctorViolationType.gazeLostExceeded,
            reason,
          );
        }
      } else {
        // Yeniden ekrana odaklanınca sayacı sıfırla/düşür
        if (_gazeLostDuration > 0) {
          _gazeLostDuration = (_gazeLostDuration - 0.2).clamp(0.0, maxToleranceSeconds);
        }
      }

      _notifyState();
    });
  }

  void stopMonitoring() {
    _isActive = false;
    _tickerTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }

  /// ML Kit veya Kamera Frame işleyicisinden gelen kafa/göz verilerini günceller
  void updateFacePose({
    required bool faceDetected,
    required double yaw,
    required double pitch,
    required bool leftEyeOpen,
    required bool rightEyeOpen,
  }) {
    if (!_isActive) return;

    _isFaceDetected = faceDetected;
    _currentYaw = yaw;
    _currentPitch = pitch;

    // Açısal tolerans limitleri:
    // Yaw > ±18 derece (sağa-sola aşırı bakış)
    // Pitch > ±16 derece (aşağı-yukarı aşırı bakış)
    final bool isAngleValid = (yaw.abs() <= 18.0) && (pitch.abs() <= 16.0);
    final bool isEyesVisible = leftEyeOpen || rightEyeOpen;

    _isAttentive = faceDetected && isAngleValid && isEyesVisible;
  }

  /// Uygulama Yaşam Döngüsü Denetimi (Arka plana geçme / bölünmüş ekran)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isActive) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      // Kullanıcı başka uygulamaya geçti veya ekranı kapattı
      _isActive = false;
      onViolation(
        ProctorViolationType.appBackgrounded,
        'Test esnasında uygulamadan çıkmaya veya başka bir uygulamaya geçmeye çalıştınız!',
      );
    }
  }

  void _notifyState() {
    if (onGazeStateChanged == null) return;

    String msg = 'Gözler Ekranda • Güvenli';
    if (!_isFaceDetected) {
      msg = 'UYARI: Yüz Algılanamadı!';
    } else if (!_isAttentive) {
      final left = (maxToleranceSeconds - _gazeLostDuration).toStringAsFixed(1);
      msg = 'DİKKAT: Ekrana Odaklanın! ($left s)';
    }

    onGazeStateChanged!(
      GazeState(
        isFaceDetected: _isFaceDetected,
        isAttentive: _isAttentive,
        yawAngle: _currentYaw,
        pitchAngle: _currentPitch,
        gazeLostSeconds: _gazeLostDuration,
        maxToleranceSeconds: maxToleranceSeconds,
        statusMessage: msg,
      ),
    );
  }

  /// Geliştirici / Test simülatörü için manuel göz ayırma tetikleyicisi
  void simulateGazeShift(bool lookAway) {
    _isAttentive = !lookAway;
    _currentYaw = lookAway ? 35.0 : 0.0;
  }
}
