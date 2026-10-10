import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

void main() {
  const int size = 1024;
  final image = img.Image(width: size, height: size);

  // Arka planı şeffaf yap
  img.fill(image, color: img.ColorRgba8(0, 0, 0, 0));

  final center = size / 2.0;
  final radius = size * 0.45;

  // 1. Oval / Squircle Kart Çizimi (Radial Gradient Arka Plan)
  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      final dx = x - center;
      final dy = y - center;

      // Squircle mesafesi (Superellipse formülü: (x/a)^4 + (y/b)^4 <= 1)
      final nx = dx.abs() / (size * 0.44);
      final ny = dy.abs() / (size * 0.44);
      final dist4 = pow(nx, 4) + pow(ny, 4);

      if (dist4 <= 1.0) {
        final dist = sqrt(dx * dx + dy * dy) / radius;

        // Gradient: Merkezden dışa doğru (Deep Indigo -> Dark Navy -> Dark Slate)
        final r = (30 * (1 - dist) + 15 * dist).clamp(10, 60).toInt();
        final g = (27 * (1 - dist) + 23 * dist).clamp(10, 50).toInt();
        final b = (75 * (1 - dist) + 42 * dist).clamp(30, 110).toInt();

        // Kenar yumuşatma (Antialiasing)
        final alpha = dist4 > 0.95 ? ((1.0 - dist4) / 0.05 * 255).clamp(0, 255).toInt() : 255;

        image.setPixelRgba(x, y, r, g, b, alpha);
      }
    }
  }

  // 2. Altın & Mor Neon Çerçeve (Glow Ring)
  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      final dx = x - center;
      final dy = y - center;
      final nx = dx.abs() / (size * 0.43);
      final ny = dy.abs() / (size * 0.43);
      final dist4 = pow(nx, 4) + pow(ny, 4);

      if (dist4 >= 0.88 && dist4 <= 0.98) {
        // Altın ve Mor gradient çerçeve
        final angle = (atan2(dy, dx) + pi) / (2 * pi);
        final cr = (245 * angle + 99 * (1 - angle)).toInt().clamp(0, 255);
        final cg = (158 * angle + 102 * (1 - angle)).toInt().clamp(0, 255);
        final cb = (11 * angle + 241 * (1 - angle)).toInt().clamp(0, 255);

        image.setPixelRgba(x, y, cr, cg, cb, 220);
      }
    }
  }

  // 3. Merkez Göz / İris (Proctor) ve Beyin (IQ) Şekli Çizimi
  final highlightColor = img.ColorRgba8(255, 255, 255, 240);

  // Göz Eğrisi
  for (int x = (center - 240).toInt(); x <= (center + 240).toInt(); x++) {
    final relX = (x - center) / 240.0;
    if (relX.abs() <= 1.0) {
      final height = 150.0 * (1.0 - relX * relX);
      for (int t = -8; t <= 8; t++) {
        final topY = (center - height + t).toInt();
        final botY = (center + height + t).toInt();
        if (topY >= 0 && topY < size) image.setPixelRgba(x, topY, 99, 102, 241, 240);
        if (botY >= 0 && botY < size) image.setPixelRgba(x, botY, 99, 102, 241, 240);
      }
    }
  }

  // Merkez İris Dairesi
  final irisRadius = 110.0;
  for (int y = (center - irisRadius).toInt(); y <= (center + irisRadius).toInt(); y++) {
    for (int x = (center - irisRadius).toInt(); x <= (center + irisRadius).toInt(); x++) {
      final dx = x - center;
      final dy = y - center;
      final d = sqrt(dx * dx + dy * dy);

      if (d <= irisRadius) {
        // İris Gradient (Altın / Cyan / Indigo)
        final factor = d / irisRadius;
        if (d > 55) {
          final r = (245 * (1 - factor) + 99 * factor).toInt();
          final g = (158 * (1 - factor) + 102 * factor).toInt();
          final b = (11 * (1 - factor) + 241 * factor).toInt();
          image.setPixelRgba(x, y, r, g, b, 255);
        } else {
          // Göz Bebeği (Pupil)
          image.setPixelRgba(x, y, 15, 23, 42, 255);
        }
      }
    }
  }

  // Parlama ve Işıltı Noktası (Glossy Specular Highlight)
  img.fillCircle(
    image,
    x: (center - 32).toInt(),
    y: (center - 32).toInt(),
    radius: 18,
    color: highlightColor,
  );

  // Küçük İkincil Parlama
  img.fillCircle(
    image,
    x: (center + 24).toInt(),
    y: (center + 24).toInt(),
    radius: 8,
    color: img.ColorRgba8(255, 255, 255, 180),
  );

  // Üst Kısma Küçük Taç / Mensa Rozet Çizgisi
  img.drawLine(
    image,
    x1: (center - 60).toInt(),
    y1: (center - 220).toInt(),
    x2: center.toInt(),
    y2: (center - 260).toInt(),
    color: img.ColorRgba8(245, 158, 11, 255),
    thickness: 6,
  );
  img.drawLine(
    image,
    x1: center.toInt(),
    y1: (center - 260).toInt(),
    x2: (center + 60).toInt(),
    y2: (center - 220).toInt(),
    color: img.ColorRgba8(245, 158, 11, 255),
    thickness: 6,
  );

  // Dizini oluştur ve kaydet
  final dir = Directory('assets/icon');
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }

  final pngBytes = img.encodePng(image);
  File('assets/icon/app_icon.png').writeAsBytesSync(pngBytes);
  print('✓ App icon generated successfully at assets/icon/app_icon.png (1024x1024)');
}
