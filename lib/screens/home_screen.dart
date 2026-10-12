import 'package:flutter/material.dart';
import '../models/test_model.dart';
import '../data/default_tests.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import 'consent_screen.dart';
import 'result_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  StorageService? _storageService;
  AuthService? _authService;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    _storageService = await StorageService.getInstance();
    _authService = await AuthService.getInstance();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _refreshData() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService?.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.psychology_alt_rounded, color: Color(0xFF818CF8), size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user != null ? user.fullName : 'TrueIQ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (user != null)
                    Text(
                      '@${user.username}',
                      style: const TextStyle(color: Color(0xFF818CF8), fontSize: 12),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: const Color(0xFF1E293B),
            onSelected: (val) async {
              if (val == 'logout') {
                await _authService?.logout();
                if (context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                }
              } else if (val == 'reset_all') {
                await _storageService?.clearAllData();
                _refreshData();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tüm deneme hakları ve kayıtlar sıfırlandı.'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                }
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'reset_all',
                child: Row(
                  children: [
                    Icon(Icons.restart_alt, color: Colors.amberAccent, size: 20),
                    SizedBox(width: 8),
                    Text('Hakları Sıfırla (Test)', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.redAccent, size: 20),
                    SizedBox(width: 8),
                    Text('Çıkış Yap', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : SafeArea(
              child: RefreshIndicator(
                onRefresh: () async => _refreshData(),
                color: const Color(0xFF6366F1),
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Bilgi Banner'ı
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF312E81), Color(0xFF1E293B)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF4338CA)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.verified_user_rounded, color: Color(0xFF818CF8), size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Göz Takibi & Sınav Güvenliği Aktif',
                                  style: TextStyle(
                                    color: Color(0xFF818CF8),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Sınavlar esnasında gözleriniz ön kamerayla izlenir. Her test için maksimum 3 başarısızlık hakkınız vardır. Başarısız olunan testlerde tekrar eden sorular elenir.',
                            style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 13, height: 1.4),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Text(
                      'Mevcut IQ Testleri',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Test Listesi
                    ...DefaultTests.testList.map((test) => _buildTestCard(test)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTestCard(TestModel test) {
    final storage = _storageService;
    final isCompleted = storage?.isTestCompleted(test.id) ?? false;
    final remaining = storage?.getRemainingAttempts(test.id, maxAttempts: test.maxFailureAttempts) ?? test.maxFailureAttempts;
    final isLocked = storage?.isTestLocked(test.id, maxAttempts: test.maxFailureAttempts) ?? false;
    final bestScore = storage?.getBestIqScore(test.id);

    Color badgeBg;
    Color badgeText;
    String badgeLabel;

    if (isCompleted) {
      badgeBg = const Color(0xFF10B981).withValues(alpha: 0.2);
      badgeText = const Color(0xFF10B981);
      badgeLabel = '✓ TAMAMLANDI';
    } else if (isLocked) {
      badgeBg = Colors.red.withValues(alpha: 0.2);
      badgeText = Colors.redAccent;
      badgeLabel = 'KİLİTLENDİ (0 Hak)';
    } else if (remaining == 3) {
      badgeBg = const Color(0xFF6366F1).withValues(alpha: 0.2);
      badgeText = const Color(0xFF818CF8);
      badgeLabel = '3 / 3 Hak';
    } else if (remaining == 2) {
      badgeBg = const Color(0xFFF59E0B).withValues(alpha: 0.2);
      badgeText = const Color(0xFFF59E0B);
      badgeLabel = '2 / 3 Hak Kaldı';
    } else {
      badgeBg = Colors.orange.withValues(alpha: 0.2);
      badgeText = Colors.orangeAccent;
      badgeLabel = 'Son 1 Hak!';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF10B981).withValues(alpha: 0.5)
              : (isLocked ? Colors.red.withValues(alpha: 0.4) : const Color(0xFF334155)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () async {
          if (isCompleted) {
            final completedAttempt = storage?.getCompletedAttempt(test.id);
            if (completedAttempt != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Bu testi tamamladınız. Bilişsel analiz raporunuz açılıyor.'),
                  backgroundColor: Color(0xFF10B981),
                  duration: Duration(seconds: 2),
                ),
              );
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ResultScreen(
                    test: test,
                    attempt: completedAttempt,
                  ),
                ),
              );
              _refreshData();
            }
            return;
          }

          if (isLocked) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Bu test 3 başarısızlık hakkı aşıldığı için kilitlenmiştir.'),
                backgroundColor: Colors.redAccent,
              ),
            );
            return;
          }

          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ConsentScreen(
                test: test,
                remainingAttempts: remaining,
              ),
            ),
          );
          _refreshData();
        },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: test.themeColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: test.themeColor.withValues(alpha: 0.5)),
                    ),
                    child: Icon(test.icon, color: test.themeColor, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          test.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          test.subtitle,
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: badgeText.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      badgeLabel,
                      style: TextStyle(
                        color: badgeText,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                test.description,
                style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13, height: 1.3),
              ),
              const SizedBox(height: 14),
              const Divider(color: Color(0xFF334155)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.help_outline, color: Color(0xFF94A3B8), size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${test.totalQuestionsPerSession} Soru',
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.timer_outlined, color: Color(0xFF94A3B8), size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${test.durationMinutes} Dakika',
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                  const Spacer(),
                  if (bestScore != null && bestScore > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'En İyi IQ: $bestScore',
                        style: const TextStyle(
                          color: Color(0xFF818CF8),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
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
}
