import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../app_theme.dart';
import '../providers/user_provider.dart';
import '../providers/app_provider.dart';
import '../services/schedule_checker.dart';
import '../main.dart';
import 'auth_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _animCtrl, curve: Curves.elasticOut));

    _animCtrl.forward();

    Future.delayed(const Duration(milliseconds: 1600), _initAndRoute);
  }

  // Ping backend to wake it from Railway sleep
  // Railway free tier sleeps after 30min of inactivity
  Future<void> _wakeBackend() async {
    try {
      await http.get(
        Uri.parse('https://autosilence-backend-production.up.railway.app/'),
      ).timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  Future<void> _initAndRoute() async {
    if (!mounted) return;

    // Wake up Railway backend (it sleeps after inactivity)
    // Fire and forget — don't wait for it
    _wakeBackend();

    final userProv = context.read<UserProvider>();
    final appProv  = context.read<AppProvider>();

    // Step 1 — load user session from device storage
    await userProv.init();

    // Step 2 — load schedules
    // Guest   → from local device storage
    // LoggedIn → from MongoDB API
    await appProv.loadSchedules();

    // Step 3 — start schedule checker (silences phone on schedule)
    ScheduleChecker.start();

    if (!mounted) return;

    // Step 3 — route to correct screen
    if (userProv.isLoggedIn || userProv.isGuest) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tc(context).bg,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: SizedBox(
                    height: 140,
                    child: Image.asset(
                      'assets/screenIcon.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Silenz',
                    style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: tc(context).textPrimary)),
                const SizedBox(height: 6),
                Text('Smart silence, on schedule',
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: tc(context).textMuted)),
                const SizedBox(height: 40),
                SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.accent.withOpacity(0.5)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}