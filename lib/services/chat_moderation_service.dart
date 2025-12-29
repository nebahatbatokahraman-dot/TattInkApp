/// Chat Mesaj Moderasyon Servisi
/// 
/// Hızlı, temel filtreleme için kullanılır.
/// AI filtreleme için GeminiService kullanılmalıdır.
class ChatModerationService {
  // Engelenecek kelimeler veya desenler
  static const List<String> _forbiddenKeywords = [
    // Küfürler (genişletilmiş liste)
    'ibn', 'p*ç', 's*ktir', 'amk', 'orospu', 'piç', 'sürtük', 'yarrak', 'sikerim',
    'fuck', 'shit', 'bitch', 'asshole', 'damn', 'bastard', 'motherfucker',
    'ananı', 'babanı', 'bacını', 'kahpe', 'fahişe', 'göt', 'yarak',
    // Dış bağlantılar ve iletişim bilgileri
    'instagram.com', 'ig:', '@gmail', '@hotmail', '@yahoo',
    'www.', 'http://', 'https://', 'iban',
    // Spam desenleri
    'kazan', 'bedava', 'ücretsiz', 'tıkla', 'şimdi tıkla',
  ];

  // Kritik ihlaller - mesajı direkt engelle
  static const List<String> _criticalKeywords = [
    // Çok ağır küfürler - direkt engelle
    'ananı sikeyim', 'babanı sikeyim', 'bacını sikeyim', 'sikeyim seni',
    'motherfucker', 'son of a bitch', 'go fuck yourself',
    'öl', 'geber', 'kır', 'dövdürürüm', 'tehdit', 'şantaj',
  ];

  // Telefon numaralarını yakalamak için Regex (05xx... gibi)
  static final RegExp _phoneRegex = RegExp(r'(0\s?5[0-9]{2}\s?[0-9]{3}\s?[0-9]{2}\s?[0-9]{2})|([0-9]{10,11})');

  // Email regex
  static final RegExp _emailRegex = RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b');

  /// Mesajı temel filtreleme ile temizle
  /// 
  /// Bu metod hızlı, temel filtreleme yapar.
  /// Daha kapsamlı analiz için GeminiService.analyzeChatMessage() kullanılmalıdır.
  static String filterMessage(String text) {
    String cleanText = text;

    // 1. Telefon Numarası Kontrolü
    if (_phoneRegex.hasMatch(cleanText)) {
      cleanText = cleanText.replaceAll(_phoneRegex, "[İletişim bilgisi gizlendi]");
    }

    // 2. Email Kontrolü
    if (_emailRegex.hasMatch(cleanText)) {
      cleanText = cleanText.replaceAll(_emailRegex, "[Email gizlendi]");
    }

    // 3. Kelime Bazlı Filtreleme
    for (var word in _forbiddenKeywords) {
      if (cleanText.toLowerCase().contains(word.toLowerCase())) {
        // Kelimeyi yıldızla
        cleanText = cleanText.replaceAll(
          RegExp(word, caseSensitive: false), 
          "*" * word.length
        );
      }
    }

    return cleanText;
  }
  
  /// Mesajda kritik ihlal var mı kontrol et
  /// 
  /// Eğer mesajda çok ağır bir ihlal varsa gönderimi tamamen durdurur.
  /// Returns: true ise mesaj gönderilmemeli
  static bool isMessageViolating(String text) {
    final lowerText = text.toLowerCase();
    
    // Kritik kelimeler kontrolü
    for (var keyword in _criticalKeywords) {
      if (lowerText.contains(keyword.toLowerCase())) {
        return true;
      }
    }
    
    // Çok fazla yasaklı kelime varsa
    int violationCount = 0;
    for (var keyword in _forbiddenKeywords) {
      if (lowerText.contains(keyword.toLowerCase())) {
        violationCount++;
      }
    }
    
    // 3'ten fazla yasaklı kelime varsa engelle
    if (violationCount > 3) {
      return true;
    }
    
    return false; 
  }
  
  /// Mesajın uzunluğunu kontrol et (spam önleme)
  static bool isMessageTooLong(String text) {
    // 1000 karakterden uzun mesajlar spam olabilir
    return text.length > 300;
  }
  
  /// Mesajın çok kısa olup olmadığını kontrol et (spam önleme)
  static bool isMessageTooShort(String text) {
    // 1 karakterden kısa mesajlar geçersiz
    return text.trim().length < 1;
  }
}