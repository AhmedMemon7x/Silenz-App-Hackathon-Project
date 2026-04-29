import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../providers/app_provider.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final current  = provider.currentNavIndex;
    final colors   = tc(context);

    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          _NavItem(
            icon:       Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'Home',
            index: 0, current: current,
            onTap: () => provider.setNavIndex(0),
          ),
          _NavItem(
            icon:       Icons.calendar_today_outlined,
            activeIcon: Icons.calendar_today_rounded,
            label: 'Schedules',
            index: 1, current: current,
            onTap: () => provider.setNavIndex(1),
          ),

          // ── FAB Centre ──
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: () => provider.setNavIndex(2),
                child: Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.black, size: 26),
                ),
              ),
            ),
          ),

          // _NavItem(
          //   icon:       Icons.bar_chart_outlined,
          //   activeIcon: Icons.bar_chart_rounded,
          //   label: 'Stats',
          //   index: 3, current: current,
          //   onTap: () => provider.setNavIndex(3),
          // ),
          _NavItem(
            icon:       Icons.location_on_outlined,
            activeIcon: Icons.location_on_rounded,
            label: 'Zones',
            index: 3, current: current,
            onTap: () => provider.setNavIndex(3),
          ),
          _NavItem(
            icon:       Icons.settings_outlined,
            activeIcon: Icons.settings_rounded,
            label: 'Settings',
            index: 4, current: current,
            onTap: () => provider.setNavIndex(4),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final int index, current;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == current;
    final colors   = tc(context);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppColors.accent : colors.textSecondary,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.dmMono(
                color: isActive ? AppColors.accent : colors.textSecondary,
                fontSize: 9,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isActive ? 16 : 0,
              height: 2,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}