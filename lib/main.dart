import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// --- EKLENEN EKSİK IMPORTLAR ---
import 'package:firebase_auth/firebase_auth.dart'; // User tipi için gerekli
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore ve DocumentSnapshot için gerekli
// -------------------------------

// Servis ve Provider Importları
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/main_screen.dart'; 
import 'screens/auth/login_screen.dart'; 
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/gemini_service.dart';
import 'config/gemini_config.dart';
import 'utils/constants.dart';
import 'language_provider.dart'; 
import 'app_localizations.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    String? token = await messaging.getToken();
    debugPrint("FCM Token: $token");
    
  } catch (e) {
    debugPrint("Firebase Başlatma Hatası: $e");
  }
  
  await initializeDateFormatting('tr_TR', null);
  
  final geminiApiKey = GeminiConfig.getApiKey();
  if (geminiApiKey != null && GeminiConfig.isValidApiKey(geminiApiKey)) {
    GeminiService.setApiKey(geminiApiKey);
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);

    return MaterialApp(
      title: 'TattInk',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,

      // Dil Ayarları
      locale: langProvider.appLocale,

      supportedLocales: const [
        Locale('en', 'US'),
        Locale('tr', 'TR'),
      ],

      localizationsDelegates: const [
        localizationsDelegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      localeResolutionCallback: (deviceLocale, supportedLocales) {
        if (langProvider.appLocale != null) {
          return langProvider.appLocale;
        }

        if (deviceLocale != null) {
          for (var supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == deviceLocale.languageCode) {
              return supportedLocale; 
            }
          }
        }
        return supportedLocales.first;
      },

      home: const SplashScreen(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _setupNotifications();
  }

  Future<void> _setupNotifications() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    if (user != null) {
      try {
        // Burada veritabanı kontrolü yapmıyoruz, sadece null değilse token alıyoruz
        // Veritabanı kontrolünü aşağıda build içinde yapacağız.
        final fcm = FirebaseMessaging.instance;
        await fcm.subscribeToTopic('all');
        // Rol bazlı abonelikler kullanıcı modeli çekilince yapılabilir, 
        // şimdilik basit tutuyoruz çökmemesi için.
      } catch (e) {
        debugPrint("Bildirim hatası: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // 1. Bağlantı bekleniyorsa
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // 2. Kullanıcı Giriş Yapmış Görünüyor mu?
        if (snapshot.hasData && snapshot.data != null) {
          // Firebase Auth kullanıcısı (User tipini kullanabilmek için import ekledik)
          final User firebaseUser = snapshot.data!;

          // GHOST USER KONTROLÜ: Veritabanında hala var mı?
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection(AppConstants.collectionUsers).doc(firebaseUser.uid).get(),
            builder: (context, userSnapshot) {
              
              // Veritabanı sorgusu sürerken loading
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              // Veri geldi ama doküman YOKSA (Silinmiş Hesap)
              if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                
                // HESABI ZORLA ÇIKIŞ YAPTIR (Frame bittikten sonra)
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  authService.signOut(); 
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Hesap bulunamadı veya silinmiş. Çıkış yapıldı.'), 
                      backgroundColor: Colors.red
                    ),
                  );
                });
                
                // O anlık yine de anasayfayı göster (zaten çıkış yapacak birazdan)
                return const MainScreen(); 
              }

              // Kullanıcı var ve geçerli, Anasayfaya devam et
              return const MainScreen();
            },
          );
        }
        
        // 3. Kullanıcı giriş yapmamış (Misafir Modu)
        return const MainScreen(); 
      },
    );
  }
}