import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../services/auth_service.dart';
import 'otp_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController     = TextEditingController();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController  = TextEditingController();
  bool _obscure1   = true;
  bool _obscure2   = true;
  bool _isLoading  = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name     = _nameController.text.trim();
    final email    = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm  = _confirmController.text;

    if (name.isEmpty || email.isEmpty ||
        password.isEmpty || confirm.isEmpty) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }
    if (password != confirm) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    final result = await AuthService.register(
        name: name, email: email, password: password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      // ── Go to OTP screen to verify email ──
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OTPScreen(
            email:   result['email'] ?? email,
            purpose: 'email_verify',
          ),
        ),
      );
    } else {
      setState(() => _error = result['message'] ?? 'Registration failed.');
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Text('Create Account', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, color: tc(context).textPrimary)),
              const SizedBox(height: 6),
              Text("We'll send a code to verify your email",
                  style: GoogleFonts.outfit(fontSize: 13, color: tc(context).textSecondary)),
              const SizedBox(height: 32),

              // Name
              Text('FULL NAME', style: GoogleFonts.dmMono(fontSize: 10, fontWeight: FontWeight.w500, color: tc(context).textSecondary, letterSpacing: 1.5)),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                style: GoogleFonts.poppins(
                    color: tc(context).textPrimary, fontSize: 14),
                decoration:  InputDecoration(
                  hintText: 'Your name',
                  prefixIcon: Icon(Icons.person_outline,
                      color: tc(context).textSecondary, size: 20),
                ),
              ),

              const SizedBox(height: 16),

              // Email
              Text('EMAIL', style: GoogleFonts.dmMono(fontSize: 10, fontWeight: FontWeight.w500, color: tc(context).textSecondary, letterSpacing: 1.5)),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.poppins(
                    color: tc(context).textPrimary, fontSize: 14),
                decoration: InputDecoration(
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
                obscureText: _obscure1,
                style: GoogleFonts.poppins(
                    color: tc(context).textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Min. 6 characters',
                  prefixIcon:  Icon(Icons.lock_outline,
                      color: tc(context).textSecondary, size: 20),
                  suffixIcon: GestureDetector(
                    onTap: () => setState(() => _obscure1 = !_obscure1),
                    child: Icon(
                      _obscure1 ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: tc(context).textSecondary, size: 20,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Confirm
              Text('CONFIRM PASSWORD', style: GoogleFonts.dmMono(fontSize: 10, fontWeight: FontWeight.w500, color: tc(context).textSecondary, letterSpacing: 1.5)),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmController,
                obscureText: _obscure2,
                style: GoogleFonts.poppins(
                    color: tc(context).textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Repeat your password',
                  prefixIcon:  Icon(Icons.lock_outline,
                      color: tc(context).textSecondary, size: 20),
                  suffixIcon: GestureDetector(
                    onTap: () => setState(() => _obscure2 = !_obscure2),
                    child: Icon(
                      _obscure2 ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: tc(context).textSecondary, size: 20,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

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
                const SizedBox(height: 16),
              ],

              // Register Button
              GestureDetector(
                onTap: _isLoading ? null : _register,
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
                      : Text('Create Account & Verify',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15))),
                ),
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already have an account?',
                      style: GoogleFonts.poppins(
                          color: tc(context).textSecondary, fontSize: 13)),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Sign In',
                        style: GoogleFonts.poppins(
                            color: AppColors.accentOrBlack(context),
                            fontWeight: FontWeight.w700, fontSize: 13)),
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