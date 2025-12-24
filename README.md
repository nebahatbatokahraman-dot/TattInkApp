# TattInk Flutter Uygulaması

TattInk, dövme artistleri ile müşterileri bir araya getiren bir mobil uygulamadır.

## Özellikler

- **Kullanıcı Rolleri:**
  - Müşteri: Artistleri takip edebilir, beğenebilir, mesaj atabilir ve randevu talep edebilir
  - Onaylı Artist: Paylaşım yapabilir, mesaj atabilir, beğeni yapabilir
  - Onaysız Artist: Uygulamada gezinebilir ancak paylaşım yapamaz
  - Admin: Artist onay/red işlemleri yapabilir

- **Ana Özellikler:**
  - Instagram benzeri post akışı
  - Real-time mesajlaşma
  - Randevu yönetimi
  - Artist profil sayfaları
  - Filtreleme ve sıralama
  - Konum tabanlı arama
  - Admin onay paneli

## Kurulum

### Gereksinimler

- Flutter SDK (3.10.4 veya üzeri)
- Firebase projesi
- Android Studio / Xcode (platform geliştirme için)

### Adımlar

1. **Projeyi klonlayın:**
   ```bash
   git clone <repository-url>
   cd TattInkApp
   ```

2. **Bağımlılıkları yükleyin:**
   ```bash
   flutter pub get
   ```

3. **Firebase yapılandırması:**
   - Firebase Console'da yeni bir proje oluşturun
   - Authentication'ı etkinleştirin (Email/Password)
   - Firestore Database oluşturun
   - Storage'ı etkinleştirin
   - FlutterFire CLI ile yapılandırın:
     ```bash
     flutterfire configure
     ```
   - Bu komut `lib/firebase_options.dart` dosyasını otomatik oluşturur

4. **Firestore Güvenlik Kuralları:**
   Firestore'da aşağıdaki güvenlik kurallarını ayarlayın (geliştirme için):
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /{document=**} {
         allow read, write: if request.auth != null;
       }
     }
   }
   ```
   **Not:** Production için daha detaylı güvenlik kuralları oluşturulmalıdır.

5. **Cloud Functions Kurulumu:**
   ```bash
   cd functions
   npm install
   ```
   
   Email yapılandırması:
   ```bash
   firebase functions:config:set email.user="your-email@gmail.com"
   firebase functions:config:set email.password="your-app-password"
   ```
   
   Functions'ı deploy edin:
   ```bash
   firebase deploy --only functions
   ```

6. **Uygulamayı çalıştırın:**
   ```bash
   flutter run
   ```

## Proje Yapısı

```
lib/
├── main.dart                 # Ana uygulama giriş noktası
├── models/                   # Veri modelleri
│   ├── user_model.dart
│   ├── post_model.dart
│   ├── appointment_model.dart
│   ├── message_model.dart
│   └── artist_approval_model.dart
├── screens/                   # Ekranlar
│   ├── auth/                 # Authentication ekranları
│   ├── profile/              # Profil ekranları
│   ├── admin/                # Admin paneli
│   ├── home_screen.dart
│   ├── studios_screen.dart
│   ├── create_post_screen.dart
│   ├── chat_screen.dart
│   └── appointments_screen.dart
├── services/                 # Servisler
│   ├── auth_service.dart
│   ├── image_service.dart
│   ├── location_service.dart
│   └── notification_service.dart
├── theme/                     # Tema tanımları
│   └── app_theme.dart
└── utils/                     # Yardımcı sınıflar
    ├── constants.dart
    ├── validators.dart
    └── helpers.dart
```

## Tema Renkleri

- **Background:** #191919
- **Primary:** #944B79
- **Text:** #ebebeb
- **Card:** #2A2A2A

## Önemli Notlar

1. **Firebase Yapılandırması:** `firebase_options.dart` dosyası FlutterFire CLI ile oluşturulmalıdır. Placeholder dosya mevcut ancak gerçek Firebase proje bilgileriyle değiştirilmelidir.

2. **Email Servisi:** Cloud Functions'da email gönderimi için Gmail veya başka bir email servisi yapılandırılmalıdır.

3. **Admin Kullanıcı:** İlk admin kullanıcıyı oluşturmak için Firestore'da bir kullanıcı dokümanı oluşturup `role` alanını `admin` olarak ayarlayın.

4. **Konum Servisleri:** Android ve iOS için gerekli izinler `AndroidManifest.xml` ve `Info.plist` dosyalarına eklenmiştir.

5. **Görsel Optimizasyon:** Görseller client-side'da optimize edilmektedir. Production için Cloud Functions ile server-side optimizasyon önerilir.

## Geliştirme

### Test Kullanıcıları Oluşturma

1. **Müşteri:** Uygulama üzerinden kayıt olun
2. **Artist:** Artist kayıt ekranından kayıt olun
3. **Admin:** Firestore'da manuel olarak `role: "admin"` ayarlayın

### Firebase Emulator (Opsiyonel)

Geliştirme için Firebase emulator kullanabilirsiniz:
```bash
firebase emulators:start
```

## Lisans

Bu proje özel bir projedir.
