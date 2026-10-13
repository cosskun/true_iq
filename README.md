# 🧠 TrueIQ (Göz Takibi ve Güvenlikli Mobil IQ Testi)

Flutter ile geliştirilmiş, **On-Device Yapay Zeka (Göz & Dikkat Takibi)** ve **Kiosk / Sınav Güvenliği** mimarisine sahip yeni nesil IQ testi uygulaması.

---

## ✨ Temel Özellikler

1. **👁️ Canlı Göz ve Dikkat Takibi (Eye-Tracking):**
   * Kullanıcının gözleri ve kafa açısı ekrandan 5 saniyeden uzun süre ayrıldığında sınav otomatik olarak sonlandırılır.
   * Görüntüler sunucuya aktarılmaz, cihazın geçici belleğinde anlık olarak işlenir.
2. **🔒 Uygulama Kitleme ve Odak Koruması:**
   * Test sırasında başka bir uygulamaya geçiş yapıldığında veya arka plana atıldığında test anında başarısız sayılır.
3. **⏸️ 3 Kere Duraklatma Hakkı (Pause Güvenliği):**
   * Kullanıcı acil bir durumda testi en fazla 3 kez duraklatabilir. Duraklatıldığında soru ve şıklar anında gizlenir.
4. **🎲 Dinamik Soru Havuzu:**
   * Kullanıcı başarısız olup tekrar sınava girdiğinde, daha önce gördüğü sorular veritabanı filtresiyle elenir ve tamamen yeni sorular getirilir.
5. **🚫 3 Başarısızlık Hakkı Limiti & Tek Bitirme Kuralı:**
   * Bir testten en fazla 3 kez başarısız olunabilir. 3. başarısızlığın ardından test kilitlenir.
   * Başarıyla tamamlanan bir test kalıcı olarak kilitlenir ve bir daha asla çözülemez.
6. **🌟 Detaylı Bilişsel Rapor & Sosyal Medya Paylaşım Sertifikası:**
   * Kullanıcının Adı, Soyadı, `@kullaniciadi`, IQ Skoru ve Güvenlik Mührü içeren paylaşılabilir sertifika kartı.
7. **🏆 Özel Test Kataloğu & Kullanıcı Adlı Liderlik Sıralaması:**
   * **6 Farklı Özel Test:** `TrueIQ Alpha Matrix`, `Mensa Titan Challenge`, `Cortex HyperSpeed`, `Nexus 3D Vision`, `Quantum Deduction`, `Verbal Spectrum`.
   * Her testin bağımsız liderlik tablosu; oyuncuların `@kullanıcıadı`, IQ skoru ve bitirme sürelerine göre altın, gümüş, bronz podyum ve sıralama listesi.
   * Kullanıcının kendi derecesini anlık takip edebileceği interaktif sıralama modülü (`LeaderboardModal`).

---

## 📂 Dosya Yapısı

```
true_iq/
├── lib/
│   ├── data/
│   │   ├── iq_question_bank.dart   # Zengin IQ soru havuzu
│   │   └── default_tests.dart       # Test kategorileri ve tanımları
│   ├── models/
│   │   ├── question.dart            # Soru modeli ve kategoriler
│   │   ├── test_model.dart          # Test modeli
│   │   ├── test_attempt.dart        # Sınav girişimleri ve sonuçları
│   │   └── user_model.dart          # Kullanıcı modeli
│   ├── screens/
│   │   ├── login_screen.dart        # Giriş ekranı
│   │   ├── register_screen.dart     # Kayıt ekranı (Benzersiz kullanıcı adı)
│   │   ├── home_screen.dart         # Ana sayfa ve test listesi
│   │   ├── consent_screen.dart      # KVKK ve Sınav Güvenlik Sözleşmesi
│   │   ├── test_screen.dart         # Sınav ekranı + Göz Takibi HUD
│   │   └── result_screen.dart       # Sonuç, Bilişsel Rapor ve Sertifika
│   ├── services/
│   │   ├── auth_service.dart        # Kimlik doğrulama & kullanıcı adı yönetimi
│   │   ├── proctor_service.dart     # Göz/Kafa ve Yaşam Döngüsü Denetleyicisi
│   │   ├── storage_service.dart     # Hak Sayacı ve Görülmemiş Soru Filtresi
│   │   └── firebase_service.dart    # Bulut Veritabanı Köprüsü
│   ├── widgets/
│   │   ├── proctor_hud.dart         # Canlı Kamera ve Dikkat Göstergesi
│   │   ├── matrix_question_viewer.dart # Raven Matrisi Çizim Motoru
│   │   └── share_certificate_card.dart # Sosyal Medya Sertifikası
│   └── main.dart
├── baslat.bat                       # Tek tıkla web/mobil test başlatıcı
└── FIREBASE_KURULUM_REHBERI.md     # Firebase & Firestore kurulum rehberi
```
