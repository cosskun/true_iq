import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:true_iq/data/default_tests.dart';
import 'package:true_iq/data/iq_question_bank.dart';
import 'package:true_iq/models/test_attempt.dart';
import 'package:true_iq/models/user_model.dart';
import 'package:true_iq/models/leaderboard_entry.dart';
import 'package:true_iq/services/auth_service.dart';
import 'package:true_iq/services/storage_service.dart';
import 'package:true_iq/screens/login_screen.dart';
import 'package:true_iq/screens/register_screen.dart';
import 'package:true_iq/screens/home_screen.dart';
import 'package:true_iq/screens/consent_screen.dart';
import 'package:true_iq/screens/result_screen.dart';
import 'package:true_iq/widgets/share_certificate_card.dart';
import 'package:true_iq/widgets/leaderboard_modal.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('1. Veritabanı ve Mantık Testleri (Storage & Logic)', () {
    test('Soru havuzu zengin ve kategoriler eksiksiz olmalı', () {
      expect(IqQuestionBank.allQuestions.length, greaterThanOrEqualTo(15));
      for (final q in IqQuestionBank.allQuestions) {
        expect(q.options.length, greaterThanOrEqualTo(3));
        expect(q.correctOptionIndex, inInclusiveRange(0, q.options.length - 1));
      }
    });

    test('3 Başarısızlık hakkı ve tek bitirme kuralı düzgün işlemeli', () async {
      final storage = await StorageService.getInstance();
      const testId = 'test_standard_iq';

      expect(storage.getRemainingAttempts(testId), 3);
      expect(storage.isTestLocked(testId), false);
      expect(storage.isTestCompleted(testId), false);

      // 1. Başarısızlık
      await storage.incrementFailedAttempt(testId);
      expect(storage.getRemainingAttempts(testId), 2);
      expect(storage.isTestLocked(testId), false);

      // 2. Başarısızlık
      await storage.incrementFailedAttempt(testId);
      expect(storage.getRemainingAttempts(testId), 1);

      // 3. Başarısızlık (Kilitlenmeli)
      await storage.incrementFailedAttempt(testId);
      expect(storage.getRemainingAttempts(testId), 0);
      expect(storage.isTestLocked(testId), true);

      // Sıfırla
      await storage.resetTestProgress(testId);
      expect(storage.getRemainingAttempts(testId), 3);

      // Başarıyla tamamlandı kuralı
      await storage.markTestAsCompleted(testId);
      expect(storage.isTestCompleted(testId), true);
      expect(storage.isTestLocked(testId), true);
      expect(storage.canStartTest(testId), false);
    });

    test('Daha önce görülen sorular tekrar çıkmamalı (Dinamik Havuz)', () async {
      final storage = await StorageService.getInstance();
      const testId = 'test_standard_iq';

      final batch1 = storage.getQuestionsForNewAttempt(testId: testId, requestedCount: 5);
      final batch1Ids = batch1.map((q) => q.id).toList();
      await storage.markQuestionsAsSeen(testId, batch1Ids);

      final batch2 = storage.getQuestionsForNewAttempt(testId: testId, requestedCount: 5);
      final batch2Ids = batch2.map((q) => q.id).toSet();

      for (final id in batch1Ids) {
        expect(batch2Ids.contains(id), false);
      }
    });
  });

  group('2. Kimlik Doğrulama Testleri (Auth & Unique Username & Email)', () {
    test('Aynı kullanıcı adı ile 2. kayıt yapılamaz (Büyük/küçük harf duyarsız)', () async {
      final auth = await AuthService.getInstance();

      final reg1 = await auth.register(
        fullName: 'Ahmet Yılmaz',
        username: 'ahmetyilmaz',
        email: 'ahmet_unique1@test.com',
        password: 'password123',
      );
      expect(reg1.success, true);
      expect(reg1.user?.username, 'ahmetyilmaz');
      // Kayıt sonrası otomatik oturum açılmamalı
      expect(auth.isLoggedIn, false);
      expect(auth.currentUser, isNull);

      // 1. Aynı kullanıcı adı (küçük harf) ile 2. kayıt engellenmeli
      final reg2 = await auth.register(
        fullName: 'Mehmet Demir',
        username: 'ahmetyilmaz',
        email: 'mehmet_farkli@test.com',
        password: 'password123',
      );
      expect(reg2.success, false);
      expect(reg2.error, contains('zaten kullanılıyor'));

      // 2. Aynı kullanıcı adı büyük harflerle (AHMETYILMAZ) girildiğinde de engellenmeli
      final reg3 = await auth.register(
        fullName: 'Ayşe Kaya',
        username: 'AHMETYILMAZ',
        email: 'ayse_farkli@test.com',
        password: 'password123',
      );
      expect(reg3.success, false);
      expect(reg3.error, contains('zaten kullanılıyor'));

      final login = await auth.login(usernameOrEmail: 'ahmetyilmaz', password: 'password123');
      expect(login.success, true);
      expect(auth.isLoggedIn, true);
    });

    test('Aynı e-posta adresi ile 2. kayıt yapılamaz (Büyük/küçük harf duyarsız)', () async {
      final auth = await AuthService.getInstance();

      final reg1 = await auth.register(
        fullName: 'Canan Can',
        username: 'canancan',
        email: 'canan@unique-mail.com',
        password: 'password123',
      );
      expect(reg1.success, true);

      // 1. Farklı kullanıcı adı ama AYNI e-posta ile kayıt engellenmeli
      final regDuplicateEmail = await auth.register(
        fullName: 'Farklı Kullanıcı',
        username: 'farklikullanici',
        email: 'canan@unique-mail.com',
        password: 'password123',
      );
      expect(regDuplicateEmail.success, false);
      expect(regDuplicateEmail.error, contains('Bu e-posta adresi ile kayıtlı bir hesap zaten mevcut'));

      // 2. Büyük harflerle aynı e-posta (CANAN@UNIQUE-MAIL.COM) girildiğinde de engellenmeli
      final regCaseInsensitiveEmail = await auth.register(
        fullName: 'Büyük Harf Eposta Testi',
        username: 'buyukharfuser',
        email: 'CANAN@UNIQUE-MAIL.COM',
        password: 'password123',
      );
      expect(regCaseInsensitiveEmail.success, false);
      expect(regCaseInsensitiveEmail.error, contains('Bu e-posta adresi ile kayıtlı bir hesap zaten mevcut'));
    });
  });

  group('3. Ekran Arayüz & Buton Testleri (UI & Navigation)', () {
    testWidgets('Giriş Ekranı (LoginScreen) bileşenleri ve form testi', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
      await tester.pumpAndSettle();

      expect(find.text('TrueIQ'), findsOneWidget);
      expect(find.text('Giriş Yap'), findsOneWidget);
      expect(find.text('Hızlı Demo Girişi (Test)'), findsOneWidget);
      expect(find.text('Hemen Kayıt Olun'), findsOneWidget);

      await tester.ensureVisible(find.text('Giriş Yap'));
      await tester.tap(find.text('Giriş Yap'));
      await tester.pumpAndSettle();
      expect(find.text('Lütfen kullanıcı adı veya e-posta giriniz.'), findsOneWidget);
    });

    testWidgets('Kayıt Ekranı (RegisterScreen) form alanları ve validation', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Yeni Hesap Oluştur'), findsOneWidget);
      expect(find.text('Ad Soyad'), findsOneWidget);
      expect(find.text('Kullanıcı Adı (Benzersiz)'), findsOneWidget);
      expect(find.text('E-Posta Adresi (Benzersiz)'), findsOneWidget);

      final submitBtn = find.text('Hesap Oluştur');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();
      expect(find.text('Ad Soyad alanı zorunludur.'), findsOneWidget);
    });

    testWidgets('Kayıt Ekranı başarılı kayıt sonrası "Kayıt başarılı lütfen giriş yapınız." uyarısı göstermeli', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Yeni Kullanıcı');
      await tester.enterText(fields.at(1), 'yenikullanici_${DateTime.now().millisecondsSinceEpoch}');
      await tester.enterText(fields.at(2), 'yeni_${DateTime.now().millisecondsSinceEpoch}@test.com');
      await tester.enterText(fields.at(3), 'sifre1234');
      await tester.enterText(fields.at(4), 'sifre1234');
      await tester.pumpAndSettle();

      final submitBtn = find.text('Hesap Oluştur');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Kayıt başarılı lütfen giriş yapınız.'), findsOneWidget);
    });

    testWidgets('Kayıt Ekranı (UI) mükerrer kullanıcı adı ve e-posta girişinde anlık uyarı verir ve kaydı engeller', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      final auth = await AuthService.getInstance();
      await auth.register(
        fullName: 'Mevcut Kullanıcı',
        username: 'mevcutuser',
        email: 'mevcut@mail.com',
        password: 'password123',
      );

      await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);

      // Alınmış kullanıcı adını yaz -> anlık uyarı vermeli
      await tester.enterText(fields.at(1), 'mevcutuser');
      await tester.pumpAndSettle();
      expect(find.text('❌ Bu kullanıcı adı zaten alınmış!'), findsOneWidget);

      // Alınmış e-postayı yaz -> anlık uyarı vermeli
      await tester.enterText(fields.at(2), 'mevcut@mail.com');
      await tester.pumpAndSettle();
      expect(find.text('❌ Bu e-posta adresi zaten kullanılıyor!'), findsOneWidget);

      // Form alanlarını doldurup submit etmeyi dene -> form validator engellemeli
      await tester.enterText(fields.at(0), 'Test İsim');
      await tester.enterText(fields.at(3), 'sifre123');
      await tester.enterText(fields.at(4), 'sifre123');
      final submitBtn = find.text('Hesap Oluştur');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Uyarı mesajı form validator altında da görünmeli ve kayıt tamamlanmamalı
      expect(find.text('Bu kullanıcı adı zaten alınmış!'), findsOneWidget);
      expect(find.text('Kayıt başarılı lütfen giriş yapınız.'), findsNothing);
    });

    testWidgets('Ana Menü Ekranı (HomeScreen) test kartları ve rozetler', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Genel Bilişsel IQ Testi'), findsOneWidget);
      expect(find.text('Mensa Seviye Yüksek IQ'), findsOneWidget);
      expect(find.text('Bilişsel Hız & Çalışma Belleği'), findsOneWidget);
      expect(find.text('Göz Takibi & Sınav Güvenliği Aktif'), findsOneWidget);
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('Onay Ekranı (ConsentScreen) kurallar ve checkbox zorunluluğu', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      final testModel = DefaultTests.testList.first;
      await tester.pumpWidget(
        MaterialApp(
          home: ConsentScreen(
            test: testModel,
            remainingAttempts: 3,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(testModel.title), findsOneWidget);
      expect(find.text('🛡️ Sınav Güvenlik Kuralları'), findsOneWidget);
      expect(find.text('Göz ve Dikkat Takibi (Zorunlu)'), findsOneWidget);

      final startBtn = find.text('Testi Başlat');
      expect(startBtn, findsOneWidget);

      // Onay kutuları işaretlenmeden tıklandığında uyarı SnackBar'ı görünmeli
      await tester.ensureVisible(startBtn);
      await tester.tap(startBtn);
      await tester.pumpAndSettle();

      expect(find.text('Bu seçeneği işaretlemeden teste başlayamazsınız.'), findsOneWidget);

      final checkboxes = find.byType(CheckboxListTile);
      expect(checkboxes, findsNWidgets(2));

      await tester.ensureVisible(checkboxes.at(0));
      await tester.tap(checkboxes.at(0));
      await tester.pumpAndSettle();

      await tester.ensureVisible(checkboxes.at(1));
      await tester.tap(checkboxes.at(1));
      await tester.pumpAndSettle();

      final buttonAfter = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(buttonAfter.onPressed, isNotNull);
    });

    testWidgets('Sonuç Ekranı (ResultScreen) IQ ve Bilişsel Analiz Raporu', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      final testModel = DefaultTests.testList.first;
      final attempt = TestAttempt(
        id: 'att_123',
        testId: testModel.id,
        attemptNumber: 1,
        startedAt: DateTime.now().subtract(const Duration(minutes: 15)),
        finishedAt: DateTime.now(),
        status: AttemptStatus.completedSuccess,
        totalQuestions: 15,
        correctAnswers: 13,
        calculatedIq: 134,
        percentile: 98.4,
        cognitiveProfile: 'Üstün Mantık & Soyut Muhakeme Uzmanı',
        categoryBreakdown: {
          'patternReasoning': 0.95,
          'numberSequences': 0.85,
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ResultScreen(
            test: testModel,
            attempt: attempt,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bilişsel Analiz Raporu'), findsOneWidget);
      expect(find.text('TEST TAMAMLANDI'), findsOneWidget);
      expect(find.text('134'), findsOneWidget);
      expect(find.text('Çok Üstün Zeka'), findsOneWidget);
      expect(find.text('📊 Bilişsel Yetenek Dağılımı'), findsOneWidget);
      expect(find.text('Matris & Görsel Örüntü'), findsOneWidget);
      expect(find.text('Sonucu Sosyal Medyada Paylaş / Sertifika'), findsOneWidget);
      expect(find.text('Ana Menüye Dön'), findsOneWidget);
    });

    testWidgets('Sosyal Medya Sertifika Kartı (ShareCertificateCard)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      final testModel = DefaultTests.testList.first;
      final attempt = TestAttempt(
        id: 'att_1234567890',
        testId: testModel.id,
        attemptNumber: 1,
        startedAt: DateTime.now(),
        finishedAt: DateTime.now(),
        status: AttemptStatus.completedSuccess,
        totalQuestions: 15,
        calculatedIq: 138,
        percentile: 99.1,
        cognitiveProfile: 'Mensa Seviye Analist',
      );

      final user = UserModel(
        id: 'u1',
        fullName: 'Zeynep Kaya',
        username: 'zeynepkaya',
        email: 'zeynep@test.com',
        password: 'pass',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ShareCertificateCard(
              test: testModel,
              attempt: attempt,
              user: user,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('TRUEIQ'), findsOneWidget);
      expect(find.text('Göz Takibi Onaylı'), findsOneWidget);
      expect(find.text('RESMİ BİLİŞSEL DEĞERLENDİRME SERTİFİKASI'), findsOneWidget);
      expect(find.text('Zeynep Kaya'), findsOneWidget);
      expect(find.text('@zeynepkaya'), findsOneWidget);
      expect(find.text('138'), findsOneWidget);
      expect(find.text('En İyi %0.9'), findsOneWidget);
    });
  });

  group('4. Liderlik Tablosu & Yeni Testler (Leaderboard & Extended Tests)', () {
    test('Tüm testler benzersiz özel isimlere sahip olmalı (6 Test)', () {
      expect(DefaultTests.testList.length, 6);
      
      final titles = DefaultTests.testList.map((t) => t.title).toList();
      expect(titles.contains('TrueIQ Alpha Matrix'), isTrue);
      expect(titles.contains('Mensa Titan Challenge'), isTrue);
      expect(titles.contains('Cortex HyperSpeed'), isTrue);
      expect(titles.contains('Nexus 3D Vision'), isTrue);
      expect(titles.contains('Quantum Deduction'), isTrue);
      expect(titles.contains('Verbal Spectrum'), isTrue);

      final subtitles = DefaultTests.testList.map((t) => t.subtitle).toList();
      expect(subtitles.contains('Genel Bilişsel IQ Testi'), isTrue);
      expect(subtitles.contains('Mensa Seviye Yüksek IQ'), isTrue);
      expect(subtitles.contains('Bilişsel Hız & Çalışma Belleği'), isTrue);
    });

    test('Liderlik Tablosu (Storage) kullanıcı ekleme ve skor sıralaması', () async {
      final storage = await StorageService.getInstance();
      const testId = 'test_standard_iq';

      // Başlangıç liderlik tablosu gelmeli
      final initialList = storage.getLeaderboard(testId);
      expect(initialList.isNotEmpty, isTrue);

      // Yeni bir oyuncu skoru ekleyelim
      final newPlayer = LeaderboardEntry(
        testId: testId,
        username: 'sampiyon_ali',
        fullName: 'Ali Demir',
        iqScore: 155, // En yüksek skor
        correctAnswers: 15,
        totalQuestions: 15,
        timeTakenSeconds: 300,
        completedAt: DateTime.now(),
      );
      await storage.addOrUpdateLeaderboardEntry(newPlayer);

      // Yeniden sorgulayalım: Ali Demir 155 IQ ile #1 olmalı
      final updatedList = storage.getLeaderboard(testId, currentUsername: 'sampiyon_ali');
      expect(updatedList.first.username, 'sampiyon_ali');
      expect(updatedList.first.iqScore, 155);
      expect(updatedList.first.isCurrentUser, isTrue);

      final rank = storage.getUserRankInLeaderboard(testId, 'sampiyon_ali');
      expect(rank, 1);
    });

    testWidgets('Liderlik Tablosu (LeaderboardModal) arayüz ve podyum gösterimi', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      final testModel = DefaultTests.testList.first;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LeaderboardModal(selectedTest: testModel),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Liderlik Sıralaması'), findsOneWidget);
      expect(find.text('En Yüksek Bilişsel IQ Dereceleri'), findsOneWidget);
      expect(find.text('TrueIQ Alpha Matrix'), findsOneWidget);
      expect(find.text('Mensa Titan Challenge'), findsOneWidget);
    });
  });
}
