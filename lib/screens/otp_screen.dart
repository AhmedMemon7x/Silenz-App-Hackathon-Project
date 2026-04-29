import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../providers/user_provider.dart';
import '../providers/app_provider.dart';
import '../services/auth_service.dart';
import '../main.dart';

class OTPScreen extends StatefulWidget {
  final String email;
  final String purpose; // 'email_verify' | 'google_verify' | 'forgot'
  final String? googleName;

  const OTPScreen({
    super.key,
    required this.email,
    required this.purpose,
    this.googleName,
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final List<TextEditingController> _controllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
  List.generate(6, (_) => FocusNode());

  late TextEditingController _nameController;

  bool _isLoading   = false;
  bool _isResending = false;
  String? _error;
  int _resendSeconds = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.googleName ?? '');
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    _nameController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _resendSeconds = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendSeconds == 0) {
        t.cancel();
      } else {
        if (mounted) setState(() => _resendSeconds--);
      }
    });
  }

  String get _otpValue => _controllers.map((c) => c.text).join();

  Future<void> _submit() async {
    final otp = _otpValue;
    if (otp.length < 6) {
      setState(() => _error = 'Please enter all 6 digits.');
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    Map<String, dynamic> result;


      result = await AuthService.verifyOTP(
        email:   widget.email,
        otp:     otp,
        purpose: widget.purpose,
      );


    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      if (widget.purpose == 'forgot') {
        // Go to reset password screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(
              email: widget.email,
              otp:   otp,
            ),
          ),
        );
      } else {
        // ✅ Update UserProvider so drawer + home avatar update immediately
        if (result['user'] != null) {
          await context.read<UserProvider>().setUser(result['user']);
          // Sync any guest schedules to cloud, then load from API
          await context.read<AppProvider>().syncAndReload();
        }
        // Go home
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainShell()),
              (_) => false,
        );
      }
    } else {
      setState(() => _error = result['message'] ?? 'Invalid OTP.');
      _clearBoxes();
    }
  }

  Future<void> _resend() async {
    if (_resendSeconds > 0) return;
    setState(() { _isResending = true; _error = null; });

    final result = await AuthService.resendOTP(
      email:   widget.email,
      purpose: widget.purpose,
    );

    if (!mounted) return;
    setState(() => _isResending = false);

    if (result['success'] == true) {
      _startTimer();
      _clearBoxes();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        content: Text('New code sent to ${widget.email}',
            style: GoogleFonts.poppins(
                color: Colors.white, fontSize: 13)),
      ));
    } else {
      setState(() => _error = result['message']);
    }
  }

  void _clearBoxes() {
    for (final c in _controllers) c.clear();
    _focusNodes[0].requestFocus();
  }

  void _onDigitChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (int i = 0; i < 6 && i < digits.length; i++) {
        _controllers[i].text = digits[i];
      }
      if (digits.length >= 6) {
        _focusNodes[5].requestFocus();
        _submit();
      }
    }
  }

  String get _title {
    switch (widget.purpose) {
      case 'google_verify': return 'Verify Google Account';
      case 'forgot':        return 'Reset Password';
      default:              return 'Verify Your Email';
    }
  }

  String get _subtitle {
    switch (widget.purpose) {
      case 'google_verify': return 'Confirm your Gmail ownership';
      case 'forgot':        return 'Enter the code to reset your password';
      default:              return 'Complete your account setup';
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

              const SizedBox(height: 12),

              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.accent.withOpacity(0.2)),
                ),
                child: Center(
                  child: Icon(Icons.mark_email_unread_rounded,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.accent
                      : Colors.black87, size: 30)),
              ),

              const SizedBox(height: 20),
              Text(_title, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, color: tc(context).textPrimary)),
              const SizedBox(height: 6),
              Text(_subtitle, style: GoogleFonts.outfit(fontSize: 13, color: tc(context).textSecondary)),
              const SizedBox(height: 12),

              RichText(
                text: TextSpan(
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: tc(context).textSecondary),
                  children: [
                    const TextSpan(text: 'Code sent to '),
                    TextSpan(
                      text: widget.email,
                      style: GoogleFonts.poppins(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.accent
                              : Colors.black87,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Name field (Google verify only)
              if (widget.purpose == 'google_verify') ...[
                Text('YOUR NAME', style: GoogleFonts.dmMono(fontSize: 10, fontWeight: FontWeight.w500, color: tc(context).textSecondary, letterSpacing: 1.5)),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  style: GoogleFonts.poppins(
                      color: tc(context).textPrimary, fontSize: 14),
                  decoration:  InputDecoration(
                    hintText: 'Enter or edit your name',
                    prefixIcon: Icon(Icons.person_outline,
                        color: tc(context).textSecondary, size: 20),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              Text('VERIFICATION CODE', style: GoogleFonts.dmMono(fontSize: 10, fontWeight: FontWeight.w500, color: tc(context).textSecondary, letterSpacing: 1.5)),
              const SizedBox(height: 12),

              // 6 digit boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) => _DigitBox(
                  controller:  _controllers[i],
                  focusNode:   _focusNodes[i],
                  onChanged:   (v) => _onDigitChanged(i, v),
                  onBackspace: () {
                    if (_controllers[i].text.isEmpty && i > 0) {
                      _controllers[i - 1].clear();
                      _focusNodes[i - 1].requestFocus();
                    }
                  },
                )),
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

              const SizedBox(height: 8),

              // Verify Button
              GestureDetector(
                onTap: _isLoading ? null : _submit,
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
                      : Text(
                      widget.purpose == 'forgot'
                          ? 'Verify & Continue'
                          : 'Verify & Activate Account',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15))),
                ),
              ),

              const SizedBox(height: 24),

              // Resend
              Center(
                child: _isResending
                    ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(
                        color: AppColors.accent, strokeWidth: 2))
                    : _resendSeconds > 0
                    ? RichText(
                  text: TextSpan(
                    style: GoogleFonts.poppins(
                        color: tc(context).textSecondary,
                        fontSize: 13),
                    children: [
                      const TextSpan(text: 'Resend code in '),
                      TextSpan(
                        text: '${_resendSeconds}s',
                        style: GoogleFonts.poppins(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? AppColors.accent
                                : Colors.black87,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                )
                    : GestureDetector(
                  onTap: _resend,
                  child: Text("Didn't receive it? Resend",
                      style: GoogleFonts.poppins(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.accent
                              : Colors.black87,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Single digit input box
// ─────────────────────────────────────────
class _DigitBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspace;

  const _DigitBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46, height: 56,
      child: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: (event) {
          if (event is RawKeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              controller.text.isEmpty) {
            onBackspace();
          }
        },
        child: TextField(
          controller:   controller,
          focusNode:    focusNode,
          textAlign:    TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength:    1,
          style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: tc(context).textPrimary),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            counterText: '',
            contentPadding: EdgeInsets.zero,
            filled:     true,
            fillColor:  tc(context).surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:  BorderSide(color: tc(context).border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:  BorderSide(color: tc(context).border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
              const BorderSide(color: AppColors.accent, width: 2),
            ),
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Reset Password Screen
// ─────────────────────────────────────────
class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String otp;
  const ResetPasswordScreen(
      {super.key, required this.email, required this.otp});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _ob1      = true;
  bool _ob2      = true;
  bool _loading  = false;
  String? _error;

  @override
  void dispose() {
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    if (_passCtrl.text.isEmpty || _confirmCtrl.text.isEmpty) {
      setState(() => _error = 'Please fill in both fields.');
      return;
    }
    if (_passCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    if (_passCtrl.text.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }

    setState(() { _loading = true; _error = null; });

    final result = await AuthService.resetPassword(
      email:    widget.email,
      otp:      widget.otp,
      password: _passCtrl.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result['success'] == true) {
      if (result['user'] != null) {
        await context.read<UserProvider>().setUser(result['user']);
        await context.read<AppProvider>().syncAndReload();
      }
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
            (_) => false,
      );
    } else {
      setState(() => _error = result['message'] ?? 'Reset failed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tc(context).bg,
      appBar: AppBar(
        backgroundColor: tc(context).bg, elevation: 0,
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
              Text('New Password', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, color: tc(context).textPrimary)),
              const SizedBox(height: 6),
              Text('Choose a strong new password.',
                  style: GoogleFonts.outfit(fontSize: 13, color: tc(context).textSecondary)),
              const SizedBox(height: 32),

              Text('NEW PASSWORD', style: GoogleFonts.dmMono(fontSize: 10, fontWeight: FontWeight.w500, color: tc(context).textSecondary, letterSpacing: 1.5)),
              const SizedBox(height: 8),
              TextField(
                controller: _passCtrl,
                obscureText: _ob1,
                style: GoogleFonts.poppins(
                    color: tc(context).textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Min. 6 characters',
                  prefixIcon:  Icon(Icons.lock_outline,
                      color: tc(context).textSecondary, size: 20),
                  suffixIcon: GestureDetector(
                    onTap: () => setState(() => _ob1 = !_ob1),
                    child: Icon(
                      _ob1 ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: tc(context).textSecondary, size: 20,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text('CONFIRM PASSWORD', style: GoogleFonts.dmMono(fontSize: 10, fontWeight: FontWeight.w500, color: tc(context).textSecondary, letterSpacing: 1.5)),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmCtrl,
                obscureText: _ob2,
                style: GoogleFonts.poppins(
                    color: tc(context).textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Repeat password',
                  prefixIcon:  Icon(Icons.lock_outline,
                      color: tc(context).textSecondary, size: 20),
                  suffixIcon: GestureDetector(
                    onTap: () => setState(() => _ob2 = !_ob2),
                    child: Icon(
                      _ob2 ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: tc(context).textSecondary, size: 20,
                    ),
                  ),
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
                  child: Text(_error!,
                      style: GoogleFonts.poppins(
                          color: AppColors.danger, fontSize: 12)),
                ),
                const SizedBox(height: 16),
              ],

              GestureDetector(
                onTap: _loading ? null : _reset,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: AppColors.accentGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(child: _loading
                      ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                      : Text('Set New Password',
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