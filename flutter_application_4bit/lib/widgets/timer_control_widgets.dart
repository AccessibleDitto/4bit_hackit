import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/timer_models.dart';

class TimerActionButtons extends StatelessWidget {
  final TimerState timerState;
  final String selectedTask;
  final VoidCallback? onStartFocus;
  final VoidCallback? onPause;
  final VoidCallback? onContinue;
  final VoidCallback? onStartBreak;
  final VoidCallback? onSkipBreak;
  final VoidCallback? onReset;

  const TimerActionButtons({
    super.key,
    required this.timerState,
    required this.selectedTask,
    this.onStartFocus,
    this.onPause,
    this.onContinue,
    this.onStartBreak,
    this.onSkipBreak,
    this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonWidth = (screenWidth * 0.6).clamp(200.0, 280.0);
    final smallButtonWidth = (screenWidth * 0.35).clamp(120.0, 180.0);
    const buttonHeight = 56.0;
    final fontSize = (screenWidth * 0.04).clamp(14.0, 18.0);
    
    switch (timerState) {
      case TimerState.idle:
        return SizedBox(
          width: buttonWidth,
          height: buttonHeight,
          child: ElevatedButton(
            onPressed: selectedTask != 'Select Task' ? onStartFocus : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: selectedTask != 'Select Task' 
                ? const Color(0xFF9333EA) 
                : const Color(0xFF27272A),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              disabledBackgroundColor: const Color(0xFF27272A),
              disabledForegroundColor: const Color(0xFF71717A),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_arrow, size: fontSize + 4),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Start Focus Session',
                    style: GoogleFonts.inter(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
        
      case TimerState.focusRunning:
        return SizedBox(
          width: buttonWidth,
          height: buttonHeight,
          child: ElevatedButton(
            onPressed: onPause,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: const Color(0xFF9333EA),
              elevation: 0,
              side: const BorderSide(color: Color(0xFF9333EA), width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.pause, size: fontSize + 4),
                const SizedBox(width: 8),
                Text(
                  'Pause',
                  style: GoogleFonts.inter(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
        
      case TimerState.focusPaused:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: smallButtonWidth,
              height: buttonHeight,
              child: OutlinedButton(
                onPressed: onReset,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: const Color(0xFFEF4444),
                  side: const BorderSide(color: Color(0xFFEF4444), width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Stop',
                  style: GoogleFonts.inter(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: smallButtonWidth,
              height: buttonHeight,
              child: ElevatedButton(
                onPressed: onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9333EA),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Continue',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1, 
                  style: GoogleFonts.inter(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
        
      case TimerState.breakIdle:
        return SizedBox(
          width: buttonWidth,
          height: buttonHeight,
          child: ElevatedButton(
            onPressed: onStartBreak,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.coffee, size: fontSize + 4),
                const SizedBox(width: 8),
                Text(
                  'Start Break',
                  style: GoogleFonts.inter(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
        
      case TimerState.breakRunning:
        return SizedBox(
          width: buttonWidth,
          height: buttonHeight,
          child: OutlinedButton(
            onPressed: onSkipBreak,
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: const Color(0xFF10B981),
              side: const BorderSide(color: Color(0xFF10B981), width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Skip Break',
              style: GoogleFonts.inter(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
        
      case TimerState.completed:
        return const SizedBox.shrink();
    }
  }
}