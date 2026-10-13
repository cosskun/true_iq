class LeaderboardEntry {
  final String testId;
  final String username;
  final String fullName;
  final int iqScore;
  final int correctAnswers;
  final int totalQuestions;
  final int timeTakenSeconds;
  final DateTime completedAt;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.testId,
    required this.username,
    required this.fullName,
    required this.iqScore,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.timeTakenSeconds,
    required this.completedAt,
    this.isCurrentUser = false,
  });

  LeaderboardEntry copyWith({
    String? testId,
    String? username,
    String? fullName,
    int? iqScore,
    int? correctAnswers,
    int? totalQuestions,
    int? timeTakenSeconds,
    DateTime? completedAt,
    bool? isCurrentUser,
  }) {
    return LeaderboardEntry(
      testId: testId ?? this.testId,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      iqScore: iqScore ?? this.iqScore,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      timeTakenSeconds: timeTakenSeconds ?? this.timeTakenSeconds,
      completedAt: completedAt ?? this.completedAt,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
    );
  }

  Map<String, dynamic> toJson() => {
    'testId': testId,
    'username': username,
    'fullName': fullName,
    'iqScore': iqScore,
    'correctAnswers': correctAnswers,
    'totalQuestions': totalQuestions,
    'timeTakenSeconds': timeTakenSeconds,
    'completedAt': completedAt.toIso8601String(),
  };

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json, {bool isCurrentUser = false}) => LeaderboardEntry(
    testId: json['testId'] as String? ?? '',
    username: json['username'] as String? ?? 'anonim',
    fullName: json['fullName'] as String? ?? json['username'] as String? ?? 'Anonim',
    iqScore: (json['iqScore'] as num?)?.toInt() ?? 100,
    correctAnswers: (json['correctAnswers'] as num?)?.toInt() ?? 0,
    totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 20,
    timeTakenSeconds: (json['timeTakenSeconds'] as num?)?.toInt() ?? 0,
    completedAt: DateTime.tryParse(json['completedAt'] as String? ?? '') ?? DateTime.now(),
    isCurrentUser: isCurrentUser,
  );
}
