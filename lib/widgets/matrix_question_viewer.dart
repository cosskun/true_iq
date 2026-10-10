import 'package:flutter/material.dart';
import '../models/question.dart';

class MatrixQuestionViewer extends StatelessWidget {
  final Question question;

  const MatrixQuestionViewer({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.5)),
                ),
                child: const Text(
                  'Görsel Mantık / Raven Matrisi',
                  style: TextStyle(
                    color: Color(0xFF818CF8),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.grid_view_rounded, color: Color(0xFF94A3B8), size: 20),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            question.prompt,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          if (question.subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              question.subtitle!,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Görsel Matris Çizim Alanı
          Center(
            child: Container(
              width: 180,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF475569)),
              ),
              child: CustomPaint(
                painter: _MatrixGridPainter(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatrixGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF6366F1)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // 1. Hücre: Daire
    final cellW = size.width / 3;
    final cellH = size.height / 2;

    canvas.drawCircle(Offset(cellW * 0.5, cellH * 0.5), 14, paint);

    // 2. Hücre: Kare
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cellW * 1.5, cellH * 0.5), width: 24, height: 24),
      paint,
    );

    // 3. Hücre: Üçgen
    final path = Path();
    path.moveTo(cellW * 2.5, cellH * 0.5 - 14);
    path.lineTo(cellW * 2.5 - 14, cellH * 0.5 + 14);
    path.lineTo(cellW * 2.5 + 14, cellH * 0.5 + 14);
    path.close();
    canvas.drawPath(path, paint);

    // Alt Satır: Soru işareti hücresi
    final textPainter = TextPainter(
      text: const TextSpan(
        text: '?',
        style: TextStyle(
          color: Color(0xFFEC4899),
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(cellW * 1.5 - textPainter.width / 2, cellH * 1.5 - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
