import 'package:flutter/material.dart';
import 'customer_register_screen.dart';
import 'artist_register_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        elevation: 0, // Daha temiz bir görünüm için eklenebilir
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // LOGO
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
                const Text(
                  'Hesap Türü Seçin',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                
                // Customer register button
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CustomerRegisterScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Müşteri Olarak Üye Ol'),
                ),
                const SizedBox(height: 16),
                
                // Artist register button
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ArtistRegisterScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Artist Olarak Üye Ol'),
                ),
                
                // İÇERİĞİ YUKARI KAYDIRAN BOŞLUK
                // MainAxisAlignment.center ile Center içinde olduğu için 
                // alta eklenen bu boşluk tüm içeriği 100px yukarı iter.
                const SizedBox(height: 150), 
              ],
            ),
          ),
        ),
      ),
    );
  }
}