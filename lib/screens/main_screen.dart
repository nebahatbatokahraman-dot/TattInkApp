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
import '../theme/app_theme.dart'; // Renkler için eklendi

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  UserModel? _currentUser;
  
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  // --- KULLANICI VERİSİNİ YÜKLEME ---
  Future<void> _loadUser() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    if (user != null) {
      // Kullanıcı Auth'da var, Firestore'dan detayını çekelim
      final userModel = await authService.getUserModel(user.uid);
      
      if (mounted) {
        if (userModel == null) {
          // KRİTİK DÜZELTME:
          // Eğer Auth'da kullanıcı var ama Firestore'da yoksa (silinmişse),
          // "Hayalet Kullanıcı" durumunu önlemek için çıkış yap.
          await authService.signOut();
          setState(() {
            _currentUser = null;
          });
        } else {
          // Kullanıcı ve verisi sağlam
          setState(() {
            _currentUser = userModel;
          });
        }
      }
    } else {
      // Kullanıcı zaten yok
      if (mounted) {
        setState(() {
          _currentUser = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Auth durumunu anlık dinliyoruz
      body: StreamBuilder<User?>(
        stream: Provider.of<AuthService>(context, listen: false).authStateChanges,
        builder: (context, snapshot) {
          
          // Eğer Stream'den gelen veri ile lokal veri uyuşmuyorsa güncelle
          if (snapshot.connectionState == ConnectionState.active) {
             final firebaseUser = snapshot.data;
             
             // Kullanıcı çıkış yaptıysa veya silindiyse lokal veriyi temizle
             if (firebaseUser == null && _currentUser != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if(mounted) setState(() => _currentUser = null);
                });
             }
             // Kullanıcı giriş yaptı ama henüz modeli yüklenmediyse yükle
             else if (firebaseUser != null && _currentUser == null) {
                // Tekrar tekrar çağırmamak için basit bir kontrol mekanizması eklenebilir
                // ama şimdilik _loadUser içindeki kontroller yeterli.
                _loadUser();
             }
          }

          return IndexedStack(
            index: _currentIndex,
            children: [
              HomeScreen(key: _homeKey),
              const StudiosScreen(),
              _buildProfileScreen(), // Profil mantığı burada
            ],
          );
        },
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            // Anasayfaya çift tıklama ile yukarı kaydırma
            if (index == 0 && _currentIndex == 0) {
              _homeKey.currentState?.scrollToTop();
            }

            // Profil sekmesine tıklayınca, eğer kullanıcı yoksa uyarı göster
            // AMA sayfayı değiştirmesine izin ver (Misafir ekranını görsün diye)
            // İstersen burada engelleyebilirsin ama misafir ekranı daha şık durur.
            /* if (index == 2) {
              final authService = Provider.of<AuthService>(context, listen: false);
              if (authService.currentUser == null) {
                _showLoginRequiredDialog(context);
                return; // Eğer bunu açarsan Profile hiç geçmez.
              }
            }
            */

            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Anasayfa',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.store),
              label: 'Stüdyolar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }

  // --- PROFİL EKRANI YÖNETİMİ ---
  Widget _buildProfileScreen() {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    // 1. Durum: Kullanıcı hiç giriş yapmamış
    if (authService.currentUser == null) {
      return _buildGuestProfileView(); // Yeni Misafir Ekranı
    }

    // 2. Durum: Kullanıcı var ama verisi (Firestore) henüz gelmedi (Loading)
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 3. Durum: Veri geldi, role göre yönlendir
    final role = _currentUser!.role;
    if (role == 'admin') return const AdminDashboard();
    if (role == 'customer') return CustomerProfileScreen(userId: _currentUser!.uid);
    
    // Varsayılan Artist
    return ArtistProfileScreen(userId: _currentUser!.uid, isOwnProfile: true);
  }

  // --- MİSAFİR KULLANICI EKRANI ---
  // Kullanıcı silindiğinde veya giriş yapmadığında boş ekran yerine bu çıkacak.
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
              child: const Text('Giriş Yap / Kayıt Ol', style: TextStyle(color: Colors.white)),
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