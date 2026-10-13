import 'package:flutter/material.dart';
import '../models/test_model.dart';
import '../models/leaderboard_entry.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import '../data/default_tests.dart';

class LeaderboardModal extends StatefulWidget {
  final TestModel? selectedTest;

  const LeaderboardModal({super.key, this.selectedTest});

  static void show(BuildContext context, {TestModel? test}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => LeaderboardModal(selectedTest: test),
    );
  }

  @override
  State<LeaderboardModal> createState() => _LeaderboardModalState();
}

class _LeaderboardModalState extends State<LeaderboardModal> {
  late TestModel _currentTest;
  StorageService? _storageService;
  AuthService? _authService;
  List<LeaderboardEntry> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentTest = widget.selectedTest ?? DefaultTests.testList.first;
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    _storageService = await StorageService.getInstance();
    _authService = await AuthService.getInstance();
    _loadEntries();
  }

  void _loadEntries() {
    if (_storageService == null) return;
    final currentUsername = _authService?.currentUser?.username;
    final list = _storageService!.getLeaderboard(
      _currentTest.id,
      currentUsername: currentUsername,
    );
    if (mounted) {
      setState(() {
        _entries = list;
        _isLoading = false;
      });
    }
  }

  void _selectTest(TestModel test) {
    setState(() {
      _currentTest = test;
      _isLoading = true;
    });
    _loadEntries();
  }

  String _formatSeconds(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    if (m > 0) {
      return '${m}dk ${s > 0 ? '${s}sn' : ''}';
    }
    return '${s}sn';
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService?.currentUser;
    final currentUsername = currentUser?.username ?? '';
    final userRank = _entries.indexWhere((e) => e.username.toLowerCase() == currentUsername.toLowerCase());
    final hasUserScore = userRank >= 0;
    final userEntry = hasUserScore ? _entries[userRank] : null;

    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Sürükleme Çubuğu
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFF334155),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Başlık ve Kapat Butonu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.emoji_events_rounded, color: Color(0xFFF59E0B), size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Liderlik Sıralaması',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'En Yüksek Bilişsel IQ Dereceleri',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                ),
              ],
            ),
          ),

          // Test Seçim Çipleri (Yatay Kaydırma)
          Container(
            height: 48,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: DefaultTests.testList.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final test = DefaultTests.testList[i];
                final isSelected = test.id == _currentTest.id;
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        test.icon,
                        size: 16,
                        color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        test.title,
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  selected: isSelected,
                  selectedColor: _currentTest.themeColor,
                  backgroundColor: const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? _currentTest.themeColor : const Color(0xFF334155),
                    ),
                  ),
                  onSelected: (_) => _selectTest(test),
                );
              },
            ),
          ),

          // Liste Alanı
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                : _entries.isEmpty
                    ? const Center(
                        child: Text(
                          'Bu test için henüz sıralama verisi bulunmuyor.',
                          style: TextStyle(color: Color(0xFF94A3B8)),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          // İlk 3 Podyumu
                          if (_entries.length >= 3) ...[
                            _buildPodium(_entries.take(3).toList()),
                            const SizedBox(height: 16),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Text(
                                'TÜM SIRALAMA',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),
                          ],

                          // Listenin Geri Kalanı (veya tamamı)
                          ...List.generate(_entries.length, (idx) {
                            final entry = _entries[idx];
                            return _buildRankRow(entry, idx + 1);
                          }),
                          const SizedBox(height: 80),
                        ],
                      ),
          ),

          // Kullanıcının Sırası Sabit Çubuğu (Varsa)
          if (currentUser != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                border: const Border(top: BorderSide(color: Color(0xFF334155))),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Center(
                        child: Text(
                          hasUserScore ? '#${userRank + 1}' : '—',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            currentUser.fullName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '@${currentUser.username} (Siz)',
                            style: const TextStyle(
                              color: Color(0xFF818CF8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (hasUserScore && userEntry != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF10B981)),
                        ),
                        child: Text(
                          '${userEntry.iqScore} IQ',
                          style: const TextStyle(
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      )
                    else
                      const Text(
                        'Henüz Skoru Yok',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // İlk 3 Podyum Bileşeni
  Widget _buildPodium(List<LeaderboardEntry> top3) {
    final first = top3[0];
    final second = top3.length > 1 ? top3[1] : null;
    final third = top3.length > 2 ? top3[2] : null;

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2. Sıra (Gümüş)
          if (second != null)
            _buildPodiumColumn(
              entry: second,
              rank: 2,
              medalColor: const Color(0xFFCBD5E1),
              badgeText: '2. 🥈',
              height: 110,
            ),

          // 1. Sıra (Altın - En Yüksek)
          _buildPodiumColumn(
            entry: first,
            rank: 1,
            medalColor: const Color(0xFFF59E0B),
            badgeText: '1. 👑',
            height: 135,
            isWinner: true,
          ),

          // 3. Sıra (Bronz)
          if (third != null)
            _buildPodiumColumn(
              entry: third,
              rank: 3,
              medalColor: const Color(0xFFD97706),
              badgeText: '3. 🥉',
              height: 95,
            ),
        ],
      ),
    );
  }

  Widget _buildPodiumColumn({
    required LeaderboardEntry entry,
    required int rank,
    required Color medalColor,
    required String badgeText,
    required double height,
    bool isWinner = false,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            badgeText,
            style: TextStyle(
              color: medalColor,
              fontWeight: FontWeight.w900,
              fontSize: isWinner ? 16 : 14,
            ),
          ),
          const SizedBox(height: 6),
          CircleAvatar(
            radius: isWinner ? 24 : 20,
            backgroundColor: medalColor.withValues(alpha: 0.25),
            child: Text(
              entry.fullName.isNotEmpty ? entry.fullName[0].toUpperCase() : '?',
              style: TextStyle(
                color: medalColor,
                fontWeight: FontWeight.w900,
                fontSize: isWinner ? 18 : 15,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '@${entry.username}',
            style: TextStyle(
              color: entry.isCurrentUser ? const Color(0xFF818CF8) : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: medalColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: medalColor.withValues(alpha: 0.5)),
            ),
            child: Text(
              '${entry.iqScore} IQ',
              style: TextStyle(
                color: medalColor,
                fontWeight: FontWeight.w900,
                fontSize: isWinner ? 13 : 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Sıralama Satırı
  Widget _buildRankRow(LeaderboardEntry entry, int rank) {
    final bool isUser = entry.isCurrentUser;
    Color rankColor = const Color(0xFF94A3B8);
    if (rank == 1) rankColor = const Color(0xFFF59E0B);
    if (rank == 2) rankColor = const Color(0xFFCBD5E1);
    if (rank == 3) rankColor = const Color(0xFFD97706);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isUser
            ? const Color(0xFF6366F1).withValues(alpha: 0.18)
            : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUser
              ? const Color(0xFF818CF8)
              : const Color(0xFF334155),
          width: isUser ? 1.8 : 1.0,
        ),
      ),
      child: Row(
        children: [
          // Sıra Numarası
          SizedBox(
            width: 32,
            child: Text(
              '#$rank',
              style: TextStyle(
                color: rankColor,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
          ),

          // Avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: isUser
                ? const Color(0xFF818CF8).withValues(alpha: 0.3)
                : const Color(0xFF334155),
            child: Text(
              entry.fullName.isNotEmpty ? entry.fullName[0].toUpperCase() : '?',
              style: TextStyle(
                color: isUser ? Colors.white : const Color(0xFFE2E8F0),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // İsim & Kullanıcı Adı
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isUser) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'SİZ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  '@${entry.username} • ${_formatSeconds(entry.timeTakenSeconds)} • ${entry.correctAnswers}/${entry.totalQuestions} D',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // IQ Skoru
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isUser
                  ? const Color(0xFF10B981).withValues(alpha: 0.2)
                  : const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isUser ? const Color(0xFF10B981) : const Color(0xFF334155),
              ),
            ),
            child: Text(
              '${entry.iqScore} IQ',
              style: TextStyle(
                color: isUser ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
