enum QuestionCategory {
  patternReasoning, // Matris ve Görsel Örüntü (Raven Matrices)
  numberSequences,  // Sayı Dizileri ve Matematiksel Mantık
  spatialAwareness, // Uzamsal Zeka ve Şekil Döndürme
  logicalDeduction, // Mantıksal Çıkarım ve Kıyas
  verbalAnalogies,  // Sözel Analojiler ve Kavramsal Mantık
  workingMemory,    // Bilişsel Hız ve Bellek
}

enum QuestionType {
  multipleChoiceText,
  visualMatrix,
  sequencePuzzle,
}

class Question {
  final String id;
  final String testId;
  final QuestionCategory category;
  final QuestionType type;
  final String prompt;
  final String? subtitle;
  final List<String> options;
  final int correctOptionIndex;
  final String explanation;
  final int difficultyLevel; // 1 (Kolay) - 5 (Mensa Seviyesi)
  final Map<String, dynamic>? visualData; // Özel şekil veya matris çizim verileri

  const Question({
    required this.id,
    required this.testId,
    required this.category,
    required this.type,
    required this.prompt,
    this.subtitle,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
    this.difficultyLevel = 3,
    this.visualData,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'testId': testId,
    'category': category.name,
    'type': type.name,
    'prompt': prompt,
    'subtitle': subtitle,
    'options': options,
    'correctOptionIndex': correctOptionIndex,
    'explanation': explanation,
    'difficultyLevel': difficultyLevel,
    'visualData': visualData,
  };

  factory Question.fromJson(Map<String, dynamic> json) => Question(
    id: json['id'] as String,
    testId: json['testId'] as String,
    category: QuestionCategory.values.firstWhere(
      (e) => e.name == json['category'],
      orElse: () => QuestionCategory.logicalDeduction,
    ),
    type: QuestionType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => QuestionType.multipleChoiceText,
    ),
    prompt: json['prompt'] as String,
    subtitle: json['subtitle'] as String?,
    options: List<String>.from(json['options'] as List),
    correctOptionIndex: json['correctOptionIndex'] as int,
    explanation: json['explanation'] as String,
    difficultyLevel: json['difficultyLevel'] as int? ?? 3,
    visualData: json['visualData'] as Map<String, dynamic>?,
  );
}
