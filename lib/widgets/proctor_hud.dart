import 'package:flutter/material.dart';
import '../services/proctor_service.dart';

class ProctorHud extends StatelessWidget {
  final GazeState? gazeState;
  final VoidCallback? onSimulateLookAway;
  final VoidCallback? onSimulateLookBack;
  final bool showSimulatorControls;

  const ProctorHud({
    super.key,
    required this.gazeState,
    this.onSimulateLookAway,
    this.onSimulateLookBack,
    this.showSimulatorControls = true,
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
                ? Colors.redAccent.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            spreadRadius: isWarning ? 2 : 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Küçük Ön Kamera Önizleme Çerçevesi
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  shape: BoxShape.circle,
                  border: Border.all(color: badgeColor, width: 2),
                ),
                child: Center(
                  child: Icon(
                    state.isFaceDetected
                        ? (state.isAttentive ? Icons.visibility : Icons.visibility_off)
                        : Icons.no_photography,
                    color: badgeColor,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                        Text(
                          state.statusMessage,
                          style: TextStyle(
                            color: isWarning ? Colors.redAccent : Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
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
                        minHeight: 5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Simülasyon test butonları (Tarayıcı ve Geliştirici ortamı için)
          if (showSimulatorControls) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'Göz Takibi Simülatörü:',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: onSimulateLookAway,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                    ),
                    child: const Text(
                      'Gözü Ayır (İhlal Et)',
                      style: TextStyle(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: onSimulateLookBack,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                    ),
                    child: const Text(
                      'Ekrana Bak',
                      style: TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
