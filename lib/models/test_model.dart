import 'package:flutter/material.dart';

class TestModel {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final int totalQuestionsPerSession; // Sınavda sorulacak soru sayısı (örn: 20 veya 100)
  final int durationMinutes;
  final int maxFailureAttempts; // Genelde 3
  final Color themeColor;
  final IconData icon;
  final String difficultyLabel;

  const TestModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    this.totalQuestionsPerSession = 20,
    this.durationMinutes = 25,
    this.maxFailureAttempts = 3,
    required this.themeColor,
    required this.icon,
    required this.difficultyLabel,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'description': description,
    'totalQuestionsPerSession': totalQuestionsPerSession,
    'durationMinutes': durationMinutes,
    'maxFailureAttempts': maxFailureAttempts,
    'difficultyLabel': difficultyLabel,
  };
}
