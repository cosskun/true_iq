import '../models/test_attempt.dart';
import '../models/question.dart';

/// Firebase Firestore ve Cloud Functions Entegrasyon Köprüsü
/// Bu servis, Firebase projesi eklendiğinde bulut senkronizasyonunu yönetir.
class FirebaseService {
  static final FirebaseService instance = FirebaseService._();
  FirebaseService._();

  bool _isFirebaseInitialized = false;
  bool get isInitialized => _isFirebaseInitialized;

  /// Firebase başlatma durumu (google-services.json / GoogleService-Info.plist)
  Future<void> initialize() async {
    // Firebase.initializeApp() çağrısı buraya bağlanabilir
    _isFirebaseInitialized = false; // Varsayılan olarak lokal/hızlı mod
  }

  /// Sınav girişimini Firestore 'test_attempts' koleksiyonuna yazar
  Future<void> syncAttemptToCloud(String userId, TestAttempt attempt) async {
    if (!_isFirebaseInitialized) {
      // Firebase aktif değilken lokal veri saklanır
      return;
    }
    // Örnek Firestore yazma yapısı:
    // await FirebaseFirestore.instance
    //     .collection('users')
    //     .doc(userId)
    //     .collection('attempts')
    //     .doc(attempt.id)
    //     .set(attempt.toJson());
  }

  /// Soru havuzunu Firestore'dan dinamik olarak indirmek için kullanılır
  Future<List<Question>> fetchCloudQuestions(String testId) async {
    if (!_isFirebaseInitialized) return [];
    // Firestore'dan çekme mantığı
    return [];
  }
}
