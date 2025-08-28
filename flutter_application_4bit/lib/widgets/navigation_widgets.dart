import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const BottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          NavigationItem(
            icon: Icons.timer,
            label: 'Pomodoro',
            isSelected: selectedIndex == 0,
            onTap: () => onItemSelected(0),
          ),
          NavigationItem(
            icon: Icons.apps,
            label: 'Manage',
            isSelected: selectedIndex == 1,
            onTap: () => onItemSelected(1),
          ),
          NavigationItem(
            icon: Icons.calendar_today,
            label: 'Calendar',
            isSelected: selectedIndex == 2,
            onTap: () => onItemSelected(2),
          ),
          NavigationItem(
            icon: Icons.trending_up,
            label: 'Report',
            isSelected: selectedIndex == 3,
            onTap: () => onItemSelected(3),
          ),
          NavigationItem(
            icon: Icons.settings,
            label: 'Settings',
            isSelected: selectedIndex == 4,
            onTap: () => onItemSelected(4),
          ),
        ],
      ),
    );
  }
}

class NavigationItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

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
    );
  }
}