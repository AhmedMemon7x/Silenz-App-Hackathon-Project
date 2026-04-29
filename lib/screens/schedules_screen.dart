import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../providers/app_provider.dart';
import '../models/schedule_model.dart';
import 'edit_schedule_screen.dart';


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
class SchedulesScreen extends StatefulWidget {
  const SchedulesScreen({super.key});

  @override
  State<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends State<SchedulesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    // Rebuild whenever the text changes so the list filters live
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filter schedules by name, mode, or day
  List<Schedule> _filtered(List<Schedule> all) {
    if (_query.isEmpty) return all;
    return all.where((s) {
      return s.name.toLowerCase().contains(_query) ||
          s.mode.toLowerCase().contains(_query) ||
          s.days.any((d) => d.toLowerCase().contains(_query));
    }).toList();
  }

  // ── Delete confirmation dialog ──
  Future<void> _confirmDelete(BuildContext context, Schedule s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tc(context).surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Schedule?',
          style: GoogleFonts.poppins(
            color: tc(context).textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        content: Text(
          '"${s.name}" will be permanently removed.',
          style: GoogleFonts.poppins(
            color: tc(context).textSecondary,
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: tc(context).textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<AppProvider>().deleteSchedule(s.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: tc(context).surface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(
            '${s.name} deleted',
            style: GoogleFonts.poppins(
              color: tc(context).textPrimary,
              fontSize: 13,
            ),
          ),
        ),
      );
    }
  }

  // ── Open edit screen ──
  void _openEdit(BuildContext context, Schedule s) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditScheduleScreen(schedule: s)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final filtered = _filtered(provider.schedules);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Schedules', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, color: tc(context).textPrimary),),
                    Text(
                      '${provider.activeCount} active · '
                          '${provider.schedules.length - provider.activeCount} disabled',
                      style: GoogleFonts.outfit(fontSize: 13, color: tc(context).textSecondary),
                    ),
                  ],
                ),
                // Total count badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.accent.withOpacity(0.1)
                        : Colors.black.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.accent.withOpacity(0.2)
                            : Colors.black.withOpacity(0.15)),),
                  child: Text(
                    '${provider.schedules.length} total',
                    style: GoogleFonts.poppins(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.accent
                          : Colors.black,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Search Bar ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.poppins(
                color: tc(context).textPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Search by name, mode or day...',
                hintStyle: GoogleFonts.poppins(
                  color: tc(context).textSecondary,
                  fontSize: 13,
                ),
                prefixIcon:  Icon(
                  Icons.search,
                  color: tc(context).textSecondary,
                  size: 20,
                ),
                // Clear button appears when there is text
                suffixIcon: _query.isNotEmpty
                    ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                  child:  Icon(
                    Icons.close,
                    color: tc(context).textSecondary,
                    size: 18,
                  ),
                )
                    : null,
                filled: true,
                fillColor: tc(context).surface,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 13),
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
          ),

          const SizedBox(height: 8),

          // ── Results count when searching ──
          if (_query.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '${filtered.length} result${filtered.length == 1 ? '' : 's'} for "$_query"',
                style: GoogleFonts.poppins(
                  color: tc(context).textSecondary,
                  fontSize: 11,
                ),
              ),
            ),

          const SizedBox(height: 8),

          // ── Schedule List ──
          Expanded(
            child: filtered.isEmpty
                ? _EmptyState(query: _query)
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final s = filtered[index];
                return _ScheduleCard(
                  schedule: s,
                  onToggle: () =>
                      provider.toggleSchedule(s.id),
                  onEdit: () => _openEdit(context, s),
                  onDelete: () => _confirmDelete(context, s),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Schedule Card with swipe + action buttons
// ─────────────────────────────────────────
class _ScheduleCard extends StatelessWidget {
  final Schedule schedule;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ScheduleCard({
    required this.schedule,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  Color get _modeColor {
    switch (schedule.mode) {
      case 'DND':    return AppColors.danger;
      case 'Vibrate': return AppColors.warning;
      default:        return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isOn = schedule.isEnabled;

    return Dismissible(
      key: ValueKey(schedule.id),
      direction: DismissDirection.endToStart,
      // Red delete background revealed on swipe
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.danger.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.danger.withOpacity(0.3)),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.delete_outline,
                color: AppColors.danger, size: 24),
            const SizedBox(height: 4),
            Text('Delete',
                style: GoogleFonts.poppins(
                    color: AppColors.danger,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        // Reuse the same confirm dialog
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: tc(context).surface,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Text('Delete Schedule?',
                style: GoogleFonts.poppins(
                    color: tc(context).textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 17)),
            content: Text('"${schedule.name}" will be permanently removed.',
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
                child: Text('Delete',
                    style: GoogleFonts.poppins(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );
        if (confirmed == true) onDelete();
        return false; // We handle deletion manually via onDelete
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: tc(context).surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isOn ? tc(context).border2 : tc(context).border,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Main Row ──
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon
                  Opacity(
                    opacity: isOn ? 1.0 : 0.4,
                    child: Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: tc(context).surface2,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Icon(_scheduleIcon(schedule.icon),
                            color: Theme.of(context).brightness == Brightness.dark
                                ? AppColors.accent
                                : Colors.black87,
                            size: 22),),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          schedule.name,
                          style: GoogleFonts.poppins(
                            color: isOn
                                ? tc(context).textPrimary
                                : tc(context).textSecondary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${_to12hr(schedule.startTime)} – ${_to12hr(schedule.endTime)}',
                          style: GoogleFonts.poppins(
                            color: tc(context).textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            // Mode badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _modeColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                schedule.mode,
                                style: GoogleFonts.poppins(
                                  color: _modeColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                schedule.days.join(' · '),
                                style: GoogleFonts.poppins(
                                  color: tc(context).textMuted,
                                  fontSize: 10,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Toggle switch
                  GestureDetector(
                    onTap: onToggle,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 46, height: 26,
                      decoration: BoxDecoration(
                        gradient:
                        isOn ? AppColors.accentGradient : null,
                        color: isOn ? null : tc(context).surface2,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: AnimatedAlign(
                        duration: const Duration(milliseconds: 200),
                        alignment: isOn
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 3),
                          width: 20, height: 20,
                          decoration: BoxDecoration(
                            color: isOn
                                ? Colors.white
                                : tc(context).textMuted,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Divider ──
            Divider(height: 1, indent: 16, endIndent: 16,
                color: tc(context).border),

            // ── Edit / Delete action row ──
            Row(
              children: [
                // Edit button
                Expanded(
                  child: GestureDetector(
                    onTap: onEdit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit_outlined,
                              size: 15, color: Theme.of(context).brightness == Brightness.dark
                                ? AppColors.accent
                                : Colors.black87,),
                          const SizedBox(width: 6),
                          Text(
                            'Edit',
                            style: GoogleFonts.poppins(
                               color: Theme.of(context).brightness == Brightness.dark
                                ? AppColors.accent
                                : Colors.black87,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Vertical divider
                Container(
                  width: 1, height: 28,
                  color: tc(context).border,
                ),

                // Delete button
                Expanded(
                  child: GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.delete_outline,
                              size: 15, color: AppColors.danger),
                          const SizedBox(width: 6),
                          Text(
                            'Delete',
                            style: GoogleFonts.poppins(
                              color: AppColors.danger,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String query;
  const _EmptyState({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            query.isEmpty ? Icons.calendar_today_outlined : Icons.search_off_rounded,
            color: tc(context).textSecondary, size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            query.isEmpty
                ? 'No schedules yet'
                : 'No results for "$query"',
            style: GoogleFonts.poppins(
              color: tc(context).textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            query.isEmpty
                ? 'Tap + to create your first schedule'
                : 'Try a different name, mode or day',
            style: GoogleFonts.poppins(
              color: tc(context).textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}