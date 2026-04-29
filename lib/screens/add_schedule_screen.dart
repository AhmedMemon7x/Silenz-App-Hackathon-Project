import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../providers/app_provider.dart';
import '../models/schedule_model.dart';

class AddScheduleScreen extends StatefulWidget {
  const AddScheduleScreen({super.key});

  @override
  State<AddScheduleScreen> createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends State<AddScheduleScreen> {
  final _nameController = TextEditingController(text: 'Work Hours');

  String _selectedIcon = 'work';

  // Always stored as TimeOfDay — never as String
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime   = const TimeOfDay(hour: 17, minute: 30);

  String _selectedMode = 'Silent';
  final Set<String> _selectedDays = {'Mon', 'Tue', 'Wed', 'Thu', 'Fri'};
  bool _saved = false;
  bool _userEditedName = false; // true once user manually types a name

  static const Map<String, String> _iconNames = {
    'work':    'Work Hours',
    'sleep':   'Sleep Time',
    'silent':  'Silent Mode',
    'vibrate': 'Vibrate Mode',
    'school':  'School Time',
    'gym':     'Gym Session',
    'pray':    'Prayer Time',
    'food':    'Meal Break',
    'music':   'Music Time',
    'sport':   'Sports Time',
  };

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() {
      final suggested = _iconNames[_selectedIcon] ?? '';
      if (_nameController.text == suggested) {
        // User cleared back to suggestion — allow auto-fill again
        _userEditedName = false;
      } else if (_nameController.text.isNotEmpty) {
        _userEditedName = true;
      }
    });
  }

  final List<Map<String, dynamic>> _icons = [
    {'key': 'work',    'icon': Icons.business_rounded},
    {'key': 'sleep',   'icon': Icons.bedtime_rounded},
    {'key': 'silent',  'icon': Icons.volume_off_rounded},
    {'key': 'vibrate', 'icon': Icons.vibration_rounded},
    {'key': 'school',  'icon': Icons.school_rounded},
    {'key': 'gym',     'icon': Icons.fitness_center_rounded},
    {'key': 'pray',    'icon': Icons.self_improvement_rounded},
    {'key': 'food',    'icon': Icons.restaurant_rounded},
    {'key': 'music',   'icon': Icons.music_note_rounded},
    {'key': 'sport',   'icon': Icons.sports_soccer_rounded},
  ];
  final List<String> _days  = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
  final List<String> _modes = ['Silent','Vibrate','DND'];

  // ── "9:00 AM" / "5:30 PM" ──
  String _fmt12(TimeOfDay t) {
    final int h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final String m = t.minute.toString().padLeft(2, '0');
    final String p = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $p';
  }

  // ── "09:00" for Schedule model ──
  String _fmt24(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  // ── Open native 12-hour time picker ──
  Future<void> _pickTime({required bool isStart}) async {
    final TimeOfDay initial = isStart ? _startTime : _endTime;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (BuildContext ctx, Widget? child) {
        // Force 12-hour format regardless of device locale setting
        return MediaQuery(
          data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );

    // Guard: only update state if user tapped OK (not Cancel)
    if (picked != null && mounted) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Header ──
            Text('New Schedule', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: tc(context).textPrimary)),
            const SizedBox(height: 4),
            Text('Set up automatic silence', style: GoogleFonts.outfit(fontSize: 13, color: tc(context).textSecondary)),
            const SizedBox(height: 28),

            // ── Name ──
            Text('SCHEDULE NAME', style: GoogleFonts.dmMono(fontSize: 10, fontWeight: FontWeight.w500, color: tc(context).textSecondary, letterSpacing: 1.5)),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              style: GoogleFonts.poppins(
                color: tc(context).textPrimary,
                fontWeight: FontWeight.w500,
              ),
              decoration: const InputDecoration(hintText: 'e.g. Work Hours'),
            ),
            const SizedBox(height: 24),

            // ── Icon Picker ──
            Text('ICON', style: GoogleFonts.dmMono(fontSize: 10, fontWeight: FontWeight.w500, color: tc(context).textSecondary,letterSpacing: 1)),
            const SizedBox(height: 10),
            SizedBox(
              height: 54,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _icons.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, int i) {
                  final item   = _icons[i];
                  final String key  = item['key'] as String;
                  final IconData ic = item['icon'] as IconData;
                  final bool isSel  = key == _selectedIcon;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedIcon = key;
                      if (!_userEditedName) {
                        _nameController.text = _iconNames[key] ?? '';
                        _nameController.selection = TextSelection.fromPosition(
                          TextPosition(offset: _nameController.text.length),
                        );
                      }
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 54, height: 54,
                      decoration: BoxDecoration(
                        color: isSel ? AppColors.accent : tc(context).surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSel ? AppColors.accent : tc(context).border,
                        ),
                        boxShadow: isSel
                            ? [BoxShadow(
                          color: AppColors.accent.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )]
                            : [],
                      ),
                      child: Icon(ic,
                        color: isSel ? Colors.black : tc(context).textSecondary,
                        size: 22,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // ── Time Range ──
            Text('TIME RANGE', style: GoogleFonts.dmMono(fontSize: 10, fontWeight: FontWeight.w500, color: tc(context).textSecondary,letterSpacing: 1)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _TimeCard(
                    label: 'Start',
                    time:  _fmt12(_startTime),
                    onTap: () => _pickTime(isStart: true),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(Icons.arrow_forward_rounded,
                    color: tc(context).textSecondary, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: _TimeCard(
                    label: 'End',
                    time:  _fmt12(_endTime),
                    onTap: () => _pickTime(isStart: false),
                  ),
                ),
              ],
            ),

            // ── AM / PM badges ──
            const SizedBox(height: 10),
            Row(
              children: [
                _PeriodBadge(
                  label: _startTime.period == DayPeriod.am ? 'AM' : 'PM',
                  color: _startTime.period == DayPeriod.am
                      ? AppColors.warning
                      : AppColors.accent,
                ),
                const SizedBox(width: 8),
                 Icon(Icons.arrow_forward,
                    color: tc(context).textSecondary, size: 13),
                const SizedBox(width: 8),
                _PeriodBadge(
                  label: _endTime.period == DayPeriod.am ? 'AM' : 'PM',
                  color: _endTime.period == DayPeriod.am
                      ? AppColors.warning
                      : AppColors.accent,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Repeat Days ──
            Text('REPEAT DAYS', style: GoogleFonts.dmMono(fontSize: 10, fontWeight: FontWeight.w500, color: tc(context).textSecondary,letterSpacing: 1)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _days.map((String day) {
                final bool isOn = _selectedDays.contains(day);
                return GestureDetector(
                  onTap: () => setState(() =>
                  isOn ? _selectedDays.remove(day) : _selectedDays.add(day)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      gradient: isOn ? AppColors.accentGradient : null,
                      color:    isOn ? null : tc(context).surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isOn ? Colors.transparent : tc(context).border,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        day.substring(0, 1),
                        style: GoogleFonts.poppins(
                          color: isOn ? Colors.white : tc(context).textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // ── Silence Mode ──
            Text('SILENCE MODE', style: GoogleFonts.dmMono(fontSize: 10, fontWeight: FontWeight.w500, color: tc(context).textSecondary,letterSpacing: 1)),
            const SizedBox(height: 10),
            Row(
              children: _modes.map((String mode) {
                final bool isOn  = mode == _selectedMode;
                final bool isLast = mode == _modes.last;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedMode = mode),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: EdgeInsets.only(right: isLast ? 0 : 8),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        gradient: isOn ? AppColors.accentGradient : null,
                        color:    isOn ? null : tc(context).surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isOn ? Colors.transparent : tc(context).border,
                        ),
                        boxShadow: isOn
                            ? [BoxShadow(
                          color: AppColors.accent.withOpacity(0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )]
                            : [],
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              mode == 'Silent'
                                  ? Icons.volume_off_rounded
                                  : mode == 'Vibrate'
                                  ? Icons.vibration_rounded
                                  : Icons.do_not_disturb_on_rounded,
                              color: isOn ? Colors.black : tc(context).textSecondary,
                              size: 15,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              mode,
                              style: GoogleFonts.outfit(
                                color: isOn ? Colors.black : tc(context).textSecondary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 36),

            // ── Save Button ──
            GestureDetector(
              onTap: _save,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: _saved
                      ? const LinearGradient(
                    colors: [Color(0xFF065F46), Color(0xFF10B981)],
                  )
                      : AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _saved ? '✓ Saved!' : 'Save Schedule',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final AppProvider provider = context.read<AppProvider>();
    await provider.addSchedule(Schedule(
      id:        DateTime.now().millisecondsSinceEpoch.toString(),
      name:      _nameController.text.trim().isEmpty
          ? 'New Schedule'
          : _nameController.text.trim(),
      icon:      _selectedIcon,
      startTime: _fmt24(_startTime),
      endTime:   _fmt24(_endTime),
      days:      _selectedDays.toList(),
      mode:      _selectedMode,
    ));
    setState(() => _saved = true);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        provider.setNavIndex(1);
        setState(() => _saved = false);
      }
    });
  }
}

// ─────────────────────────────────────────
// Time Card
// ─────────────────────────────────────────
class _TimeCard extends StatelessWidget {
  final String label;
  final String time;
  final VoidCallback onTap;

  const _TimeCard({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: tc(context).surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tc(context).border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                color: tc(context).textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              time,
              style: GoogleFonts.dmMono(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: tc(context).textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// AM / PM Badge
// ─────────────────────────────────────────
class _PeriodBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _PeriodBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}