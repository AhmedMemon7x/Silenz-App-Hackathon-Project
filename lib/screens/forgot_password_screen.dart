import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../services/auth_service.dart';
import 'otp_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  static Color accentOrBlack(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.accent
        : Colors.black;
  }
  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Please enter your email.');
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    final result = await AuthService.forgotPassword(email: email);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      // Go to OTP screen for password reset
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OTPScreen(
            email:   result['email'] ?? email,
            purpose: 'forgot',
          ),
        ),
      );
    } else {
      setState(() => _error = result['message'] ?? 'Something went wrong.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tc(context).bg,
      appBar: AppBar(
        backgroundColor: tc(context).bg,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child:  Icon(Icons.arrow_back_ios_new,
              color: tc(context).textPrimary, size: 18),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const SizedBox(height: 12),

              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: AppColors.accentOrBlack(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.accentOrBlack(context).withOpacity(0.13)),
                ),
                child: Center(
                  child: Icon(Icons.key_outlined,  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.black
                      : AppColors.accent, size: 48),
                ),
              ),

              const SizedBox(height: 20),

              Text('Forgot Password?', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, color: tc(context).textPrimary)),
              const SizedBox(height: 6),
              Text(
                "Enter your email and we'll send a 6-digit code to reset your password.",
                style: GoogleFonts.outfit(fontSize: 13, color: tc(context).textSecondary),
              ),

              const SizedBox(height: 32),

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

              const SizedBox(height: 20),

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
                const SizedBox(height: 16),
              ],

              GestureDetector(
                onTap: _isLoading ? null : _sendOTP,
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
                      : Text('Send Reset Code',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15))),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
