import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../models/schedule_model.dart';
import '../providers/user_provider.dart';
import '../providers/app_provider.dart';
import '../services/auth_service.dart';
import 'package:http/http.dart' as http;

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  static const String _baseUrl =  'https://autosilenc-backend-production.up.railway.app/api';

  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _weeklyData = [];
  double _totalHours     = 0;
  double _avgHoursPerDay = 0;
  int    _totalTriggers  = 0;

  double _totalHoursMonth = 0;
  int    _activeDays      = 0;
  String _mostUsedMode    = 'Silent';
  Map<String, dynamic> _modeBreakdown = {'Silent': 0, 'Vibrate': 0, 'DND': 0};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() { _isLoading = true; _error = null; });
    final isGuest = await AuthService.isGuest();
    if (isGuest) { _loadLocalStats(); return; }

    try {
      final token = await AuthService.getToken();
      final headers = {
        'Content-Type':  'application/json',
        'Authorization': 'Bearer $token',
      };
      final results = await Future.wait([
        http.get(Uri.parse('$_baseUrl/stats/weekly'),  headers: headers),
        http.get(Uri.parse('$_baseUrl/stats/summary'), headers: headers),
      ]);
      final weekly  = jsonDecode(results[0].body);
      final summary = jsonDecode(results[1].body);
      if (!mounted) return;
      if (weekly['success'] == true && summary['success'] == true) {
        final wd = weekly['data'];
        final sd = summary['data'];
        setState(() {
          _weeklyData     = List<Map<String, dynamic>>.from(wd['weeklyData']);
          _totalHours     = (wd['totalHours'] as num).toDouble();
          _avgHoursPerDay = (wd['avgHoursPerDay'] as num).toDouble();
          _totalTriggers  = wd['totalTriggers'] as int;
          _totalHoursMonth = (sd['totalHoursThisMonth'] as num).toDouble();
          _activeDays      = sd['activeDaysThisMonth'] as int;
          _mostUsedMode    = sd['mostUsedMode'] as String;
          _modeBreakdown   = Map<String, dynamic>.from(sd['modeBreakdown']);
          _isLoading       = false;
        });
      } else {
        _loadLocalStats();
      }
    } catch (e) {
      _loadLocalStats();
    }
  }

  void _loadLocalStats() {
    final schedules = context.read<AppProvider>().schedules;
    final enabled   = schedules.where((s) => s.isEnabled).toList();
    final days      = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    double _scheduleHours(Schedule s) {
      try {
        final sp    = s.startTime.split(':');
        final ep    = s.endTime.split(':');
        final start = int.parse(sp[0]) * 60 + int.parse(sp[1]);
        final end   = int.parse(ep[0]) * 60 + int.parse(ep[1]);
        final mins  = end > start ? end - start : (1440 - start + end);
        return mins / 60.0;
      } catch (_) { return 0; }
    }

    // Build per-day hours using actual days field
    _weeklyData = days.map((day) {
      final hoursForDay = enabled
          .where((s) => s.days.contains(day))
          .fold(0.0, (sum, s) => sum + _scheduleHours(s));
      return {
        'day': day,
        'silencedHours': double.parse(hoursForDay.toStringAsFixed(1)),
        'silencedMinutes': (hoursForDay * 60).toInt(),
      };
    }).toList();

    // Mode breakdown
    int silent = 0, vibrate = 0, dnd = 0;
    for (final s in enabled) {
      final mins = (_scheduleHours(s) * 60).toInt() * s.days.length;
      final mode = s.mode.toLowerCase();
      if (mode == 'silent')       silent  += mins;
      else if (mode == 'vibrate') vibrate += mins;
      else if (mode == 'dnd')     dnd     += mins;
    }

    final totalMins = enabled.fold(
        0.0, (sum, s) => sum + _scheduleHours(s) * s.days.length);
    final activeDaySet = enabled.expand((s) => s.days).toSet();
    final modeMap  = {'Silent': silent, 'Vibrate': vibrate, 'DND': dnd};
    final mostUsed = modeMap.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    final weeklyHours = _weeklyData.fold(
        0.0, (sum, d) => sum + (d['silencedHours'] as num).toDouble());
    _totalHours      = double.parse(weeklyHours.toStringAsFixed(1));
    _totalHoursMonth = double.parse((weeklyHours * 4).toStringAsFixed(1));    final totalDaysInWeek = 7;
    _avgHoursPerDay = double.parse((_totalHours / totalDaysInWeek).toStringAsFixed(1));
    _totalTriggers   = enabled.fold(0, (sum, s) => sum + s.days.length);
    _activeDays      = activeDaySet.length;
    _mostUsedMode    = enabled.isEmpty ? 'None' : mostUsed;
    _modeBreakdown   = {'Silent': silent, 'Vibrate': vibrate, 'DND': dnd};

    setState(() => _isLoading = false);
  }
  double get _maxHours {
    if (_weeklyData.isEmpty) return 8;
    final max = _weeklyData
        .map((d) => (d['silencedHours'] as num).toDouble())
        .reduce((a, b) => a > b ? a : b);
    return max < 1 ? 8 : (max * 1.3).ceilToDouble();
  }

  int get _modeTotal =>
      (_modeBreakdown['Silent'] as num? ?? 0).toInt() +
          (_modeBreakdown['Vibrate'] as num? ?? 0).toInt() +
          (_modeBreakdown['DND'] as num? ?? 0).toInt();

  double _modePct(String mode) {
    if (_modeTotal == 0) return 0;
    return (_modeBreakdown[mode] as num? ?? 0) / _modeTotal;
  }

  @override
  Widget build(BuildContext context) {
    final colors     = tc(context);
    final isLoggedIn = context.watch<UserProvider>().isLoggedIn;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadStats,
        color: AppColors.accent,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // ── Header ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('STATISTICS',
                          style: GoogleFonts.dmMono(
                            color: colors.textSecondary,
                            fontSize: 11,
                            letterSpacing: 3,
                          )),
                      const SizedBox(height: 4),
                      Text('Your silence overview',
                          style: GoogleFonts.outfit(
                            color: colors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          )),
                    ],
                  ),
                  GestureDetector(
                    onTap: _loadStats,
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.border),
                      ),
                      child: Icon(Icons.refresh_rounded,
                          color: colors.textSecondary, size: 18),
                    ),
                  ),
                ],
              ),

              // ── Guest notice ──
              if (!isLoggedIn) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.info_outline, color: AppColors.warning, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Sign in to save and sync your stats.',
                          style: GoogleFonts.outfit(
                              color: AppColors.warning, fontSize: 12)),
                    ),
                  ]),
                ),
              ],

              const SizedBox(height: 24),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: CircularProgressIndicator(
                        color: AppColors.accent, strokeWidth: 2),
                  ),
                )
              else ...[

                // ── Summary Cards ──
                Row(children: [
                  Expanded(child: _SummaryCard(
                    label: 'This Week',
                    value: '${_totalHours}h',
                    sub: 'total silenced',
                    icon: Icons.access_time_rounded,
                    color: AppColors.accent,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _SummaryCard(
                    label: 'Daily Avg',
                    value: '${_avgHoursPerDay}h',
                    sub: 'per day',
                    icon: Icons.today_rounded,
                    color: AppColors.accent,
                  )),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _SummaryCard(
                    label: 'This Month',
                    value: '${_totalHoursMonth}h',
                    sub: 'total silenced',
                    icon: Icons.calendar_month_rounded,
                    color: const Color(0xFF8B5CF6),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _SummaryCard(
                    label: 'Active Days',
                    value: '$_activeDays',
                    sub: 'days this month',
                    icon: Icons.local_fire_department_rounded,
                    color: AppColors.warning,
                  )),
                ]),

                const SizedBox(height: 28),

                // ── Weekly Bar Chart ──
                Text('WEEKLY OVERVIEW',
                    style: GoogleFonts.dmMono(
                        color: colors.textSecondary, fontSize: 10, letterSpacing: 2)),
                const SizedBox(height: 4),
                Text('Hours silenced per day',
                    style: GoogleFonts.outfit(
                        color: colors.textSecondary, fontSize: 13)),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.fromLTRB(8, 20, 16, 12),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colors.border),
                  ),
                  child: SizedBox(
                    height: 200,
                    child: _weeklyData.isEmpty
                        ? Center(child: Text('No data yet',
                        style: GoogleFonts.outfit(
                            color: colors.textSecondary, fontSize: 13)))
                        : BarChart(BarChartData(
                      maxY: _maxHours,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: _maxHours / 4,
                        getDrawingHorizontalLine: (_) =>
                            FlLine(color: colors.border, strokeWidth: 1),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            interval: _maxHours / 4,
                            getTitlesWidget: (v, _) => Text('${v.toInt()}h',
                                style: GoogleFonts.dmMono(
                                    fontSize: 9, color: colors.textSecondary)),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, _) {
                              final i = v.toInt();
                              if (i >= _weeklyData.length) return const SizedBox();
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(_weeklyData[i]['day'] ?? '',
                                    style: GoogleFonts.dmMono(
                                        fontSize: 9,
                                        color: colors.textSecondary,
                                        fontWeight: FontWeight.w600)),
                              );
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      barGroups: List.generate(_weeklyData.length, (i) {
                        final h = (_weeklyData[i]['silencedHours'] as num).toDouble();
                        return BarChartGroupData(x: i, barRods: [
                          BarChartRodData(
                            toY: h,
                            color: h > 0 ? AppColors.accent : colors.border,
                            width: 22,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ]);
                      }),
                    )),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Mode Breakdown ──
                Text('MODE BREAKDOWN',
                    style: GoogleFonts.dmMono(
                        color: colors.textSecondary, fontSize: 10, letterSpacing: 2)),
                const SizedBox(height: 4),
                Text('How you silence most',
                    style: GoogleFonts.outfit(
                        color: colors.textSecondary, fontSize: 13)),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colors.border),
                  ),
                  child: Column(children: [
                    _ModeBar(
                      icon: Icons.volume_off_rounded,
                      label: 'Silent',
                      pct: _modePct('Silent'),
                      color: AppColors.accent,
                      minutes: (_modeBreakdown['Silent'] as num? ?? 0).toInt(),
                    ),
                    const SizedBox(height: 16),
                    _ModeBar(
                      icon: Icons.vibration_rounded,
                      label: 'Vibrate',
                      pct: _modePct('Vibrate'),
                      color: AppColors.warning,
                      minutes: (_modeBreakdown['Vibrate'] as num? ?? 0).toInt(),
                    ),
                    const SizedBox(height: 16),
                    _ModeBar(
                      icon: Icons.do_not_disturb_on_rounded,
                      label: 'DND',
                      pct: _modePct('DND'),
                      color: AppColors.danger,
                      minutes: (_modeBreakdown['DND'] as num? ?? 0).toInt(),
                    ),
                  ]),
                ),

                const SizedBox(height: 28),

                // ── Quick Facts ──
                Text('QUICK FACTS',
                    style: GoogleFonts.dmMono(
                        color: colors.textSecondary, fontSize: 10, letterSpacing: 2)),
                const SizedBox(height: 16),

                _FactCard(
                  icon: Icons.emoji_events_rounded,
                  title: 'Most Used Mode',
                  value: _mostUsedMode,
                  color: AppColors.warning,
                ),
                const SizedBox(height: 10),
                _FactCard(
                  icon: Icons.repeat_rounded,
                  title: 'Times Triggered This Week',
                  value: '$_totalTriggers times',
                  color: AppColors.accent,
                ),
                const SizedBox(height: 10),
                _FactCard(
                  icon: Icons.calendar_today_rounded,
                  title: 'Active Days This Month',
                  value: '$_activeDays / 30 days',
                  color: const Color(0xFF8B5CF6),
                ),

                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Summary Card ──
class _SummaryCard extends StatelessWidget {
  final String label, value, sub;
  final IconData icon;
  final Color color;
  const _SummaryCard({required this.label, required this.value,
    required this.sub, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final colors = tc(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(value,
              style: GoogleFonts.outfit(
                  fontSize: 22, fontWeight: FontWeight.w800,
                  color: colors.textPrimary)),
          Text(label,
              style: GoogleFonts.outfit(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: colors.textSecondary)),
          Text(sub,
              style: GoogleFonts.dmMono(
                  fontSize: 9, color: colors.textSecondary)),
        ],
      ),
    );
  }
}

// ── Mode Bar ──
class _ModeBar extends StatelessWidget {
  final IconData icon;
  final String label;
  final double pct;
  final Color color;
  final int minutes;
  const _ModeBar({required this.icon, required this.label,
    required this.pct, required this.color, required this.minutes});

  @override
  Widget build(BuildContext context) {
    final colors = tc(context);
    final hrs = (minutes / 60).toStringAsFixed(1);
    return Column(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(label,
                style: GoogleFonts.outfit(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: colors.textPrimary)),
          ]),
          Text('${(pct * 100).toStringAsFixed(0)}%  ·  ${hrs}h',
              style: GoogleFonts.dmMono(
                  fontSize: 10, color: colors.textSecondary)),
        ],
      ),
      const SizedBox(height: 8),
      Stack(children: [
        Container(
          height: 6, width: double.infinity,
          decoration: BoxDecoration(
            color: colors.surface2,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        FractionallySizedBox(
          widthFactor: pct.clamp(0.0, 1.0),
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
      ]),
    ]);
  }
}

// ── Fact Card ──
class _FactCard extends StatelessWidget {
  final IconData icon;
  final String title, value;
  final Color color;
  const _FactCard({required this.icon, required this.title,
    required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final colors = tc(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.dmMono(
                      fontSize: 9, color: colors.textSecondary,
                      letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Text(value,
                  style: GoogleFonts.outfit(
                      fontSize: 15, fontWeight: FontWeight.w700,
                      color: colors.textPrimary)),
            ],
          ),
        ),
        Container(
          width: 3, height: 36,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ]),
    );
  }
}