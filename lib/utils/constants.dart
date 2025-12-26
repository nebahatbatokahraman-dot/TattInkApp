class AppConstants {
  // App Info
  static const String appName = 'TattInk';
  
  // User Roles
  static const String roleCustomer = 'customer';
  static const String roleArtistApproved = 'artist_approved';
  static const String roleArtistUnapproved = 'artist_unapproved';
  static const String roleAdmin = 'admin';
  
  // Service Types (Eski sabitler - Kod içinde kıyaslama yaparken lazım olabilir)
  static const String serviceTattoo = 'dövme';
  static const String servicePiercing = 'piercing';
  static const String serviceTemporaryTattoo = 'geçici_dövme';
  static const String serviceMakeup = 'makyaj';
  static const String serviceKina = 'kına';
  static const String serviceImplant = 'implant';
  

  // --- YENİ EKLENEN MASTER LİSTELER (Filtre ve Profil İçin) ---
  // Artistin seçebileceği ve müşterinin filtreleyebileceği ana liste
  static const List<String> applications = [
    'Dövme',
    'Piercing',
    'Geçici dövme',
    'Makyaj',
    'Kına',
    'Implant',
  ];

  static const List<String> styles = [
    'KAMPANYA',
    'Minimalist',
    'Dotwork',
    'Realist',
    'Tribal',
    'Blackwork',
    'Watercolor',
    'Trash Polka',
    'Fine Line',
    'Traditional',
    'Cover up',
    'Linework',
    'Abstract',
    'Celtic',
    'Text',
  ];
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
  
  // Logo URL
  static const String logoUrl = 'https://firebasestorage.googleapis.com/v0/b/tattinkapp.firebasestorage.app/o/app_images%2Flogo.png?alt=media';
  
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
}