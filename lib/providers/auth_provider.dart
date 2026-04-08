import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/services/firebase_service.dart';

class AuthProvider extends ChangeNotifier {
  final _firebase = FirebaseService();

  bool _loading = false;
  bool _skipLogin = false;
  String? _lastSynced;

  bool get loading => _loading;
  bool get isLoggedIn => _firebase.isLoggedIn;
  bool get skipLogin => _skipLogin;
  bool get showLoginScreen => !_skipLogin && !isLoggedIn;
  String? get userName => _firebase.userName;
  String? get userEmail => _firebase.userEmail;
  String? get userPhotoUrl => _firebase.userPhotoUrl;
  String? get lastSynced => _lastSynced;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _skipLogin = prefs.getBool('skip_login') ?? false;
    _lastSynced = prefs.getString('last_synced');
    await _firebase.init();
    notifyListeners();
  }

  Future<bool> signInWithGoogle() async {
    _loading = true;
    notifyListeners();
    final ok = await _firebase.signInWithGoogle();
    _loading = false;
    notifyListeners();
    return ok;
  }

  Future<void> skipAndContinue() async {
    _skipLogin = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('skip_login', true);
    notifyListeners();
  }

  Future<void> syncNow(Map<String, dynamic> data) async {
    _loading = true;
    notifyListeners();
    await _firebase.syncToCloud(data);
    final now = DateTime.now().toString().substring(0, 16);
    _lastSynced = now;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_synced', now);
    _loading = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _firebase.signOut();
    _skipLogin = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('skip_login', false);
    notifyListeners();
  }
}
