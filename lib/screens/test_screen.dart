import 'dart:async';
import 'package:flutter/material.dart';
import '../models/test_model.dart';
import '../models/question.dart';
import '../models/test_attempt.dart';
import '../services/storage_service.dart';
import '../services/proctor_service.dart';
import '../widgets/proctor_hud.dart';
import '../widgets/matrix_question_viewer.dart';
import 'result_screen.dart';

class TestScreen extends StatefulWidget {
  final TestModel test;

  const TestScreen({super.key, required this.test});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  late StorageService _storageService;
  late ProctorService _proctorService;
  
  List<Question> _questions = [];
  int _currentQuestionIndex = 0;
  int? _selectedOptionIndex;
  int _correctAnswersCount = 0;
  bool _isLoading = true;
  bool _isFinished = false;
  bool _isPaused = false;
  int _pauseCountUsed = 0;
  final int _maxPauseAllowed = 3;

  // Kategori bazlı doğru/yanlış takibi
  final Map<QuestionCategory, int> _categoryTotal = {};
  final Map<QuestionCategory, int> _categoryCorrect = {};

  late int _remainingSeconds;
  Timer? _countdownTimer;
  GazeState? _currentGazeState;
  late TestAttempt _attempt;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.test.durationMinutes * 60;
    _initTestSession();
  }

  Future<void> _initTestSession() async {
    _storageService = await StorageService.getInstance();
    
    // Test kilitli mi kontrol et (Max 3 başarısızlık hakkı)
    if (_storageService.isTestLocked(widget.test.id, maxAttempts: widget.test.maxFailureAttempts)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bu test için maksimum başarısızlık sınırına (3/3) ulaştınız! Test kilitlendi.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        Navigator.pop(context);
      }
      return;
    }

    // Görülmemiş soruları soru havuzundan çek
    _questions = _storageService.getQuestionsForNewAttempt(
      testId: widget.test.id,
      requestedCount: widget.test.totalQuestionsPerSession,
    );

    // Kategori sayaçlarını sıfırla
    for (var q in _questions) {
      _categoryTotal[q.category] = (_categoryTotal[q.category] ?? 0) + 1;
      _categoryCorrect[q.category] = 0;
    }

    // Çekilen soruları "görüldü" olarak işaretle (Bir dahaki denemede tekrar çıkmaması için)
    final questionIds = _questions.map((q) => q.id).toList();
    await _storageService.markQuestionsAsSeen(widget.test.id, questionIds);

    // Girişim nesnesini başlat
    final attemptNumber = _storageService.getFailedAttemptsCount(widget.test.id) + 1;
    _attempt = TestAttempt(
      id: 'att_${DateTime.now().millisecondsSinceEpoch}',
      testId: widget.test.id,
      attemptNumber: attemptNumber,
      startedAt: DateTime.now(),
      totalQuestions: _questions.length,
      maxPauseAllowed: _maxPauseAllowed,
      answeredQuestionIds: questionIds,
    );

    // Göz ve Sınav Güvenliği Servisini Başlat
    _proctorService = ProctorService(
      maxToleranceSeconds: 2.5,
      onViolation: (type, reason) {
        if (!_isPaused) {
          _handleProctorViolation(type, reason);
        }
      },
      onGazeStateChanged: (state) {
        if (mounted && !_isPaused) {
          setState(() {
            _currentGazeState = state;
          });
        }
      },
    );

    _proctorService.startMonitoring();
    _startCountdown();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _isFinished || _isPaused) return;
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _finishTestWithTimeout();
      }
    });
  }

  // ==========================================
  // DURAKLATMA (PAUSE) MEKANİZMASI
  // ==========================================
  void _pauseTest() {
    if (_isPaused || _pauseCountUsed >= _maxPauseAllowed || _isFinished) return;

    setState(() {
      _isPaused = true;
      _pauseCountUsed++;
    });

    _proctorService.stopMonitoring();
    _countdownTimer?.cancel();
  }

  void _resumeTest() {
    if (!_isPaused || _isFinished) return;

    setState(() {
      _isPaused = false;
    });

    _proctorService.startMonitoring();
    _startCountdown();
  }

  void _handleProctorViolation(ProctorViolationType type, String reason) async {
    if (_isFinished || _isPaused) return;
    _isFinished = true;
    _proctorService.stopMonitoring();
    _countdownTimer?.cancel();

    AttemptStatus status = AttemptStatus.failedGazeLost;
    if (type == ProctorViolationType.appBackgrounded) {
      status = AttemptStatus.failedAppBackground;
    }

    _attempt.finishedAt = DateTime.now();
    _attempt.status = status;
    _attempt.failReasonDetail = reason;
    _attempt.totalAnswered = _currentQuestionIndex;
    _attempt.correctAnswers = _correctAnswersCount;
    _attempt.pauseCountUsed = _pauseCountUsed;

    await _storageService.saveAttempt(_attempt);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            test: widget.test,
            attempt: _attempt,
          ),
        ),
      );
    }
  }

  void _finishTestWithTimeout() async {
    if (_isFinished) return;
    _isFinished = true;
    _proctorService.stopMonitoring();
    _countdownTimer?.cancel();

    _attempt.finishedAt = DateTime.now();
    _attempt.status = AttemptStatus.failedTimeExpired;
    _attempt.failReasonDetail = 'Sınav süreniz doldu.';
    _attempt.totalAnswered = _currentQuestionIndex;
    _attempt.correctAnswers = _correctAnswersCount;
    _attempt.pauseCountUsed = _pauseCountUsed;

    await _storageService.saveAttempt(_attempt);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            test: widget.test,
            attempt: _attempt,
          ),
        ),
      );
    }
  }

  void _submitAnswerAndNext() async {
    if (_selectedOptionIndex == null || _isPaused) return;

    final currentQuestion = _questions[_currentQuestionIndex];
    if (_selectedOptionIndex == currentQuestion.correctOptionIndex) {
      _correctAnswersCount++;
      _categoryCorrect[currentQuestion.category] =
          (_categoryCorrect[currentQuestion.category] ?? 0) + 1;
    }

    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedOptionIndex = null;
      });
    } else {
      // Test Başarıyla Tamamlandı
      _finishTestWithSuccess();
    }
  }

  void _finishTestWithSuccess() async {
    if (_isFinished) return;
    _isFinished = true;
    _proctorService.stopMonitoring();
    _countdownTimer?.cancel();

    // Standart IQ Skoru ve Yüzdelik Dilim Hesaplama
    final double accuracy = _correctAnswersCount / _questions.length;
    final int calculatedIq = (85 + (accuracy * 57)).round();

    // Yüzdelik Dilim Hesabı (Bell Curve)
    double percentile = 50.0;
    if (calculatedIq >= 140) {
      percentile = 99.6;
    } else if (calculatedIq >= 130) {
      percentile = 97.7;
    } else if (calculatedIq >= 120) {
      percentile = 90.8;
    } else if (calculatedIq >= 110) {
      percentile = 74.8;
    } else {
      percentile = (accuracy * 70.0).clamp(20.0, 65.0);
    }

    // Bilişsel Profil Belirleme
    String profile = 'Analitik Düşünür';
    if (calculatedIq >= 135) {
      profile = 'Üstün Mantık & Soyut Muhakeme Uzmanı';
    } else if (calculatedIq >= 125) {
      profile = 'Stratejik Problem Çözücü';
    } else if (calculatedIq >= 115) {
      profile = 'Görsel & Matematiksel Analist';
    }

    // Kategori Başarı Oranları
    final Map<String, double> categoryBreakdown = {};
    _categoryTotal.forEach((cat, total) {
      final correct = _categoryCorrect[cat] ?? 0;
      categoryBreakdown[cat.name] = total > 0 ? (correct / total) : 0.0;
    });

    _attempt.finishedAt = DateTime.now();
    _attempt.status = AttemptStatus.completedSuccess;
    _attempt.totalAnswered = _questions.length;
    _attempt.correctAnswers = _correctAnswersCount;
    _attempt.calculatedIq = calculatedIq;
    _attempt.percentile = percentile;
    _attempt.cognitiveProfile = profile;
    _attempt.categoryBreakdown = categoryBreakdown;
    _attempt.pauseCountUsed = _pauseCountUsed;

    await _storageService.saveAttempt(_attempt);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            test: widget.test,
            attempt: _attempt,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _proctorService.stopMonitoring();
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatTime(int totalSec) {
    final m = (totalSec ~/ 60).toString().padLeft(2, '0');
    final s = (totalSec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF6366F1)),
        ),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _questions.length;
    final remainingPauses = _maxPauseAllowed - _pauseCountUsed;

    return PopScope(
      canPop: false, // Android geri tuşunu engelle
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sınav esnasında geri tuşu ve uygulamadan çıkış yasaktır! Mola için "Duraklat" butonunu kullanın.'),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 1),
          ),
        );
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E293B),
          automaticallyImplyLeading: false,
          elevation: 0,
          title: Row(
            children: [
              Text(
                'Soru ${_currentQuestionIndex + 1}/${_questions.length}',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),

              // Duraklatma Butonu
              IconButton(
                icon: Icon(
                  Icons.pause_circle_outline,
                  color: remainingPauses > 0 ? const Color(0xFFF59E0B) : const Color(0xFF64748B),
                ),
                tooltip: 'Testi Duraklat (Kalan Hak: $remainingPauses)',
                onPressed: remainingPauses > 0 ? _pauseTest : null,
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, color: Color(0xFFF59E0B), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(_remainingSeconds),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  // Sınav İlerleme Çubuğu
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: const Color(0xFF1E293B),
                    valueColor: AlwaysStoppedAnimation<Color>(widget.test.themeColor),
                    minHeight: 4,
                  ),

                  // Göz & Dikkat Takibi Canlı HUD
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: ProctorHud(
                      gazeState: _currentGazeState,
                      onSimulateLookAway: () => _proctorService.simulateGazeShift(true),
                      onSimulateLookBack: () => _proctorService.simulateGazeShift(false),
                      showSimulatorControls: true,
                    ),
                  ),

                  // Soru ve Şıklar Alanı
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (currentQuestion.type == QuestionType.visualMatrix)
                            MatrixQuestionViewer(question: currentQuestion)
                          else
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF334155)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentQuestion.prompt,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      height: 1.4,
                                    ),
                                  ),
                                  if (currentQuestion.subtitle != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      currentQuestion.subtitle!,
                                      style: const TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 13,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                          const SizedBox(height: 20),
                          const Text(
                            'Seçenekler:',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Şıklar
                          ...List.generate(currentQuestion.options.length, (index) {
                            final optionText = currentQuestion.options[index];
                            final isSelected = _selectedOptionIndex == index;
                            final optionLetter = String.fromCharCode(65 + index);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedOptionIndex = index;
                                  });
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? widget.test.themeColor.withValues(alpha: 0.15)
                                        : const Color(0xFF1E293B),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? widget.test.themeColor
                                          : const Color(0xFF334155),
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? widget.test.themeColor
                                              : const Color(0xFF0F172A),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isSelected
                                                ? widget.test.themeColor
                                                : const Color(0xFF475569),
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            optionLetter,
                                            style: TextStyle(
                                              color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Text(
                                          optionText,
                                          style: TextStyle(
                                            color: isSelected ? Colors.white : const Color(0xFFE2E8F0),
                                            fontSize: 15,
                                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),

                  // Alt Buton (Cevapla & Sonraki)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _selectedOptionIndex != null ? _submitAnswerAndNext : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.test.themeColor,
                          disabledBackgroundColor: const Color(0xFF334155),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          _currentQuestionIndex == _questions.length - 1
                              ? 'Testi Tamamla'
                              : 'Sonraki Soru',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Duraklatma (Pause) Güvenlik Ekranı
            if (_isPaused)
              Container(
                color: const Color(0xFF0F172A).withValues(alpha: 0.96),
                width: double.infinity,
                height: double.infinity,
                padding: const EdgeInsets.all(28),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFF59E0B), width: 2),
                        ),
                        child: const Icon(Icons.pause, color: Color(0xFFF59E0B), size: 48),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'TEST DURAKLATILDI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Kalan Duraklatma Hakkınız: $remainingPauses / $_maxPauseAllowed',
                        style: const TextStyle(
                          color: Color(0xFFF59E0B),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Sınav güvenliği amacıyla sorular ve seçenekler duraklatma süresince gizlenir. Kamera ve süre sayacı durduruldu.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, height: 1.4),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: 220,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _resumeTest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.play_arrow, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Teste Devam Et',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
