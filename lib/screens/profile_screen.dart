import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../providers/user_provider.dart';
import '../providers/app_provider.dart';
import '../services/auth_service.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  bool _isSaving       = false;
  bool _isUploadingImg = false;
  String? _error;
  String? _success;

  static const String _baseUrl = 'https://autosilence-backend-production.up.railway.app/api';

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>().user;
    _nameController = TextEditingController(text: user?['name'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // ── Pick image ──
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source:       source,
        maxWidth:     512,
        maxHeight:    512,
        imageQuality: 80,
      );
      if (picked == null) return;

      setState(() { _isUploadingImg = true; _error = null; _success = null; });

      final bytes  = await File(picked.path).readAsBytes();
      final base64 = base64Encode(bytes);
      final ext    = picked.path.split('.').last.toLowerCase();
      final dataUrl = 'data:image/$ext;base64,$base64';

      final token = await AuthService.getToken();
      final res   = await http.put(
        Uri.parse('$_baseUrl/user/avatar'),
        headers: {
          'Content-Type':  'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'avatar': dataUrl}),
      );

      final data = jsonDecode(res.body);
      if (!mounted) return;

      if (data['success'] == true) {
        // ✅ Update provider → home avatar updates instantly
        await   context.read<UserProvider>().updateUser({'avatar': dataUrl});
        setState(() => _success = 'Profile photo updated!');
      } else {
        setState(() => _error = data['message'] ?? 'Upload failed.');
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not upload: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isUploadingImg = false);
    }
  }

  // ── Image picker sheet ──
  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: tc(context).surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
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
            Text('Update Profile Photo',
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: tc(context).textPrimary)),
            const SizedBox(height: 20),
            _SheetOption(
              icon: Icons.camera_alt_outlined,
              label: 'Take Photo',
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: 10),
            _SheetOption(
              icon: Icons.photo_library_outlined,
              label: 'Choose from Gallery',
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 10),
            _SheetOption(
              icon: Icons.delete_outline,
              label: 'Remove Photo',
              color: AppColors.danger,
              onTap: () {
                Navigator.pop(context);
                _removePhoto();
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // ── Remove photo ──
  Future<void> _removePhoto() async {
    setState(() { _isUploadingImg = true; _error = null; _success = null; });
    try {
      final token = await AuthService.getToken();
      final res   = await http.put(
        Uri.parse('$_baseUrl/user/avatar'),
        headers: {
          'Content-Type':  'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'avatar': null}),
      );
      final data = jsonDecode(res.body);
      if (!mounted) return;
      if (data['success'] == true) {
        // ✅ Clear avatar in provider → home avatar reverts to initials
        await    context.read<UserProvider>().updateUser({'avatar': null});
        setState(() => _success = 'Photo removed.');
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to remove photo.');
    } finally {
      if (mounted) setState(() => _isUploadingImg = false);
    }
  }

  // ── Save name ──
  Future<void> _saveName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      setState(() => _error = 'Name cannot be empty.');
      return;
    }

    setState(() { _isSaving = true; _error = null; _success = null; });

    try {
      final token = await AuthService.getToken();
      final res   = await http.put(
        Uri.parse('$_baseUrl/user/profile'),
        headers: {
          'Content-Type':  'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'name': newName}),
      );
      final data = jsonDecode(res.body);
      if (!mounted) return;
      if (data['success'] == true) {
        // ✅ Update name in provider → drawer shows new name instantly
        await     context.read<UserProvider>().updateUser({'name': newName});
        setState(() => _success = 'Name updated successfully!');
      } else {
        setState(() => _error = data['message'] ?? 'Update failed.');
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Connection error.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

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
                color: tc(context).textPrimary)),
        content: Text('You will be signed out.',
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
      await context.read<AppProvider>().clearSchedules();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
            (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ watch() not read() so UI rebuilds when provider changes
    final userProv  = context.watch<UserProvider>();
    final avatarUrl = userProv.avatarUrl;

    return Scaffold(
      backgroundColor: tc(context).bg,
      appBar: AppBar(
        backgroundColor: tc(context).surface,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child:  Icon(Icons.arrow_back_ios_new,
              color: tc(context).textPrimary, size: 18),
        ),
        title: Text('Profile',
            style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: tc(context).textPrimary)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: tc(context).border),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [

              const SizedBox(height: 16),

              // ── Photo + edit button ──
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.accent.withOpacity(0.3),
                          width: 3),
                      boxShadow: [BoxShadow(
                        color: AppColors.accent.withOpacity(0.15),
                        blurRadius: 20, offset: const Offset(0, 6),
                      )],
                    ),
                    child: ClipOval(
                      child: _isUploadingImg
                          ? Container(
                        color: tc(context).surface2,
                        child: const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.accent, strokeWidth: 2),
                        ),
                      )
                          : avatarUrl != null && avatarUrl.isNotEmpty
                          ? Image.memory(
                        base64Decode(avatarUrl.split(',').last),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _BigInitials(initials: userProv.initials),
                      )
                          : _BigInitials(initials: userProv.initials),
                    ),
                  ),

                  // Camera button
                  GestureDetector(
                    onTap: _showImagePicker,
                    child: Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        gradient: AppColors.accentGradient,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: tc(context).surface, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Text(userProv.displayName,
                  style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: tc(context).textPrimary)),
              Text(userProv.email,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: tc(context).textSecondary)),

              if (userProv.isPremium) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: AppColors.accentGradient,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text('⭐ Premium',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
              ],

              const SizedBox(height: 28),

              // Feedback banners
              if (_success != null)
                _Banner(message: _success!, isError: false),
              if (_error != null)
                _Banner(message: _error!, isError: true),
              if (_success != null || _error != null)
                const SizedBox(height: 16),

              // ── Edit Name ──
              Align(
                alignment: Alignment.centerLeft,
                child: Text('FULL NAME', style: GoogleFonts.dmMono(fontSize: 10, fontWeight: FontWeight.w500, color: tc(context).textMuted, letterSpacing: 1.5)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                style: GoogleFonts.poppins(
                    color: tc(context).textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Your name',
                  prefixIcon: Icon(Icons.person_outline,
                      color: tc(context).textMuted, size: 20),
                ),
              ),

              const SizedBox(height: 16),

              // ── Save Button ──
              GestureDetector(
                onTap: _isSaving ? null : _saveName,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    gradient: AppColors.accentGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(
                      color: AppColors.accent.withOpacity(0.3),
                      blurRadius: 16, offset: const Offset(0, 6),
                    )],
                  ),
                  child: Center(child: _isSaving
                      ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                      : Text('Save Changes',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15))),
                ),
              ),

              const SizedBox(height: 28),
              Divider(color: tc(context).border),
              const SizedBox(height: 20),

              // ── Account Info ──
              _InfoRow(
                icon:  Icons.email_outlined,
                label: 'Email',
                value: userProv.email,
              ),
              const SizedBox(height: 12),
              _InfoRow(
                icon:  Icons.login,
                label: 'Sign-in Method',
                value: _cap(userProv.user?['authProvider'] ?? 'email'),
              ),

              const SizedBox(height: 28),

              // ── Log Out ──
              GestureDetector(
                onTap: _logout,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.danger.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.logout,
                          color: AppColors.danger, size: 18),
                      const SizedBox(width: 8),
                      Text('Log Out',
                          style: GoogleFonts.poppins(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ─────────────────────────────────────────
// Big initials for profile circle
// ─────────────────────────────────────────
class _BigInitials extends StatelessWidget {
  final String initials;
  const _BigInitials({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.accentGradient),
      child: Center(
        child: Text(initials,
            style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Banner
// ─────────────────────────────────────────
class _Banner extends StatelessWidget {
  final String message;
  final bool isError;
  const _Banner({required this.message, required this.isError});

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.danger : AppColors.accent;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(
          isError ? Icons.error_outline : Icons.check_circle_outline,
          color: color, size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(message,
            style: GoogleFonts.poppins(color: color, fontSize: 12))),
      ]),
    );
  }
}

// ─────────────────────────────────────────
// Info Row
// ─────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tc(context).surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tc(context).border),
      ),
      child: Row(children: [
        Icon(icon, color: tc(context).textMuted, size: 18),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.poppins(
                    color: tc(context).textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
            Text(value,
                style: GoogleFonts.poppins(
                    color: tc(context).textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────
// Sheet Option
// ─────────────────────────────────────────
class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _SheetOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? tc(context).textPrimary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: tc(context).surface2,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(icon, color: c, size: 20),
          const SizedBox(width: 12),
          Text(label,
              style: GoogleFonts.poppins(
                  color: c,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}