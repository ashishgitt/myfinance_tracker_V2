import 'package:flutter/foundation.dart';
// Firebase imports — wrapped in try/catch; graceful fallback if
// google-services.json is missing or Firebase not configured.
// 
// SETUP INSTRUCTIONS:
// 1. Create a Firebase project at https://console.firebase.google.com
// 2. Add an Android app with package name: com.myfinance.tracker
// 3. Download google-services.json → place at android/app/google-services.json
// 4. Enable Google Sign-In in Firebase Console → Authentication → Sign-in method
// 5. Enable Cloud Firestore in Firebase Console → Firestore Database
// 6. In android/build.gradle add: classpath 'com.google.gms:google-services:4.4.0'
// 7. In android/app/build.gradle add: apply plugin: 'com.google.gms.google-services'

import 'package:google_sign_in/google_sign_in.dart';

class FirebaseService {
  static final FirebaseService _i = FirebaseService._();
  factory FirebaseService() => _i;
  FirebaseService._();

  final _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  bool _initialized = false;
  String? _userId;
  String? _userName;
  String? _userEmail;
  String? _userPhotoUrl;

  bool get isInitialized => _initialized;
  bool get isLoggedIn => _userId != null;
  String? get userId => _userId;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get userPhotoUrl => _userPhotoUrl;

  Future<void> init() async {
    try {
      // Try to restore previous session
      final account = await _googleSignIn.signInSilently();
      if (account != null) {
        _userId = account.id;
        _userName = account.displayName;
        _userEmail = account.email;
        _userPhotoUrl = account.photoUrl;
      }
      _initialized = true;
    } catch (e) {
      debugPrint('FirebaseService.init error (non-fatal): $e');
      _initialized = true; // Mark initialized even if Firebase missing
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return false;
      _userId = account.id;
      _userName = account.displayName;
      _userEmail = account.email;
      _userPhotoUrl = account.photoUrl;
      return true;
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      _userId = null;
      _userName = null;
      _userEmail = null;
      _userPhotoUrl = null;
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }

  Future<void> syncToCloud(Map<String, dynamic> data) async {
    if (!isLoggedIn) return;
    try {
      // Firestore sync (only works when Firebase is configured)
      // The import is done dynamically to avoid crash when not configured
      debugPrint('Cloud sync requested for user $_userId');
      // TODO: Uncomment once google-services.json is added:
      // final firestore = FirebaseFirestore.instance;
      // await firestore.collection('users').doc(_userId).set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Cloud sync error (non-fatal): $e');
    }
  }

  Future<Map<String, dynamic>?> fetchFromCloud() async {
    if (!isLoggedIn) return null;
    try {
      debugPrint('Cloud fetch requested for user $_userId');
      // TODO: Uncomment once google-services.json is added:
      // final firestore = FirebaseFirestore.instance;
      // final doc = await firestore.collection('users').doc(_userId).get();
      // return doc.data();
      return null;
    } catch (e) {
      debugPrint('Cloud fetch error (non-fatal): $e');
      return null;
    }
  }
}
