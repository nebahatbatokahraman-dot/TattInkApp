import 'package:google_generative_ai/google_generative_ai.dart';
import '../theme/app_theme.dart';

class GeminiService {
  static String? _apiKey;
  static GenerativeModel? _model;

  // Uygulama başlarken API Key'i buradan yüklüyoruz
  static void setApiKey(String apiKey) {
    _apiKey = apiKey;
    _model = GenerativeModel(
      model: 'gemini-1.5-flash', // Hızlı ve ekonomik olduğu için moderasyonda en iyisidir
      apiKey: _apiKey!,
    );
  }

  // Mesajı kontrol eden ve temizleyen ana fonksiyon
  static Future<String> filterMessage(String message) async {
    if (_apiKey == null || _model == null) return message;

    // AI'ya verdiğimiz görev talimatı
    final prompt = '''
    Sen TattInk uygulamasının katı bir moderatörüsün. Kullanıcı mesajını incele ve ŞU KURALLARI TAVİZSİZ UYGULA:
    
    1. Mesajda telefon numarası (05xx, +90 vb.), IBAN, Instagram kullanıcı adı (@... veya 'instagram: ...') veya e-posta adresi varsa bu kısımları "[İletişim bilgisi gizlendi]" olarak değiştir.
    2. Mesajda ağır küfür, hakaret, argo (piç, amk, vb.) veya saldırganlık varsa SADECE "[YASAKLI İÇERİK]" döndür.
    3. Eğer mesaj temizse, hiçbir şeyi değiştirmeden orijinal mesajı aynen döndür.
    
    Mesaj: "$message"
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      
      // AI'dan gelen cevabı alıyoruz, hata olursa orijinal mesajı yolluyoruz
      return response.text?.trim() ?? message;
    } catch (e) {
      print("AI Filtre Hatası: $e");
      return message; // Hata durumunda (internet vs.) mesajı olduğu gibi gönderiyoruz
    }
  }
}