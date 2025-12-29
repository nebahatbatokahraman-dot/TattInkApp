import '../../theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/validators.dart';
import '../main_screen.dart';
// ÖNEMLİ: LegalDocumentsScreen importunu buraya eklemelisin
import '../settings/legal_documents_screen.dart'; 

class CustomerRegisterScreen extends StatefulWidget {
  const CustomerRegisterScreen({super.key});

  @override
  State<CustomerRegisterScreen> createState() => _CustomerRegisterScreenState();
}

class _CustomerRegisterScreenState extends State<CustomerRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  // --- HUKUKİ ONAY DEĞİŞKENİ ---
  bool _isTermsAccepted = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    // Kutucuk işaretli değilse işlem yapma (Güvenlik önlemi)
    if (!_isTermsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Devam etmek için kullanım şartlarını kabul etmelisiniz.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Şifreler eşleşmiyor'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.registerCustomer(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kayıt başarılı!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Müşteri Kaydı'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40), 
                const Text(
                  'Kayıt işlemini tamamlayarak uygulamayı keşfetmeye başlayabilirsin; ancak tüm özellikleri kullanabilmek için e-posta adresini doğrulaman gerekiyor.',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-posta',
                    hintText: 'ornek@eposta.com',
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: Validators.validateEmail,
                ),
                const SizedBox(height: 16),
                
                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Şifre',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: Validators.validatePassword,
                ),
                const SizedBox(height: 16),
                
                // Confirm password field
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Şifre Tekrar',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Şifre tekrar gereklidir';
                    if (value != _passwordController.text) return 'Şifreler eşleşmiyor';
                    return null;
                  },
                ),
                
                const SizedBox(height: 24),

                // --- HUKUKİ ONAY KUTUCUĞU ---
                Row(
                  children: [
                    Checkbox(
                      value: _isTermsAccepted,
                      activeColor: AppTheme.primaryColor,
                      onChanged: (val) => setState(() => _isTermsAccepted = val ?? false),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LegalDocumentsScreen()),
                          );
                        },
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                            children: [
                              const TextSpan(text: "Kullanım Şartları ve Sağlık Sorumluluk Reddini "),
                              TextSpan(
                                text: "okudum, kabul ediyorum.",
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Register button
                ElevatedButton(
                  // Şartlar kabul edilmediyse buton pasif (null) olur
                  onPressed: (_isLoading || !_isTermsAccepted) ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isTermsAccepted ? AppTheme.primaryColor : Colors.grey[800],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Üye Ol', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}