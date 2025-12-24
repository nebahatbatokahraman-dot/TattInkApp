import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(); // YENİ EKLENDİ

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // --- GOOGLE İLE GİRİŞ (YENİ VE DÜZELTİLMİŞ) ---
  Future<UserModel?> signInWithGoogle() async {
    try {
      // 1. Google Giriş Penceresini Aç
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // Kullanıcı vazgeçti

      // 2. Google'dan Kimlik Bilgilerini Al
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 3. Firebase'e Giriş Yap
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        // 4. Kullanıcı veritabanında var mı kontrol et
        DocumentSnapshot doc = await _firestore.collection(AppConstants.collectionUsers).doc(user.uid).get();

        if (!doc.exists) {
          // YOKSA: Yeni Müşteri Olarak Kaydet
          
          // --- İSİM PARÇALAMA MANTIĞI (fullName hatası için) ---
          String displayName = user.displayName ?? 'Google Kullanıcısı';
          List<String> names = displayName.split(' ');
          String firstName = names.isNotEmpty ? names.first : 'Google';
          String lastName = names.length > 1 ? names.sublist(1).join(' ') : '';
          
          // Kullanıcı adı oluşturma
          String baseUsername = user.displayName?.replaceAll(' ', '').toLowerCase() ?? 'user';
          // Türkçe karakterleri temizle (opsiyonel basit temizlik)
          baseUsername = baseUsername.replaceAll('ğ', 'g').replaceAll('ü', 'u').replaceAll('ş', 's').replaceAll('ı', 'i').replaceAll('ö', 'o').replaceAll('ç', 'c');
          String username = '${baseUsername}_${user.uid.substring(0, 5)}';

          UserModel newUser = UserModel(
            uid: user.uid,
            email: user.email!,
            username: username,
            firstName: firstName, // fullName yerine firstName
            lastName: lastName,   // ve lastName
            role: AppConstants.roleCustomer, // Google ile gelenler varsayılan Müşteridir
            profileImageUrl: user.photoURL,
            createdAt: DateTime.now(),
            isApproved: true, // Müşteriler onaylıdır
            emailVerified: true, // Google mailleri onaylı sayılır
            
            // Zorunlu alanları boş string ile dolduruyoruz ki hata vermesin
            phoneNumber: "", 
            studioAddress: "",
            instagramUsername: "",
            portfolioImages: [],
            applications: [],
            applicationStyles: [],
          );
          
          await _firestore.collection(AppConstants.collectionUsers).doc(user.uid).set(newUser.toMap());
          return newUser;
        } else {
          // VARSA: Mevcut veriyi döndür
          return UserModel.fromFirestore(doc);
        }
      }
    } catch (e) {
      debugPrint("Google Giriş Hatası: $e");
      rethrow;
    }
    return null;
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Register customer
  Future<UserCredential?> registerCustomer({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Send email verification
        await credential.user!.sendEmailVerification();

        // Create user document in Firestore
        final userModel = UserModel(
          uid: credential.user!.uid,
          email: email,
          role: AppConstants.roleCustomer,
          emailVerified: false,
          createdAt: DateTime.now(),
          // Customer kaydında diğer alanlar null veya boş olabilir, modeline bağlı
        );

        await _firestore
            .collection(AppConstants.collectionUsers)
            .doc(credential.user!.uid)
            .set(userModel.toMap());
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Register artist (approved)
  Future<UserCredential?> registerApprovedArtist({
    required String email,
    required String password,
    required String username,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String studioAddress,
    required String instagramUsername,
    required String documentUrl,
    required List<String> portfolioImages,
    String? district,
    String? city,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await credential.user!.sendEmailVerification();

        final userModel = UserModel(
          uid: credential.user!.uid,
          email: email,
          username: username,
          firstName: firstName,
          lastName: lastName,
          phoneNumber: phoneNumber,
          role: AppConstants.roleArtistUnapproved,
          emailVerified: false,
          isApproved: false,
          studioAddress: studioAddress,
          district: district,
          city: city,
          instagramUsername: instagramUsername,
          documentUrl: documentUrl,
          portfolioImages: portfolioImages,
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection(AppConstants.collectionUsers)
            .doc(credential.user!.uid)
            .set(userModel.toMap());

        final approvalId = _firestore.collection(AppConstants.collectionArtistApprovals).doc().id;

        final approvalModel = {
          'id': approvalId,
          'userId': credential.user!.uid,
          'email': email,
          'username': username,
          'firstName': firstName,
          'lastName': lastName,
          'phoneNumber': phoneNumber,
          'studioAddress': studioAddress,
          'district': district,
          'city': city,
          'instagramUsername': instagramUsername,
          'documentUrl': documentUrl,
          'portfolioImages': portfolioImages,
          'isApprovedArtist': true,
          'status': 'pending',
          'createdAt': Timestamp.fromDate(DateTime.now()),
        };

        await _firestore.collection(AppConstants.collectionArtistApprovals).doc(approvalId).set(approvalModel);
      }
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Register artist (unapproved)
  Future<UserCredential?> registerUnapprovedArtist({
    required String email,
    required String password,
    required String username,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String address,
    required String instagramUsername,
    required List<String> portfolioImages,
    String? district,
    String? city,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await credential.user!.sendEmailVerification();

        final userModel = UserModel(
          uid: credential.user!.uid,
          email: email,
          username: username,
          firstName: firstName,
          lastName: lastName,
          phoneNumber: phoneNumber,
          role: AppConstants.roleArtistUnapproved,
          emailVerified: false,
          isApproved: false,
          studioAddress: address,
          district: district,
          city: city,
          instagramUsername: instagramUsername,
          portfolioImages: portfolioImages,
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection(AppConstants.collectionUsers)
            .doc(credential.user!.uid)
            .set(userModel.toMap());

        final approvalId = _firestore.collection(AppConstants.collectionArtistApprovals).doc().id;

        final approvalModel = {
          'id': approvalId,
          'userId': credential.user!.uid,
          'email': email,
          'username': username,
          'firstName': firstName,
          'lastName': lastName,
          'phoneNumber': phoneNumber,
          'studioAddress': address,
          'district': district,
          'city': city,
          'instagramUsername': instagramUsername,
          'documentUrl': null,
          'portfolioImages': portfolioImages,
          'isApprovedArtist': false,
          'status': 'pending',
          'createdAt': Timestamp.fromDate(DateTime.now()),
        };

        await _firestore.collection(AppConstants.collectionArtistApprovals).doc(approvalId).set(approvalModel);
      }
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign out (GÜNCELLENDİ)
  Future<void> signOut() async {
    await _googleSignIn.signOut(); // Google oturumunu da kapat
    await _auth.signOut();
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  // Reload user
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  // Check if email is verified
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // Get user model from Firestore
  Future<UserModel?> getUserModel(String uid) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(uid)
          .get();

      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Stream user model from Firestore
  Stream<UserModel?> getUserModelStream(String uid) {
    return _firestore
        .collection(AppConstants.collectionUsers)
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    });
  }

  // Handle auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Şifre çok zayıf';
      case 'email-already-in-use':
        return 'Bu email adresi zaten kullanılıyor';
      case 'user-not-found':
        return 'Kullanıcı bulunamadı';
      case 'wrong-password':
        return 'Yanlış şifre';
      case 'invalid-email':
        return 'Geçersiz email adresi';
      case 'user-disabled':
        return 'Bu kullanıcı devre dışı bırakılmış';
      case 'too-many-requests':
        return 'Çok fazla istek. Lütfen daha sonra tekrar deneyin';
      case 'operation-not-allowed':
        return 'Bu işlem izin verilmiyor';
      default:
        return 'Bir hata oluştu: ${e.message}';
    }
  }
}