import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class UserProvider extends ChangeNotifier {
  Map<String, dynamic>? _user;
  bool _isLoggedIn = false;
  bool _isGuest    = false;
  bool _isLoading  = true;

  Map<String, dynamic>? get user      => _user;
  bool                  get isLoggedIn => _isLoggedIn;
  bool                  get isGuest    => _isGuest;
  bool                  get isLoading  => _isLoading;

  Future<void> _fetchFromApi() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return;
      final res = await http.get(
        Uri.parse('https://autosilence-backend-production.up.railway.app/api/auth/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type':  'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);
      if (data['success'] == true && data['user'] != null) {
        _user = Map<String, dynamic>.from(data['user']);
        await AuthService.saveUser(_user!);
      }
    } catch (_) {
      // silently fail — local storage data will be used
    }
  }
  // ══════════════════════════════════════
  // Called on app start from SplashScreen
  // Reads saved token + user from device
  // ══════════════════════════════════════
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    final guest    = await AuthService.isGuest();
    final loggedIn = await AuthService.isLoggedIn();

    if (guest) {
      _user       = null;
      _isLoggedIn = false;
      _isGuest    = true;
    } else if (loggedIn) {
      _user       = await AuthService.getStoredUser();
      _isLoggedIn = true;
      _isGuest    = false;
      await _fetchFromApi();
    } else {
      _user       = null;
      _isLoggedIn = false;
      _isGuest    = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  // ══════════════════════════════════════
  // Call after successful login/signup
  // ══════════════════════════════════════
  Future<void> setUser(Map<String, dynamic> userData) async {
    _user       = userData;
    _isLoggedIn = true;
    _isGuest    = false;
    notifyListeners();
  }

  // ══════════════════════════════════════
  // Update specific fields (name, avatar)
  // Called from profile screen after save
  // ══════════════════════════════════════
  Future<void> updateUser(Map<String, dynamic> updated) async {
    if (_user == null) return;
    _user = {..._user!, ...updated};
    await AuthService.saveUser(_user!);
    notifyListeners();
  }

  // ══════════════════════════════════════
  // Guest mode
  // ══════════════════════════════════════
  Future<void> setGuest() async {
    await AuthService.continueAsGuest();
    _user       = null;
    _isLoggedIn = false;
    _isGuest    = true;
    notifyListeners();
  }

  // ══════════════════════════════════════
  // Logout
  // ══════════════════════════════════════
  Future<void> logout() async {
    await AuthService.logout();
    _user       = null;
    _isLoggedIn = false;
    _isGuest    = false;
    notifyListeners();
  }

  // ══════════════════════════════════════
  // Convenience getters
  // ══════════════════════════════════════
  String get displayName {
    if (_user == null) return 'Guest';
    return _user!['name'] ?? 'User';
  }

  String get email {
    if (_user == null) return '';
    return _user!['email'] ?? '';
  }

  String? get avatarUrl => _user?['avatar'];

  bool get isPremium => _user?['isPremium'] == true;

  String get initials {
    final name = displayName;
    if (name == 'Guest' || name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}