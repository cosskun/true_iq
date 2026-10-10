import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  String? _usernameStatusText;
  bool? _isUsernameAvailable;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _checkUsername(String val) async {
    final clean = val.trim().toLowerCase();
    if (clean.length < 3) {
      setState(() {
        _isUsernameAvailable = null;
        _usernameStatusText = null;
      });
      return;
    }

    final authService = await AuthService.getInstance();
    final taken = authService.isUsernameTaken(clean);
    setState(() {
      _isUsernameAvailable = !taken;
      _usernameStatusText = taken
          ? '❌ Bu kullanıcı adı zaten alınmış!'
          : '✓ Kullanıcı adı müsait';
    });
  }

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Girdiğiniz şifreler birbiriyle eşleşmiyor.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authService = await AuthService.getInstance();
    final result = await authService.register(
      fullName: _fullNameController.text,
      username: _usernameController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hoş geldiniz, ${result.user?.fullName}! Kaydınız başarıyla oluşturuldu.'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = result.error ?? 'Kayıt sırasında bir hata oluştu.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo & Başlık
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.4)),
                      ),
                      child: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF818CF8), size: 36),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'Yeni Hesap Oluştur',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Center(
                    child: Text(
                      'Göz takipli güvenli IQ testlerine katılmak için bilgilerinizi giriniz.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 1. Ad Soyad
                  _buildInputLabel('Ad Soyad'),
                  TextFormField(
                    controller: _fullNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      hint: 'Örn: Ahmet Yılmaz',
                      prefixIcon: Icons.badge_outlined,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Ad Soyad alanı zorunludur.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 2. Kullanıcı Adı (Unique)
                  _buildInputLabel('Kullanıcı Adı (Benzersiz)'),
                  TextFormField(
                    controller: _usernameController,
                    onChanged: _checkUsername,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      hint: 'ahmetyilmaz',
                      prefixIcon: Icons.alternate_email,
                      suffixIcon: _isUsernameAvailable == null
                          ? null
                          : Icon(
                              _isUsernameAvailable! ? Icons.check_circle : Icons.cancel,
                              color: _isUsernameAvailable! ? const Color(0xFF10B981) : Colors.redAccent,
                            ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Kullanıcı adı alanı zorunludur.';
                      if (val.trim().length < 3) return 'Kullanıcı adı en az 3 karakter olmalıdır.';
                      if (_isUsernameAvailable == false) return 'Bu kullanıcı adı zaten alınmış!';
                      return null;
                    },
                  ),
                  if (_usernameStatusText != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _usernameStatusText!,
                      style: TextStyle(
                        color: _isUsernameAvailable == true ? const Color(0xFF10B981) : Colors.redAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // 3. E-posta
                  _buildInputLabel('E-Posta Adresi'),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      hint: 'ahmet@ornek.com',
                      prefixIcon: Icons.email_outlined,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'E-posta alanı zorunludur.';
                      if (!val.contains('@') || !val.contains('.')) return 'Geçerli bir e-posta giriniz.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 4. Şifre
                  _buildInputLabel('Şifre'),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      hint: '••••••••',
                      prefixIcon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: const Color(0xFF94A3B8),
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Şifre alanı zorunludur.';
                      if (val.length < 6) return 'Şifre en az 6 karakter olmalıdır.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 5. Şifre Tekrar
                  _buildInputLabel('Şifre Tekrarı'),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      hint: '••••••••',
                      prefixIcon: Icons.lock_clock_outlined,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                          color: const Color(0xFF94A3B8),
                        ),
                        onPressed: () =>
                            setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Şifre tekrarı zorunludur.';
                      return null;
                    },
                  ),

                  const SizedBox(height: 28),

                  // Kayıt Ol Butonu
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        disabledBackgroundColor: const Color(0xFF334155),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Text(
                              'Hesap Oluştur ve Başla',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Zaten Hesabım Var
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Zaten bir hesabınız var mı? ',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                      ),
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          'Giriş Yapın',
                          style: TextStyle(
                            color: Color(0xFF818CF8),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFE2E8F0),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
      filled: true,
      fillColor: const Color(0xFF1E293B),
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF818CF8), size: 20),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF334155)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }
}
