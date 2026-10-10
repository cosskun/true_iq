# 🧠 TrueIQ - Veritabanı ve Kurulum Rehberi

Bu rehber, **TrueIQ** uygulamasının mimarisini, veritabanı (Firebase / Supabase) kurulum adımlarını ve mobil izin yapılandırmasını içerir.

---

## 🏗️ 1. Veritabanı Mimarisi ve Tablo / Koleksiyon Yapısı

Veritabanında **5 ana koleksiyon (tablo)** yer almaktadır:

### A. `users` (Kullanıcılar)
```json
{
  "id": "user_1710000000",
  "fullName": "Ahmet Yılmaz",
  "username": "ahmetyilmaz",
  "email": "ahmet@ornek.com",
  "createdAt": "2026-10-09T10:00:00Z"
}
```

### B. `tests` (Test Tanımları)
```json
{
  "testId": "test_standard_iq",
  "title": "Genel Bilişsel IQ Testi",
  "subtitle": "Standart Raven & Mantıksal Yetenek Ölçeği",
  "durationMinutes": 20,
  "totalQuestionsPerSession": 15,
  "maxFailureAttempts": 3
}
```

### C. `questions` (Soru Havuzu)
```json
{
  "id": "num_01",
  "testId": "test_standard_iq",
  "category": "numberSequences",
  "type": "multipleChoiceText",
  "prompt": "3, 7, 15, 31, 63, ?",
  "options": ["127", "126", "125", "129"],
  "correctOptionIndex": 0,
  "explanation": "Her terim bir öncekinin 2 katının 1 fazlasıdır (x * 2 + 1).",
  "difficultyLevel": 2
}
```

### D. `user_seen_questions` (Görülen Sorular - Tekrarı Engelleme)
```json
{
  "userId": "user_1710000000",
  "testId": "test_standard_iq",
  "seenQuestionIds": ["num_01", "logic_02", "verb_03", "matrix_01"]
}
```

### E. `test_attempts` (Sınav Girişimleri, Haklar ve Sertifikalar)
```json
{
  "id": "att_1710000000",
  "userId": "user_1710000000",
  "testId": "test_standard_iq",
  "attemptNumber": 1,
  "status": "completedSuccess",
  "calculatedIq": 136,
  "percentile": 98.2,
  "cognitiveProfile": "Üstün Mantık & Soyut Muhakeme Uzmanı",
  "startedAt": "2026-10-09T10:00:00Z",
  "finishedAt": "2026-10-09T10:18:30Z",
  "correctAnswers": 14,
  "totalQuestions": 15
}
```

---

## 🔥 2. Firebase Kurulumu (Adım Adım)

1. [Firebase Console](https://console.firebase.google.com/) adresine gidin ve **TrueIQ** adında yeni bir proje oluşturun.
2. **Firestore Database** sekmesinden yeni bir veritabanı oluşturun.
3. Terminalde FlutterFire CLI aracını yükleyin:
   ```bash
   dart pub global activate flutterfire_cli
   ```
4. Proje dizininde (`C:\Users\Developer6\.gemini\Project\true_iq`) komutu çalıştırarak Firebase'i bağlayın:
   ```bash
   flutterfire configure
   ```

---

## 🚀 3. Uygulamayı Başlatma

Klasör içerisindeki **`baslat.bat`** dosyasına çift tıklayarak uygulamayı anında tarayıcıda çalıştırabilir ve göz takibi / sınav akışını test edebilirsiniz.
