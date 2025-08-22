import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class ModeSelectionBar extends StatelessWidget {
  final bool isStrictMode;
  final bool isTimerMode;
  final bool isWhiteNoise;
  final VoidCallback onStrictModePressed;
  final VoidCallback onTimerModePressed;
  final VoidCallback onWhiteNoisePressed;

  const ModeSelectionBar({
    super.key,
    required this.isStrictMode,
    required this.isTimerMode,
    required this.isWhiteNoise,
    required this.onStrictModePressed,
    required this.onTimerModePressed,
    required this.onWhiteNoisePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B).withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF9333EA).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          ModeOption(
            icon: Icons.block,
            label: 'Strict Mode',
            isSelected: isStrictMode,
            color: const Color(0xFFEF4444),
            onTap: onStrictModePressed,
          ),
          ModeOption(
            icon: Icons.timer,
            label: 'Timer Mode',
            isSelected: isTimerMode,
            color: const Color(0xFF10B981),
            onTap: onTimerModePressed,
          ),
          ModeOption(
            icon: Icons.music_note,
            label: 'White Noise',
            isSelected: isWhiteNoise,
            color: const Color(0xFF3B82F6),
            onTap: onWhiteNoisePressed,
          ),
        ],
      ),
    );
  }
}

class ModeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const ModeOption({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTap();
        HapticFeedback.selectionClick();
      },
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color,
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}