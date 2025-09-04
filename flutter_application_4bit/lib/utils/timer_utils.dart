import 'package:flutter/material.dart';
import '../models/timer_models.dart';
import '../tasks_updated.dart' as tasks_data;

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
    const colorOrder = [
      Color(0xFF9333EA),
      Color(0xFF10B981),
      Color(0xFF3B82F6),
      Color(0xFFEF4444),
      Color(0xFFF59E0B), 
    ];

    final mainTasks = tasks_data.getTasksList();
    List<Task> defaultTasks = [];
    for (int i = 0; i < mainTasks.length; i++) {
      final t = mainTasks[i];
      // Use estimatedTime as sessions if available, otherwise default to 1
      int sessions = (t.estimatedTime > 0) ? t.estimatedTime.round() : 1;
      defaultTasks.add(Task(
        title: t.title,
        sessions: sessions,
        color: colorOrder[i % colorOrder.length],
      ));
    }
    return defaultTasks;
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