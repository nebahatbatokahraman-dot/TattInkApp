import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  // Static method for getting localized strings without BuildContext (useful for debug messages)
  static String getLocalizedString(String key, String localeCode) {
    return _localizedValues[localeCode]?[key] ?? key;
  }

  static const Map<String, Map<String, String>> _localizedValues = {
  'en': {
    // Ayarlar & Genel
    'settings': 'Settings',
    'account': 'Account',
    'profile_info': 'Profile Information',
    'profile_info_sub': 'Edit name, surname and photo',
    'email_password': 'Email and Password',
    'email_password_sub': 'Change your email and password',
    'preferences': 'Preferences',
    'notifications': 'Notifications',
    'notifications_sub': 'Manage notification settings',
    'language': 'Language',
    'language_sub': 'Choose app language',
    'privacy': 'Privacy',
    'blocked_users': 'Blocked Users',
    'blocked_users_sub': 'Manage people you blocked',
    'support': 'Support',
    'help': 'Help',
    'help_sub': 'FAQ and help',
    'legal': 'Legal Documents',
    'legal_sub': 'Terms and privacy policy',
    'logout': 'Logout',
    'logout_confirm': 'Are you sure you want to logout?',
    'save': 'Save',
    'error': 'Error',
    'delete_account': 'Delete My Account',
    'delete_account_sub': 'All your data will be permanently removed',
    'delete_account_warning': 'Are you sure? This action cannot be undone and all your profile data will be lost.',
    'delete_permanently': 'Yes, Delete Permanently',
    'relogin_required': 'For security reasons, you must log in again before this action.',

    // Profil Düzenleme (Ortak & Sanatçı & Müşteri)
    'edit_profile': 'Edit Profile',
    'profile_info_title': 'Profile Information',
    'first_name': 'First Name',
    'last_name': 'Last Name',
    'studio_name': 'Studio Name',
    'biography': 'Biography',
    'address_detail': 'Detailed Address',
    'city': 'City',
    'district': 'District',
    'services': 'Services',
    'select_service_to_see_styles': 'Select a service above to see styles.',
    'styles_title': 'Styles',
    'save_changes': 'Save Changes',
    'profile_updated': 'Profile updated!',
    'profile_updated_success': 'Profile updated successfully!',
    'error_picking_image': 'Error picking image',
    'update_error': 'Error during update',

    // Email & Şifre Değiştirme
    'email_password_title': 'Email and Password',
    'change_email': 'Change Email',
    'new_email': 'New Email',
    'email_same_error': 'New email cannot be the same as current email',
    'email_update_success': 'Email updated successfully',
    'email_change_error': 'Error changing email',
    'change_password': 'Change Password',
    'current_password': 'Current Password',
    'new_password': 'New Password',
    'confirm_new_password': 'Confirm New Password',
    'password_update_success': 'Password updated successfully',
    'password_change_error': 'Error changing password',
    'wrong_password_error': 'Current password is wrong',
    'weak_password_error': 'New password is too weak',

    // Bildirim Ayarları
    'notification_settings_title': 'Notification Settings',
    'notif_header_chat': 'Chat',
    'notif_new_messages': 'New Messages',
    'notif_new_messages_sub': 'Notify when you receive a message',
    'notif_header_interactions': 'Interactions',
    'notif_likes': 'Likes',
    'notif_likes_sub': 'When someone likes your post',
    'notif_follows': 'New Followers',
    'notif_follows_sub': 'When someone follows you',
    'notif_header_other': 'Other',
    'notif_campaigns': 'Campaigns',
    'notif_campaigns_sub': 'Announcements and innovations',
    'change_language': 'Change Language',
    'select_preferred_language': 'Select your preferred language',
    'language_updated_tr': 'Language set to Turkish',
    'language_updated_en': 'Language set to English',
    'blocked_users_title': 'Blocked Users',
    'no_blocked_users': 'No blocked users.',
    'user_default': 'User',
    'unblock': 'Unblock',
    'faq_title': 'Frequently Asked Questions',
    'faq_follow_q': 'How can I follow an artist?',
    'faq_follow_a': 'You can go to the artist profile page and click the "Follow" button.',
    'faq_appointment_q': 'How to create an appointment?',
    'faq_appointment_a': 'Click the "Appointment" button on the artist profile and select date and time.',
    'faq_message_q': 'How to send a message?',
    'faq_message_a': 'Click on a post or go to the artist profile and click "Send Message".',
    'faq_favorites_q': 'Where are my favorites?',
    'faq_favorites_a': 'You can see your liked posts in the "Favorites" tab on your profile page.',
    'contact': 'Contact',
    'email': 'Email',
    'phone': 'Phone',
    'legal_docs_title': 'Legal Documents',
    'tab_terms': 'Terms of Service',
    'tab_privacy': 'Privacy Policy',
    'terms_content': """
TERMS AND CONDITIONS
Last Update: December 2025

1. PARTIES AND SCOPE
These Terms of Use apply to all artists ("Artist") and users ("Customer") using the TattInk mobile application ("Application"). By downloading or using the Application, you are deemed to have accepted these terms irrevocably.

2. ROLE OF THE PLATFORM (INTERMEDIARY STATEMENT)
TattInk is a digital platform that brings together tattoo artists and customers.

The Application is not a party to the physical procedures such as tattooing, piercing, or similar processes between the Artist and the Customer.

The Application does not have the status of an "Employer", "Tattoo Studio Operator", or "Health Institution".

The Application cannot be held responsible for disputes between the parties (appointment cancellation, dissatisfaction with the result, refunds, etc.).

3. HEALTH AND SAFETY DISCLAIMER (CRITICAL)
Tattooing and similar body art procedures are interventions that disrupt skin integrity.

Medical Responsibility: The Application does not inspect the hygiene standards of the Artists listed, the content of the inks used, or the sterilization processes.

Possible Complications: All responsibility for medical situations such as infection, allergic reaction, scar tissue (keloid), or infectious diseases that may occur after the procedure belongs to the Artist performing the procedure and the Customer accepting the procedure.

Customer Obligation: The Customer is obliged to inform the Artist of any chronic illnesses, allergies, and blood-borne diseases, if any.

4. AGE LIMIT
It is essential to be at least 18 years old to create an appointment through the Application. It is the responsibility of users under the age of 18 to obtain written permission from their legal guardians and present this permission to the Artist. The Application does not guarantee the accuracy of the age declaration.

5. APPOINTMENT AND PAYMENT CONDITIONS
Appointment requests created through the Application are in the nature of a "preliminary interview".

If "deposit" or "pre-payment" transactions that may be requested by the Artist are made through methods outside the Application (money transfer/EFT/cash), the refund and tracking of these payments are not the responsibility of the Application.

6. CONTENT AND INTELLECTUAL PROPERTY
Portfolio images uploaded by Artists are the property of the artist.

Users cannot upload work belonging to others as if it were their own. Accounts with fake content detected by artificial intelligence or community audit will be permanently banned.

7. ACCOUNT DELETION AND SUSPENSION
Accounts of users who violate community rules (harassment, insults, misleading information, etc.) may be suspended or deleted by the [App Name] management without any prior notice.

8. COMPETENT COURT
Republic of Turkey Bursa Courts and Enforcement Offices are authorized for disputes arising from this agreement.
""",
    'privacy_content': """
PRIVACY POLICY
1. DATA COLLECTION
Your location data is used only to find the nearest studios.

2. MESSAGING PRIVACY
Chat contents are not shared with third parties except for community rule audits.
""",

   // Profile Screen New Keys
    'cover_photo_updated': 'Cover photo updated',
    'user_not_found_msg': 'This profile may have been deleted or suspended.',
    'admin_panel': 'Admin Panel',
    'my_appointments': 'MY APPOINTMENTS',
    'tab_following': 'Following',
    'tab_messages': 'Messages',
    'empty_generic': 'Empty',
    'empty_following': 'No following',
    'empty_messages': 'No messages',
    'report_user': 'Report User',
    'delete_chat_for_me': 'Delete Chat for Me',
    'delete_chat_dialog_title': 'Delete chat with this user?',
    'loading': 'Loading...',
    'artist_default': 'Artist',

    // Artist Profile & General
    'photo_added': 'Photo added!',
    'photo_deleted': 'Photo deleted.',
    'delete_photo_title': 'Delete Photo',
    'add_photo_gallery': 'Add Photo from Gallery',
    
    
    // Email Verification
    'email_verify_title': 'Email Verification Required',
    'email_verify_msg': 'You need to verify your email address to follow, message, and book appointments.',
    
    // Profile Stats & Tabs
    'tattoo_count': 'Tattoo',
    'btn_appointments': 'Appointments',
    'tab_portfolio': 'Portfolio',
    
    // Actions
    'message': 'Message',
    


    'expired': 'Expired',
    'time_left_suffix': 'left', // e.g. "15m left"
    'error_prefix': 'Error',
    'delete_studio_photo_confirm': 'Do you want to remove this studio photo?',
    'cancel': 'Cancel',
    'delete': 'Delete',
    'ok': 'OK',
    'resend': 'Resend',
    'verify_email_sent': 'Verification email sent again.',
    'operation_failed': 'Operation failed',
    'user_not_found': 'User Not Found',
    'remove_photo_gallery': 'Remove Photo from Gallery',
    'remove_photo_hint': 'Long press on the photo you want to delete.',
    'followers': 'Followers',
    'likes': 'Likes',
    'btn_messages': 'Messages',
    'btn_share': 'Share',
    'unfollow': 'Unfollow',
    'follow': 'Follow',
    'book_appointment': 'Book Appointment',
    'no_posts': 'No posts yet',
    'no_favorites': 'No favorites yet',
    'tab_favorites': 'Favorites',
    'tab_about': 'About',
    'no_biography': 'No biography added yet.',
    'applications': 'Applications',
    'specialty_styles': 'Specialty Styles',
    'promote_package_active': '🚀 Promotion Package Active',
    'time_remaining': 'Time Remaining',
    'ends_at': 'Ends',
    'extend_package': 'Extend Package or Buy New',
    'promote_test_title': 'Quick Test (6 Hours)',
    'promote_test_desc': 'Be featured for 6 hours.',
    'promote_daily_title': 'Daily Boost',
    'promote_daily_desc': 'Be featured for 24 hours.',
    'promote_weekly_title': 'Weekly Boost',
    'promote_weekly_desc': 'Be featured for 7 days.',
    'ssl_secure': '256-Bit SSL Secure Payment',
    'payment_success': 'Success! 🎉 New end date: ',
    'featured_badge': 'Featured',
    'promote_btn': 'Promote',
    'block_user': 'Block',
    'profile_info_sub_artist': 'Edit studio, style and specialty tags',
    'delete_account_title': 'Delete Account',

    // Studios Screen
    'new_year_campaign': 'New Year Campaign! 20% Discount',
    'discover_new_studios': 'Discover New Studios 🎨',
    'free_consultation_opportunity': 'Free Consultation Opportunity',
    'reset': 'Reset',
    'search_and_filter': 'Search & Filter',
    'filters_active': 'Filters Active',
    'popular': 'Popular',
    'distance': 'Distance',
    'show_results': 'Show Results',
    'application_type': 'Application',
    'styles': 'Styles',
    'select_application_for_styles': 'Select an application above to see styles.',
    'no_results': 'No results',
    'no_studios_found_criteria': 'No studios found matching these criteria.',
    'this_is_your_own_profile': 'This is your own profile.',

    // Home Screen
    'report_post': 'Report Post',
    'block_artist': 'Block Artist',
    'email_verification_required': 'Email Verification Required',
    'email_verification_message': 'Email verification is required to like and send messages.',
    'ok_button': 'OK',
    'filter': 'Filter',
    'sort': 'Sort',
    'newest': 'Newest',
    'artist_score': 'Artist Score',
    'campaigns': 'Campaigns',
    'no_posts_yet': 'No posts yet',
    'no_posts_found': 'No posts to display.',
    'get_info': 'Get Info',
    'featured': 'FEATURED',
    'show_more': 'show more...',
    'delete_post_title': 'Delete Post',
    'delete_post_confirmation': 'Are you sure you want to delete this post?',
    'edit': 'Edit',
    'login_required': 'You must log in',
    'mark_as_read': 'Mark as Read',
    'post_not_available': 'This post is no longer available.',
    'no_notifications_yet': 'No notifications yet',
    'liked_your_post': 'liked your post.',
    'started_following_you': 'started following you.',
    'sent_you_message': 'sent you a message.',
    'created_appointment_request': 'created an appointment request.',
    'updated_appointment_request': 'updated your appointment request.',
    'sent_new_notification': 'sent a new notification.',
    'minutes_ago': 'minutes ago',
    'hours_ago': 'hours ago',
    'days_ago': 'days ago',
    'appointments_title': 'Appointments',
    'incoming_requests': 'Incoming Requests',
    'no_incoming_requests': 'No incoming requests yet.',
    'no_appointments_booked': 'You haven\'t booked any appointments yet.',
    'pending': 'Pending',
    'confirmed': 'Confirmed',
    'rejected': 'Rejected',
    'completed': 'Completed',
    'cancelled': 'Cancelled',
    'cancelled_by_you': 'Cancelled by you',
    'cancelled_by_other': 'Cancelled by the other party',
    'waiting_for_your_approval': 'waiting for your approval for',
    'waiting_for_other_approval': 'waiting for the other party\'s approval for',
    'note': 'Note:',
    'new_time_approval': 'New Time Approval:',
    'reject': 'Reject',
    'approve': 'Approve',
    'cancel_appointment': 'Cancel',
    'edit_appointment': 'Edit',
    'confirm': 'Confirm',
    'edit_appointment_title': 'Edit Appointment',
    'select_time': 'Select Time',
    'send_update_request': 'Send Update Request',
    'change_request_sent': 'Change request sent.',
    'new_time_approved': 'New time approved',
    'request_rejected': 'Request rejected',
    'date_change_accepted': 'Date Change Accepted ✅',
    'date_change_rejected': 'Date Change Rejected ❌',
    'appointment_time_updated': 'Appointment time updated to',
    'appointment_time_change_rejected': 'Appointment time change rejected. Try a different date.',
    'appointment_confirmed': 'Your appointment is confirmed! ✅',
    'appointment_request_rejected': 'Appointment request rejected ❌',
    'appointment_cancelled': 'Appointment cancelled ⚠️',
    'operation_successful': 'Operation successful',
    'new_appointment_request': 'New Appointment Request',
    'please_select_date_time': 'Please select date and time',
    'artist_not_found': 'Artist not found',
    'appointment_request_sent': 'Appointment request sent',
    'select_date': 'Select Date',
    'notes_optional': 'Notes (Optional)',
    'health_declaration_text': 'I declare that I have no health impediment for the procedure, I accept the Health Responsibility Disclaimer.',
    'send_appointment_request': 'Send Appointment Request',
    'media_cannot_be_changed_edit_mode': 'Media cannot be changed in edit mode.',
    'please_select_media': 'Please select at least one image or video',
    'please_select_application': 'Please select an application type',
    'post_updated': 'Post updated',
    'video_error': 'Video error',
    'edit_post': 'Edit Post',
    'new_post': 'New Post',
    'share_post': 'Share',
    'add_photo': 'Add Photo',
    'add_video': 'Add Video',
    'existing_media_cannot_edit': 'Existing Media (Cannot be edited)',
    'description': 'Description',
    'provide_post_details': 'Provide details about your post...',
    'post_published_successfully': 'Post published successfully',

    // Application Types
    'app_tattoo': 'Tattoo',
    'app_piercing': 'Piercing',
    'app_makeup': 'Makeup',
    'app_henna': 'Henna',

    // Register Screen
    'select_account_type': 'Select Account Type',
    'register_as_customer': 'Register as Customer',
    'register_as_artist': 'Register as Artist',

    // Navigation & Main Screen
    'home': 'Home',
    'studios': 'Studios',
    'profile': 'Profile',
    'profile_login_required': 'You must log in to view your profile.',
    'login_register': 'Login / Register',

    // Customer Register Screen
    'customer_registration': 'Customer Registration',
    'registration_instruction': 'Complete your registration to start exploring the app; however, you need to verify your email address to use all features.',
    'email_hint': 'example@email.com',
    'confirm_password': 'Confirm Password',
    'confirm_password_required': 'Confirm password is required',
    'passwords_not_match': 'Passwords do not match',
    'accept_terms_to_continue': 'You must accept the terms of use to continue.',
    'registration_successful': 'Registration successful!',
    'terms_and_disclaimer': 'I have read and accept the Terms of Use and Health Responsibility Disclaimer',

    // Login Screen
    'forgot_password': 'Forgot Password?',
    'login': 'Login',
    'or': 'or',
    'continue_with_google': 'Continue with Google',
    'dont_have_account': 'Don\'t have an account?',
    'register_link': 'Register',
    'artist_profile_instruction': 'For artist profile, please register with email',
    'login_error': 'Login error',
    'google_login_error': 'Google login error',
    'login_register_title': 'Login / Register',
    'login_required_message': 'You need to log in or register to perform this action.',
    'register_button': 'Register',
    'login_button': 'Login',

    // Customer Profile Tabs
    'favorites_tab': 'Favorites',
    'following_tab': 'Following',
    'messages_tab': 'Messages',

    // Customer Profile Screen
    'delete_chat_title': 'Delete chat with',

    // Artist Register Screen
    'artist_registration': 'Artist Registration',
    'artist_type': 'Artist Type',
    'approved_artist': 'Approved Artist',
    'approved_artist_description': 'Tax certificate or work permit required',
    'unapproved_artist': 'Unapproved Artist',
    'unapproved_artist_description': 'No document required',
    'studio_name_example': 'Example: Dream Tattoo Studio',
    'studio_address': 'Studio Address',
    'select_city_first': 'Select city first',
    'instagram_username': 'Instagram Username',
    'tax_certificate_work_permit': 'Tax Certificate or Work Permit',
    'upload_pdf_or_photo': 'Upload PDF or Photo',
    'portfolio_photos_3_required': 'Portfolio Photos (3 required)',
    'terms_and_health_disclaimer': 'I have read and accept the Terms of Use and Health Responsibility Disclaimer',
    'file_error_prefix': 'File error',
    'max_portfolio_photos_reached': 'Already added 3 portfolio photos',
    'photo_selection_error': 'Error selecting photo',
    'document_required_approved_artist': 'Document required for approved artist',
    'add_3_portfolio_photos': 'Please add 3 portfolio photos',
    'account_sent_for_approval': 'Account sent for approval',
    'registration_error': 'Registration error',
    'firebase_init_error_prefix': 'Firebase initialization error',
    'notification_subscription_error_prefix': 'Notification subscription error',

    // Featured Artist Card
    'featured_artist': 'FEATURED ARTIST',
    'view_profile': 'View Profile',


    // Rejection Reasons
    'reason_documents_missing': 'Documents missing or invalid',
    'reason_insufficient_portfolio': 'Insufficient portfolio',
    'reason_missing_info': 'Information missing or incorrect',
    'reason_inappropriate_content': 'Inappropriate content',
    'reason_other': 'Other',

    // Tattoo Styles
    'style_campaign': 'Campaign',
    'style_realistic': 'Realistic',
    'style_minimal': 'Minimal',
    'style_old_school': 'Old School',
    'style_tribal': 'Tribal',
    'style_watercolor': 'Watercolor',
    'style_blackwork': 'Blackwork',
    'style_dotwork': 'Dotwork',
    'style_japanese': 'Japanese',
    'style_neo_traditional': 'Neo Traditional',
    'style_portrait': 'Portrait',
    'style_geometric': 'Geometric',
    'style_script': 'Script',
    'style_fine_line': 'Fine Line',
    'style_cover_up': 'Cover Up',
    'style_abstract': 'Abstract',
    'style_celtic': 'Celtic',
    'style_biomechanical': 'Biomechanical',
    'style_sketch': 'Sketch',

    // Piercing Styles
    'style_ear': 'Ear',
    'style_nose': 'Nose',
    'style_navel': 'Navel',
    'style_lip': 'Lip',
    'style_eyebrow': 'Eyebrow',
    'style_tongue': 'Tongue',
    'style_industrial': 'Industrial',
    'style_nipple': 'Nipple',
    'style_septum': 'Septum',
    'style_tragus': 'Tragus',
    'style_helix': 'Helix',
    'style_implant': 'Implant',

    // Makeup Styles
    'style_microblading': 'Microblading',
    'style_lip_tinting': 'Lip Tinting',
    'style_eyeliner': 'Eyeliner',
    'style_dipliner': 'Dipliner',
    'style_eyebrow_powdering': 'Eyebrow Powdering',

    // Henna Styles
    'style_henna': 'Henna',
    'style_airbrush': 'Airbrush',
    'style_spray': 'Spray',
    'style_sticker': 'Sticker',

    // Validation Messages
    'email_required': 'Email is required',
    'invalid_email': 'Please enter a valid email address',
    'password_required': 'Password is required',
    'password_min_length': 'Password must be at least 6 characters',
    'field_required': 'is required',
    'phone_required': 'Phone number is required',
    'invalid_phone': 'Please enter a valid phone number',
    'username_required': 'Username is required',
    'username_min_length': 'Username must be at least 3 characters',
    'username_invalid_chars': 'Username can only contain letters, numbers and underscores',
  },
  'tr': {

    'loading': 'Yükleniyor...',
    'photo_added': 'Fotoğraf eklendi!',
    'error_prefix': 'Hata',
    'photo_deleted': 'Fotoğraf silindi.',
    'delete_photo_title': 'Fotoğrafı Sil',
    'delete_studio_photo_confirm': 'Bu stüdyo fotoğrafını kaldırmak istiyor musunuz?',
    'delete': 'Sil',
    'email_verify_title': 'E-posta Onayı Gerekli',
    'email_verify_msg': 'Takip etme, mesaj atma ve randevu alma işlemleri için e-posta adresinizi onaylamanız gerekmektedir.',
    'ok': 'Tamam',
    'resend': 'Tekrar Gönder',
    'verify_email_sent': 'Doğrulama e-postası tekrar gönderildi.',
    'user_not_found': 'Kullanıcı Bulunamadı',
    'remove_photo_gallery': 'Galeriden Fotoğraf Çıkar',
    'remove_photo_hint': 'Silmek istediğiniz fotoğrafın üzerine uzunca basın.',
    'tattoo_count': 'Dövme',
    'followers': 'Takipçi',
    'likes': 'Beğeni',
    'unfollow': 'Takibi Bırak',
    'follow': 'Takip Et',
    'message': 'Mesaj',
    'book_appointment': 'Randevu Al',
    'biography': 'Biyografi',
    'delete_account_title': 'Hesabı Sil',
    'featured_badge': 'Öne Çıkarıldı',
    'report_user': 'Kullanıcıyı Şikayet Et',
    'block_user': 'Engelle',


    // Email Doğrulama

    // Profil İstatistik & Sekmeler
    'profile_info_sub_artist': 'Stüdyo, stil ve uzmanlık etiketlerinizi düzenleyin',
    'btn_appointments': 'Randevular',
    'btn_messages': 'Mesajlar',
    'btn_share': 'Paylaş',
    'tab_portfolio': 'Portfolyo',
    'tab_about': 'Hakkında',

    // Aksiyonlar
    'operation_failed': 'İşlem başarısız',

    // Hakkında Sekmesi
    'no_biography': 'Henüz bir biyografi eklenmemiş.',
    'applications': 'Uygulamalar',
    'specialty_styles': 'Uzmanlık Stilleri',
    'no_posts': 'Henüz paylaşım yok',
    'no_favorites': 'Henüz favori yok',

    // Öne Çıkarma Sistemi
    'promote_btn': 'Öne Çıkar',
    'promote_package_active': '🚀 Öne Çıkarma Paketiniz Aktif',
    'time_remaining': 'Kalan Süre',
    'ends_at': 'Bitiş',
    'extend_package': 'Paketini Uzat veya Yeni Paket Al',
    'promote_test_title': 'Hızlı Test (6 Saat)',
    'promote_test_desc': '6 saat boyunca öne çıkın.',
    'promote_daily_title': 'Günlük Boost',
    'promote_daily_desc': '24 saat boyunca öne çıkın.',
    'promote_weekly_title': 'Haftalık Boost',
    'promote_weekly_desc': '7 gün boyunca öne çıkın.',
    'ssl_secure': '256-Bit SSL Güvenli Ödeme',
    'payment_success': 'Başarılı! 🎉 Yeni bitiş: ',
    'expired': 'Süre Doldu',
    'time_left_suffix': 'kaldı',

    // Profil Ekranı Yeni Anahtarlar
    'cover_photo_updated': 'Kapak fotoğrafı güncellendi',
    'user_not_found_msg': 'Bu profil silinmiş veya askıya alınmış olabilir.',
    'admin_panel': 'Yönetim Paneli',
    'my_appointments': 'RANDEVULARIM',
    'tab_favorites': 'Favoriler',
    'tab_following': 'Takip',
    'tab_messages': 'Mesajlar',
    'empty_generic': 'Boş',
    'empty_following': 'Takip yok',
    'empty_messages': 'Mesaj yok',
    'delete_chat_for_me': 'Sohbeti Benden Sil',
    'delete_chat_dialog_title': 'Bu kullanıcıyla sohbeti sil?',
    'artist_default': 'Sanatçı',
    // Ayarlar & Genel
    'settings': 'Ayarlar',
    'faq_title': 'Sık Sorulan Sorular',
    'faq_follow_q': 'Nasıl artist takip edebilirim?',
    'faq_follow_a': 'Artist profil sayfasına gidip "Takip Et" butonuna tıklayabilirsiniz.',
    'faq_appointment_q': 'Randevu nasıl oluşturulur?',
    'faq_appointment_a': 'Artist profil sayfasında "Randevu" butonuna tıklayıp tarih ve saat seçerek randevu oluşturabilirsiniz.',
    'faq_message_q': 'Mesaj nasıl gönderilir?',
    'faq_message_a': 'Anasayfadaki bir paylaşıma tıklayıp "Mesaj At" butonuna basabilir veya artist profil sayfasından mesaj gönderebilirsiniz.',
    'faq_favorites_q': 'Favorilerim nerede?',
    'faq_favorites_a': 'Profil sayfanızdaki "Favoriler" sekmesinde beğendiğiniz paylaşımları görebilirsiniz.',
    'contact': 'İletişim',
    'phone': 'Telefon',
    'account': 'Hesap',
    'profile_info': 'Profil Bilgileri',
    'profile_info_sub': 'Ad, soyad ve fotoğraf düzenleyin',
    'email_password': 'Email ve Şifre',
    'email_password_sub': 'Email adresinizi ve şifrenizi değiştirin',
    'preferences': 'Tercihler',
    'notifications': 'Bildirimler',
    'notifications_sub': 'Bildirim ayarlarınızı yönetin',
    'language': 'Dil',
    'language_sub': 'Uygulama dilini seçin',
    'privacy': 'Gizlilik',
    'blocked_users': 'Engellenen Kullanıcılar',
    'blocked_users_sub': 'Engellediğiniz kişileri yönetin',
    'support': 'Destek',
    'help': 'Yardım',
    'help_sub': 'Sık sorulan sorular ve yardım',
    'legal': 'Hukuki Metinler',
    'legal_sub': 'Kullanım şartları ve gizlilik politikası',
    'logout': 'Çıkış Yap',
    'logout_confirm': 'Çıkış yapmak istediğinize emin misiniz?',
    'cancel': 'İptal',
    'save': 'Kaydet',
    'error': 'Hata',
    'delete_account': 'Hesabımı Sil',
    'delete_account_sub': 'Tüm verileriniz kalıcı olarak kaldırılır',
    'delete_account_warning': 'Emin misiniz? Bu işlem geri alınamaz ve tüm profil verileriniz silinecektir.',
    'delete_permanently': 'Evet, Kalıcı Olarak Sil',
    'relogin_required': 'Güvenlik nedeniyle, bu işlemden önce tekrar giriş yapmalısınız.',

    // Profil Düzenleme (Ortak & Sanatçı & Müşteri)
    'edit_profile': 'Profili Düzenle',
    'profile_info_title': 'Profil Bilgileri',
    'first_name': 'Ad',
    'last_name': 'Soyad',
    'studio_name': 'Stüdyo Adı',
    'address_detail': 'Açık Adres',
    'city': 'Şehir',
    'district': 'Semt',
    'services': 'Hizmetler',
    'select_service_to_see_styles': 'Stilleri görmek için yukarıdan hizmet seçiniz.',
    'styles_title': 'Stilleri',
    'save_changes': 'Değişiklikleri Kaydet',
    'profile_updated': 'Profil güncellendi!',
    'profile_updated_success': 'Profil bilgileri başarıyla güncellendi!',
    'error_picking_image': 'Fotoğraf seçilirken hata oluştu',
    'update_error': 'Güncelleme sırasında hata oluştu',

    // Email & Şifre Değiştirme
    'email_password_title': 'Email ve Şifre',
    'change_email': 'Email Değiştir',
    'new_email': 'Yeni Email',
    'email_same_error': 'Yeni email adresi mevcut email ile aynı olamaz',
    'email_update_success': 'Email adresi başarıyla güncellendi',
    'email_change_error': 'Email değiştirilirken hata oluştu',
    'change_password': 'Şifre Değiştir',
    'current_password': 'Mevcut Şifre',
    'new_password': 'Yeni Şifre',
    'confirm_new_password': 'Yeni Şifre Tekrar',
    'confirm_password_required': 'Şifre tekrarı gereklidir',
    'passwords_not_match': 'Şifreler eşleşmiyor',
    'password_update_success': 'Şifre başarıyla güncellendi',
    'password_change_error': 'Şifre değiştirilirken hata oluştu',
    'wrong_password_error': 'Mevcut şifre yanlış',
    'weak_password_error': 'Yeni şifre çok zayıf',
    'legal_docs_title': 'Hukuki Metinler',
    'tab_terms': 'Kullanım Şartları',
    'tab_privacy': 'Gizlilik Politikası',

    'terms_content': """
KULLANIM ŞARTLARI VE KOŞULLARI
Son Güncelleme: Aralık 2025

1. TARAFLAR VE KAPSAM
Bu Kullanım Şartları, TattInk mobil uygulamasını ("Uygulama") kullanan tüm sanatçılar ("Artist") ve kullanıcılar ("Müşteri") için geçerlidir. Uygulamayı indirerek veya kullanarak bu şartları gayrikabili rücu kabul etmiş sayılırsınız.

2. PLATFORMUN ROLÜ (ARACILIK BEYANI)
TattInk, dövme sanatçıları ile müşterileri bir araya getiren dijital bir platformdur.

Uygulama, Artist ile Müşteri arasında gerçekleşen dövme, piercing veya benzeri fiziksel işlemlerin bir tarafı değildir.

Uygulama, bir "İşveren", "Dövme Stüdyosu İşletmecisi" veya "Sağlık Kuruluşu" sıfatına sahip değildir.

Taraflar arasındaki anlaşmazlıklardan (randevu iptali, sonuçtan memnuniyetsizlik, ücret iadesi vb.) Uygulama sorumlu tutulamaz.

3. SAĞLIK VE GÜVENLİK SORUMLULUK REDDİ (KRİTİK)
Dövme ve benzeri vücut sanatı işlemleri deri bütünlüğünü bozan müdahalelerdir.

Tıbbi Sorumluluk: Uygulama üzerinde listelenen Artistlerin hijyen standartlarını, kullanılan boyaların içeriğini veya sterilizasyon süreçlerini denetlemez.

Olası Komplikasyonlar: İşlem sonrası oluşabilecek enfeksiyon, alerjik reaksiyon, skar dokusu (keloid) veya bulaşıcı hastalıklar gibi tıbbi durumlarda tüm sorumluluk işlemi gerçekleştiren Artist ve işlemi kabul eden Müşteri'ye aittir.

Müşteri Yükümlülüğü: Müşteri, varsa kronik hastalıklarını, alerjilerini ve kan yoluyla bulaşan rahatsızlıklarını Artist'e bildirmekle yükümlüdür.

4. YAŞ SINIRI
Uygulama üzerinden randevu oluşturmak için 18 yaşını doldurmuş olmak esastır. 18 yaş altındaki kullanıcıların yasal vasilerinden yazılı izin almaları ve bu izni Artist'e sunmaları kendi sorumluluklarındadır. Uygulama, yaş beyanının doğruluğunu garanti etmez.

5. RANDEVU VE ÖDEME KOŞULLARI
Uygulama üzerinden oluşturulan randevu talepleri birer "ön görüşme" niteliğindedir.

Artist tarafından talep edilebilecek "kapora" veya "ön ödeme" işlemleri Uygulama dışı yöntemlerle (havale/EFT/nakit) yapılıyorsa, bu ödemelerin iadesi ve takibi Uygulama'nın sorumluluğunda değildir.

6. İÇERİK VE FİKRİ MÜLKİYET
Artistler tarafından yüklenen portfolyo görselleri sanatçının kendi mülkiyetindedir.

Kullanıcılar, başkasına ait çalışmaları kendisininmiş gibi yükleyemez. Yapay zeka veya topluluk denetimi tarafından tespit edilen sahte içerikli hesaplar kalıcı olarak uzaklaştırılır.

7. HESAP SİLME VE DURDURMA
Topluluk kurallarını (taciz, hakaret, yanıltıcı bilgi vb.) ihlal eden kullanıcıların hesapları, hiçbir ön ihbara gerek kalmaksızın [Uygulama Adı] yönetimi tarafından askıya alınabilir veya silinebilir.

8. YETKİLİ MAHKEME
Bu sözleşmeden doğacak ihtilaflarda T.C. Bursa Mahkemeleri ve İcra Daireleri yetkilidir. 
""",
    'privacy_content': """
GİZLİLİK POLİTİKASI
1. VERİ TOPLAMA
Konum verileriniz sadece en yakın stüdyoları bulmak için kullanılır.

2. MESAJLAŞMA GİZLİLİĞİ
Sohbet içerikleri topluluk kuralları denetimi dışında üçüncü taraflarla paylaşılmaz.
""",

    // Bildirim Ayarları
    'notification_settings_title': 'Bildirim Ayarları',
    'notif_header_chat': 'Sohbet',
    'notif_new_messages': 'Yeni Mesajlar',
    'notif_new_messages_sub': 'Mesaj aldığında bildir',
    'notif_header_interactions': 'Etkileşimler',
    'notif_likes': 'Beğeniler',
    'notif_likes_sub': 'Biri gönderini beğendiğinde',
    'notif_follows': 'Yeni Takipçiler',
    'notif_follows_sub': 'Biri seni takip ettiğinde',
    'notif_header_other': 'Diğer',
    'notif_campaigns': 'Kampanyalar',
    'notif_campaigns_sub': 'Duyuru ve yenilikler',
    'change_language': 'Dili Değiştir',
    'select_preferred_language': 'Tercih ettiğiniz dili seçin',
    'language_updated_tr': 'Dil Türkçe olarak güncellendi',
    'language_updated_en': 'Dil İngilizce olarak güncellendi',
    'blocked_users_title': 'Engellenen Kullanıcılar',
    'no_blocked_users': 'Engellenen kullanıcı yok.',
    'user_default': 'Kullanıcı',
    'unblock': 'Kaldır',

    // Studios Screen
    'new_year_campaign': 'Yılbaşı Kampanyası! %20 İndirim',
    'discover_new_studios': 'Yeni Stüdyoları Keşfedin 🎨',
    'free_consultation_opportunity': 'Ücretsiz Konsültasyon Fırsatı',
    'reset': 'Sıfırla',
    'search_and_filter': 'Ara & Filtrele',
    'filters_active': 'Filtreler Aktif',
    'popular': 'Popüler',
    'distance': 'Mesafe',
    'show_results': 'Sonuçları Göster',
    'application_type': 'Uygulama',
    'styles': 'Stiller',
    'select_application_for_styles': 'Stilleri görmek için uygulama seçiniz.',
    'no_results': 'Sonuç yok',
    'no_studios_found_criteria': 'Bu kriterlere uygun stüdyo bulunamadı.',
    'this_is_your_own_profile': 'Bu sizin kendi profiliniz.',

    // Home Screen
    'report_post': 'Şikayet Et',
    'block_artist': 'Sanatçıyı Engelle',
    'email_verification_required': 'E-posta Onayı Gerekli',
    'email_verification_message': 'Beğeni yapabilmek ve mesaj atabilmek için e-posta onayı gereklidir.',
    'ok_button': 'Tamam',
    'filter': 'Filtrele',
    'sort': 'Sırala',
    'newest': 'En Yeniler',
    'artist_score': 'Artist Puanı',
    'campaigns': 'Kampanyalar',
    'no_posts_yet': 'Henüz paylaşım yok',
    'no_posts_found': 'Gösterilecek gönderi bulunamadı.',
    'get_info': 'Bilgi Al',
    'featured': 'ÖNE ÇIKAN',
    'show_more': 'daha fazla...',
    'delete_post_title': 'Gönderiyi Sil',
    'delete_post_confirmation': 'Bu gönderiyi silmek istediğine emin misin?',
    'edit': 'Düzenle',
    'login_required': 'Giriş yapmalısınız',
    'mark_as_read': 'Okundu',
    'post_not_available': 'Bu gönderi artık mevcut değil.',
    'no_notifications_yet': 'Henüz bildirim yok',
    'liked_your_post': 'gönderini beğendi.',
    'started_following_you': 'seni takip etmeye başladı.',
    'sent_you_message': 'sana mesaj gönderdi.',
    'created_appointment_request': 'randevu talebi oluşturdu.',
    'updated_appointment_request': 'randevu talebinizi güncelledi.',
    'sent_new_notification': 'yeni bir bildirim gönderdi.',
    'minutes_ago': 'dk önce',
    'hours_ago': 'sa önce',
    'days_ago': 'g önce',
    'appointments_title': 'Randevular',
    'incoming_requests': 'Gelen Talepler',
    'no_incoming_requests': 'Henüz gelen bir talep yok.',
    'no_appointments_booked': 'Henüz randevu almadınız.',
    'pending': 'Bekliyor',
    'confirmed': 'Onaylandı',
    'rejected': 'Reddedildi',
    'completed': 'Tamamlandı',
    'cancelled': 'İptal Edildi',
    'cancelled_by_you': 'Sizin tarafınızdan iptal edildi',
    'cancelled_by_other': 'Karşı taraf tarafından iptal edildi',
    'waiting_for_your_approval': 'için onayınız bekleniyor',
    'waiting_for_other_approval': 'için karşı tarafın onayı bekleniyor',
    'note': 'Not:',
    'new_time_approval': 'Yeni Saat Onayı:',
    'reject': 'Reddet',
    'approve': 'Onayla',
    'cancel_appointment': 'İptal Et',
    'edit_appointment': 'Düzenle',
    'confirm': 'Onayla',
    'edit_appointment_title': 'Randevu Düzenle',
    'select_time': 'Saat Seçin',
    'send_update_request': 'Güncelleme Talebi Gönder',
    'change_request_sent': 'Değişiklik talebi iletildi.',
    'new_time_approved': 'Yeni saat onaylandı',
    'request_rejected': 'Talep reddedildi',
    'date_change_accepted': 'Tarih Değişikliği Kabul Edildi ✅',
    'date_change_rejected': 'Tarih Değişikliği Reddedildi ❌',
    'appointment_time_updated': 'Randevu saati olarak güncellendi.',
    'appointment_time_change_rejected': 'Randevu saati değişikliği reddedildi. Farklı bir tarih deneyin.',
    'appointment_confirmed': 'Randevunuz Onaylandı! ✅',
    'appointment_request_rejected': 'Randevu Talebi Reddedildi ❌',
    'appointment_cancelled': 'Randevu İptal Edildi ⚠️',
    'operation_successful': 'İşlem başarılı',
    'new_appointment_request': 'Yeni Randevu Talebi',
    'please_select_date_time': 'Lütfen tarih ve saat seçin',
    'artist_not_found': 'Artist bulunamadı',
    'appointment_request_sent': 'Randevu talebi gönderildi',
    'select_date': 'Tarih Seç',
    'notes_optional': 'Notlar (Opsiyonel)',
    'health_declaration_text': 'İşlem için sağlık engelim olmadığını beyan eder, Sağlık Sorumluluk Reddini kabul ederim.',
    'send_appointment_request': 'Randevu Talebi Gönder',
    'media_cannot_be_changed_edit_mode': 'Düzenleme modunda medya değiştirilemez.',
    'please_select_media': 'Lütfen en az bir görsel veya video seçin',
    'please_select_application': 'Lütfen bir uygulama türü seçin',
    'post_updated': 'Paylaşım güncellendi',
    'video_error': 'Video hatası',
    'edit_post': 'Gönderiyi Düzenle',
    'new_post': 'Yeni Paylaşım',
    'share_post': 'Paylaş',
    'add_photo': 'Fotoğraf Ekle',
    'add_video': 'Video Ekle',
    'existing_media_cannot_edit': 'Mevcut Medya (Düzenlenemez)',
    'description': 'Açıklama',
    'provide_post_details': 'Paylaşımınız hakkında detay verin...',
    'post_published_successfully': 'Paylaşım başarıyla yayınlandı',

    // Application Types
    'app_tattoo': 'Dövme',
    'app_piercing': 'Piercing',
    'app_makeup': 'Makyaj',
    'app_henna': 'Geçici Dövme',

    // Register Screen
    'select_account_type': 'Hesap Türü Seçin',
    'register_as_customer': 'Müşteri Olarak Üye Ol',
    'register_as_artist': 'Artist Olarak Üye Ol',

    // Navigation & Main Screen
    'home': 'Anasayfa',
    'studios': 'Stüdyolar',
    'profile': 'Profil',
    'profile_login_required': 'Profilinizi görmek için giriş yapmalısınız.',
    'login_register': 'Giriş Yap / Kayıt Ol',

    // Customer Register Screen
    'customer_registration': 'Müşteri Kaydı',
    'registration_instruction': 'Kayıt işlemini tamamlayarak uygulamayı keşfetmeye başlayabilirsin; ancak tüm özellikleri kullanabilmek için e-posta adresini doğrulaman gerekiyor.',
    'email_hint': 'ornek@eposta.com',
    'confirm_password': 'Şifre Tekrar',
    'accept_terms_to_continue': 'Devam etmek için kullanım şartlarını kabul etmelisiniz.',
    'registration_successful': 'Kayıt başarılı!',
    'terms_and_disclaimer': 'Kullanım Şartları ve Sağlık Sorumluluk Reddini okudum, kabul ediyorum',

    // Login Screen
    'forgot_password': 'Şifremi Unuttum?',
    'login': 'Giriş Yap',
    'or': 'veya',
    'continue_with_google': 'Google ile Devam Et',
    'dont_have_account': 'Hesabın yok mu?',
    'register_link': 'Kayıt Ol',
    'artist_profile_instruction': 'Sanatçı profili için lütfen e-posta ile kayıt olun',
    'login_error': 'Giriş hatası',
    'google_login_error': 'Google giriş hatası',
    'login_register_title': 'Giriş Yap / Üye Ol',
    'login_required_message': 'Bu işlemi yapmak için giriş yapmanız veya üye olmanız gerekiyor.',
    'register_button': 'Üye Ol',
    'login_button': 'Giriş Yap',

    // Customer Profile Tabs
    'favorites_tab': 'Favoriler',
    'following_tab': 'Takip Edilenler',
    'messages_tab': 'Mesajlar',

    // Customer Profile Screen
    'delete_chat_title': 'ile sohbeti sil',

    // Artist Register Screen
    'artist_registration': 'Artist Kaydı',
    'artist_type': 'Artist Türü',
    'approved_artist': 'Onaylı Artist',
    'approved_artist_description': 'Vergi levhası veya çalışma izni gerekli',
    'unapproved_artist': 'Onaysız Artist',
    'unapproved_artist_description': 'Belge gerekmez',
    'studio_name_example': 'Örn: Dream Tattoo Studio',
    'studio_address': 'Stüdyo Adresi',
    'select_city_first': 'Önce şehir seçin',
    'instagram_username': 'Instagram Kullanıcı Adı',
    'tax_certificate_work_permit': 'Vergi Levhası veya Çalışma İzni',
    'upload_pdf_or_photo': 'PDF veya Fotoğraf Yükle',
    'portfolio_photos_3_required': 'Portfolyo Fotoğrafları (3 adet seçin)',
    'terms_and_health_disclaimer': 'Kullanım Şartları ve Sağlık Sorumluluk Reddini okudum, kabul ediyorum',
    'file_error_prefix': 'Dosya hatası',
    'max_portfolio_photos_reached': 'Zaten 3 portfolyo fotoğrafı eklediniz',
    'photo_selection_error': 'Fotoğraf seçilirken hata',
    'document_required_approved_artist': 'Onaylı artist için belge yüklemeniz gerekiyor',
    'add_3_portfolio_photos': 'Lütfen 3 adet portfolyo fotoğrafı ekleyin',
    'account_sent_for_approval': 'Hesabınız onaya gönderilmiştir',
    'registration_error': 'Kayıt sırasında hata',
    'firebase_init_error_prefix': 'Firebase başlatma hatası',
    'notification_subscription_error_prefix': 'Bildirim abonelik hatası',

    // Featured Artist Card
    'featured_artist': 'ÖNE ÇIKAN ARTİST',
    'view_profile': 'Profili Gör',


    // Rejection Reasons
    'reason_documents_missing': 'Belgeler eksik veya geçersiz',
    'reason_insufficient_portfolio': 'Portfolyo yetersiz',
    'reason_missing_info': 'Bilgiler eksik veya hatalı',
    'reason_inappropriate_content': 'Uygunsuz içerik',
    'reason_other': 'Diğer',

    // Tattoo Styles
    'style_campaign': 'Kampanya',
    'style_realistic': 'Gerçekçi',
    'style_minimal': 'Minimal',
    'style_old_school': 'Old School',
    'style_tribal': 'Tribal',
    'style_watercolor': 'Suluboya',
    'style_blackwork': 'Siyah İşçilik',
    'style_dotwork': 'Nokta İşçilik',
    'style_japanese': 'Japon',
    'style_neo_traditional': 'Neo Geleneksel',
    'style_portrait': 'Portre',
    'style_geometric': 'Geometrik',
    'style_script': 'Yazı',
    'style_fine_line': 'İnce Çizgi',
    'style_cover_up': 'Kapama',
    'style_abstract': 'Soyut',
    'style_celtic': 'Kelt',
    'style_biomechanical': 'Biyomekanik',
    'style_sketch': 'Kroki',

    // Piercing Styles
    'style_ear': 'Kulak',
    'style_nose': 'Burun',
    'style_navel': 'Göbek',
    'style_lip': 'Dudak',
    'style_eyebrow': 'Kaş',
    'style_tongue': 'Dil',
    'style_industrial': 'Industrial',
    'style_nipple': 'Meme Ucu',
    'style_septum': 'Septum',
    'style_tragus': 'Tragus',
    'style_helix': 'Helix',
    'style_implant': 'İmplant',

    // Makeup Styles
    'style_microblading': 'Microblading',
    'style_lip_tinting': 'Dudak Renklendirme',
    'style_eyeliner': 'Göz Kalemi',
    'style_dipliner': 'Dipliner',
    'style_eyebrow_powdering': 'Kaş Pudralama',

    // Henna Styles
    'style_henna': 'Kına',
    'style_airbrush': 'Hava Fırçası',
    'style_spray': 'Sprey',
    'style_sticker': 'Çıkartma',

    // Validation Messages
    'email_required': 'Email adresi gereklidir',
    'invalid_email': 'Geçerli bir email adresi giriniz',
    'password_required': 'Şifre gereklidir',
    'password_min_length': 'Şifre en az 6 karakter olmalıdır',
    'field_required': 'gereklidir',
    'phone_required': 'Telefon numarası gereklidir',
    'invalid_phone': 'Geçerli bir telefon numarası giriniz',
    'username_required': 'Kullanıcı adı gereklidir',
    'username_min_length': 'Kullanıcı adı en az 3 karakter olmalıdır',
    'username_invalid_chars': 'Kullanıcı adı sadece harf, rakam ve alt çizgi içerebilir',
  },
};

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}

// Delegate sınıfı (Main'de kullanacağız)
class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'tr'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

const localizationsDelegate = _AppLocalizationsDelegate();