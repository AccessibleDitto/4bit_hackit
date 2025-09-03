import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../homepage.dart';
import '../calendar_page.dart';
import '../tasks_updated.dart';
import '../settings.dart';
import '../report.dart';

class BottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final bool isStrictMode;

  const BottomNavigation({
    super.key,
    required this.selectedIndex,
    this.isStrictMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            NavigationItem(
              icon: Icons.timer,
              label: 'Pomodoro',
              isSelected: selectedIndex == 0,
              onTap: isStrictMode
                  ? null
                  : () {
                      if (selectedIndex != 0) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const TimerModePage()),
                        );
                      }
                    },
            ),
            NavigationItem(
              icon: Icons.apps,
              label: 'Manage',
              isSelected: selectedIndex == 1,
              onTap: isStrictMode
                  ? null
                  : () {
                      if (selectedIndex != 1) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => TasksPage()),
                        );
                      }
                    },
            ),
            NavigationItem(
              icon: Icons.calendar_today,
              label: 'Calendar',
              isSelected: selectedIndex == 2,
              onTap: isStrictMode
                  ? null
                  : () {
                      if (selectedIndex != 2) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const CalendarPage()),
                        );
                      }
                    },
            ),
            NavigationItem(
              icon: Icons.trending_up,
              label: 'Report',
              isSelected: selectedIndex == 3,
              onTap: isStrictMode
                  ? null
                  : () {
                      if (selectedIndex != 3) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => ReportScreen()),
                        );
                      }
                    },
            ),
            NavigationItem(
              icon: Icons.settings,
              label: 'Settings',
              isSelected: selectedIndex == 4,
              onTap: isStrictMode
                  ? null
                  : () {
                      if (selectedIndex != 4) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => SettingsScreen()),
                        );
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }
}

class NavigationItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const NavigationItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: onTap == null ? 0.4 : 1.0,
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFF9333EA) : const Color(0xFFA1A1AA),
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: isSelected ? const Color(0xFF9333EA) : const Color(0xFFA1A1AA),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ));
  }
}