# iOS Build Sorunları ve Çözümleri

## ✅ Yapılan Düzeltmeler

1. **iOS Deployment Target:** 13.0 → 14.0'a yükseltildi
   - `ios/Podfile` dosyasında `platform :ios, '14.0'` ayarlandı
   - `ios/Runner.xcodeproj/project.pbxproj` dosyasında `IPHONEOS_DEPLOYMENT_TARGET = 14.0` ayarlandı
   - `Podfile`'ın `post_install` bölümüne deployment target ayarı eklendi

## Simulator için Çalıştırma

Simulator için code signing gerekmez. Şu komutla çalıştırabilirsiniz:

```bash
flutter run
```

Veya belirli bir simulator seçmek için:

```bash
# Mevcut simulator'leri listeleyin
flutter devices

# Belirli bir simulator seçin
flutter run -d <simulator-id>
```

## Gerçek Cihaz için Çalıştırma

Gerçek iOS cihazında çalıştırmak için:

1. Xcode'u açın:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. Xcode'da:
   - Sol panelde "Runner" projesini seçin
   - "Runner" target'ını seçin
   - "Signing & Capabilities" sekmesine gidin
   - "Team" altından Apple Developer hesabınızı seçin
   - Xcode otomatik olarak provisioning profile oluşturacak

3. Flutter ile çalıştırın:
   ```bash
   flutter run
   ```

## Yaygın Sorunlar

### Pod Install Hatası
Eğer pod install hatası alırsanız:

```bash
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
```

### Encoding Hatası
Terminal encoding sorunu için:

```bash
export LANG=en_US.UTF-8
```

### Firebase Yapılandırması Eksik
Firebase yapılandırması yapılmadıysa:

```bash
flutterfire configure
```

veya manuel olarak `lib/firebase_options.dart` dosyasını düzenleyin.

## Build Başarılı! 🎉

iOS build başarıyla tamamlandı. Artık uygulamayı çalıştırabilirsiniz.

