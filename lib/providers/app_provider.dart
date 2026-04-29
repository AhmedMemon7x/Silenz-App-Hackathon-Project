import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/schedule_model.dart';
import '../services/schedule_service.dart';
import '../services/schedule_checker.dart';

class AppProvider extends ChangeNotifier {
  bool isSilentActive  = false;
  int  currentNavIndex = 0;

  List<Schedule> schedules = [];
  bool   isLoading = true;
  String? loadError;

  // ── Theme Mode ──
  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  // AppProvider() { _loadTheme(); }

  AppProvider() {
    _themeMode = ThemeMode.dark; // set immediately before async load
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? true;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode = isDark ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
    notifyListeners();
  }

  // ════════════════════════════════════════
  // LOAD — called on splash
  // ════════════════════════════════════════
  Future<void> loadSchedules() async {
    isLoading = true;
    loadError = null;
    notifyListeners();

    try {
      schedules = await ScheduleService.loadSchedules();
    } catch (_) {
      loadError = 'Could not load schedules.';
      schedules = [];
    }

    isLoading = false;
    notifyListeners();

    // ✅ Always sync to checker after load
    await ScheduleChecker.saveSchedules(schedules);
  }

  // ════════════════════════════════════════
  // SYNC + RELOAD — called on login
  // ════════════════════════════════════════
  Future<void> syncAndReload() async {
    isLoading = true;
    notifyListeners();

    try {
      schedules = await ScheduleService.syncGuestToCloud();
    } catch (_) {
      try {
        schedules = await ScheduleService.loadFromCloud();
      } catch (_) {
        schedules = [];
      }
    }

    isLoading = false;
    notifyListeners();

    // ✅ Fixed: was missing this — checker never got updated after login
    await ScheduleChecker.saveSchedules(schedules);
  }

  // ════════════════════════════════════════
  // TOGGLE SILENT (UI toggle)
  // ════════════════════════════════════════
  void toggleSilent() {
    isSilentActive = !isSilentActive;
    notifyListeners();
  }

  // ════════════════════════════════════════
  // TOGGLE SCHEDULE ENABLED
  // ════════════════════════════════════════
  Future<void> toggleSchedule(String id) async {
    final idx = schedules.indexWhere((s) => s.id == id);
    if (idx == -1) return;

    schedules[idx].isEnabled = !schedules[idx].isEnabled;
    notifyListeners();

    await ScheduleService.updateSchedule(schedules[idx]);
    // ✅ Immediately recheck — disable should restore Normal
    await ScheduleChecker.saveSchedules(schedules);
  }

  // ════════════════════════════════════════
  // ADD
  // ════════════════════════════════════════
  Future<void> addSchedule(Schedule schedule) async {
    if (schedule.id.isEmpty) {
      schedule.id = 'local_${DateTime.now().millisecondsSinceEpoch}';
    }

    schedules.insert(0, schedule);
    notifyListeners();

    final saved = await ScheduleService.addSchedule(schedule);
    if (saved != null && saved.id != schedule.id) {
      final idx = schedules.indexWhere((s) => s.id == schedule.id);
      if (idx != -1) {
        schedules[idx] = saved;
        notifyListeners();
      }
    }
    // ✅ Check immediately — new schedule might be active right now
    await ScheduleChecker.saveSchedules(schedules);
  }

  // ════════════════════════════════════════
  // UPDATE
  // ════════════════════════════════════════
  Future<void> updateSchedule(Schedule updated) async {
    final idx = schedules.indexWhere((s) => s.id == updated.id);
    if (idx != -1) {
      schedules[idx] = updated;
      notifyListeners();
    }
    await ScheduleService.updateSchedule(updated);
    await ScheduleChecker.saveSchedules(schedules);
  }

  // ════════════════════════════════════════
  // DELETE
  // ════════════════════════════════════════
  Future<void> deleteSchedule(String id) async {
    schedules.removeWhere((s) => s.id == id);
    notifyListeners();
    await ScheduleService.deleteSchedule(id);
    // ✅ Check immediately — deleted schedule might have been active
    await ScheduleChecker.saveSchedules(schedules);
  }

  // ════════════════════════════════════════
  // CLEAR — called on logout
  // ════════════════════════════════════════
  Future<void> clearSchedules() async {
    schedules      = [];
    isSilentActive = false;
    notifyListeners();

    await ScheduleService.clearGuestStorage();

    // ✅ Stop checker and restore normal mode on logout
    await ScheduleChecker.saveSchedules([]);
    ScheduleChecker.stop();
  }

  // ════════════════════════════════════════
  // NAV
  // ════════════════════════════════════════
  void setNavIndex(int index) {
    currentNavIndex = index;
    notifyListeners();
  }

  int get activeCount => schedules.where((s) => s.isEnabled).length;

  Schedule? get activeSchedule {
    final now     = DateTime.now();
    final today   = _dayAbbr(now.weekday);
    final nowMins = now.hour * 60 + now.minute;

    for (final s in schedules) {
      if (!s.isEnabled) continue;
      if (!s.days.contains(today)) continue;
      final start = _toMins(s.startTime);
      final end   = _toMins(s.endTime);
      final isActive = end > start
          ? nowMins >= start && nowMins < end
          : nowMins >= start || nowMins < end;
      if (isActive) return s;
    }
    return null;
  }

  static int    _toMins(String t) { final p = t.split(':'); return int.parse(p[0]) * 60 + int.parse(p[1]); }
  static String _dayAbbr(int w)   => ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][w - 1];
}