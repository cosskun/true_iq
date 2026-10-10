import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/test_model.dart';
import '../models/test_attempt.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class ShareCertificateCard extends StatelessWidget {
  final TestModel test;
  final TestAttempt attempt;
  final UserModel? user;

  const ShareCertificateCard({
    super.key,
    required this.test,
    required this.attempt,
    this.user,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd.MM.yyyy').format(attempt.finishedAt ?? DateTime.now());
    final isHighIq = attempt.calculatedIq >= 130;

    return FutureBuilder<AuthService>(
      future: AuthService.getInstance(),
      builder: (context, snapshot) {
        final activeUser = user ?? snapshot.data?.currentUser;
        final displayName = activeUser?.fullName ?? 'Değerlendirilen Kullanıcı';
        final displayUsername = activeUser != null ? '@${activeUser.username}' : '@katilimci';

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isHighIq
                  ? [const Color(0xFF1E1B4B), const Color(0xFF311042), const Color(0xFF0F172A)]
                  : [const Color(0xFF0F172A), const Color(0xFF1E293B), const Color(0xFF0F172A)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isHighIq ? const Color(0xFFF59E0B) : const Color(0xFF6366F1),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: (isHighIq ? const Color(0xFFF59E0B) : const Color(0xFF6366F1))
                    .withValues(alpha: 0.25),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Üst Başlık & Mühür
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isHighIq ? const Color(0xFFF59E0B) : const Color(0xFF6366F1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.psychology, color: Colors.black, size: 20),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'TRUEIQ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.8,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, color: Color(0xFF10B981), size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Göz Takibi Onaylı',
                          style: TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Resmi Başlık
              const Text(
                'RESMİ BİLİŞSEL DEĞERLENDİRME SERTİFİKASI',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                test.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 14),

              // Kullanıcı Adı ve Soyadı Rozeti
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person, color: Color(0xFF818CF8), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      displayUsername,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // IQ Skoru Devasa Rakam
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isHighIq
                        ? const Color(0xFFF59E0B).withValues(alpha: 0.5)
                        : const Color(0xFF6366F1).withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '${attempt.calculatedIq}',
                      style: TextStyle(
                        color: isHighIq ? const Color(0xFFFBBF24) : Colors.white,
                        fontSize: 54,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isHighIq ? '🌟 MENSA SEVİYESİ / ÇOK ÜSTÜN ZEKA' : 'STANDART IQ SKORU',
                      style: TextStyle(
                        color: isHighIq ? const Color(0xFFFBBF24) : const Color(0xFF818CF8),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Yüzdelik Dilim & Bilişsel Profil
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'YÜZDELİK DİLİM',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'En İyi %${(100.0 - attempt.percentile).toStringAsFixed(1)}',
                            style: const TextStyle(color: Color(0xFF10B981), fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'BİLİŞSEL PROFİL',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            attempt.cognitiveProfile,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Color(0xFF818CF8), fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(color: Color(0xFF334155)),
              const SizedBox(height: 10),

              // Alt Bilgi & Doğrulama Kodu
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tarih: $dateStr',
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                  ),
                  Text(
                    'Doğrulama: #${attempt.id.substring(0, 10)}',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
