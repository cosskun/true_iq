import 'package:flutter/material.dart';
import '../models/test_model.dart';

class DefaultTests {
  static const List<TestModel> testList = [
    TestModel(
      id: 'test_standard_iq',
      title: 'Genel Bilişsel IQ Testi',
      subtitle: 'Standart Raven & Mantıksal Yetenek Ölçeği',
      description: 'Sayı dizileri, örüntü tamamlama, sözel mantık ve analojik düşünme becerilerinizi ölçen kapsamlı standart test.',
      totalQuestionsPerSession: 15,
      durationMinutes: 20,
      maxFailureAttempts: 3,
      themeColor: Color(0xFF6366F1), // Indigo
      icon: Icons.psychology,
      difficultyLabel: 'Orta - İleri Düzey',
    ),
    TestModel(
      id: 'test_mensa_challenge',
      title: 'Mensa Seviye Yüksek IQ',
      subtitle: 'Üst %2 Dilim İçin İleri Mantık & 3D Matris',
      description: 'Soyut muhakeme, çok katmanlı dönüşümler ve yüksek düzeyli problem çözme testidir. Hata affetmez.',
      totalQuestionsPerSession: 10,
      durationMinutes: 15,
      maxFailureAttempts: 3,
      themeColor: Color(0xFFEC4899), // Rose/Pink
      icon: Icons.auto_awesome,
      difficultyLabel: 'Mensa Seviyesi (130+ IQ)',
    ),
    TestModel(
      id: 'test_speed_iq',
      title: 'Bilişsel Hız & Çalışma Belleği',
      subtitle: 'Zamana Karşı Hızlı Karar ve Dikkat',
      description: 'Zaman baskısı altında dikkatinizi koruma, hızlı mantık ve analitik karar verme reflekslerinizi ölçer.',
      totalQuestionsPerSession: 10,
      durationMinutes: 10,
      maxFailureAttempts: 3,
      themeColor: Color(0xFF10B981), // Emerald Green
      icon: Icons.bolt,
      difficultyLabel: 'Hız ve Refleks',
    ),
  ];
}
