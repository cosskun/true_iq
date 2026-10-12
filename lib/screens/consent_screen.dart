import 'package:flutter/material.dart';
import '../models/test_model.dart';
import 'test_screen.dart';

class ConsentScreen extends StatefulWidget {
  final TestModel test;
  final int remainingAttempts;

  const ConsentScreen({
    super.key,
    required this.test,
    required this.remainingAttempts,
  });

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _agreedKvkk = false;
  bool _agreedRules = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Text(
          widget.test.title,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Uyarı & Kalan Hak Kartı
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.test.themeColor.withValues(alpha: 0.2),
                      const Color(0xFF1E293B),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: widget.test.themeColor.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: widget.test.themeColor.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(widget.test.icon, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kalan Deneme Hakkınız: ${widget.remainingAttempts} / ${widget.test.maxFailureAttempts}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Toplam 3 başarısızlık hakkınız bulunur. 3 kez başarısız olursanız test kalıcı olarak kilitlenir.',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Text(
                '🛡️ Sınav Güvenlik Kuralları',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              _buildRuleItem(
                icon: Icons.visibility_off,
                title: 'Göz ve Dikkat Takibi (Zorunlu)',
                description: 'Test sırasında ön kamera aracılığıyla gözleriniz izlenir. Gözlerinizi 2.5 saniyeden uzun süre ekrandan ayırırsanız test BAŞARISIZ sayılarak sonlandırılır.',
              ),
              _buildRuleItem(
                icon: Icons.lock,
                title: 'Uygulamadan Çıkış Yasağı',
                description: 'Test süresince uygulamayı arka plana alamaz, bildirimleri açamaz veya başka bir uygulamaya geçemezsiniz. Bu durum anında elenme sebebidir.',
              ),
              _buildRuleItem(
                icon: Icons.shuffle,
                title: 'Dinamik Soru Havuzu',
                description: 'Testten başarısız olup tekrar girdiğinizde daha önce gördüğünüz sorularla ASLA karşılaşmazsınız. Tamamen yeni sorular sunulur.',
              ),

              const SizedBox(height: 20),
              const Divider(color: Color(0xFF334155)),
              const SizedBox(height: 12),

              // KVKK Aydınlatma Metni
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.shield_outlined, color: Color(0xFF10B981), size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Kamera ve Gizlilik Taahhüdü (KVKK/GDPR)',
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Kamera görüntüleriniz hiçbir sunucuya iletilmez, kaydedilmez veya depolanmaz. Tüm açı hesaplamaları tamamen telefonunuzun geçici belleğinde (RAM) anlık olarak işlenir ve silinir.',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Onay Kutuları
              CheckboxListTile(
                value: _agreedKvkk,
                onChanged: (val) => setState(() => _agreedKvkk = val ?? false),
                activeColor: const Color(0xFF6366F1),
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Kamera verilerimin yalnızca cihaz üstünde anlık göz takibi için işlenmesini onaylıyorum.',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
              CheckboxListTile(
                value: _agreedRules,
                onChanged: (val) => setState(() => _agreedRules = val ?? false),
                activeColor: const Color(0xFF6366F1),
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Sınav kurallarını ve 3 başarısızlık hakkı sınırını okudum, kabul ediyorum.',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),

              const SizedBox(height: 24),

              // Testi Başlat Butonu
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: (_agreedKvkk && _agreedRules)
                      ? () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TestScreen(test: widget.test),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.test.themeColor,
                    disabledBackgroundColor: const Color(0xFF334155),
                    shape: RoundedRectangleUri(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_arrow_rounded, color: Colors.white, size: 26),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Testi Başlat & Kamerayı Aç',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRuleItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Icon(icon, color: const Color(0xFFF59E0B), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RoundedRectangleUri extends RoundedRectangleBorder {
  const RoundedRectangleUri({super.borderRadius});
}
