enum AttemptStatus {
  inProgress,
  completedSuccess,
  failedGazeLost,      // Göz ekrandan uzun süre ayrıldı
  failedAppBackground, // Uygulamadan çıkıldı / arkaya atıldı
  failedTimeExpired,   // Süre bitti
  failedManualQuit,    // Kullanıcı vazgeçti
}

class TestAttempt {
  final String id;
  final String testId;
  final int attemptNumber; // 1, 2, 3
  final DateTime startedAt;
  DateTime? finishedAt;
  AttemptStatus status;
  int correctAnswers;
  int totalAnswered;
  int totalQuestions;
  int calculatedIq;
  int pauseCountUsed; // Kullanılan duraklatma sayısı (Max 3)
  final int maxPauseAllowed;
  double percentile; // Örn: %98.4 (Top %1.6)
  String cognitiveProfile; // Örn: 'Analitik Stratejist'
  Map<String, double> categoryBreakdown; // Kategori doğruluk oranları
  String? failReasonDetail;
  final List<String> answeredQuestionIds;

  TestAttempt({
    required this.id,
    required this.testId,
    required this.attemptNumber,
    required this.startedAt,
    this.finishedAt,
    this.status = AttemptStatus.inProgress,
    this.correctAnswers = 0,
    this.totalAnswered = 0,
    required this.totalQuestions,
    this.calculatedIq = 0,
    this.pauseCountUsed = 0,
    this.maxPauseAllowed = 3,
    this.percentile = 50.0,
    this.cognitiveProfile = 'Analitik Düşünür',
    Map<String, double>? categoryBreakdown,
    this.failReasonDetail,
    List<String>? answeredQuestionIds,
  })  : categoryBreakdown = categoryBreakdown ?? {},
        answeredQuestionIds = answeredQuestionIds ?? [];

  bool get isFailed =>
      status == AttemptStatus.failedGazeLost ||
      status == AttemptStatus.failedAppBackground ||
      status == AttemptStatus.failedTimeExpired ||
      status == AttemptStatus.failedManualQuit;

  bool get isSuccess => status == AttemptStatus.completedSuccess;

  String get statusMessage {
    switch (status) {
      case AttemptStatus.completedSuccess:
        return 'Test Başarıyla Tamamlandı';
      case AttemptStatus.failedGazeLost:
        return 'Başarısız: Gözleriniz ekrandan ayrıldığı için test sonlandırıldı!';
      case AttemptStatus.failedAppBackground:
        return 'Başarısız: Uygulamadan çıkmaya veya arka plana almaya çalıştınız!';
      case AttemptStatus.failedTimeExpired:
        return 'Başarısız: Sınav süresi doldu!';
      case AttemptStatus.failedManualQuit:
        return 'Başarısız: Test iptal edildi.';
      case AttemptStatus.inProgress:
        return 'Test Devam Ediyor...';
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'testId': testId,
    'attemptNumber': attemptNumber,
    'startedAt': startedAt.toIso8601String(),
    'finishedAt': finishedAt?.toIso8601String(),
    'status': status.name,
    'correctAnswers': correctAnswers,
    'totalAnswered': totalAnswered,
    'totalQuestions': totalQuestions,
    'calculatedIq': calculatedIq,
    'pauseCountUsed': pauseCountUsed,
    'maxPauseAllowed': maxPauseAllowed,
    'percentile': percentile,
    'cognitiveProfile': cognitiveProfile,
    'categoryBreakdown': categoryBreakdown,
    'failReasonDetail': failReasonDetail,
    'answeredQuestionIds': answeredQuestionIds,
  };

  factory TestAttempt.fromJson(Map<String, dynamic> json) => TestAttempt(
    id: json['id'] as String,
    testId: json['testId'] as String,
    attemptNumber: json['attemptNumber'] as int,
    startedAt: DateTime.parse(json['startedAt'] as String),
    finishedAt: json['finishedAt'] != null
        ? DateTime.parse(json['finishedAt'] as String)
        : null,
    status: AttemptStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => AttemptStatus.inProgress,
    ),
    correctAnswers: json['correctAnswers'] as int? ?? 0,
    totalAnswered: json['totalAnswered'] as int? ?? 0,
    totalQuestions: json['totalQuestions'] as int? ?? 20,
    calculatedIq: json['calculatedIq'] as int? ?? 0,
    pauseCountUsed: json['pauseCountUsed'] as int? ?? 0,
    maxPauseAllowed: json['maxPauseAllowed'] as int? ?? 3,
    percentile: (json['percentile'] as num?)?.toDouble() ?? 50.0,
    cognitiveProfile: json['cognitiveProfile'] as String? ?? 'Analitik Düşünür',
    categoryBreakdown: (json['categoryBreakdown'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ) ??
        {},
    failReasonDetail: json['failReasonDetail'] as String?,
    answeredQuestionIds: List<String>.from(json['answeredQuestionIds'] ?? []),
  );
}
