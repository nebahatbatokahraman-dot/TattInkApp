class AppConstants {
  // App Info
  static const String appName = 'TattInk';
  
  // User Roles
  static const String roleCustomer = 'customer';
  static const String roleArtistApproved = 'artist_approved';
  static const String roleArtistUnapproved = 'artist_unapproved';
  static const String roleAdmin = 'admin';
  
  // --- MASTER DATA: HİZMET VE STİL EŞLEŞTİRMESİ ---
  // Burası uygulamanın beynidir. 
  static const Map<String, List<String>> applicationStylesMap = {
    'Dövme': [
      'KAMPANYA','Realistik', 'Minimal', 'Old School', 'Tribal', 'Watercolor', 
      'Blackwork', 'Dotwork', 'Japanese', 'Neo Traditional', 'Portrait', 
      'Geometrik', 'Yazı', 'Fine Line', 'Cover Up', 'Abstract', 'Celtic',
      'Biyomekanik', 'Sketch'
    ],
    'Piercing': [
      'KAMPANYA', 'Kulak', 'Burun', 'Göbek', 'Dudak', 'Kaş', 'Dil', 
      'Endüstriyel', 'Hızma', 'Septum', 'Tragus', 'Helix', 'Implant'
    ],
    'Makyaj': [
      'KAMPANYA', 'Microblading', 'Dudak Renklendirme', 'Eyeliner', 
      'Dipliner', 'Kaş Pudralama'
    ],
    'Geçici Dövme': [
      'Hint Kınası', 'Airbrush', 'Spray', 'Sticker'
    ],
  };

  // --- DİNAMİK GETTERLAR (HATALARI ÇÖZEN KISIM) ---
  
  // 1. Uygulama Listesi
  static List<String> get applications => applicationStylesMap.keys.toList();

  // 2. TÜM STİLLER (Eski kodların 'AppConstants.styles' diyerek aradığı liste)
  // Haritadaki tüm stilleri tek bir listede birleştirir.
  static List<String> get styles => applicationStylesMap.values.expand((x) => x).toSet().toList();

  // -----------------------------------------------------------

  // Sort Options
  static const String sortNewest = 'en_yeniler';
  static const String sortDistance = 'mesafe';
  static const String sortArtistScore = 'artist_puanı';
  static const String sortPopular = 'popüler';
  static const String sortCampaigns = 'kampanyalar';
  
  // Firestore Collections
  static const String collectionUsers = 'users';
  static const String collectionPosts = 'posts';
  static const String collectionAppointments = 'appointments';
  static const String collectionMessages = 'messages';
  static const String collectionChats = 'chats';
  static const String collectionLikes = 'likes';
  static const String collectionFollows = 'follows';
  static const String collectionArtistApprovals = 'artist_approvals';
  static const String collectionNotifications = 'notifications';
  
  // Storage Paths
  static const String storageProfileImages = 'profile_images';
  static const String storageCoverImages = 'cover_images';
  static const String storagePostImages = 'post_images';
  static const String storagePostVideos = 'post_videos';
  static const String storagePortfolioImages = 'portfolio_images';
  static const String storageDocuments = 'documents';
  static const String storageAppImages = 'app_images';
  
  // Logo URL (Hata veren eksik değişken buydu)
  static const String logoUrl = 'https://firebasestorage.googleapis.com/v0/b/tattinkapp.firebasestorage.app/o/app_images%2Flogo.png?alt=media&token=b58cd8b2-e470-4d77-abca-b88540168eab';
  
  // Image Constraints
  static const int maxImageWidth = 1080;
  static const int maxImageHeight = 1080;
  static const int imageQuality = 85;
  
  // Rejection Reasons
  static const List<String> rejectionReasons = [
    'Belgeler eksik veya geçersiz',
    'Portfolyo yetersiz',
    'Bilgiler eksik veya hatalı',
    'Uygunsuz içerik',
    'Diğer',
  ];

  static const String geminiModelName = 'gemini-pro';
}