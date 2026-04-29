import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../providers/user_provider.dart';
import 'profile_screen.dart';
import 'auth_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkTheme = false; // theme toggle state (UI only for now)

  // ── Logout ──
  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tc(context).surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('Log Out?',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: tc(context).textPrimary,
                fontSize: 17)),
        content: Text('You will be signed out of your account.',
            style: GoogleFonts.poppins(
                color: tc(context).textSecondary, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.poppins(
                    color: tc(context).textSecondary,
                    fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Log Out',
                style: GoogleFonts.poppins(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<UserProvider>().logout();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
            (_) => false,
      );
    }
  }

  // ── Rating dialog ──
  int _selectedStars = 0;

  void _showRating() {
    int tempStars = _selectedStars;
    showModalBottomSheet(
      context: context,
      backgroundColor: tc(context).surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: tc(context).border,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 20),
              Text("Rate Silenz",
                  style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: tc(context).textPrimary)),
              const SizedBox(height: 6),
              Text("How would you rate your experience?",
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: tc(context).textSecondary)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final filled = i < tempStars;
                  return GestureDetector(
                    onTap: () => setModalState(() => tempStars = i + 1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        filled ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 48,
                        color: filled ? const Color(0xFFF59E0B) : tc(context).border,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              Text(
                tempStars == 0
                    ? "Tap a star to rate"
                    : tempStars == 1
                    ? "😔  Poor"
                    : tempStars == 2
                    ? "😐  Fair"
                    : tempStars == 3
                    ? "🙂  Good"
                    : tempStars == 4
                    ? "😊  Great"
                    : "🤩  Excellent!",
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: tempStars == 0
                        ? tc(context).textSecondary
                        : tc(context).textPrimary),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: tempStars == 0
                    ? null
                    : () {
                  setState(() => _selectedStars = tempStars);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: tc(context).surface,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      content: Text(
                        "Thanks for rating us $tempStars ⭐!",
                        style: GoogleFonts.poppins(
                            color: tc(context).textPrimary, fontSize: 13),
                      ),
                    ),
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    gradient: tempStars > 0 ? AppColors.accentGradient : null,
                    color: tempStars == 0 ? tc(context).surface2 : null,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text("Submit Rating",
                        style: GoogleFonts.poppins(
                            color: tempStars > 0 ? Colors.white : tc(context).textSecondary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ── Feedback dialog ──
  void _showFeedback() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: tc(context).surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 20, 24,
            MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: tc(context).border,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text('Send Feedback',
                style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: tc(context).textPrimary)),
            const SizedBox(height: 6),
            Text('We read every message and use it to improve.',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: tc(context).textSecondary)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 4,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: tc(context).textPrimary),
              decoration: InputDecoration(
                hintText: 'Tell us what you think...',
                hintStyle: GoogleFonts.poppins(
                    color: tc(context).textSecondary, fontSize: 13),
                filled: true,
                fillColor: tc(context).surface2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: tc(context).border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: tc(context).border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                      color: AppColors.accent, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: tc(context).surface,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    content: Text('Thanks for your feedback! 🙏',
                        style: GoogleFonts.poppins(
                            color: tc(context).textPrimary,
                            fontSize: 13)),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text('Submit',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── FAQs bottom sheet ──
  void _showFAQs() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: tc(context).surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (_, scrollCtrl) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: tc(context).border,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Text('FAQs',
                  style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: tc(context).textPrimary)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  children: const [
                    _FAQItem(
                      question: 'How does Silenz work?',
                      answer:
                      'Silenz automatically silences your phone based on schedules you create. You set a time range, days, and mode — the app does the rest.',
                    ),
                    _FAQItem(
                      question: 'Does it work when the app is closed?',
                      answer:
                      'Yes. Silenz runs a background service that activates your schedules even when the app is not open.',
                    ),
                    _FAQItem(
                      question: 'What is Guest mode?',
                      answer:
                      'Guest mode lets you use the app without creating an account. Your schedules are saved locally on your device only.',
                    ),
                    _FAQItem(
                      question: 'What do I get with a Premium account?',
                      answer:
                      'Premium users get cloud sync across devices, unlimited schedules, cloud backup, and priority support.',
                    ),
                    _FAQItem(
                      question: 'How do I sync schedules across devices?',
                      answer:
                      'Log in with the same account on all your devices. Schedules are automatically synced to the cloud.',
                    ),
                    _FAQItem(
                      question: 'Can I use Google or Apple to sign in?',
                      answer:
                      'Yes! You can sign in with Google on Android and iOS, and with Apple ID on iOS.',
                    ),
                    _FAQItem(
                      question: 'How do I reset my password?',
                      answer:
                      'On the login screen, tap "Forgot Password?" and enter your email. We will send you a reset link.',
                    ),
                    _FAQItem(
                      question: 'How do I delete my account?',
                      answer:
                      'Go to Settings → Help → Contact Support and send us a deletion request. We will process it within 7 days.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Help bottom sheet ──
  void _showHelp() {
    showModalBottomSheet(
      context: context,
      backgroundColor: tc(context).surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: tc(context).border,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text('Help & Support',
                style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: tc(context).textPrimary)),
            const SizedBox(height: 20),
            _HelpOption(
              icon: Icons.email_outlined,
              title: 'Email Support',
              subtitle: 'support@Silenz.app',
              onTap: () => Navigator.pop(ctx),
            ),
            const SizedBox(height: 10),
            _HelpOption(
              icon: Icons.bug_report_outlined,
              title: 'Report a Bug',
              subtitle: 'Help us fix issues faster',
              onTap: () => Navigator.pop(ctx),
            ),
            const SizedBox(height: 10),
            _HelpOption(
              icon: Icons.question_answer_outlined,
              title: 'View FAQs',
              subtitle: 'Common questions answered',
              onTap: () {
                Navigator.pop(ctx);
                _showFAQs();
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProv   = context.watch<UserProvider>();
    final isLoggedIn = userProv.isLoggedIn;
    final user       = userProv.user;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Header ──
            Text('Settings', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: tc(context).textPrimary)),
            const SizedBox(height: 4),
            Text('Manage your account & preferences',
                style: GoogleFonts.outfit(fontSize: 13, color: tc(context).textSecondary)),

            const SizedBox(height: 28),

            // ════════════════════════════════════
            // ACCOUNT SECTION
            // ════════════════════════════════════
            _SectionLabel(label: 'ACCOUNT'),
            const SizedBox(height: 10),

            _SettingsCard(
              children: [

                // ── Profile Summary (if logged in) ──
                if (isLoggedIn) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 52, height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.accent.withOpacity(0.3),
                                width: 2),
                          ),
                          child: ClipOval(
                            child: user?['avatar'] != null &&
                                (user!['avatar'] as String).isNotEmpty
                                ? (user['avatar'] as String).startsWith('data:image')
                                ? Image.memory(
                                base64Decode((user['avatar'] as String).split(',').last),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _MiniInitials(initials: userProv.initials))
                                : Image.network(
                                user['avatar'],
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _MiniInitials(initials: userProv.initials))
                                : _MiniInitials(initials: userProv.initials),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(userProv.displayName,
                                  style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: tc(context).textPrimary)),
                              Text(userProv.email,
                                  style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: tc(context).textSecondary)),
                            ],
                          ),
                        ),
                        if (userProv.isPremium)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: AppColors.accentGradient,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('PRO',
                                style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800)),
                          ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: tc(context).border),
                ],

                // ── Update Profile ──
                _SettingsTile(
                  icon: Icons.person_outline,
                  iconColor: AppColors.accent,
                  title: 'Update Profile',
                  subtitle: 'Edit name and photo',
                  onTap: () {
                    if (isLoggedIn) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ProfileScreen()),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AuthScreen()),
                      );
                    }
                  },
                ),

                Divider(height: 1, indent: 54, color: tc(context).border),

                // ── Sign In / Log Out ──
                isLoggedIn
                    ? _SettingsTile(
                  icon: Icons.logout,
                  iconColor: AppColors.danger,
                  title: 'Log Out',
                  subtitle: 'Sign out of your account',
                  titleColor: AppColors.danger,
                  onTap: _logout,
                  showArrow: false,
                )
                    : _SettingsTile(
                  icon: Icons.login,
                  iconColor: AppColors.accent,
                  title: 'Sign In',
                  subtitle: 'Log in or create an account',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AuthScreen()),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ════════════════════════════════════
            // APPEARANCE SECTION
            // ════════════════════════════════════
            _SectionLabel(label: 'APPEARANCE'),
            const SizedBox(height: 10),

            _SettingsCard(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      // Icon
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: tc(context).textPrimary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child:  Icon(Icons.dark_mode_outlined,
                            color: tc(context).textPrimary, size: 18),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Dark Theme',
                                style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: tc(context).textPrimary)),
                            Text('Switch to dark mode',
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: tc(context).textSecondary)),
                          ],
                        ),
                      ),
                      // Toggle switch
                      GestureDetector(
                        onTap: () =>
                            setState(() => _isDarkTheme = !_isDarkTheme),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 46, height: 26,
                          decoration: BoxDecoration(
                            gradient: _isDarkTheme
                                ? AppColors.accentGradient
                                : null,
                            color: _isDarkTheme
                                ? null
                                : tc(context).surface2,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: AnimatedAlign(
                            duration: const Duration(milliseconds: 200),
                            alignment: _isDarkTheme
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 3),
                              width: 20, height: 20,
                              decoration: BoxDecoration(
                                color: _isDarkTheme
                                    ? Colors.white
                                    : tc(context).textSecondary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ════════════════════════════════════
            // SUPPORT SECTION
            // ════════════════════════════════════
            _SectionLabel(label: 'SUPPORT'),
            const SizedBox(height: 10),

            _SettingsCard(
              children: [
                _SettingsTile(
                  icon: Icons.feedback_outlined,
                  iconColor: const Color(0xFF8B5CF6),
                  title: 'Send Feedback',
                  subtitle: 'Share your thoughts with us',
                  onTap: _showFeedback,
                ),
                Divider(height: 1, indent: 54, color: tc(context).border),
                _SettingsTile(
                  icon: Icons.help_outline,
                  iconColor: const Color(0xFF0EA5E9),
                  title: 'Help',
                  subtitle: 'Contact support or report a bug',
                  onTap: _showHelp,
                ),
                Divider(height: 1, indent: 54, color: tc(context).border),
                _SettingsTile(
                  icon: Icons.quiz_outlined,
                  iconColor: const Color(0xFFF59E0B),
                  title: 'FAQs',
                  subtitle: 'Frequently asked questions',
                  onTap: _showFAQs,
                ),
                Divider(height: 1, indent: 54, color: tc(context).border),
                _SettingsTile(
                  icon: Icons.star_outline_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  title: 'Rate Silenz',
                  subtitle: 'Love the app? Leave us a rating!',
                  onTap: _showRating,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── App version ──
            Center(
              child: Text('Silenz v1.0.0',
                  style: GoogleFonts.poppins(
                      color: tc(context).textSecondary, fontSize: 11)),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Section Label
// ─────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: tc(context).textSecondary,
            letterSpacing: 0.8));
  }
}

// ─────────────────────────────────────────
// Settings Card (white rounded container)
// ─────────────────────────────────────────
class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: tc(context).surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tc(context).border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

// ─────────────────────────────────────────
// Settings Tile Row
// ─────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? titleColor;
  final bool showArrow;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.titleColor,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Icon box
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: titleColor ?? tc(context).textPrimary)),
                  Text(subtitle,
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: tc(context).textSecondary)),
                ],
              ),
            ),
            if (showArrow)
               Icon(Icons.chevron_right,
                  color: tc(context).textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Mini initials avatar (used in profile row)
// ─────────────────────────────────────────
class _MiniInitials extends StatelessWidget {
  final String initials;
  const _MiniInitials({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.accentGradient),
      child: Center(
        child: Text(initials,
            style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ─────────────────────────────────────────
// FAQ Expandable Item
// ─────────────────────────────────────────
class _FAQItem extends StatefulWidget {
  final String question;
  final String answer;
  const _FAQItem({required this.question, required this.answer});

  @override
  State<_FAQItem> createState() => _FAQItemState();
}

class _FAQItemState extends State<_FAQItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: tc(context).surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _expanded
              ? AppColors.accent.withOpacity(0.3)
              : tc(context).border,
        ),
      ),
      child: GestureDetector(
        onTap: () => setState(() => _expanded = !_expanded),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(widget.question,
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: tc(context).textPrimary)),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: tc(context).textSecondary,
                    size: 20,
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 10),
                Text(widget.answer,
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: tc(context).textSecondary,
                        height: 1.5)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Help option tile
// ─────────────────────────────────────────
class _HelpOption extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  const _HelpOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: tc(context).surface2,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.accent, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: tc(context).textPrimary)),
                  Text(subtitle,
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: tc(context).textSecondary)),
                ],
              ),
            ),
             Icon(Icons.chevron_right,
                color: tc(context).textSecondary, size: 18),
          ],
        ),
      ),
    );
  }
}