import 'package:flutter/material.dart';
import '../models/timer_models.dart';

class TimerUtils {
  static String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  static double calculateProgress({
    required int currentSeconds,
    required int totalSeconds,
  }) {
    if (totalSeconds == 0) return 0.0;
    return (totalSeconds - currentSeconds) / totalSeconds;
  }

  static Color getProgressColor(bool isBreakTime) {
    return isBreakTime ? const Color(0xFF10B981) : const Color(0xFF9333EA);
  }

  static String getTimerSubtext(TimerState state, int currentSession, int totalSessions) {
    switch (state) {
      case TimerState.idle:
        return currentSession > 0 ? 'Session $currentSession of $totalSessions' : 'Ready to focus';
      case TimerState.focusRunning:
      case TimerState.focusPaused:
        return 'Focus Time - Session $currentSession of $totalSessions';
      case TimerState.breakIdle:
      case TimerState.breakRunning:
        return 'Break Time - Take a rest';
      case TimerState.completed:
        return 'All sessions completed!';
    }
  }

  static List<Task> getDefaultTasks() {
    return [
      const Task(
        title: 'Design User Experience (UX)',
        sessions: 7,
        color: Color(0xFF9333EA),
      ),
      const Task(
        title: 'Design User Interface (UI)',
        sessions: 6,
        color: Color(0xFF10B981),
      ),
      const Task(
        title: 'Create a Design Wireframe',
        sessions: 4,
        color: Color(0xFF3B82F6),
      ),
      const Task(
        title: 'Write Documentation',
        sessions: 3,
        color: Color(0xFFEF4444),
      ),
      const Task(
        title: 'Code Review Session',
        sessions: 2,
        color: Color(0xFFF59E0B),
      ),
    ];
  }

  static SessionStats calculateSessionStats(int totalSessions, int completedSessions, int focusMinutes) {
    return SessionStats(
      completedSessions: completedSessions,
      totalSessions: totalSessions,
      focusTimeMinutes: totalSessions * focusMinutes,
      totalBreaks: totalSessions - 1,
    );
  }
}