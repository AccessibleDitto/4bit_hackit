import 'package:flutter/material.dart';
import '../models/timer_models.dart';
import '../tasks_updated.dart' as tasks_data;
import '../pomodoro_preferences.dart';

class TimerUtils {
  static String formatTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int remainingSeconds = seconds % 60;
    
    if (hours > 0) {
      return '${hours}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    }
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
    
    return mainTasks.asMap().map((index, taskData) {
      try {
        return MapEntry(index, Task(
          title: taskData.title,
          color: colorOrder[index % colorOrder.length],
          estimatedTime: taskData.estimatedTime,
          focusMinutes: PomodoroSettings.instance.pomodoroLength,
        ));
      } catch (e) {
        // If error, create a default task with 1 hour estimate
        return MapEntry(index, Task(
          title: taskData.title,
          color: colorOrder[index % colorOrder.length],
          estimatedTime: 1.0,
          focusMinutes: PomodoroSettings.instance.pomodoroLength,
        ));
      }
    }).values.toList();
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