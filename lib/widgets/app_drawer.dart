import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../providers/app_provider.dart';
import '../providers/user_provider.dart';
import '../screens/auth_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final provider   = context.watch<AppProvider>();
    final userProv   = context.watch<UserProvider>();
    final isLoggedIn = userProv.isLoggedIn;
    final colors     = tc(context);

    return Drawer(
      backgroundColor: colors.bg,
      child: Column(
        children: [

          // ── Header ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
            color: colors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.accent, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: isLoggedIn && userProv.avatarUrl != null && userProv.avatarUrl!.isNotEmpty
                        ? userProv.avatarUrl!.startsWith('data:image')
                        ? Image.memory(
                        base64Decode(userProv.avatarUrl!.split(',').last),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _Initials(initials: userProv.initials))
                        : Image.network(
                        userProv.avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _Initials(initials: userProv.initials))
                        : isLoggedIn
                        ? _Initials(initials: userProv.initials)
                        : Icon(Icons.person_outline, color: colors.textPrimary, size: 18),
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  isLoggedIn ? userProv.displayName : 'Guest',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isLoggedIn ? userProv.email : 'Sign in to sync schedules',
                  style: GoogleFonts.dmMono(
                    fontSize: 10,
                    color: colors.textSecondary,
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),

                // Status pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                  ),
                  child: Text(
                    isLoggedIn
                        ? (userProv.isPremium ? '⭐ Premium' : 'Free Plan')
                        : 'Guest Mode',
                    style: GoogleFonts.dmMono(
                      color: AppColors.accentOrBlack(context),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Nav Items ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
              children: [
                _DrawerItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Home',
                  active: provider.currentNavIndex == 0,
                  onTap: () { Navigator.pop(context); provider.setNavIndex(0); },
                ),
                _DrawerItem(
                  icon: Icons.add_circle_outline,
                  activeIcon: Icons.add_circle_rounded,
                  label: 'Add Schedule',
                  active: provider.currentNavIndex == 2,
                  onTap: () { Navigator.pop(context); provider.setNavIndex(2); },
                ),
                _DrawerItem(
                  icon: Icons.calendar_month_outlined,
                  activeIcon: Icons.calendar_month_rounded,
                  label: 'All Schedules',
                  active: provider.currentNavIndex == 1,
                  badge: provider.schedules.isNotEmpty ? '${provider.schedules.length}' : null,
                  onTap: () { Navigator.pop(context); provider.setNavIndex(1); },
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: colors.border, height: 1),
                ),

                _DrawerItem(
                  icon: Icons.location_on_outlined,
                  activeIcon: Icons.location_on_rounded,
                  label: 'Add Zones',
                  active: provider.currentNavIndex == 3,
                  onTap: () { Navigator.pop(context); provider.setNavIndex(3); },
                ),
                _DrawerItem(
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings_rounded,
                  label: 'Settings',
                  active: provider.currentNavIndex == 4,
                  onTap: () { Navigator.pop(context); provider.setNavIndex(4); },
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: colors.border, height: 1),
                ),

                // ── Dark Mode Toggle ──
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          color: colors.surface2,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          provider.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.accent
                              : Colors.black87,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          provider.isDark ? 'Dark Mode' : 'Light Mode',
                          style: GoogleFonts.outfit(
                            color: colors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => provider.toggleTheme(),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 44, height: 24,
                          decoration: BoxDecoration(
                            color: provider.isDark ? AppColors.accent : colors.border2,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: AnimatedAlign(
                            duration: const Duration(milliseconds: 200),
                            alignment: provider.isDark
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              width: 18, height: 18,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: provider.isDark ? Colors.black : Colors.white,
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
          ),

          // ── Bottom — Sign In / Log Out ──
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colors.border)),
            ),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 28),
            child: isLoggedIn
                ? _LogoutButton(
                onTap: () async {
              // Navigator.pop(context);
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: tc(context).surface,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  title: Text('Log Out?',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w800,
                          color: tc(context).textPrimary,
                          fontSize: 18)),
                  content: Text('You will be signed out.',
                      style: GoogleFonts.outfit(
                          color: tc(context).textSecondary, fontSize: 13)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text('Cancel',
                          style: GoogleFonts.outfit(
                              color: tc(context).textSecondary,
                              fontWeight: FontWeight.w600)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text('Log Out',
                          style: GoogleFonts.outfit(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                Navigator.pop(context);
                await context.read<UserProvider>().logout();
                await context.read<AppProvider>().clearSchedules();
                Navigator.pushAndRemoveUntil(context,
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                        (_) => false);
              }
            })
                : _SignInButton(onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AuthScreen()));
            }),
          ),
        ],
      ),
    );
  }
}

// ── Initials ──
class _Initials extends StatelessWidget {
  final String initials;
  const _Initials({required this.initials});
  @override
  Widget build(BuildContext context) => Container(
    color: Colors.black,
    child: Center(
      child: Text(initials,
          style: GoogleFonts.outfit(
              color: AppColors.accent, fontSize: 20, fontWeight: FontWeight.w800)),
    ),
  );
}

// ── Drawer Item ──
class _DrawerItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final bool active;
  final String? badge;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final colors = tc(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: active ? Colors.transparent : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? (Theme.of(context).brightness == Brightness.dark ? AppColors.accent.withOpacity(0.2) : Colors.black.withOpacity(0.15)) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: active ? Theme.of(context).brightness == Brightness.dark
                    ? AppColors.accent.withOpacity(0.12)
                    : Colors.black : colors.surface2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                active ? activeIcon : icon,
                color: active ? Theme.of(context).brightness == Brightness.dark
                    ? AppColors.accent
                    : Colors.white : colors.textSecondary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.outfit(
                    color: active ? (Theme.of(context).brightness == Brightness.dark ? AppColors.accent : Colors.black) : colors.textPrimary,
                    fontSize: 14,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  )),
            ),
            if (active)
              Container(
                width: 6, height: 6,
                decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.accent
                        : Colors.black, shape: BoxShape.circle),
              ),
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.surface2,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(badge!,
                    style: GoogleFonts.dmMono(
                        color: colors.textMuted, fontSize: 10)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Logout Button ──
class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutButton({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.danger.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.danger.withOpacity(0.2)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.logout_rounded, color: AppColors.danger, size: 18),
          const SizedBox(width: 8),
          Text('Log Out',
              style: GoogleFonts.outfit(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
        ]),
      ),
    );
  }
}

// ── Sign In Button ──
class _SignInButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SignInButton({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.login_rounded, color: Colors.black, size: 18),
          const SizedBox(width: 8),
          Text('Sign In',
              style: GoogleFonts.outfit(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                  fontSize: 14)),
        ]),
      ),
    );
  }
}