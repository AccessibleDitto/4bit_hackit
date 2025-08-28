import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/timer_models.dart';
import '../utils/timer_utils.dart';

class TimerCircle extends StatelessWidget {
  final int currentSeconds;
  final TimerState timerState;
  final bool isBreakTime;
  final int focusSeconds;
  final int breakSeconds;
  final Animation<double> progressAnimation;

  const TimerCircle({
    super.key,
    required this.currentSeconds,
    required this.timerState,
    required this.isBreakTime,
    required this.focusSeconds,
    required this.breakSeconds,
    required this.progressAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    final maxCircleSize = screenWidth * 0.7;
    final availableHeight = screenHeight * 0.4;
    final circleSize = [maxCircleSize, availableHeight, 300.0].reduce((a, b) => a < b ? a : b);
    
    final timerFontSize = circleSize * 0.16;
    final subtextFontSize = circleSize * 0.053;
    
    return SizedBox(
      width: 300,
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Circle
          SizedBox(
            width: 300,
            height: 300,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF27272A),
                  width: 8,
                ),
              ),
            ),
          ),
          // Progress Circle
          SizedBox(
            width: 300,
            height: 300,
            child: AnimatedBuilder(
              animation: progressAnimation,
              builder: (context, child) {
                return CircularProgressIndicator(
                  value: progressAnimation.value,
                  strokeWidth: 16,
                  backgroundColor: const Color(0xFF27272A),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    TimerUtils.getProgressColor(isBreakTime),
                  ),
                  strokeCap: StrokeCap.round,
                );
              },
            ),
          ),
          // Timer Content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                TimerUtils.formatTime(currentSeconds),
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: timerFontSize,
                  fontWeight: FontWeight.w300,
                  letterSpacing: -1,
                ),
              ),
              SizedBox(height: circleSize * 0.027),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: circleSize * 0.1),
                child: Text(
                  _getSubtext(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: const Color(0xFFA1A1AA),
                    fontSize: subtextFontSize,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getSubtext() {
    switch (timerState) {
      case TimerState.idle:
        return 'Ready to focus';
      case TimerState.focusRunning:
      case TimerState.focusPaused:
        return 'Focus Time';
      case TimerState.breakIdle:
      case TimerState.breakRunning:
        return 'Break Time - Take a rest';
      case TimerState.completed:
        return 'All sessions completed!';
    }
  }
}

class SessionIndicator extends StatelessWidget {
  final int currentSession;
  final int totalSessions;

  const SessionIndicator({
    super.key,
    required this.currentSession,
    required this.totalSessions,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final circleSize = screenWidth * 0.7;
    
    return Container(
      margin: EdgeInsets.only(bottom: circleSize * 0.133),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalSessions, (index) {
          final dotSize = circleSize * 0.04;
          final activeDotSize = circleSize * 0.048;
          
          return Container(
            margin: EdgeInsets.symmetric(horizontal: circleSize * 0.013),
            width: index < currentSession ? activeDotSize : dotSize,
            height: index < currentSession ? activeDotSize : dotSize,
            decoration: BoxDecoration(
              color: index < currentSession 
                ? const Color(0xFF9333EA)
                : const Color(0xFF9333EA).withOpacity(0.3),
              shape: BoxShape.circle,
            ),
          );
        }),
      ),
    );
  }
}

class SessionStat extends StatelessWidget {
  final String label;
  final String value;

  const SessionStat({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            color: const Color(0xFF9333EA),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            color: const Color(0xFFA1A1AA),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}