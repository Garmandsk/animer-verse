import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
// Import standar (tanpa alias 'as ...' untuk menghindari kebingungan)
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  // Singleton Pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;  

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- INISIALISASI GOOGLE SIGN IN ---
  // Kita gunakan constructor standar. 
  // Untuk Web, Client ID dimasukkan lewat parameter clientId di sini.
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  
  AuthService._internal() {
    // Jalankan inisialisasi di sini
    _initGoogleSignIn();
  }

  void _initGoogleSignIn() {
    // unawaited memberitahu Flutter: "Jalanin aja di background, gak usah ditungguin"
    unawaited(
      _googleSignIn.initialize(
        clientId: kIsWeb
            ? '101643469100-bvvij3rb3a50rlrf8qjl7ru1pt1tmr8t.apps.googleusercontent.com'
            : null,
      ).then((_) {
        debugPrint('✅ Google Sign-In Initialized!');

        // PERBAIKAN DI SINI:
        // Gunakan tipe 'GoogleSignInAuthenticationEvent', bukan 'GoogleSignInAuthentication'
        _googleSignIn.authenticationEvents.listen(
          (GoogleSignInAuthenticationEvent event) async {
            
            // Kita harus cek jenis event-nya (Sign In atau Sign Out)
            switch (event) {
              case GoogleSignInAuthenticationEventSignIn(user: final user):
                // Event SIGN IN terjadi
                debugPrint('✅ User Signed In: ${user.email}');
                
                // Kalau mau lihat token (untuk debug saja):
                final auth = await user.authentication;
                debugPrint('🔑 Token ID: ${auth.idToken?.substring(0, 10)}...');
                break;

              case GoogleSignInAuthenticationEventSignOut():
                // Event SIGN OUT terjadi
                debugPrint('👋 User Signed Out');
                break;
            }
          },
          onError: (error) {
            debugPrint('❌ Google Sign-In Auth Event Error: $error');
          },
        );

        // Fitur "One Tap" (Login otomatis di Web)
        if (kIsWeb) {
          _googleSignIn.attemptLightweightAuthentication();
        }
      }).catchError((e) {
        debugPrint('❌ Gagal Inisialisasi Google Sign In: $e');
      }),
    );
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // --- LOGIN GOOGLE (CARA STANDAR & STABIL) ---
  Future<UserCredential> signInWithGoogle() async {
    try {
      // 1. Pemicu Login (Popup di Web / Halaman pilih akun di Android)
      // Method signIn() ini sudah otomatis menangani inisialisasi di dalamnya.
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // Jika user menutup popup / tekan back
      if (googleUser == null) {
        throw AuthException('Login dibatalkan oleh user');
      }

      // 2. Ambil Token Autentikasi
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Buat Credential untuk Firebase
      final OAuthCredential credential = GoogleAuthProvider.credential(        
        idToken: googleAuth.idToken,
      );

      // 4. Masuk ke Firebase
      return await _auth.signInWithCredential(credential);

    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      // Tangkap error lain (termasuk error dari Google Sign In)
      throw AuthException('Gagal Login: ${e.toString()}');
    }
  }

  // --- LOGOUT ---
  Future<void> signOut() async {
    await _googleSignIn.signOut(); // Logout Google
    await _auth.signOut();         // Logout Firebase
  }

  // --- FUNGSI EMAIL & PASSWORD (SAMA SEPERTI SEBELUMNYA) ---
  Future<UserCredential> signInWithEmail({
    required String email, 
    required String password
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  // --- ERROR HANDLING ---
  AuthException _handleFirebaseAuthException(FirebaseAuthException e) {
    // Sederhanakan pesan error untuk user
    return AuthException(e.message ?? "Terjadi kesalahan autentikasi");
  }
}

// Class Exception Sederhana
class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}