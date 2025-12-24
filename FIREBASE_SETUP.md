# Firebase Yapılandırma Rehberi

## Firebase Bilgilerini Nereden Bulabilirsiniz?

1. Firebase Console'a gidin: https://console.firebase.google.com
2. Projenizi seçin
3. Proje Ayarları (⚙️) > Genel sekmesine gidin
4. "Uygulamalarınız" bölümünden Android ve iOS uygulamalarınızı oluşturun

## Android Uygulaması İçin:

1. Firebase Console > Proje Ayarları > Genel
2. "Android uygulamanızı ekleyin" butonuna tıklayın
3. Android paket adı: `com.tattink.tattinkApp`
4. Uygulamayı ekledikten sonra `google-services.json` dosyasını indirin
5. Bu dosyayı `android/app/` klasörüne kopyalayın

Android için gerekli bilgiler:
- **apiKey**: `google-services.json` dosyasındaki `current_key` veya `api_key` değeri
- **appId**: `google-services.json` dosyasındaki `mobilesdk_app_id` değeri
- **messagingSenderId**: `google-services.json` dosyasındaki `project_number` değeri
- **projectId**: Proje ID'niz (Firebase Console'da görünür)
- **storageBucket**: `[PROJECT_ID].appspot.com` formatında

## iOS Uygulaması İçin:

1. Firebase Console > Proje Ayarları > Genel
2. "iOS uygulamanızı ekleyin" butonuna tıklayın
3. iOS paket ID: `com.tattink.tattinkApp`
4. Uygulamayı ekledikten sonra `GoogleService-Info.plist` dosyasını indirin
5. Bu dosyayı Xcode'da `ios/Runner/` klasörüne ekleyin

iOS için gerekli bilgiler:
- **apiKey**: `GoogleService-Info.plist` dosyasındaki `API_KEY` değeri
- **appId**: `GoogleService-Info.plist` dosyasındaki `GOOGLE_APP_ID` değeri
- **messagingSenderId**: `GoogleService-Info.plist` dosyasındaki `GCM_SENDER_ID` değeri
- **projectId**: Proje ID'niz
- **storageBucket**: `[PROJECT_ID].appspot.com` formatında
- **iosBundleId**: `com.tattink.tattinkApp`

## Manuel Yapılandırma

`lib/firebase_options.dart` dosyasını açın ve aşağıdaki değerleri doldurun:

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'BURAYA_ANDROID_API_KEY',
  appId: 'BURAYA_ANDROID_APP_ID',
  messagingSenderId: 'BURAYA_MESSAGING_SENDER_ID',
  projectId: 'BURAYA_PROJECT_ID',
  storageBucket: 'BURAYA_STORAGE_BUCKET',
);

static const FirebaseOptions ios = FirebaseOptions(
  apiKey: 'BURAYA_IOS_API_KEY',
  appId: 'BURAYA_IOS_APP_ID',
  messagingSenderId: 'BURAYA_MESSAGING_SENDER_ID',
  projectId: 'BURAYA_PROJECT_ID',
  storageBucket: 'BURAYA_STORAGE_BUCKET',
  iosBundleId: 'com.tattink.tattinkApp',
);
```

## Otomatik Yapılandırma (FlutterFire CLI)

Terminal'de şu komutu çalıştırın:

```bash
flutterfire configure
```

Bu komut:
1. Firebase projelerinizi listeler
2. Projenizi seçmenizi ister
3. Android ve iOS platformlarını seçmenizi ister
4. Otomatik olarak `firebase_options.dart` dosyasını oluşturur

## Önemli Notlar

1. **google-services.json** (Android) ve **GoogleService-Info.plist** (iOS) dosyalarını projeye eklemeyi unutmayın
2. Android için `android/build.gradle` ve `android/app/build.gradle` dosyalarında Google Services plugin'inin eklendiğinden emin olun
3. iOS için `ios/Podfile` dosyasında gerekli pod'ların yüklendiğinden emin olun

