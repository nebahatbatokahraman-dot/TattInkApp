import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // <--- EKLENDİ

import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/main_screen.dart';
import 'screens/auth/login_screen.dart';
import 'services/auth_service.dart';
import 'services/gemini_service.dart';
import 'config/gemini_config.dart';
import 'utils/constants.dart'; // <--- Rolleri kontrol etmek için eklendi

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Bildirim izinlerini iste (Uygulama ilk açıldığında sorar)
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  
  await initializeDateFormatting('tr_TR', null);
  
  // Gemini AI servisini initialize et
  final geminiApiKey = GeminiConfig.getApiKey();
  if (geminiApiKey != null && GeminiConfig.isValidApiKey(geminiApiKey)) {
    GeminiService.setApiKey(geminiApiKey);
    print('Gemini AI servisi başlatıldı');
  } else {
    print('UYARI: Gemini API anahtarı bulunamadı veya geçersiz. AI filtreleme çalışmayacak.');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(
          create: (_) => AuthService(),
        ),
      ],
      child: MaterialApp(
        title: 'TattInk',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        supportedLocales: const [
          Locale('tr', 'TR'),
          Locale('en', 'US'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        locale: const Locale('tr', 'TR'),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget { // StatelessWidget'tan StatefulWidget'a çevirdik
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  
  @override
  void initState() {
    super.initState();
    // Uygulama açılır açılmaz bildirim aboneliklerini ayarla
    _setupNotifications();
  }

  Future<void> _setupNotifications() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    if (user != null) {
      // Kullanıcı modelini çekip rolüne bakalım
      final userModel = await authService.getUserModel(user.uid);
      if (userModel != null) {
        final fcm = FirebaseMessaging.instance;
        
        // 1. Herkes 'all' grubuna üye olur
        await fcm.subscribeToTopic('all');

        // 2. Rolüne göre özel gruba dahil et
        if (userModel.role == AppConstants.roleAdmin) {
          await fcm.subscribeToTopic('admins');
        } else if (userModel.role == AppConstants.roleArtistApproved || userModel.role == 'artist') {
          await fcm.subscribeToTopic('artists');
        } else {
          await fcm.subscribeToTopic('customers');
        }
        print("Bildirim aboneliği tamamlandı: ${userModel.role}");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mevcut mantığın: Uygulama direkt MainScreen'e gidiyor
    return const MainScreen();
  }
}