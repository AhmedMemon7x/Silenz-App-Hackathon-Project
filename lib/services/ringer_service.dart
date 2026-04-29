import 'package:flutter/services.dart';

class RingerService {
  static const _channel = MethodChannel('com.autosilence.app/ringer');

  static Future<bool> applyMode(String mode) async {
    switch (mode) {
      case 'Silent':  return setSilent();
      case 'Vibrate': return setVibrate();
      case 'DND':     return setDND();
      default:        return setNormal();
    }
  }

  static Future<bool> setSilent() async {
    try {
      final result = await _channel.invokeMethod<bool>('setSilentOnly');
      return result ?? false;
    } catch (_) { return false; }
  }

  static Future<bool> setVibrate() async {
    try {
      final result = await _channel.invokeMethod<bool>('setVibrateOnly');
      return result ?? false;
    } catch (_) { return false; }
  }

  static Future<bool> setDND() async {
    try {
      final result = await _channel.invokeMethod<bool>('setDND');
      return result ?? false;
    } catch (_) { return false; }
  }

  static Future<bool> setNormal() async {
    try {
      final result = await _channel.invokeMethod<bool>('setNormal');
      return result ?? false;
    } catch (_) { return false; }
  }

  static Future<String> getRingerMode() async {
    try {
      final result = await _channel.invokeMethod<String>('getRingerMode');
      return result ?? 'Normal';
    } catch (_) { return 'Normal'; }
  }

  static Future<bool> isDNDGranted() async {
    try {
      final result = await _channel.invokeMethod<bool>('isDNDGranted');
      return result ?? false;
    } catch (_) { return false; }
  }

  static Future<void> openDNDSettings() async {
    try { await _channel.invokeMethod('openDNDSettings'); } catch (_) {}
  }

  static Future<bool> isBatteryOptimized() async {
    try {
      final result = await _channel.invokeMethod<bool>('isBatteryOptimized');
      return result ?? false;
    } catch (_) { return false; }
  }

  static Future<void> openBatterySettings() async {
    try { await _channel.invokeMethod('openBatterySettings'); } catch (_) {}
  }
}