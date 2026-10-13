import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  static AuthService? _instance;
  static SharedPreferences? _prefs;
  UserModel? _currentUser;

  AuthService._();

  static Future<AuthService> getInstance() async {
    if (_instance == null) {
      _instance = AuthService._();
      _prefs = await SharedPreferences.getInstance();
      await _instance!._loadCurrentSession();
    }
    return _instance!;
  }

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  Future<void> _loadCurrentSession() async {
    final currentJson = _prefs?.getString('current_session_user');
    if (currentJson != null) {
      try {
        _currentUser = UserModel.fromJson(jsonDecode(currentJson));
      } catch (_) {
        _currentUser = null;
      }
    }
  }

  /// Tüm kayıtlı kullanıcıları getirir
  List<UserModel> getAllUsers() {
    final list = _prefs?.getStringList('registered_users') ?? [];
    return list.map((str) {
      try {
        return UserModel.fromJson(jsonDecode(str));
      } catch (_) {
        return null;
      }
    }).whereType<UserModel>().toList();
  }

  /// Kullanıcı adının daha önce alınıp alınmadığını kontrol eder (Büyük/Küçük harf duyarsız - Unique)
  bool isUsernameTaken(String username) {
    final normalized = username.trim().toLowerCase();
    final users = getAllUsers();
    return users.any((u) => u.username.trim().toLowerCase() == normalized);
  }

  /// E-posta adresinin daha önce alınıp alınmadığını kontrol eder
  bool isEmailTaken(String email) {
    final normalized = email.trim().toLowerCase();
    final users = getAllUsers();
    return users.any((u) => u.email.trim().toLowerCase() == normalized);
  }

  /// Yeni kullanıcı kaydı oluşturur
  Future<({bool success, String? error, UserModel? user})> register({
    required String fullName,
    required String username,
    required String email,
    required String password,
  }) async {
    final cleanUsername = username.trim().toLowerCase();
    final cleanEmail = email.trim().toLowerCase();

    if (cleanUsername.isEmpty || cleanEmail.isEmpty || fullName.trim().isEmpty || password.isEmpty) {
      return (success: false, error: 'Lütfen tüm alanları doldurunuz.', user: null);
    }

    if (cleanUsername.length < 3) {
      return (success: false, error: 'Kullanıcı adı en az 3 karakter olmalıdır.', user: null);
    }

    // Unique Kullanıcı Adı Kontrolü
    if (isUsernameTaken(cleanUsername)) {
      return (
        success: false,
        error: 'Bu kullanıcı adı (@$cleanUsername) zaten kullanılıyor. Lütfen başka bir kullanıcı adı seçiniz.',
        user: null
      );
    }

    // Unique E-posta Kontrolü
    if (isEmailTaken(cleanEmail)) {
      return (
        success: false,
        error: 'Bu e-posta adresi ile kayıtlı bir hesap zaten mevcut.',
        user: null
      );
    }

    final newUser = UserModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      fullName: fullName.trim(),
      email: cleanEmail,
      username: cleanUsername,
      password: password,
      createdAt: DateTime.now(),
    );

    // Listeye kaydet
    final users = getAllUsers();
    users.add(newUser);
    final usersJsonList = users.map((u) => jsonEncode(u.toJson())).toList();
    await _prefs?.setStringList('registered_users', usersJsonList);

    // Kayıt sonrası otomatik oturum açılmıyor, kullanıcı manuel giriş yapmalıdır
    return (success: true, error: null, user: newUser);
  }

  /// Giriş Yap (Kullanıcı Adı veya E-Posta + Şifre ile)
  Future<({bool success, String? error, UserModel? user})> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    final identifier = usernameOrEmail.trim().toLowerCase();
    if (identifier.isEmpty || password.isEmpty) {
      return (success: false, error: 'Kullanıcı adı/e-posta ve şifre gereklidir.', user: null);
    }

    final users = getAllUsers();
    try {
      final user = users.firstWhere(
        (u) =>
            (u.username.toLowerCase() == identifier || u.email.toLowerCase() == identifier) &&
            u.password == password,
      );

      _currentUser = user;
      await _prefs?.setString('current_session_user', jsonEncode(user.toJson()));
      return (success: true, error: null, user: user);
    } catch (_) {
      return (
        success: false,
        error: 'Kullanıcı adı/e-posta veya şifre hatalı.',
        user: null,
      );
    }
  }

  /// Oturumu Kapat
  Future<void> logout() async {
    _currentUser = null;
    await _prefs?.remove('current_session_user');
  }
}
