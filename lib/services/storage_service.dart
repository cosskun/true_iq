import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/question.dart';
import '../models/test_attempt.dart';
import '../models/leaderboard_entry.dart';
import '../data/iq_question_bank.dart';

class StorageService {
  static StorageService? _instance;
  static SharedPreferences? _prefs;

  StorageService._();

  static Future<StorageService> getInstance() async {
    if (_instance == null) {
      _instance = StorageService._();
      _prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  // ==========================================
  // HAK YÖNETİMİ & TEK BİTİRME KURALI
  // ==========================================

  /// Testin daha önce başarıyla tamamlanıp tamamlanmadığını kontrol eder.
  /// Bir test bir kere tamamlandığında bir daha asla çözülemez.
  bool isTestCompleted(String testId) {
    return _prefs?.getBool('completed_$testId') ?? false;
  }

  /// Tamamlanmış olan test girişimini getirir (Sonuç/Sertifika görüntüleme için)
  TestAttempt? getCompletedAttempt(String testId) {
    final attempts = getAllAttempts();
    try {
      return attempts.firstWhere(
        (a) => a.testId == testId && a.isSuccess,
      );
    } catch (_) {
      return null;
    }
  }

  /// Belirli bir testte kullanıcının kaç kez başarısız olduğunu döner.
  int getFailedAttemptsCount(String testId) {
    return _prefs?.getInt('fail_count_$testId') ?? 0;
  }

  /// Kalan deneme hakkını hesaplar (Varsayılan: 3 - Başarısızlık sayısı).
  int getRemainingAttempts(String testId, {int maxAttempts = 3}) {
    if (isTestCompleted(testId)) return 0; // Tamamlandıysa hak kalmadı (tekrar çözülemez)
    final failedCount = getFailedAttemptsCount(testId);
    final remaining = maxAttempts - failedCount;
    return remaining > 0 ? remaining : 0;
  }

  /// Testin kilitli veya tamamlanmış olup olmadığını kontrol eder (Çözülemez).
  bool isTestLocked(String testId, {int maxAttempts = 3}) {
    if (isTestCompleted(testId)) return true;
    return getRemainingAttempts(testId, maxAttempts: maxAttempts) <= 0;
  }

  /// Kullanıcının bu testi çözüp çözemeyeceğini döner.
  bool canStartTest(String testId, {int maxAttempts = 3}) {
    if (isTestCompleted(testId)) return false;
    return getRemainingAttempts(testId, maxAttempts: maxAttempts) > 0;
  }

  /// Başarısızlık sayısını 1 artırır ve kaydeder.
  Future<int> incrementFailedAttempt(String testId) async {
    final current = getFailedAttemptsCount(testId);
    final next = current + 1;
    await _prefs?.setInt('fail_count_$testId', next);
    return next;
  }

  /// Testi kalıcı olarak "Tamamlandı" olarak işaretler.
  Future<void> markTestAsCompleted(String testId) async {
    await _prefs?.setBool('completed_$testId', true);
  }

  // ==========================================
  // DİNAMİK SORU HAVUZU & GÖRÜLEN SORU TAKİBİ
  // ==========================================

  /// Kullanıcının bu testte daha önce gördüğü soru ID'lerinin listesini getirir.
  List<String> getSeenQuestionIds(String testId) {
    return _prefs?.getStringList('seen_questions_$testId') ?? [];
  }

  /// Yeni sorular görüldüğünde hafızaya ekler (Tekrar sorulmaması için).
  Future<void> markQuestionsAsSeen(String testId, List<String> questionIds) async {
    final current = getSeenQuestionIds(testId).toSet();
    current.addAll(questionIds);
    await _prefs?.setStringList('seen_questions_$testId', current.toList());
  }

  /// Kullanıcıya daha önce HİÇ GÖRMEDİĞİ sorulardan oluşan dinamik bir sınav seti hazırlar.
  List<Question> getQuestionsForNewAttempt({
    required String testId,
    required int requestedCount,
  }) {
    final seenIds = getSeenQuestionIds(testId).toSet();
    
    // 1. Bu teste ait soruları öncelikli olarak filtrele
    final directQuestions = IqQuestionBank.allQuestions.where((q) => q.testId == testId).toList();
    final generalQuestions = IqQuestionBank.allQuestions.where((q) => q.testId != testId).toList();
    
    final candidatePool = [
      ...directQuestions,
      if (directQuestions.length < requestedCount * 2) ...generalQuestions,
    ];

    // 2. Henüz görülmemiş olanları ayıkla
    final unseen = candidatePool.where((q) => !seenIds.contains(q.id)).toList();
    unseen.shuffle();

    if (unseen.length >= requestedCount) {
      return unseen.take(requestedCount).toList();
    }

    // Eğer soru havuzundaki tüm sorular bittiyse veya yeterli soru kalmadıysa,
    // en az görülenleri karıştırarak tamamla
    final pool = List<Question>.from(candidatePool)..shuffle();
    return pool.take(requestedCount).toList();
  }

  // ==========================================
  // GEÇMİŞ DENEMELER VE KAYITLAR (ATTEMPTS)
  // ==========================================

  Future<void> saveAttempt(TestAttempt attempt) async {
    final listJson = _prefs?.getStringList('user_attempts') ?? [];
    listJson.add(jsonEncode(attempt.toJson()));
    await _prefs?.setStringList('user_attempts', listJson);

    // Eğer başarılı olduysa testi kalıcı olarak tamamlandı olarak işaretle (bir daha çözülemez)
    if (attempt.isSuccess) {
      await markTestAsCompleted(attempt.testId);
    }

    // Eğer başarısız olduysa sayacı artır
    if (attempt.isFailed) {
      await incrementFailedAttempt(attempt.testId);
    }
  }

  List<TestAttempt> getAllAttempts() {
    final listJson = _prefs?.getStringList('user_attempts') ?? [];
    return listJson.map((str) {
      try {
        return TestAttempt.fromJson(jsonDecode(str));
      } catch (e) {
        return null;
      }
    }).whereType<TestAttempt>().toList().reversed.toList();
  }

  /// Test ID'sine göre en yüksek başarılı IQ skorunu getirir.
  int getBestIqScore(String testId) {
    final attempts = getAllAttempts()
        .where((a) => a.testId == testId && a.isSuccess)
        .toList();
    if (attempts.isEmpty) return 0;
    attempts.sort((a, b) => b.calculatedIq.compareTo(a.calculatedIq));
    return attempts.first.calculatedIq;
  }

  // ==========================================
  // LİDERLİK TABLOSU & SIRALAMA (LEADERBOARD)
  // ==========================================

  List<LeaderboardEntry> _getDefaultLeaderboard(String testId) {
    switch (testId) {
      case 'test_mensa_challenge':
        return [
          LeaderboardEntry(
            testId: testId,
            username: 'mensa_tarik',
            fullName: 'Prof. Dr. Tarık Öz',
            iqScore: 146,
            correctAnswers: 10,
            totalQuestions: 10,
            timeTakenSeconds: 380,
            completedAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
          LeaderboardEntry(
            testId: testId,
            username: 'hyper_ece',
            fullName: 'Ece Çetin',
            iqScore: 142,
            correctAnswers: 10,
            totalQuestions: 10,
            timeTakenSeconds: 450,
            completedAt: DateTime.now().subtract(const Duration(days: 3)),
          ),
          LeaderboardEntry(
            testId: testId,
            username: 'burak_titan',
            fullName: 'Burak Aksoy',
            iqScore: 138,
            correctAnswers: 9,
            totalQuestions: 10,
            timeTakenSeconds: 410,
            completedAt: DateTime.now().subtract(const Duration(days: 5)),
          ),
          LeaderboardEntry(
            testId: testId,
            username: 'quantum_ayse',
            fullName: 'Ayşe Doğan',
            iqScore: 135,
            correctAnswers: 9,
            totalQuestions: 10,
            timeTakenSeconds: 490,
            completedAt: DateTime.now().subtract(const Duration(days: 7)),
          ),
          LeaderboardEntry(
            testId: testId,
            username: 'arda_simsek',
            fullName: 'Arda Şimşek',
            iqScore: 131,
            correctAnswers: 8,
            totalQuestions: 10,
            timeTakenSeconds: 520,
            completedAt: DateTime.now().subtract(const Duration(days: 10)),
          ),
        ];

      case 'test_speed_iq':
        return [
          LeaderboardEntry(
            testId: testId,
            username: 'speedy_mert',
            fullName: 'Mert Yıldız',
            iqScore: 138,
            correctAnswers: 10,
            totalQuestions: 10,
            timeTakenSeconds: 190,
            completedAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
          LeaderboardEntry(
            testId: testId,
            username: 'flash_bora',
            fullName: 'Bora Keskin',
            iqScore: 135,
            correctAnswers: 10,
            totalQuestions: 10,
            timeTakenSeconds: 215,
            completedAt: DateTime.now().subtract(const Duration(days: 4)),
          ),
          LeaderboardEntry(
            testId: testId,
            username: 'refleks_elif',
            fullName: 'Elif Aslan',
            iqScore: 130,
            correctAnswers: 9,
            totalQuestions: 10,
            timeTakenSeconds: 230,
            completedAt: DateTime.now().subtract(const Duration(days: 6)),
          ),
          LeaderboardEntry(
            testId: testId,
            username: 'can_hiz',
            fullName: 'Can Tezcan',
            iqScore: 126,
            correctAnswers: 9,
            totalQuestions: 10,
            timeTakenSeconds: 260,
            completedAt: DateTime.now().subtract(const Duration(days: 8)),
          ),
        ];

      case 'test_spatial_3d':
        return [
          LeaderboardEntry(
            testId: testId,
            username: 'mimar_selim',
            fullName: 'Selim Koç',
            iqScore: 141,
            correctAnswers: 10,
            totalQuestions: 10,
            timeTakenSeconds: 320,
            completedAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
          LeaderboardEntry(
            testId: testId,
            username: 'geometri_eda',
            fullName: 'Eda Polat',
            iqScore: 137,
            correctAnswers: 9,
            totalQuestions: 10,
            timeTakenSeconds: 350,
            completedAt: DateTime.now().subtract(const Duration(days: 3)),
          ),
          LeaderboardEntry(
            testId: testId,
            username: '3d_volkan',
            fullName: 'Volkan Çelik',
            iqScore: 132,
            correctAnswers: 9,
            totalQuestions: 10,
            timeTakenSeconds: 390,
            completedAt: DateTime.now().subtract(const Duration(days: 5)),
          ),
        ];

      case 'test_quantum_logic':
        return [
          LeaderboardEntry(
            testId: testId,
            username: 'algo_derya',
            fullName: 'Derya Sancar',
            iqScore: 143,
            correctAnswers: 10,
            totalQuestions: 10,
            timeTakenSeconds: 340,
            completedAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
          LeaderboardEntry(
            testId: testId,
            username: 'mantik_osman',
            fullName: 'Osman Yalçın',
            iqScore: 138,
            correctAnswers: 9,
            totalQuestions: 10,
            timeTakenSeconds: 370,
            completedAt: DateTime.now().subtract(const Duration(days: 4)),
          ),
          LeaderboardEntry(
            testId: testId,
            username: 'boolean_melis',
            fullName: 'Melis Akın',
            iqScore: 133,
            correctAnswers: 9,
            totalQuestions: 10,
            timeTakenSeconds: 405,
            completedAt: DateTime.now().subtract(const Duration(days: 7)),
          ),
        ];

      case 'test_verbal_spectrum':
        return [
          LeaderboardEntry(
            testId: testId,
            username: 'filolog_asli',
            fullName: 'Aslı Bozkurt',
            iqScore: 142,
            correctAnswers: 10,
            totalQuestions: 10,
            timeTakenSeconds: 290,
            completedAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
          LeaderboardEntry(
            testId: testId,
            username: 'semantik_kerem',
            fullName: 'Kerem Sezer',
            iqScore: 136,
            correctAnswers: 9,
            totalQuestions: 10,
            timeTakenSeconds: 315,
            completedAt: DateTime.now().subtract(const Duration(days: 3)),
          ),
          LeaderboardEntry(
            testId: testId,
            username: 'edebiyat_naz',
            fullName: 'Naz Yurt',
            iqScore: 131,
            correctAnswers: 9,
            totalQuestions: 10,
            timeTakenSeconds: 340,
            completedAt: DateTime.now().subtract(const Duration(days: 6)),
          ),
        ];

      case 'test_standard_iq':
      default:
        return [
          LeaderboardEntry(
            testId: testId,
            username: 'cortex_kaan',
            fullName: 'Kaan Demir',
            iqScore: 139,
            correctAnswers: 15,
            totalQuestions: 15,
            timeTakenSeconds: 420,
            completedAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
          LeaderboardEntry(
            testId: testId,
            username: 'selin_mensa',
            fullName: 'Selin Yılmaz',
            iqScore: 136,
            correctAnswers: 14,
            totalQuestions: 15,
            timeTakenSeconds: 490,
            completedAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
          LeaderboardEntry(
            testId: testId,
            username: 'alp_bilge',
            fullName: 'Alp Eren',
            iqScore: 132,
            correctAnswers: 14,
            totalQuestions: 15,
            timeTakenSeconds: 530,
            completedAt: DateTime.now().subtract(const Duration(days: 4)),
          ),
          LeaderboardEntry(
            testId: testId,
            username: 'neuro_deniz',
            fullName: 'Dr. Deniz Kaya',
            iqScore: 128,
            correctAnswers: 13,
            totalQuestions: 15,
            timeTakenSeconds: 460,
            completedAt: DateTime.now().subtract(const Duration(days: 5)),
          ),
          LeaderboardEntry(
            testId: testId,
            username: 'emre_analitik',
            fullName: 'Emre Vural',
            iqScore: 124,
            correctAnswers: 13,
            totalQuestions: 15,
            timeTakenSeconds: 580,
            completedAt: DateTime.now().subtract(const Duration(days: 8)),
          ),
        ];
    }
  }

  /// Belirli bir testin liderlik sıralamasını getirir.
  List<LeaderboardEntry> getLeaderboard(String testId, {String? currentUsername}) {
    final listJson = _prefs?.getStringList('leaderboard_$testId');
    List<LeaderboardEntry> list;
    if (listJson == null || listJson.isEmpty) {
      list = _getDefaultLeaderboard(testId);
    } else {
      list = listJson.map((str) {
        try {
          return LeaderboardEntry.fromJson(jsonDecode(str));
        } catch (_) {
          return null;
        }
      }).whereType<LeaderboardEntry>().toList();
      if (list.isEmpty) {
        list = _getDefaultLeaderboard(testId);
      }
    }

    // Sıralama kriteri: 1) IQ Skoru (Azalan), 2) Harcanan Süre (Artan / Daha hızlı bitiren önde)
    list.sort((a, b) {
      final scoreCmp = b.iqScore.compareTo(a.iqScore);
      if (scoreCmp != 0) return scoreCmp;
      return a.timeTakenSeconds.compareTo(b.timeTakenSeconds);
    });

    if (currentUsername != null && currentUsername.isNotEmpty) {
      list = list.map((entry) {
        final isMatch = entry.username.toLowerCase() == currentUsername.toLowerCase();
        return entry.copyWith(isCurrentUser: isMatch);
      }).toList();
    }

    return list;
  }

  /// Kullanıcının test derecesini sıralama tablosuna ekler veya rekorunu günceller.
  Future<void> addOrUpdateLeaderboardEntry(LeaderboardEntry entry) async {
    final list = getLeaderboard(entry.testId);
    final existingIndex = list.indexWhere(
      (e) => e.username.toLowerCase() == entry.username.toLowerCase(),
    );

    if (existingIndex >= 0) {
      final existing = list[existingIndex];
      // Eğer yeni skor daha yüksekse veya aynı skoru daha hızlı sürede yaptıysa güncelle
      if (entry.iqScore > existing.iqScore ||
          (entry.iqScore == existing.iqScore && entry.timeTakenSeconds < existing.timeTakenSeconds)) {
        list[existingIndex] = entry;
      }
    } else {
      list.add(entry);
    }

    // Yeniden sırala
    list.sort((a, b) {
      final scoreCmp = b.iqScore.compareTo(a.iqScore);
      if (scoreCmp != 0) return scoreCmp;
      return a.timeTakenSeconds.compareTo(b.timeTakenSeconds);
    });

    final jsonList = list.map((e) => jsonEncode(e.toJson())).toList();
    await _prefs?.setStringList('leaderboard_${entry.testId}', jsonList);
  }

  /// Kullanıcının bu testteki sıralamasını döner (1-tabanlı, bulunamazsa 0).
  int getUserRankInLeaderboard(String testId, String username) {
    if (username.isEmpty) return 0;
    final list = getLeaderboard(testId, currentUsername: username);
    final idx = list.indexWhere((e) => e.username.toLowerCase() == username.toLowerCase());
    return idx >= 0 ? (idx + 1) : 0;
  }

  // ==========================================
  // GELİŞTİRİCİ / TEST ARAÇLARI (SIFIRLAMA)
  // ==========================================
  Future<void> resetTestProgress(String testId) async {
    await _prefs?.remove('fail_count_$testId');
    await _prefs?.remove('seen_questions_$testId');
    await _prefs?.remove('completed_$testId');
  }

  Future<void> clearAllData() async {
    await _prefs?.clear();
  }
}
