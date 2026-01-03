import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/auth_service.dart';
import '../../utils/validators.dart';
import '../../theme/app_theme.dart';
import '../main_screen.dart';
import 'register_screen.dart';
import '../../app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.translate('login_error')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- GOOGLE İLE GİRİŞ FONKSİYONU (GÜNCELLENDİ) ---
  Future<void> _loginWithGoogle() async {
    // 1. Durumu güncelle
    setState(() => _isLoading = true);
    debugPrint("🔵 [DEBUG] Google Login Butonuna Basıldı...");

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      debugPrint("🟡 [DEBUG] AuthService.signInWithGoogle() çağrılıyor...");
      
      // 2. AuthService üzerinden girişi başlat
      final user = await authService.signInWithGoogle().timeout(
        const Duration(seconds: 45), // 45 saniye sonra otomatik hata fırlat (donmayı engellemek için)
        onTimeout: () {
          debugPrint("🔴 [DEBUG] Google Login Zaman Aşımına Uğradı!");
          throw "Bağlantı zaman aşımına uğradı. Lütfen internetinizi veya yapılandırmanızı kontrol edin.";
        },
      );
      
      debugPrint("🟢 [DEBUG] İşlem Tamamlandı. Gelen Kullanıcı: ${user?.uid}");

      if (user != null && mounted) {
         debugPrint("🚀 [DEBUG] Giriş Başarılı, MainScreen'e yönlendiriliyor...");
         if (!mounted) return;
         Navigator.of(context).pushAndRemoveUntil(
           MaterialPageRoute(builder: (context) => const MainScreen()),
           (route) => false,
         );
      } else {
        debugPrint("⚠️ [DEBUG] Kullanıcı null döndü (Giriş iptal edilmiş olabilir).");
      }
    } catch (e) {
      debugPrint("❌ [DEBUG] Google Giriş Hatası Yakalandı: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.translate('google_login_error')}: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint("🏁 [DEBUG] Loading Durumu: false");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: CachedNetworkImage(
                        imageUrl: "https://firebasestorage.googleapis.com/v0/b/tattinkapp.firebasestorage.app/o/app_images%2Flogo.png?alt=media&token=b58cd8b2-e470-4d77-abca-b88540168eab",
                        height: 40,
                        placeholder: (context, url) => const CircularProgressIndicator(),
                        errorWidget: (context, url, error) => const Icon(Icons.brush, size: 50),
                      ),
                    ),
                  ),
                  // Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: AppTheme.textColor),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.translate('email'),
                      prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[800]!),
                      ),
                    ),
                    validator: Validators.validateEmail,
                  ),
                  const SizedBox(height: 16),

                  // Şifre
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: AppTheme.textColor),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.translate('password'),
                      prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: Colors.grey,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[800]!),
                      ),
                    ),
                    validator: Validators.validatePassword,
                  ),
                  
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: Text(AppLocalizations.of(context)!.translate('forgot_password'), style: const TextStyle(color: Colors.grey)),
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  // Giriş Yap Butonu
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.textColor),
                          )
                        : Text(
                            AppLocalizations.of(context)!.translate('login'),
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textColor),
                          ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[800])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(AppLocalizations.of(context)!.translate('or'), style: const TextStyle(color: Colors.grey)),
                      ),
                      Expanded(child: Divider(color: Colors.grey[800])),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // --- GOOGLE BUTONU ---
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _loginWithGoogle,
                      icon: const Icon(Icons.g_mobiledata, color: AppTheme.textColor, size: 24),
                      label: Text(
                        AppLocalizations.of(context)!.translate('continue_with_google'),
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textColor),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.textColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        foregroundColor: AppTheme.textColor,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Kayıt Ol Linki
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.translate('dont_have_account'),
                        style: TextStyle(color: Colors.grey),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RegisterScreen()),
                          );
                        },
                        child: Text(
                          AppLocalizations.of(context)!.translate('register_link'),
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    AppLocalizations.of(context)!.translate('artist_profile_instruction'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),  
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}