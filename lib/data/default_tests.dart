import 'package:flutter/material.dart';
import '../models/test_model.dart';

class DefaultTests {
  static const List<TestModel> testList = [
    TestModel(
      id: 'test_standard_iq',
      title: 'TrueIQ Alpha Matrix',
      subtitle: 'Genel Bilişsel IQ Testi',
      description: 'Raven matrisleri, sayı dizileri ve analitik düşünme becerilerinizi ölçen kapsamlı standart test.',
      totalQuestionsPerSession: 25,
      durationMinutes: 30,
      maxFailureAttempts: 3,
      themeColor: Color(0xFF6366F1), // Indigo
      icon: Icons.psychology_rounded,
      difficultyLabel: 'Kapsamlı Standart (25 Soru)',
    ),
    TestModel(
      id: 'test_mensa_challenge',
      title: 'Mensa Titan Challenge',
      subtitle: 'Mensa Seviye Yüksek IQ',
      description: 'Üst %2 dilim için tasarlanmış soyut muhakeme, çok katmanlı dönüşümler ve Mensa seviyesi problem çözme.',
      totalQuestionsPerSession: 20,
      durationMinutes: 25,
      maxFailureAttempts: 3,
      themeColor: Color(0xFFEC4899), // Rose/Pink
      icon: Icons.auto_awesome_rounded,
      difficultyLabel: 'Mensa Seviyesi (130+ IQ - 20 Soru)',
    ),
    TestModel(
      id: 'test_speed_iq',
      title: 'Cortex HyperSpeed',
      subtitle: 'Bilişsel Hız & Çalışma Belleği',
      description: 'Zaman baskısı altında dikkati koruma, anlık örüntü yakalama ve yüksek hızlı karar refleksi.',
      totalQuestionsPerSession: 20,
      durationMinutes: 15,
      maxFailureAttempts: 3,
      themeColor: Color(0xFF10B981), // Emerald
      icon: Icons.bolt_rounded,
      difficultyLabel: 'Yüksek Hız & Refleks (20 Soru)',
    ),
    TestModel(
      id: 'test_spatial_3d',
      title: 'Nexus 3D Vision',
      subtitle: 'Uzamsal Zeka & 3D Geometri',
      description: 'Üç boyutlu zihinsel rotasyon, izometrik perspektif, zihinsel katlama ve uzamsal derinlik analizi.',
      totalQuestionsPerSession: 20,
      durationMinutes: 25,
      maxFailureAttempts: 3,
      themeColor: Color(0xFF8B5CF6), // Purple
      icon: Icons.view_in_ar_rounded,
      difficultyLabel: 'İleri Düzey Uzamsal (20 Soru)',
    ),
    TestModel(
      id: 'test_quantum_logic',
      title: 'Quantum Deduction',
      subtitle: 'Algoritmik Mantık & Kıyas Çıkarımı',
      description: 'Önermeler mantığı, boolean ilişkiler, karmaşık kıyas (syllogism) ve sebep-sonuç zincirleri testi.',
      totalQuestionsPerSession: 20,
      durationMinutes: 25,
      maxFailureAttempts: 3,
      themeColor: Color(0xFFF59E0B), // Amber
      icon: Icons.account_tree_rounded,
      difficultyLabel: 'Yüksek Mantıksal Yetenek (20 Soru)',
    ),
    TestModel(
      id: 'test_verbal_spectrum',
      title: 'Verbal Spectrum',
      subtitle: 'Kavramsal Analoji & Sözel Zeka',
      description: 'Dilsel semantik, kavramsal zıtlıklar, metaforik bağıntılar ve çok katmanlı sözel kavrayış ölçeği.',
      totalQuestionsPerSession: 20,
      durationMinutes: 20,
      maxFailureAttempts: 3,
      themeColor: Color(0xFF06B6D4), // Cyan
      icon: Icons.menu_book_rounded,
      difficultyLabel: 'Sözel & Kavramsal Deha (20 Soru)',
    ),
  ];
}
