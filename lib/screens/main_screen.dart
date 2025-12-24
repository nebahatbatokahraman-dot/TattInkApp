import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // FirebaseAuth eklendi
import 'home_screen.dart';
import 'studios_screen.dart';
import 'profile/customer_profile_screen.dart';
import 'profile/artist_profile_screen.dart';
import 'admin/admin_dashboard.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../widgets/login_required_dialog.dart';
import 'package:provider/provider.dart';

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

  // Kullanıcı değiştiğinde modeli tekrar yükle (Giriş yaptıktan sonra profilin açılması için)
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
    } else {
      setState(() {
        _currentUser = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // StreamBuilder ile oturum durumunu dinliyoruz
      body: StreamBuilder<User?>(
        stream: Provider.of<AuthService>(context, listen: false).authStateChanges,
        builder: (context, snapshot) {
          // Oturum durumu değiştiğinde kullanıcı modelini güncelle
          if (snapshot.hasData && _currentUser == null) {
            _loadUser();
          } else if (!snapshot.hasData && _currentUser != null) {
            _currentUser = null;
          }

          return IndexedStack(
            index: _currentIndex,
            children: [
              HomeScreen(key: _homeKey),
              const StudiosScreen(),
              _buildProfileScreen(),
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

            // Profil sekmesine tıklandığında giriş kontrolü
            if (index == 2) {
              final authService = Provider.of<AuthService>(context, listen: false);
              if (authService.currentUser == null) {
                // Giriş yoksa uyarıyı göster ve sekme değiştirme
                _showLoginRequiredDialog(context);
                return;
              }
            }

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

  Widget _buildProfileScreen() {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    // Eğer kullanıcı giriş yapmamışsa boş bir placeholder gösteriyoruz
    // (Zaten BottomNavigationBar engelliyor ama güvenlik için IndexedStack'te bulunmalı)
    if (authService.currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Profilinizi görmek için lütfen giriş yapın.'),
        ),
      );
    }

    // Model yüklenirken beklet
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Role göre yönlendirme
    final role = _currentUser!.role;
    if (role == 'admin') return const AdminDashboard();
    if (role == 'customer') return CustomerProfileScreen(userId: _currentUser!.uid);
    return ArtistProfileScreen(userId: _currentUser!.uid, isOwnProfile: true);
  }

  void _showLoginRequiredDialog(BuildContext context) {
    LoginRequiredDialog.show(context);
  }
}