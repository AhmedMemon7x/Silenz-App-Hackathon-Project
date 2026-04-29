import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../providers/app_provider.dart';
import '../providers/user_provider.dart';
import 'auth_screen.dart';
import 'profile_screen.dart';
import '../services/ringer_service.dart';
import '../services/schedule_checker.dart';

String _to12hr(String time24) {
  try {
    final parts = time24.split(':');
    int hour    = int.parse(parts[0]);
    final min   = parts[1];
    final period = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    return '$hour:$min $period';
  } catch (_) { return time24; }
}




IconData _scheduleIcon(String key) {
  switch (key) {
    case 'work':    return Icons.business_rounded;
    case 'sleep':   return Icons.bedtime_rounded;
    case 'silent':  return Icons.volume_off_rounded;
    case 'vibrate': return Icons.vibration_rounded;
    case 'school':  return Icons.school_rounded;
    case 'gym':     return Icons.fitness_center_rounded;
    case 'pray':    return Icons.self_improvement_rounded;
    case 'food':    return Icons.restaurant_rounded;
    case 'music':   return Icons.music_note_rounded;
    case 'sport':   return Icons.sports_soccer_rounded;
  // legacy emoji fallbacks
    case '🔕': return Icons.volume_off_rounded;
    case '📳': return Icons.vibration_rounded;
    case '🔊': return Icons.volume_up_rounded;
    case '😴': return Icons.bedtime_rounded;
    case '🏢': return Icons.business_rounded;
    default:   return Icons.notifications_off_rounded;
  }
}
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider  = context.watch<AppProvider>();
    final userProv  = context.watch<UserProvider>();
    final colors    = tc(context);
    final isLoggedIn = userProv.isLoggedIn;
    final active    = provider.activeSchedule;
    final hasActive = active != null;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const SizedBox(height: 16),

            // ── Top Bar ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Scaffold.of(context).openDrawer(),
                  child: _IconBtn(icon: Icons.menu_rounded),
                ),
                Text('SILENZ',
                    style: GoogleFonts.dmMono(
                      color: colors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 3,
                    )),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => isLoggedIn
                          ? const ProfileScreen()
                          : const AuthScreen())),
                  child: _Avatar(
                    isLoggedIn: isLoggedIn,
                    avatarUrl: userProv.avatarUrl,
                    initials: userProv.initials,

                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Main Status Card ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: hasActive
                      ? AppColors.accent.withOpacity(0.4)
                      : colors.border,
                  width: hasActive ? 1.5 : 1,
                ),
                boxShadow: hasActive ? [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.06),
                    blurRadius: 24, offset: const Offset(0, 8),
                  )
                ] : [],
              ),
              child: Row(
                children: [
                  // Mode indicator
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: hasActive
                          ? AppColors.accent.withOpacity(0.08)
                          : colors.surface2,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: hasActive
                            ? AppColors.accent.withOpacity(0.3)
                            : colors.border,
                      ),
                    ),

                    child: Center(
                      child: Icon(
                        hasActive
                            ? (active!.mode == 'Vibrate'
                            ? Icons.vibration_rounded
                            : active!.mode == 'Normal'
                            ? Icons.volume_up_rounded
                            : Icons.volume_off_rounded)
                            : Icons.volume_up_rounded,
                        color: hasActive ? AppColors.accent : colors.textPrimary,
                        size: 28,
                      ),
                    ),

                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasActive
                              ? active!.mode.toUpperCase()
                              : 'NORMAL',
                          style: GoogleFonts.outfit(
                            color: hasActive
                                ? AppColors.accent
                                : colors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasActive
                              ? '${active!.name} · Until ${_to12hr(active.endTime)}'
                              : 'No active schedule',
                          style: GoogleFonts.dmMono(
                            color: colors.textSecondary,
                            fontSize: 10,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (hasActive) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('● ACTIVE',
                                style: GoogleFonts.dmMono(
                                  color: Colors.black,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                )),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Stats Row ──
            Row(
              children: [
                _StatCard(
                  value: '${provider.schedules.length}',
                  label: 'SCHEDULES',
                ),
                const SizedBox(width: 10),
                _StatCard(
                  value: '${provider.activeCount}',
                  label: 'ACTIVE',
                  highlight: provider.activeCount > 0,
                ),
                const SizedBox(width: 10),
                _StatCard(
                  value: '${provider.schedules.where((s) => s.isEnabled).length * 8}h',
                  label: 'THIS WEEK',
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Quick actions ──
            Row(
              children: [
                Expanded(
                  child: _ActionBtn(
                    label: 'DND',
                    icon: Icons.do_disturb_on,
                    accentColor: AppColors.accentOrBlack(context),
                    onTap: () async {
                      final ok = await RingerService.setSilent();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          backgroundColor: ok ? AppColors.accent : AppColors.danger,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          content: Text(ok ? 'DND mode applied' : 'Failed — grant DND permission',
                              style: GoogleFonts.outfit(
                                  color: ok ? Colors.black : Colors.white,
                                  fontWeight: FontWeight.w600)),
                        ));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionBtn(
                    label: 'SILENT',
                    icon: Icons.volume_off_rounded,
                    accentColor: const Color(0xFF7F5AF0),
                    onTap: () async {
                      final ok = await RingerService.setVibrate();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          backgroundColor: ok ? AppColors.accent : AppColors.danger,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          content: Text(ok ? 'SILENT mode applied' : 'Failed',
                              style: GoogleFonts.outfit(
                                  color: ok ? Colors.black : Colors.white,
                                  fontWeight: FontWeight.w600)),
                        ));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionBtn(
                    label: 'NORMAL',
                    icon: Icons.volume_up_rounded,
                    accentColor: const Color(0xFF2CB67D),
                    onTap: () async {
                      final ok = await RingerService.setNormal();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          backgroundColor: ok ? AppColors.accent : AppColors.danger,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          content: Text(ok ? 'Normal mode restored' : 'Failed',
                              style: GoogleFonts.outfit(
                                  color: ok ? Colors.black : Colors.white,
                                  fontWeight: FontWeight.w600)),
                        ));
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Schedules Section ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('SCHEDULES',
                    style: GoogleFonts.dmMono(
                      color: colors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 2,
                    )),
                GestureDetector(
                  onTap: () => ScheduleChecker.checkNow(),
                  child: Text('SYNC',
                      style: GoogleFonts.dmMono(
                        color: AppColors.accentOrBlack(context),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      )),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (provider.schedules.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  children: [
                    Icon(Icons.calendar_today_outlined, color: tc(context).textMuted, size: 32),
                    const SizedBox(height: 10),
                    Text('No schedules yet',
                        style: GoogleFonts.outfit(
                            color: colors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('Add a schedule to get started',
                        style: GoogleFonts.dmMono(
                            color: colors.textSecondary, fontSize: 10)),
                  ],
                ),
              )
            else
              ...provider.schedules
                  .take(3)
                  .map((s) => _ScheduleTile(schedule: s)),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Icon Button ──
class _IconBtn extends StatelessWidget {
  final IconData icon;
  const _IconBtn({required this.icon});

  @override
  Widget build(BuildContext context) {
    final colors = tc(context);
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Icon(icon, color: colors.textSecondary, size: 18),
    );
  }
}

// ── Avatar ──
class _Avatar extends StatelessWidget {
  final bool isLoggedIn;
  final String? avatarUrl;
  final String initials;
  const _Avatar({required this.isLoggedIn, this.avatarUrl, required this.initials});

  @override
  Widget build(BuildContext context) {
    final colors = tc(context);
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: isLoggedIn ? Colors.black : colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLoggedIn ? AppColors.accent : colors.border,
          width: isLoggedIn ? 1.5 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: isLoggedIn && avatarUrl != null && avatarUrl!.isNotEmpty
            ? avatarUrl!.startsWith('data:image')
            ? Image.memory(
            base64Decode(avatarUrl!.split(',').last),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _Initials(initials: initials))
            : Image.network(
            avatarUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _Initials(initials: initials))
            : isLoggedIn
            ? _Initials(initials: initials)
            : Icon(Icons.person_outline, color: colors.textPrimary, size: 18),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  final String initials;
  const _Initials({required this.initials});
  @override
  Widget build(BuildContext context) => Container(
    color: Colors.black,
    child: Center(
      child: Text(initials,
          style: GoogleFonts.outfit(
              color: AppColors.accent, fontSize: 14, fontWeight: FontWeight.w800)),
    ),
  );
}

// ── Stat Card ──
class _StatCard extends StatelessWidget {
  final String value, label;
  final bool highlight;
  const _StatCard({required this.value, required this.label, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final colors = tc(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: highlight ? AppColors.accent.withOpacity(0.3) : colors.border,
          ),
        ),
        child: Column(
          children: [
            Text(value,
                style: GoogleFonts.outfit(
                  color: highlight ? AppColors.accent : colors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                )),
            const SizedBox(height: 2),
            Text(label,
                style: GoogleFonts.dmMono(
                  color: colors.textSecondary,
                  fontSize: 8,
                  letterSpacing: 1,
                )),
          ],
        ),
      ),
    );
  }
}

// ── Action Button ──
class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final Color? accentColor;
  const _ActionBtn({required this.label, required this.onTap, this.icon, this.accentColor});

  @override
  Widget build(BuildContext context) {
    final colors = tc(context);
    final color  = accentColor ?? colors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: color, size: 18),
              const SizedBox(height: 5),
            ],
            Text(label,
                style: GoogleFonts.dmMono(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1)),
          ],
        ),
      ),
    );
  }
}

// ── Schedule Tile ──
class _ScheduleTile extends StatelessWidget {
  final dynamic schedule;
  const _ScheduleTile({required this.schedule});

  @override
  Widget build(BuildContext context) {
    final colors = tc(context);
    final isActive = schedule.isEnabled;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? AppColors.accent.withOpacity(0.25)
              : colors.border,
        ),
      ),
      child: Row(
        children: [
          Opacity(
            opacity: isActive ? 1.0 : 0.4,
            child: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: tc(context).surface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.accent
                      : tc(context).surface2,
                  ),
              ),
              child: Center(
                  child: Icon(_scheduleIcon(schedule.icon),
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.accent
                          : Colors.black87, size: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(schedule.name,
                    style: GoogleFonts.outfit(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
                Text('${_to12hr(schedule.startTime)} – ${_to12hr(schedule.endTime)}',
                    style: GoogleFonts.dmMono(
                        color: colors.textSecondary, fontSize: 9)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isActive ? AppColors.accent : colors.surface2,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              schedule.mode.toUpperCase(),
              style: GoogleFonts.dmMono(
                color: isActive ? Colors.black : colors.textMuted,
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}