import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/proctor_service.dart';

class ProctorHud extends StatelessWidget {
  final GazeState? gazeState;
  final CameraController? cameraController;
  final bool isCameraActive;

  const ProctorHud({
    super.key,
    required this.gazeState,
    this.cameraController,
    this.isCameraActive = true,
  });

  @override
  Widget build(BuildContext context) {
    final state = gazeState ??
        const GazeState(
          isFaceDetected: true,
          isAttentive: true,
          yawAngle: 0.0,
          pitchAngle: 0.0,
          gazeLostSeconds: 0.0,
          statusMessage: 'Kamera Aktif • İzleniyor',
        );

    final bool isWarning = !state.isAttentive || !state.isFaceDetected;
    final Color badgeColor = isWarning ? Colors.redAccent : const Color(0xFF10B981);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isWarning ? Colors.redAccent : const Color(0xFF334155),
          width: isWarning ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isWarning
                ? Colors.redAccent.withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.2),
            blurRadius: isWarning ? 14 : 8,
            spreadRadius: isWarning ? 2 : 0,
          ),
        ],
      ),
      child: Row(
        children: [
          // CANLI ÖN KAMERA AKIŞI (Oval Çerçeve)
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              shape: BoxShape.circle,
              border: Border.all(
                color: badgeColor,
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: badgeColor.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipOval(
              child: _buildCameraPreview(badgeColor),
            ),
          ),
          const SizedBox(width: 14),

          // Durum Mesajı ve Dikkat Seviyesi İlerleme Çubuğu
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: badgeColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        state.statusMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isWarning ? Colors.redAccent : Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: state.attentionPercent,
                    backgroundColor: const Color(0xFF334155),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      state.attentionPercent > 0.5
                          ? const Color(0xFF10B981)
                          : Colors.redAccent,
                    ),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isWarning ? '⚠️ Göz/Kafa Ekran Dışında' : '🛡️ Otomatik Yapay Zeka Göz Takibi',
                      style: TextStyle(
                        fontSize: 10,
                        color: isWarning ? Colors.redAccent : const Color(0xFF94A3B8),
                        fontWeight: isWarning ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    Text(
                      '${(state.attentionPercent * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 10,
                        color: badgeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview(Color badgeColor) {
    if (cameraController != null && cameraController!.value.isInitialized) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: cameraController!.value.previewSize?.height ?? 100,
          height: cameraController!.value.previewSize?.width ?? 100,
          child: CameraPreview(cameraController!),
        ),
      );
    }

    return Center(
      child: Icon(
        Icons.face_retouching_natural,
        color: badgeColor,
        size: 26,
      ),
    );
  }
}
