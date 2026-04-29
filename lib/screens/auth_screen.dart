import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../providers/user_provider.dart';
import '../providers/app_provider.dart';
import '../services/auth_service.dart';
import '../main.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import 'otp_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure   = true;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Email Login ──
  Future<void> _login() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      setState(() => _error = 'Please enter your email and password.');
      return;
    }
    setState(() { _isLoading = true; _error = null; });

    final result = await AuthService.login(
      email:    _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      // ✅ Update provider so drawer/home show real user data
      await context.read<UserProvider>().setUser(result['user']);
      // Sync any guest schedules to cloud, then load from API
      await context.read<AppProvider>().syncAndReload();
      _goHome();
    } else if (result['needsVerification'] == true) {
    Navigator.push(context, MaterialPageRoute(
    builder: (_) => OTPScreen(
    email:   result['email'],
    purpose: 'email_verify',
    ),
    ));
    } else {
    setState(() => _error = result['message'] ?? 'Login failed.');
    }
    }

  // ── Google Sign-In ──
  // Future<void> _googleSignIn() async {
  //   setState(() { _isLoading = true; _error = null; });
  //
  //   final result = await AuthService.googleSignIn();
  //
  //   if (!mounted) return;
  //   setState(() => _isLoading = false);
  //
  //   if (result['success'] == true && result['needsOTP'] != true) {
  //     // ✅ Existing Google user — update provider
  //     await context.read<UserProvider>().setUser(result['user']);
  //     // Sync any guest schedules to cloud, then load from API
  //     await context.read<AppProvider>().syncAndReload();
  //     _goHome();
  //
  //   } else if (result['needsOTP'] == true) {
  //     // New Google user — go to OTP screen
  //     Navigator.push(context, MaterialPageRoute(
  //       builder: (_) => OTPScreen(
  //         email:      result['email'],
  //         purpose:    'google_verify',
  //       ),
  //     ));
  //   } else {
  //     setState(() => _error = result['message'] ?? 'Google sign-in failed.');
  //   }
  // }

  // ── Guest ──
  Future<void> _guest() async {
    await context.read<UserProvider>().setGuest();
    if (!mounted) return;
    await context.read<AppProvider>().loadSchedules();
    _goHome();
  }

  void _goHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainShell()),
          (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tc(context).bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Logo
              Center(
                child: SizedBox(
                  height: 140,
                  child: Image.asset(
                    'assets/screenIcon.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Center(child: Text('Welcome Back', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, color: tc(context).textPrimary))),
              const SizedBox(height: 6),
              Center(child: Text('Sign in to your account',
                  style: GoogleFonts.outfit(fontSize: 13, color: tc(context).textSecondary))),
              const SizedBox(height: 36),

              // Email
              Text('EMAIL', style: GoogleFonts.dmMono(fontSize: 10, fontWeight: FontWeight.w500, color: tc(context).textSecondary, letterSpacing: 1.5)),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.poppins(
                    color: tc(context).textPrimary, fontSize: 14),
                decoration:  InputDecoration(
                  hintText: 'you@example.com',
                  prefixIcon: Icon(Icons.email_outlined,
                      color: tc(context).textSecondary, size: 20),
                ),
              ),

              const SizedBox(height: 16),

              // Password
              Text('PASSWORD', style: GoogleFonts.dmMono(fontSize: 10, fontWeight: FontWeight.w500, color: tc(context).textSecondary, letterSpacing: 1.5)),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscure,
                style: GoogleFonts.poppins(
                    color: tc(context).textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: '••••••••',
                  prefixIcon:  Icon(Icons.lock_outline,
                      color: tc(context).textSecondary, size: 20),
                  suffixIcon: GestureDetector(
                    onTap: () => setState(() => _obscure = !_obscure),
                    child: Icon(
                      _obscure ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: tc(context).textSecondary, size: 20,
                    ),
                  ),
                ),
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen())),
                  child: Text('Forgot Password?',
                      style: GoogleFonts.poppins(
                          color: AppColors.accentOrBlack(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ),

              // Error
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.danger.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.danger, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!,
                        style: GoogleFonts.poppins(
                            color: AppColors.danger, fontSize: 12))),
                  ]),
                ),
                const SizedBox(height: 12),
              ],

              const SizedBox(height: 8),

              // Sign In Button
              GestureDetector(
                onTap: _isLoading ? null : _login,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: AppColors.accentGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(
                      color: AppColors.accent.withOpacity(0.3),
                      blurRadius: 16, offset: const Offset(0, 6),
                    )],
                  ),
                  child: Center(child: _isLoading
                      ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                      : Text('Sign In',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15))),
                ),
              ),

              const SizedBox(height: 24),

              // OR
              Row(children: [
                 Expanded(child: Divider(color: tc(context).border)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('or',
                      style: GoogleFonts.poppins(
                          color: tc(context).textSecondary, fontSize: 12)),
                ),
                 Expanded(child: Divider(color: tc(context).border)),
              ]),

              const SizedBox(height: 20),

              // Google Button
              // GestureDetector(
              //   onTap: _isLoading ? null : _googleSignIn,
              //   child: Container(
              //     width: double.infinity,
              //     padding: const EdgeInsets.symmetric(vertical: 14),
              //     decoration: BoxDecoration(
              //       color: tc(context).surface,
              //       borderRadius: BorderRadius.circular(14),
              //       border: Border.all(color: tc(context).border),
              //       boxShadow: [BoxShadow(
              //         color: Colors.black.withOpacity(0.04),
              //         blurRadius: 8, offset: const Offset(0, 2),
              //       )],
              //     ),
              //     child: Row(
              //       mainAxisAlignment: MainAxisAlignment.center,
              //       children: [
              //          Icon(Icons.g_mobiledata,
              //             color: tc(context).textPrimary, size: 26),
              //         const SizedBox(width: 8),
              //         Text('Continue with Google',
              //             style: GoogleFonts.poppins(
              //                 color: tc(context).textPrimary,
              //                 fontWeight: FontWeight.w600,
              //                 fontSize: 14)),
              //       ],
              //     ),
              //   ),
              // ),

              const SizedBox(height: 12),

              // Guest Button
              GestureDetector(
                onTap: _isLoading ? null : _guest,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: tc(context).surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: tc(context).border),
                  ),
                  child: Center(
                    child: Text('Continue as Guest',
                        style: GoogleFonts.poppins(
                            color: tc(context).textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Sign Up link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account?",
                      style: GoogleFonts.poppins(
                          color: tc(context).textSecondary, fontSize: 13)),
                  TextButton(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const SignupScreen())),
                    child: Text('Sign Up',
                        style: GoogleFonts.poppins(
                            color: AppColors.accentOrBlack(context),
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}