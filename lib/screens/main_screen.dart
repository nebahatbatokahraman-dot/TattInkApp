import 'dart:async'; // StreamSubscription için gerekli
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:provider/provider.dart';

// --- EKRANLAR ---
import 'home_screen.dart';
import 'studios_screen.dart';
import 'profile/customer_profile_screen.dart';
import 'profile/artist_profile_screen.dart';
import 'admin/admin_dashboard.dart';

// --- MODELLER VE SERVİSLER ---
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../widgets/login_required_dialog.dart';
import '../theme/app_theme.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  UserModel? _currentUser;
  StreamSubscription<User?>? _authSubscription; // Auth dinleyicisi
  
  // HomeScreen'in durumunu korumak için Key
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();

  @override
  void initState() {
    super.initState();
    _loadUser(); // İlk açılışta kullanıcıyı yükle
    _setupAuthListener(); // Dinleyiciyi başlat
  }

  // StreamBuilder yerine bu dinleyiciyi kullanıyoruz.
  // Bu sayede build metodu her seferinde tetiklenip sayfayı sıfırlamaz.
  void _setupAuthListener() {
    final authService = Provider.of<AuthService>(context, listen: false);
    _authSubscription = authService.authStateChanges.listen((User? firebaseUser) {
      if (firebaseUser == null) {
        // Çıkış yapıldıysa
        if (mounted) {
          setState(() {
            _currentUser = null;
          });
        }
      } else {
        // Giriş yapıldıysa veya kullanıcı değiştiyse veriyi güncelle
        _loadUser();
      }
    });
  }

  Future<void> _loadUser() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    if (user != null) {
      final userModel = await authService.getUserModel(user.uid);
      if (mounted) {
        setState(() {
          _currentUser = userModel;
        });
      }
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel(); // Hafıza sızıntısını önlemek için dinleyiciyi kapat
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ARTIK STREAMBUILDER YOK. IndexedStack doğrudan çalışıyor.
      // Bu sayede HomeScreen hafızada hep canlı kalıyor.
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // 1. Sayfa: HomeScreen (KeepAliveMixin sayesinde durumu korunacak)
          HomeScreen(key: _homeKey),
          
          // 2. Sayfa: Stüdyolar (Const olduğu için zaten sabit)
          const StudiosScreen(),
          
          // 3. Sayfa: Profil (Kullanıcı durumuna göre değişir)
          _buildProfileScreen(), 
        ],
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          // MainScreen.dart içindeki BottomNavigationBar -> onTap kısmı:
          onTap: (index) {

            // 1. Tıklamayı algılıyor mu?
            print("Tıklama Algılandı! Tıklanan: $index, Mevcut: $_currentIndex");

            if (index == 0 && _currentIndex == 0) {
              print("Çift tıklama koşulu sağlandı. Akıllı scroll/refresh tetikleniyor...");

              // HomeScreen'in scrollToTop fonksiyonunu çağır
              // Bu fonksiyon otomatik olarak scroll veya refresh yapar
              _homeKey.currentState?.scrollToTop();

              print("✅ Akıllı scroll/refresh tamamlandı!");
              return; // Erken çıkış yap
            }

            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Anasayfa'),
            BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Stüdyolar'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
          ],
        ),
      ),
    );
  }

  // --- PROFİL EKRANI YÖNETİMİ ---
  Widget _buildProfileScreen() {
    // Auth servisini buradan alıyoruz
    final authService = Provider.of<AuthService>(context, listen: false);
    
    // Firebase Auth tarafında kullanıcı yoksa Misafir göster
    if (authService.currentUser == null) {
      return _buildGuestProfileView();
    }

    // Kullanıcı var ama modeli henüz yüklenmediyse loading göster
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      );
    }

    final role = _currentUser!.role;

    if (role == 'admin' || role == 'customer') {
      return CustomerProfileScreen(userId: _currentUser!.uid);
    }
    
    return ArtistProfileScreen(userId: _currentUser!.uid, isOwnProfile: true);
  }

  Widget _buildGuestProfileView() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_circle_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Profilinizi görmek için giriş yapmalısınız.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _showLoginRequiredDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Giriş Yap / Kayıt Ol', style: TextStyle(color: AppTheme.textColor)),
            ),
          ],
        ),
      ),
    );
  }

  void _showLoginRequiredDialog(BuildContext context) {
    LoginRequiredDialog.show(context);
  }
}