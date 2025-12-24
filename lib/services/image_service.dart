import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import '../utils/constants.dart';

class ImageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // 1. Optimize and Smart Crop Image (4:5 Ratio)
  Future<Uint8List> optimizeImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final originalImage = img.decodeImage(bytes);

    if (originalImage == null) {
      throw Exception('Görsel işlenemedi');
    }

    // --- AKILLI KIRPMA (4:5 ORANI ZORLAMASI) ---
    const double targetAspect = 0.8; // 4/5 oranı
    int width = originalImage.width;
    int height = originalImage.height;
    double currentAspect = width / height;

    img.Image croppedImage;

    if (currentAspect > targetAspect) {
      // Görsel çok yatay, yanlardan kesiyoruz
      int newWidth = (height * targetAspect).toInt();
      int xOffset = (width - newWidth) ~/ 2;
      croppedImage = img.copyCrop(originalImage, x: xOffset, y: 0, width: newWidth, height: height);
    } else if (currentAspect < targetAspect) {
      // Görsel çok dikey, alt ve üstten kesiyoruz
      int newHeight = (width / targetAspect).toInt();
      int yOffset = (height - newHeight) ~/ 2;
      croppedImage = img.copyCrop(originalImage, x: 0, y: yOffset, width: width, height: newHeight);
    } else {
      croppedImage = originalImage;
    }

    // Resize if needed (Genişliği max limite çek, boy oranla otomatik ayarlanır)
    img.Image resizedImage = croppedImage;
    if (croppedImage.width > AppConstants.maxImageWidth) {
      resizedImage = img.copyResize(
        croppedImage,
        width: AppConstants.maxImageWidth,
      );
    }

    // Convert to JPEG and compress
    final jpegBytes = Uint8List.fromList(
      img.encodeJpg(resizedImage, quality: AppConstants.imageQuality),
    );

    return jpegBytes;
  }

  // 2. Upload image to Firebase Storage (Eksik olan buydu)
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

  // 3. Upload file (PDF vb. belgeler için, kayıt sayfasında lazım)
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