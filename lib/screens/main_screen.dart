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
  
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    if (user != null) {
      final userModel = await authService.getUserModel(user.uid);
      
      if (mounted) {
        if (userModel == null) {
          await authService.signOut();
          setState(() {
            _currentUser = null;
          });
        } else {
          setState(() {
            _currentUser = userModel;
          });
        }
      }
    } else {
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
      body: StreamBuilder<User?>(
        stream: Provider.of<AuthService>(context, listen: false).authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
             final firebaseUser = snapshot.data;
             
             if (firebaseUser == null && _currentUser != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if(mounted) setState(() => _currentUser = null);
                });
             }
             else if (firebaseUser != null && _currentUser == null) {
                _loadUser();
             }
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
            if (index == 0 && _currentIndex == 0) {
              _homeKey.currentState?.scrollToTop();
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

  // --- PROFİL EKRANI YÖNETİMİ (GÜNCELLENDİ) ---
  Widget _buildProfileScreen() {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    if (authService.currentUser == null) {
      return _buildGuestProfileView();
    }

    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final role = _currentUser!.role;

    // GÜNCELLEME: Admin ise direkt Dashboard'a atmıyoruz. 
    // Önce kendi profilini görsün, profilin içinden Dashboard'a gitsin.
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