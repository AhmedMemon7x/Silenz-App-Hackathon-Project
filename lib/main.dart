import 'screens/location_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';
import 'providers/app_provider.dart';
import 'providers/user_provider.dart';
import 'screens/home_screen.dart';
import 'screens/schedules_screen.dart';
import 'screens/add_schedule_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/permission_screen.dart';
import 'widgets/bottom_nav_bar.dart';
import 'widgets/app_drawer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor:                    Colors.transparent,
    statusBarIconBrightness:           Brightness.light,
    systemNavigationBarColor:          AppColors.darkSurface,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const AutoSilenceApp(),
    ),
  );
}

class AutoSilenceApp extends StatelessWidget {
  const AutoSilenceApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<AppProvider>().themeMode;
    return MaterialApp(
      title: 'Silenz',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      home: const _StartupRouter(),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Routes to PermissionScreen or SplashScreen
// Also starts the background service here — AFTER
// the Flutter engine and UI are fully initialized
// ─────────────────────────────────────────────────────────
class _StartupRouter extends StatefulWidget {
  const _StartupRouter();

  @override
  State<_StartupRouter> createState() => _StartupRouterState();
}

class _StartupRouterState extends State<_StartupRouter> {
  static const _permKey = 'permissions_granted';

  @override
  void initState() {
    super.initState();
    // Wait one frame so Flutter engine is fully ready,
    // then start service + route
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final prefs   = await SharedPreferences.getInstance();
    final granted = prefs.getBool(_permKey) ?? false;

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => granted
            ? const SplashScreen()
            : const PermissionScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      backgroundColor: tc(context).bg,
      body: Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Main shell
// ─────────────────────────────────────────────────────────
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  static const _screens = [
    HomeScreen(),
    SchedulesScreen(),
    AddScheduleScreen(),
    LocationScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return Scaffold(
      backgroundColor: tc(context).bg,
      drawer:          const AppDrawer(),
      body:            _screens[provider.currentNavIndex],
      bottomNavigationBar: const AppBottomNavBar(),
    );
  }
}