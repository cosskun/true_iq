import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/test_model.dart';
import '../models/test_attempt.dart';
import '../models/question.dart';
import '../services/storage_service.dart';
import '../widgets/share_certificate_card.dart';
import '../widgets/leaderboard_modal.dart';
import 'consent_screen.dart';

class ResultScreen extends StatefulWidget {
  final TestModel test;
  final TestAttempt attempt;

  const ResultScreen({
    super.key,
    required this.test,
    required this.attempt,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  int _remainingAttempts = 3;
  bool _isLocked = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAttemptStats();
  }

  Future<void> _loadAttemptStats() async {
    final storage = await StorageService.getInstance();
    final remaining = storage.getRemainingAttempts(
      widget.test.id,
      maxAttempts: widget.test.maxFailureAttempts,
    );
    final locked = storage.isTestLocked(
      widget.test.id,
      maxAttempts: widget.test.maxFailureAttempts,
    );

    if (mounted) {
      setState(() {
        _remainingAttempts = remaining;
        _isLocked = locked;
        _isLoading = false;
      });
    }
  }

  String _getIqClassification(int iq) {
    if (iq >= 140) return 'Dahi / Mensa Seviyesi';
    if (iq >= 130) return 'Çok Üstün Zeka';
    if (iq >= 120) return 'Üstün Yetenekli';
    if (iq >= 110) return 'Yüksek Ortalama';
    if (iq >= 90) return 'Ortalama Zeka';
    return 'Geliştirilebilir Düzey';
  }

  String _getCategoryDisplayName(String catKey) {
    if (catKey == QuestionCategory.patternReasoning.name) return 'Matris & Görsel Örüntü';
    if (catKey == QuestionCategory.numberSequences.name) return 'Sayı Dizileri & Matematik';
    if (catKey == QuestionCategory.spatialAwareness.name) return 'Uzamsal & 3D Düşünme';
    if (catKey == QuestionCategory.logicalDeduction.name) return 'Mantıksal Çıkarım';
    if (catKey == QuestionCategory.verbalAnalogies.name) return 'Sözel Analoji & Dil';
    if (catKey == QuestionCategory.workingMemory.name) return 'Bilişsel Hız & Bellek';
    return catKey;
  }

  void _openShareModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '🌟 Sosyal Medya Paylaşım Kartı',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Sertifika Görsel Kartı
              ShareCertificateCard(
                test: widget.test,
                attempt: widget.attempt,
              ),

              const SizedBox(height: 20),

              // Paylaşım Butonları
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final shareText =
                            '🧠 TrueIQ Bilişsel Değerlendirme Testini ${widget.attempt.calculatedIq} IQ skoruyla tamamladım! (En iyi %${(100.0 - widget.attempt.percentile).toStringAsFixed(1)} dilim - ${widget.attempt.cognitiveProfile}). 🛡️ Göz takipli hilesiz sınav mimarisiyle doğrulandı.';
                        Clipboard.setData(ClipboardData(text: shareText));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Paylaşım metni panoya kopyalandı!'),
                            backgroundColor: Color(0xFF10B981),
                          ),
                        );
                        Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.copy, color: Colors.white),
                      label: const Text('Metni Kopyala', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Sertifika kartı görseli oluşturuldu.'),
                            backgroundColor: Color(0xFF10B981),
                          ),
                        );
                        Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.share, color: Colors.white),
                      label: const Text('Paylaş', style: TextStyle(color: Colors.white)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF6366F1)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isFailed = widget.attempt.isFailed;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          isFailed ? 'Sınav Başarısız' : 'Bilişsel Analiz Raporu',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ana Başarı / Başarısızlık Kartı
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isFailed
                              ? [
                                  Colors.red.shade900.withValues(alpha: 0.5),
                                  const Color(0xFF1E293B),
                                ]
                              : [
                                  const Color(0xFF6366F1).withValues(alpha: 0.3),
                                  const Color(0xFF1E293B),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isFailed ? Colors.redAccent : const Color(0xFF6366F1),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            isFailed ? Icons.error_outline_rounded : Icons.workspace_premium_rounded,
                            color: isFailed ? Colors.redAccent : const Color(0xFFF59E0B),
                            size: 58,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            isFailed ? 'TESTTEN ELENDİNİZ' : 'TEST TAMAMLANDI',
                            style: TextStyle(
                              color: isFailed ? Colors.redAccent : const Color(0xFFF59E0B),
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.attempt.statusMessage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (widget.attempt.failReasonDetail != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              widget.attempt.failReasonDetail!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                            ),
                          ],
                          if (!isFailed) ...[
                            const SizedBox(height: 16),
                            const Divider(color: Color(0xFF334155)),
                            const SizedBox(height: 12),
                            Text(
                              '${widget.attempt.calculatedIq}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 52,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Text(
                              'HESAPLANAN IQ SKORU (STANDART ÖLÇEK)',
                              style: TextStyle(
                                color: Color(0xFF818CF8),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _getIqClassification(widget.attempt.calculatedIq),
                              style: const TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Başarılıysa: BİLİŞSEL ANALİZ DETAYLARI
                    if (!isFailed) ...[
                      const Text(
                        '📊 Bilişsel Yetenek Dağılımı',
                        style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: Column(
                          children: [
                            if (widget.attempt.categoryBreakdown.isNotEmpty)
                              ...widget.attempt.categoryBreakdown.entries.map((entry) {
                                final pct = entry.value;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _getCategoryDisplayName(entry.key),
                                            style: const TextStyle(color: Colors.white, fontSize: 13),
                                          ),
                                          Text(
                                            '%${(pct * 100).round()}',
                                            style: const TextStyle(
                                              color: Color(0xFF818CF8),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: pct,
                                          backgroundColor: const Color(0xFF0F172A),
                                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                                          minHeight: 6,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              })
                            else
                              const Text(
                                'Kategori bazlı analiz başarıyla kaydedildi.',
                                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Sosyal Medya Paylaşım Butonu
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _openShareModal,
                          icon: const Icon(Icons.share, color: Colors.white),
                          label: const Text(
                            'Sonucu Sosyal Medyada Paylaş / Sertifika',
                            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEC4899),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Sıralamadaki Yeri Gör Butonu
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: () => LeaderboardModal.show(context, test: widget.test),
                          icon: const Icon(Icons.emoji_events_rounded, color: Color(0xFFF59E0B)),
                          label: const Text(
                            '🏆 Sıralamadaki Yerinizi Görün',
                            style: TextStyle(color: Color(0xFFF59E0B), fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFF59E0B)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Tamamlandı Bilgisi veya Başarısızlık Kalan Hak Kartı
                    if (!isFailed)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF10B981).withValues(alpha: 0.5),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle, color: Color(0xFF10B981), size: 26),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Resmi Değerlendirme Tamamlandı',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Bu test bir kez başarıyla tamamlanmıştır. Sınav güvenliği kuralı gereği aynı test tekrar çözülemez.',
                                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _isLocked ? Colors.redAccent : const Color(0xFF334155),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isLocked ? Icons.lock_clock : Icons.replay,
                              color: _isLocked ? Colors.redAccent : const Color(0xFFF59E0B),
                              size: 26,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isLocked
                                        ? 'Maksimum Hak Doldu (Kilitlendi)'
                                        : 'Kalan Deneme Hakkı: $_remainingAttempts / ${widget.test.maxFailureAttempts}',
                                    style: TextStyle(
                                      color: _isLocked ? Colors.redAccent : Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _isLocked
                                        ? 'Aynı testten 3 kez başarısız olunduğu için 4. bir hak verilmez.'
                                        : 'Tekrar girildiğinde görülen sorular elenerek YENİ sorular gelecektir.',
                                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Yeniden Dene Butonu (Yalnızca BAŞARISIZ olunduğunda ve hak varsa görünür)
                    if (isFailed && !_isLocked)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ConsentScreen(
                                  test: widget.test,
                                  remainingAttempts: _remainingAttempts,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.test.themeColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.refresh, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Yeni Sorularla Tekrar Dene',
                                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.popUntil(context, (route) => route.isFirst);
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF475569)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text(
                          'Ana Menüye Dön',
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
