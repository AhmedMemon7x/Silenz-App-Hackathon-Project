import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/schedule_model.dart';
import 'auth_service.dart';

class ScheduleService {
  // ✅ Replace YOUR_RAILWAY_URL with your actual Railway URL
  static const String _baseUrl = 'https://autosilence-backend-production.up.railway.app/api';
  // When deploying → replace with Railway URL above

  static const _storage           = FlutterSecureStorage();
  static const _localSchedulesKey = 'guest_schedules';

  // ════════════════════════════════════════
  // LOAD
  // Guest   → from device local storage
  // LoggedIn → from MongoDB API
  // ════════════════════════════════════════
  static Future<List<Schedule>> loadSchedules() async {
    final isGuest = await AuthService.isGuest();
    return isGuest ? _loadLocal() : _loadFromApi();
  }

  // ════════════════════════════════════════
  // ADD
  // ════════════════════════════════════════
  static Future<Schedule?> addSchedule(Schedule schedule) async {
    final isGuest = await AuthService.isGuest();

    if (isGuest) {
      final all = await _loadLocal();
      all.insert(0, schedule);
      await _saveLocal(all);
      return schedule;
    } else {
      return _createOnApi(schedule);
    }
  }

  // ════════════════════════════════════════
  // UPDATE
  // ════════════════════════════════════════
  static Future<bool> updateSchedule(Schedule schedule) async {
    final isGuest = await AuthService.isGuest();

    if (isGuest) {
      final all = await _loadLocal();
      final idx = all.indexWhere((s) => s.id == schedule.id);
      if (idx != -1) {
        all[idx] = schedule;
        await _saveLocal(all);
      }
      return true;
    } else {
      return _updateOnApi(schedule);
    }
  }

  // ════════════════════════════════════════
  // DELETE
  // ════════════════════════════════════════
  static Future<bool> deleteSchedule(String id) async {
    final isGuest = await AuthService.isGuest();

    if (isGuest) {
      final all = await _loadLocal();
      all.removeWhere((s) => s.id == id);
      await _saveLocal(all);
      return true;
    } else {
      return _deleteOnApi(id);
    }
  }

  // ════════════════════════════════════════
  // TOGGLE
  // ════════════════════════════════════════
  static Future<bool> toggleSchedule(Schedule schedule) async {
    schedule.isEnabled = !schedule.isEnabled;
    return updateSchedule(schedule);
  }

  // ════════════════════════════════════════
  // SYNC GUEST → CLOUD  (called on login)
  //
  // CORRECT BEHAVIOUR:
  //  - Read guest schedules from local storage
  //  - POST to /schedules/sync  →  backend MERGES them
  //    into existing cloud schedules (does NOT delete old ones)
  //  - Clear local guest storage
  //  - Return the combined list from API
  //
  // If guest had NO schedules → skip sync, just load from API
  // ════════════════════════════════════════
  static Future<List<Schedule>> syncGuestToCloud() async {
    final guestSchedules = await _loadLocal();

    try {
      final token   = await AuthService.getToken();
      final headers = {
        'Content-Type':  'application/json',
        'Authorization': 'Bearer $token',
      };

      // Always call /sync — backend handles empty list gracefully
      // and returns all existing cloud schedules
      final res  = await http.post(
        Uri.parse('$_baseUrl/schedules/sync'),
        headers: headers,
        body: jsonEncode({
          'schedules': guestSchedules.map((s) => s.toJson()).toList(),
        }),
      );

      final data = jsonDecode(res.body);

      if (data['success'] == true) {
        // ✅ FIX: Always clear guest storage after login
        // so next guest session starts fresh
        await clearGuestStorage();

        // Return MERGED list from backend (existing + guest)
        return (data['data'] as List)
            .map((j) => Schedule.fromApi(j))
            .toList();
      }
    } catch (_) {
      // If network fails, just clear local storage and return empty
      // Cloud schedules will load normally when connection resumes
      await clearGuestStorage();
    }

    // Fallback — try loading cloud directly
    return _loadFromApi();
  }

  // ════════════════════════════════════════
  // LOAD FROM CLOUD ONLY (for logged-in users)
  // Used after login — ignores local guest storage
  // ════════════════════════════════════════
  static Future<List<Schedule>> loadFromCloud() async {
    return _loadFromApi();
  }

  // ════════════════════════════════════════
  // CLEAR GUEST STORAGE
  // Called on logout so next guest session is fresh
  // Called on login so guest schedules are discarded
  // ════════════════════════════════════════
  static Future<void> clearGuestStorage() async {
    await _storage.delete(key: _localSchedulesKey);
  }

  // ════════════════════════════════════════
  // PRIVATE — Local (Guest)
  // ════════════════════════════════════════
  static Future<List<Schedule>> _loadLocal() async {
    try {
      final raw = await _storage.read(key: _localSchedulesKey);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List;
      return list.map((j) => Schedule.fromJson(j)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveLocal(List<Schedule> schedules) async {
    final json = jsonEncode(schedules.map((s) => s.toJson()).toList());
    await _storage.write(key: _localSchedulesKey, value: json);
  }

  // ════════════════════════════════════════
  // PRIVATE — API (Logged-in)
  // ════════════════════════════════════════
  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type':  'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<List<Schedule>> _loadFromApi() async {
    try {
      final res  = await http.get(
        Uri.parse('$_baseUrl/schedules'),
        headers: await _headers(),
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        return (data['data'] as List)
            .map((j) => Schedule.fromApi(j))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<Schedule?> _createOnApi(Schedule s) async {
    try {
      final res  = await http.post(
        Uri.parse('$_baseUrl/schedules'),
        headers: await _headers(),
        body: jsonEncode({
          'name':      s.name,
          'icon':      s.icon,
          'startTime': s.startTime,
          'endTime':   s.endTime,
          'days':      s.days,
          'mode':      s.mode,
          'isEnabled': s.isEnabled,
        }),
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true) return Schedule.fromApi(data['data']);
    } catch (_) {}
    return null;
  }

  static Future<bool> _updateOnApi(Schedule s) async {
    try {
      final res  = await http.put(
        Uri.parse('$_baseUrl/schedules/${s.id}'),
        headers: await _headers(),
        body: jsonEncode({
          'name':      s.name,
          'icon':      s.icon,
          'startTime': s.startTime,
          'endTime':   s.endTime,
          'days':      s.days,
          'mode':      s.mode,
          'isEnabled': s.isEnabled,
        }),
      );
      final data = jsonDecode(res.body);
      return data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _deleteOnApi(String id) async {
    try {
      final res  = await http.delete(
        Uri.parse('$_baseUrl/schedules/$id'),
        headers: await _headers(),
      );
      final data = jsonDecode(res.body);
      return data['success'] == true;
    } catch (_) {
      return false;
    }
  }
}