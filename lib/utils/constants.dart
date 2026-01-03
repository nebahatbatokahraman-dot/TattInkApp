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
    'app_tattoo': [
      'style_campaign','style_realistic', 'style_minimal', 'style_old_school', 'style_tribal', 'style_watercolor',
      'style_blackwork', 'style_dotwork', 'style_japanese', 'style_neo_traditional', 'style_portrait',
      'style_geometric', 'style_script', 'style_fine_line', 'style_cover_up', 'style_abstract', 'style_celtic',
      'style_biomechanical', 'style_sketch'
    ],
    'app_piercing': [
      'style_campaign', 'style_ear', 'style_nose', 'style_navel', 'style_lip', 'style_eyebrow', 'style_tongue',
      'style_industrial', 'style_nipple', 'style_septum', 'style_tragus', 'style_helix', 'style_implant'
    ],
    'app_makeup': [
      'style_campaign', 'style_microblading', 'style_lip_tinting', 'style_eyeliner',
      'style_dipliner', 'style_eyebrow_powdering'
    ],
    'app_henna': [
      'style_henna', 'style_airbrush', 'style_spray', 'style_sticker'
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
    'reason_documents_missing',
    'reason_insufficient_portfolio',
    'reason_missing_info',
    'reason_inappropriate_content',
    'reason_other',
  ];

  static const String geminiModelName = 'gemini-pro';
}