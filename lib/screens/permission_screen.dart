import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_theme.dart';
import '../services/ringer_service.dart';
import 'splash_screen.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen>
    with WidgetsBindingObserver {

  bool _dndGranted  = false;
  bool _isChecking  = true;
  bool _hasOpened   = false; // track if we already opened settings once

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAndAutoOpen();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Re-check when user returns from system settings
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  // First open — check then automatically open DND settings
  Future<void> _checkAndAutoOpen() async {
    setState(() => _isChecking = true);
    final dnd = await RingerService.isDNDGranted();
    setState(() {
      _dndGranted = dnd;
      _isChecking = false;
    });

    if (dnd) {
      // Already granted — proceed immediately
      await _proceed();
    } else if (!_hasOpened) {
      // Not granted — automatically open DND settings
      _hasOpened = true;
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) await RingerService.openDNDSettings();
    }
  }

  Future<void> _checkPermissions() async {
    setState(() => _isChecking = true);
    final dnd = await RingerService.isDNDGranted();
    setState(() {
      _dndGranted = dnd;
      _isChecking = false;
    });
    if (dnd) await _proceed();
  }

  Future<void> _proceed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('permissions_granted', true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SplashScreen()),
    );
  }

  Future<void> _skip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('permissions_granted', true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SplashScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tc(context).bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              // Icon
              Center(
                child: SizedBox(
                  height: 140,
                  child: Image.asset(
                    'assets/screenIcon.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              Text('One Permission Needed',
                  style: AppTextStyles.heading1,
                  textAlign: TextAlign.center),

              const SizedBox(height: 12),

              Text(
                'Silenz needs Do Not Disturb access\nto silence your phone on schedule.\n\nFind "auto_silent" in the list and toggle it ON.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(height: 1.6),
              ),

              const SizedBox(height: 36),

              // Status card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _dndGranted
                      ? AppColors.accent.withOpacity(0.08)
                      : tc(context).surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _dndGranted
                        ? AppColors.accent.withOpacity(0.4)
                        : tc(context).border,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: _dndGranted
                            ? AppColors.accent.withOpacity(0.1)
                            : tc(context).surface2,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Icon(Icons.do_not_disturb_on_rounded,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? AppColors.accent
                                : Colors.black87,size: 24),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Do Not Disturb',
                              style: GoogleFonts.poppins(
                                  color: tc(context).textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
                          Row(
                            children: [
                              Icon(
                                _dndGranted ? Icons.check_circle_rounded : Icons.access_time_rounded,
                                color: _dndGranted ? AppColors.accent : tc(context).textMuted,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _dndGranted ? 'Granted' : 'Waiting for permission...',
                                style: GoogleFonts.poppins(
                                    color: _dndGranted ? AppColors.accent : tc(context).textMuted,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (_isChecking)
                      const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.accent),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Open settings button
              if (!_dndGranted)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => RingerService.openDNDSettings(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Open Settings Again',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                  ),
                ),

              const SizedBox(height: 12),

              // Skip button
              TextButton(
                onPressed: _skip,
                child: Text(
                  _dndGranted
                      ? 'Continue →'
                      : 'Skip for now (Silent/Vibrate still works)',
                  style: GoogleFonts.poppins(
                      color: _dndGranted
                          ? AppColors.accent
                          : tc(context).textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ),

              const Spacer(),

              TextButton(
                onPressed: () => SystemNavigator.pop(),
                child: Text('Close app',
                    style: GoogleFonts.poppins(
                        color: AppColors.danger,
                        fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}