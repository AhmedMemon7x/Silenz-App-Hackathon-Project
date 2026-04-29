import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../providers/app_provider.dart';
import '../models/schedule_model.dart';

class EditScheduleScreen extends StatefulWidget {
  final Schedule schedule;
  const EditScheduleScreen({super.key, required this.schedule});

  @override
  State<EditScheduleScreen> createState() => _EditScheduleScreenState();
}

class _EditScheduleScreenState extends State<EditScheduleScreen> {
  late TextEditingController _nameController;
  late String _selectedIcon;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late String _selectedMode;
  late Set<String> _selectedDays;
  bool _saving = false;
  bool _userEditedName = false;

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

  @override
  void initState() {
    super.initState();
    final s = widget.schedule;
    _nameController = TextEditingController(text: s.name);
    _selectedIcon   = s.icon;
    _selectedMode   = s.mode;
    _selectedDays   = Set<String>.from(s.days);
    _startTime      = _parseTime(s.startTime);
    _endTime        = _parseTime(s.endTime);

    // Track manual name edits
    _nameController.addListener(() {
      final suggested = _iconNames[_selectedIcon] ?? '';
      if (_nameController.text == suggested) {
        _userEditedName = false;
      } else if (_nameController.text.isNotEmpty) {
        _userEditedName = true;
      }
    });
  }

  TimeOfDay _parseTime(String hhmm) {
    final parts = hhmm.split(':');
    return TimeOfDay(
      hour:   int.tryParse(parts[0]) ?? 0,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  String _fmt12(TimeOfDay t) {
    final int h    = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final String m = t.minute.toString().padLeft(2, '0');
    final String p = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $p';
  }

  String _fmt24(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime({required bool isStart}) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: false),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isStart) _startTime = picked;
        else         _endTime   = picked;
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
    final colors = tc(context);
    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.arrow_back_ios_new_rounded,
              color: colors.textPrimary, size: 18),
        ),
        title: Text('Edit Schedule',
            style: GoogleFonts.outfit(
                fontSize: 16, fontWeight: FontWeight.w800,
                color: colors.textPrimary)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: colors.border),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

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
                          color: isSel ? AppColors.accent : colors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSel ? AppColors.accent : colors.border,
                          ),
                          boxShadow: isSel ? [BoxShadow(
                            color: AppColors.accent.withOpacity(0.3),
                            blurRadius: 12, offset: const Offset(0, 4),
                          )] : [],
                        ),
                        child: Icon(ic,
                          color: isSel ? Colors.black : colors.textSecondary,
                          size: 22,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // ── Name ──
              Text('SCHEDULE NAME', style: GoogleFonts.dmMono(fontSize: 10, fontWeight: FontWeight.w500, color: tc(context).textSecondary,letterSpacing: 1)),
              const SizedBox(height: 10),
              TextField(
                controller: _nameController,
                style: GoogleFonts.outfit(
                  color: colors.textPrimary, fontWeight: FontWeight.w600,
                ),
                decoration: const InputDecoration(hintText: 'e.g. Work Hours'),
              ),
              const SizedBox(height: 24),

              // ── Time Range ──
              Text('TIME RANGE', style: GoogleFonts.dmMono(fontSize: 10, fontWeight: FontWeight.w500, color: tc(context).textSecondary,letterSpacing: 1)),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _TimeCard(
                  label: 'Start', time: _fmt12(_startTime),
                  onTap: () => _pickTime(isStart: true),
                )),
                const SizedBox(width: 10),
                Icon(Icons.arrow_forward_rounded, color: colors.textSecondary, size: 16),
                const SizedBox(width: 10),
                Expanded(child: _TimeCard(
                  label: 'End', time: _fmt12(_endTime),
                  onTap: () => _pickTime(isStart: false),
                )),
              ]),

              const SizedBox(height: 10),
              Row(children: [
                _PeriodBadge(
                  label: _startTime.period == DayPeriod.am ? 'AM' : 'PM',
                  icon: _startTime.period == DayPeriod.am
                      ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded,
                  color: _startTime.period == DayPeriod.am
                      ? AppColors.warning : AppColors.accent,
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, color: colors.textSecondary, size: 13),
                const SizedBox(width: 8),
                _PeriodBadge(
                  label: _endTime.period == DayPeriod.am ? 'AM' : 'PM',
                  icon: _endTime.period == DayPeriod.am
                      ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded,
                  color: _endTime.period == DayPeriod.am
                      ? AppColors.warning : AppColors.accent,
                ),
              ]),
              const SizedBox(height: 24),

              // ── Days ──
              Text('REPEAT DAYS', style: GoogleFonts.dmMono(fontSize: 10, fontWeight: FontWeight.w500, color: tc(context).textSecondary,letterSpacing: 1)),
              const SizedBox(height: 10),
              Row(
                children: _days.map((day) {
                  final bool isOn  = _selectedDays.contains(day);
                  final bool isLast = day == _days.last;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        isOn ? _selectedDays.remove(day) : _selectedDays.add(day);
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: EdgeInsets.only(right: isLast ? 0 : 6),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isOn ? AppColors.accent : colors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isOn ? AppColors.accent : colors.border,
                          ),
                        ),
                        child: Center(
                          child: Text(day.substring(0, 1),
                              style: GoogleFonts.outfit(
                                color: isOn ? Colors.black : colors.textSecondary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              )),
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
                  final bool isOn   = mode == _selectedMode;
                  final bool isLast = mode == _modes.last;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedMode = mode),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: EdgeInsets.only(right: isLast ? 0 : 8),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: isOn ? AppColors.accent : colors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isOn ? AppColors.accent : colors.border,
                          ),
                          boxShadow: isOn ? [BoxShadow(
                            color: AppColors.accent.withOpacity(0.25),
                            blurRadius: 12, offset: const Offset(0, 4),
                          )] : [],
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
                                color: isOn ? Colors.black : colors.textSecondary,
                                size: 15,
                              ),
                              const SizedBox(width: 5),
                              Text(mode,
                                  style: GoogleFonts.outfit(
                                    color: isOn ? Colors.black : colors.textSecondary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  )),
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
                onTap: _saveChanges,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(
                      color: AppColors.accent.withOpacity(0.3),
                      blurRadius: 20, offset: const Offset(0, 8),
                    )],
                  ),
                  child: Center(
                    child: _saving
                        ? Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.check_rounded,
                          color: Colors.black, size: 18),
                      const SizedBox(width: 8),
                      Text('Saved!',
                          style: GoogleFonts.outfit(
                              color: Colors.black,
                              fontWeight: FontWeight.w800,
                              fontSize: 15)),
                    ])
                        : Text('Save Changes',
                        style: GoogleFonts.outfit(
                            color: Colors.black,
                            fontWeight: FontWeight.w800,
                            fontSize: 15)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _saveChanges() async {
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text('Please select at least one day.',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 13)),
      ));
      return;
    }
    final updated = Schedule(
      id:        widget.schedule.id,
      name:      _nameController.text.trim().isEmpty
          ? widget.schedule.name
          : _nameController.text.trim(),
      icon:      _selectedIcon,
      startTime: _fmt24(_startTime),
      endTime:   _fmt24(_endTime),
      days:      _selectedDays.toList(),
      mode:      _selectedMode,
      isEnabled: widget.schedule.isEnabled,
    );
    await context.read<AppProvider>().updateSchedule(updated);
    setState(() => _saving = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) Navigator.pop(context);
    });
  }
}

// ── Time Card ──
class _TimeCard extends StatelessWidget {
  final String label, time;
  final VoidCallback onTap;
  const _TimeCard({required this.label, required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = tc(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: GoogleFonts.dmMono(
                  color: colors.textSecondary, fontSize: 9, letterSpacing: 1)),
          const SizedBox(height: 6),
          Text(time,
              style: GoogleFonts.dmMono(
                  fontSize: 20, fontWeight: FontWeight.w500,
                  color: colors.textPrimary)),
        ]),
      ),
    );
  }
}

// ── Period Badge ──
class _PeriodBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _PeriodBadge({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.dmMono(
                color: color, fontSize: 10, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}