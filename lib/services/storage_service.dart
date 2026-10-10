import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/question.dart';
import '../models/test_attempt.dart';
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
    
    // 1. Bu teste ait soruları filtrele
    final testQuestions = IqQuestionBank.allQuestions
        .where((q) => q.testId == testId || q.testId == 'test_standard_iq')
        .toList();

    // 2. Henüz görülmemiş olanları ayıkla
    final unseen = testQuestions.where((q) => !seenIds.contains(q.id)).toList();
    unseen.shuffle();

    if (unseen.length >= requestedCount) {
      return unseen.take(requestedCount).toList();
    }

    // Eğer soru havuzundaki tüm sorular bittiyse veya yeterli soru kalmadıysa,
    // en az görülenleri karıştırarak tamamla
    final pool = List<Question>.from(testQuestions)..shuffle();
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
