import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import '../utils/constants.dart';
import '../theme/app_theme.dart';

class ImageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // 1. Optimize Image (Kırpma İPTAL EDİLDİ, Sadece Boyutlandırma)
  Future<Uint8List> optimizeImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final originalImage = img.decodeImage(bytes);

    if (originalImage == null) {
      throw Exception('Görsel işlenemedi');
    }

    // --- DEĞİŞİKLİK BURADA: ARTIK ZORUNLU KIRPMA YOK ---
    // Resmi olduğu gibi alıyoruz, sadece çok büyükse küçülteceğiz.
    img.Image resizedImage = originalImage;

    // Resize if needed (Genişliği max limite çek, boy oranla otomatik ayarlanır)
    // Bu sayede resim kesilmez, sadece dosya boyutu optimize edilir.
    if (originalImage.width > AppConstants.maxImageWidth) {
      resizedImage = img.copyResize(
        originalImage,
        width: AppConstants.maxImageWidth,
        // height parametresi vermediğimiz için 'image' paketi 
        // otomatik olarak en-boy oranını korur (maintainAspect: true).
      );
    }

    // Convert to JPEG and compress
    final jpegBytes = Uint8List.fromList(
      img.encodeJpg(resizedImage, quality: AppConstants.imageQuality),
    );

    return jpegBytes;
  }

  // 2. Upload image to Firebase Storage
  Future<String> uploadImage({
    required Uint8List imageBytes,
    required String path,
    String? fileName,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final name = fileName ?? 'image_$timestamp.jpg';
      final ref = _storage.ref().child('$path/$name');

      final uploadTask = ref.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Görsel yüklenirken hata oluştu: $e');
    }
  }

  // 3. Upload file (PDF vb. belgeler için)
  Future<String> uploadFile({
    required File file,
    required String path,
    String? fileName,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final name = fileName ?? 'file_$timestamp';
      final ref = _storage.ref().child('$path/$name');

      final uploadTask = ref.putFile(file);

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Dosya yüklenirken hata oluştu: $e');
    }
  }

  // 4. Delete image from Storage
  Future<void> deleteImage(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      // Dosya zaten yoksa hata verme
    }
  }
}