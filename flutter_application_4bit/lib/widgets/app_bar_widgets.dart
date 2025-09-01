import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/timer_models.dart';

class TimerAppBar extends StatelessWidget {
  final String selectedTask;
  final TimerState timerState;
  final VoidCallback onBackPressed;
  final VoidCallback onResetToHome;
  final VoidCallback onSettingsPressed;

  const TimerAppBar({
    super.key,
    required this.selectedTask,
    required this.timerState,
    required this.onBackPressed,
    required this.onResetToHome,
    required this.onSettingsPressed,
  });

  @override
  Widget build(BuildContext context) {
    bool shouldShowTaskPill = timerState != TimerState.idle && 
                              timerState != TimerState.completed;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF9333EA), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              onBackPressed();
              HapticFeedback.lightImpact();
            },
            child: const Icon(
              Icons.timer,
              color: Colors.white,
              size: 24,
            ),
          ),
          Expanded(
            child: shouldShowTaskPill ? Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF18181B).withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      selectedTask,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: onResetToHome,
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ) : Center(
              child: Text(
                'Timer Mode',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              onSettingsPressed();
              HapticFeedback.lightImpact();
            },
            child: const Icon(
              Icons.notifications_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}