import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:true_iq/data/default_tests.dart';
import 'package:true_iq/data/iq_question_bank.dart';
import 'package:true_iq/models/test_attempt.dart';
import 'package:true_iq/models/user_model.dart';
import 'package:true_iq/services/auth_service.dart';
import 'package:true_iq/services/storage_service.dart';
import 'package:true_iq/screens/login_screen.dart';
import 'package:true_iq/screens/register_screen.dart';
import 'package:true_iq/screens/home_screen.dart';
import 'package:true_iq/screens/consent_screen.dart';
import 'package:true_iq/screens/result_screen.dart';
import 'package:true_iq/widgets/share_certificate_card.dart';

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

  group('2. Kimlik Doğrulama Testleri (Auth & Unique Username)', () {
    test('Kullanıcı kaydı ve benzersiz kullanıcı adı doğrulaması', () async {
      final auth = await AuthService.getInstance();

      final reg1 = await auth.register(
        fullName: 'Ahmet Yılmaz',
        username: 'ahmetyilmaz',
        email: 'ahmet@test.com',
        password: 'password123',
      );
      expect(reg1.success, true);
      expect(reg1.user?.username, 'ahmetyilmaz');

      // Aynı kullanıcı adı ile 2. kayıt engellenmeli
      final reg2 = await auth.register(
        fullName: 'Mehmet Demir',
        username: 'ahmetyilmaz',
        email: 'mehmet@test.com',
        password: 'password123',
      );
      expect(reg2.success, false);
      expect(reg2.error, contains('zaten kullanılıyor'));

      final login = await auth.login(usernameOrEmail: 'ahmetyilmaz', password: 'password123');
      expect(login.success, true);
      expect(auth.isLoggedIn, true);
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
      expect(find.text('E-Posta Adresi'), findsOneWidget);

      final submitBtn = find.text('Hesap Oluştur ve Başla');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();
      expect(find.text('Ad Soyad alanı zorunludur.'), findsOneWidget);
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

      final startBtn = find.text('Testi Başlat & Kamerayı Aç');
      expect(startBtn, findsOneWidget);

      final buttonBefore = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(buttonBefore.onPressed, isNull);

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
}
