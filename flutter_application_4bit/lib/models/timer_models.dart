import 'package:flutter/material.dart';

enum TimerState { idle, focusRunning, focusPaused, breakIdle, breakRunning, completed }

class Task {
  final String title;
  final int sessions;
  final Color color;

  const Task({
    required this.title,
    required this.sessions,
    required this.color,
  });
}

class TimerConfiguration {
  final int focusMinutes;
  final int breakMinutes;
  final int totalSessions;
  final bool isStrictMode;
  final bool isTimerMode;
  final bool isWhiteNoise;

  const TimerConfiguration({
    this.focusMinutes = 25,
    this.breakMinutes = 5,
    this.totalSessions = 4,
    this.isStrictMode = false,
    this.isTimerMode = true,
    this.isWhiteNoise = false,
  });

  TimerConfiguration copyWith({
    int? focusMinutes,
    int? breakMinutes,
    int? totalSessions,
    bool? isStrictMode,
    bool? isTimerMode,
    bool? isWhiteNoise,
  }) {
    return TimerConfiguration(
      focusMinutes: focusMinutes ?? this.focusMinutes,
      breakMinutes: breakMinutes ?? this.breakMinutes,
      totalSessions: totalSessions ?? this.totalSessions,
      isStrictMode: isStrictMode ?? this.isStrictMode,
      isTimerMode: isTimerMode ?? this.isTimerMode,
      isWhiteNoise: isWhiteNoise ?? this.isWhiteNoise,
    );
  }
}

class SessionStats {
  final int completedSessions;
  final int totalSessions;
  final int focusTimeMinutes;
  final int totalBreaks;

  const SessionStats({
    required this.completedSessions,
    required this.totalSessions,
    required this.focusTimeMinutes,
    required this.totalBreaks,
  });
}