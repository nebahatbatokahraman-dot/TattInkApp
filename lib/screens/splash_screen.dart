import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
// Firestore importunu kaldırdım çünkü artık bu sayfada kullanılmıyor
import 'package:tattink_app/main.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import 'appointments_screen.dart';
import 'auth/login_screen.dart'; 
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // --- LOGO ANİMASYONU ---
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // --- 3 SANİYE SONRA YÖNLENDİR ---
    Timer(const Duration(seconds: 3), () {
      _checkStatusAndNavigate();
    });
  }

  Future<void> _checkStatusAndNavigate() async {
    if (mounted) {
        Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthWrapper()), 
        );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                // --- PARLAKLIK EKLENMİŞ LOGO ALANI ---
                Container(
                height: 200, 
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                    BoxShadow(
                        color: AppTheme.cardLightColor.withOpacity(0.9), 
                        blurRadius: 90, 
                        spreadRadius: 8, 
                    ),
                    ],
                ),
                child: CachedNetworkImage(
                    imageUrl: "https://firebasestorage.googleapis.com/v0/b/tattinkapp.firebasestorage.app/o/app_images%2Flogo.png?alt=media&token=b58cd8b2-e470-4d77-abca-b88540168eab",
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryColor),
                    ),
                    errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.grey),
                ),
                ),
              
              const SizedBox(height: 80),
              
              // --- ALT YÜKLENİYOR İNDİKATÖRÜ ---
              const SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                  strokeWidth: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}