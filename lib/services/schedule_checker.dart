import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/schedule_model.dart';
import 'ringer_service.dart';

class ScheduleChecker {
  static Timer?         _timer;
  static String         _lastAppliedMode = '';
  static List<Schedule> _schedules       = [];

  static void start() {
    _timer?.cancel();
    _check();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _check());
  }

  static void stop() {
    _timer?.cancel();
    _timer           = null;
    _lastAppliedMode = '';
    _schedules       = [];
  }

  static Future<void> checkNow() async {
    _lastAppliedMode = '';
    await _check();
  }

  static Future<void> saveSchedules(List<Schedule> schedules) async {
    _schedules = List.from(schedules);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'bg_schedules',
        jsonEncode(schedules.map((s) => s.toJson()).toList()),
      );
    } catch (_) {}
    await checkNow();
  }

  static Future<void> _check() async {
    try {
      List<Schedule> schedules = _schedules;
      if (schedules.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final raw   = prefs.getString('bg_schedules');
        if (raw == null || raw.isEmpty) {
          if (_lastAppliedMode != 'Normal' && _lastAppliedMode.isNotEmpty) {
            await _applyMode('Normal');
          }
          return;
        }
        final list = jsonDecode(raw) as List;
        schedules  = list.map((j) => Schedule.fromJson(j as Map<String, dynamic>)).toList();
        _schedules = schedules;
      }

      final active     = _findActive(schedules);
      final targetMode = active?.mode ?? 'Normal';

      if (targetMode != _lastAppliedMode) {
        await _applyMode(targetMode);
        if (active != null) {
          debugPrint('🔕 AutoSilence: ${active.name} → $targetMode until ${active.endTime}');
        } else {
          debugPrint('🔔 AutoSilence: No active schedule → Normal');
        }
      }
    } catch (e) {
      debugPrint('ScheduleChecker error: $e');
    }
  }

  static Future<void> _applyMode(String mode) async {
    bool ok = false;
    switch (mode) {
      case 'Silent':  ok = await RingerService.setSilent();  break;  // volume 0
      case 'Vibrate': ok = await RingerService.setVibrate(); break;  // vibrate only
      case 'DND':     ok = await RingerService.setDND();     break;  // full DND
      default:        ok = await RingerService.setNormal();  break;  // normal
    }
    if (ok) {
      _lastAppliedMode = mode;
      debugPrint('✅ RingerService: Applied $mode');
    } else {
      debugPrint('❌ RingerService: Failed to apply $mode');
    }
  }

  static Schedule? _findActive(List<Schedule> schedules) {
    final now     = DateTime.now();
    final today   = _dayAbbr(now.weekday);
    final nowMins = now.hour * 60 + now.minute;

    debugPrint('⏰ Check: $today $nowMins mins | ${schedules.length} schedules');

    for (final s in schedules) {
      if (!s.isEnabled) continue;
      if (!s.days.contains(today)) continue;

      final start = _toMins(s.startTime);
      final end   = _toMins(s.endTime);

      final isActive = end > start
          ? nowMins >= start && nowMins < end
          : nowMins >= start || nowMins < end;

      debugPrint('  📋 ${s.name}: $start–$end active=$isActive mode=${s.mode}');

      if (isActive) return s;
    }
    return null;
  }

  static int    _toMins(String t) { final p = t.split(':'); return int.parse(p[0]) * 60 + int.parse(p[1]); }
  static String _dayAbbr(int w)   => ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][w - 1];
  static String get currentMode   => _lastAppliedMode;
}