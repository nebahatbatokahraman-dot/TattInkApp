import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme/app_theme.dart';

class PaymentWebView extends StatefulWidget {
  final String url;
  final VoidCallback onPaymentComplete;

  const PaymentWebView({super.key, required this.url, required this.onPaymentComplete});

  @override
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
            
            // Gerçek Shopier linkin olduğunda burası çalışacak
            if (url.contains('success') || url.contains('thanks') || url.contains('confirm')) {
              widget.onPaymentComplete(); 
              Navigator.pop(context);
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView Hatası: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cardColor,
      appBar: AppBar(
        title: Column(
            children: [
            const Text("Güvenli Ödeme Alt Yapısı", style: TextStyle(fontSize: 14, color: Colors.white)),
            Text("Shopier ile korunmaktadır", style: TextStyle(fontSize: 10, color: Colors.grey[400])),
            ],
        ),
        centerTitle: true,
        backgroundColor: AppTheme.backgroundColor, 
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 18),
            onPressed: () => Navigator.pop(context),
        ),
     ),
      body: Column( // Stack yerine Column kullanarak alta buton ekledik
        children: [
          Expanded(
            child: Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_isLoading)
                const LinearProgressIndicator(
                    backgroundColor: AppTheme.primaryColor,
                    color: Colors.amber,
                    minHeight: 2,
                ),
              ],
            ),
          ),
          
          // --- TEST BUTONU (Gerçek Shopier linkin gelene kadar kullan) ---
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.backgroundColor,
            child: Column(
              children: [
                const Text(
                  "Ödemeyi tamamladıktan sonra butona basınız",
                  style: TextStyle(color: AppTheme.primaryColor, fontSize: 12),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      // Bu buton ödeme yapılmış gibi davranır
                      widget.onPaymentComplete(); 
                      Navigator.pop(context);
                    },
                    child: const Text("ÖDEMEYİ ONAYLA", 
                      style: TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}