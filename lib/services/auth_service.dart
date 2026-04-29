import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class AuthService {
  // ── Pick ONE, comment the others ──
  // ✅ Android Emulator
  // ✅ Replace YOUR_RAILWAY_URL with your actual Railway URL
  static const String _baseUrl = 'https://autosilence-backend-production.up.railway.app/api';
  // ❌ iOS Simulator
  // ❌ Real device — replace X.X with your PC IP

  static const _storage  = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';
  static const _userKey  = 'auth_user';
  static const _guestKey = 'is_guest';
  static const _timeout = Duration(seconds: 60);
  // static final _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  // ══════════════════════════════════════
  // STEP 1: REGISTER — sends OTP to email
  // Returns { success, message, email }
  // ══════════════════════════════════════
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      ).timeout(_timeout);
      return jsonDecode(res.body);
    }on TimeoutException {
      return {'success': false, 'message': 'Server took too long. Try again.'};
    } catch (e) {
      return {'success': false, 'message': 'Something went wrong. Try again.'};
    }
  }

  // ══════════════════════════════════════
  // STEP 2: VERIFY OTP
  // purpose: 'email_verify' | 'forgot'
  // On success saves token and logs in
  // ══════════════════════════════════════
  static Future<Map<String, dynamic>> verifyOTP({
    required String email,
    required String otp,
    required String purpose,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp, 'purpose': purpose}),
      ).timeout(_timeout);
      final data = jsonDecode(res.body);
      if (data['success'] == true && purpose == 'email_verify') {
        await _saveSession(data);
      }
      return data;
    }catch (e) {
      final msg = e.toString();
      String error = 'Something went wrong. Try again.';
      if (msg.contains('TimeoutException')) error = 'Server took too long. Try again.';
      if (msg.contains('SocketException')) error = 'No internet connection.';
      return {'success': false, 'message': error};
    }
  }

  // ══════════════════════════════════════
  // RESEND OTP
  // ══════════════════════════════════════
  static Future<Map<String, dynamic>> resendOTP({
    required String email,
    required String purpose,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/auth/resend-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'purpose': purpose}),
      ).timeout(_timeout);
      return jsonDecode(res.body);
    } catch (e) {
      final msg = e.toString();
      String error = 'Something went wrong. Try again.';
      if (msg.contains('TimeoutException')) error = 'Server took too long. Try again.';
      if (msg.contains('SocketException')) error = 'No internet connection.';
      return {'success': false, 'message': error};
    }
  }

  // ══════════════════════════════════════
  // LOGIN — email + password
  // ══════════════════════════════════════
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(_timeout);
      final data = jsonDecode(res.body);
      if (data['success'] == true) await _saveSession(data);
      return data;
    } catch (e) {
      final msg = e.toString();
      String error = 'Something went wrong. Try again.';
      if (msg.contains('TimeoutException')) error = 'Server took too long. Try again.';
      if (msg.contains('SocketException')) error = 'No internet connection.';
      return {'success': false, 'message': error};
    }
  }

  // ══════════════════════════════════════
  // GOOGLE STEP 1 — get idToken, call backend
  // Returns:
  //   { success, needsOTP, email, googleName } for new users
  //   { success, token, user } for existing users
  // ══════════════════════════════════════
  // static Future<Map<String, dynamic>> googleSignIn() async {
  //   try {
  //     final googleUser = await _googleSignIn.signIn();
  //     if (googleUser == null) {
  //       return {'success': false, 'message': 'Google sign-in cancelled.'};
  //     }
  //
  //     final googleAuth = await googleUser.authentication;
  //     final idToken    = googleAuth.idToken;
  //
  //     if (idToken == null) {
  //       return {'success': false, 'message': 'Failed to get Google token.'};
  //     }
  //
  //     final res  = await http.post(
  //       Uri.parse('$_baseUrl/auth/google'),
  //       headers: {'Content-Type': 'application/json'},
  //       body: jsonEncode({'idToken': idToken}),
  //     );
  //     final data = jsonDecode(res.body);
  //
  //     // If existing user → save session and done
  //     if (data['success'] == true && data['needsOTP'] != true) {
  //       await _saveSession(data);
  //     }
  //
  //     return data;
  //   }catch (e) {
  //     final msg = e.toString();
  //     String error = 'Something went wrong. Try again.';
  //     if (msg.contains('TimeoutException')) error = 'Server took too long. Try again.';
  //     if (msg.contains('SocketException')) error = 'No internet connection.';
  //     return {'success': false, 'message': error};
  //   }
  // }

  // ══════════════════════════════════════
  // GOOGLE STEP 2 — confirm OTP + name
  // ══════════════════════════════════════
  // static Future<Map<String, dynamic>> googleComplete({
  //   required String email,
  //   required String otp,
  //   required String name,
  // }) async {
  //   try {
  //     final res = await http.post(
  //       Uri.parse('$_baseUrl/auth/google-complete'),
  //       headers: {'Content-Type': 'application/json'},
  //       body: jsonEncode({'email': email, 'otp': otp, 'name': name}),
  //     );
  //     final data = jsonDecode(res.body);
  //     if (data['success'] == true) await _saveSession(data);
  //     return data;
  //   } catch (e) {
  //     final msg = e.toString();
  //     String error = 'Something went wrong. Try again.';
  //     if (msg.contains('TimeoutException')) error = 'Server took too long. Try again.';
  //     if (msg.contains('SocketException')) error = 'No internet connection.';
  //     return {'success': false, 'message': error};
  //   }
  // }

  // ══════════════════════════════════════
  // FORGOT PASSWORD — sends OTP
  // ══════════════════════════════════════
  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      ).timeout(_timeout);
      return jsonDecode(res.body);
    }catch (e) {
      final msg = e.toString();
      String error = 'Something went wrong. Try again.';
      if (msg.contains('TimeoutException')) error = 'Server took too long. Try again.';
      if (msg.contains('SocketException')) error = 'No internet connection.';
      return {'success': false, 'message': error};
    }
  }

  // ══════════════════════════════════════
  // RESET PASSWORD — OTP + new password
  // ══════════════════════════════════════
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String password,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp, 'password': password}),
      ).timeout(_timeout);
      final data = jsonDecode(res.body);
      if (data['success'] == true) await _saveSession(data);
      return data;
    } catch (e) {
      final msg = e.toString();
      String error = 'Something went wrong. Try again.';
      if (msg.contains('TimeoutException')) error = 'Server took too long. Try again.';
      if (msg.contains('SocketException')) error = 'No internet connection.';
      return {'success': false, 'message': error};
    }
  }

  // ══════════════════════════════════════
  // GUEST
  // ══════════════════════════════════════
  static Future<void> continueAsGuest() async {
    await _storage.write(key: _guestKey, value: 'true');
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }

  // ══════════════════════════════════════
  // LOGOUT
  // ══════════════════════════════════════
  static Future<void> logout() async {
    // await _googleSignIn.signOut().catchError((_) {});
    await _storage.deleteAll();
  }

  // ══════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════
  static Future<bool> isLoggedIn() async {
    final token   = await _storage.read(key: _tokenKey);
    final isGuest = await _storage.read(key: _guestKey);
    return (token != null && token.isNotEmpty) || (isGuest == 'true');
  }

  static Future<bool> isGuest() async {
    return await _storage.read(key: _guestKey) == 'true';
  }

  static Future<String?> getToken() async =>
      _storage.read(key: _tokenKey);

  static Future<Map<String, dynamic>?> getStoredUser() async {
    final json = await _storage.read(key: _userKey);
    if (json == null) return null;
    return jsonDecode(json);
  }

  static Future<void> _saveSession(Map<String, dynamic> data) async {
    if (data['token'] != null) {
      await _storage.write(key: _tokenKey, value: data['token']);
    }
    if (data['user'] != null) {
      await _storage.write(key: _userKey, value: jsonEncode(data['user']));
    }
    await _storage.delete(key: _guestKey);
  }

  static Future<void> saveUser(Map<String, dynamic> user) async {
    await _storage.write(key: _userKey, value: jsonEncode(user));
  }
}

