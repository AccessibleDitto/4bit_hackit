import 'package:flutter/material.dart';

enum TimerState { idle, focusRunning, focusPaused, breakIdle, breakRunning, completed }

class Task {
  final String title;
  final Color color;
  final double estimatedTime; // in hours
  final int focusMinutes;

  const Task({
    required this.title,
    required this.color,
    double? estimatedTime,  // Make it nullable
    this.focusMinutes = 25,
  }) : this.estimatedTime = estimatedTime ?? 1.0;  // Default to 1 hour if null

  int get sessions {
    // Calculate number of sessions based on estimated time
    // If estimatedTime is 0 or negative, return 1 session as minimum
    if (estimatedTime <= 0) return 1;
    return (estimatedTime * 60 / focusMinutes).ceil();
  }
}

class TimerConfiguration {
  final int focusMinutes;
  final int breakMinutes;
  final int totalSessions;
  final bool isStrictMode;
  final bool isTimerMode;
  final bool isAmbientMusic;

  const TimerConfiguration({
    this.focusMinutes = 25,
    this.breakMinutes = 5,
    this.totalSessions = 4,
    this.isStrictMode = false,
    this.isTimerMode = true,
    this.isAmbientMusic = false,
  });

  TimerConfiguration copyWith({
    int? focusMinutes,
    int? breakMinutes,
    int? totalSessions,
    bool? isStrictMode,
    bool? isTimerMode,
    bool? isAmbientMusic,
  }) {
    return TimerConfiguration(
      focusMinutes: focusMinutes ?? this.focusMinutes,
      breakMinutes: breakMinutes ?? this.breakMinutes,
      totalSessions: totalSessions ?? this.totalSessions,
      isStrictMode: isStrictMode ?? this.isStrictMode,
      isTimerMode: isTimerMode ?? this.isTimerMode,
      isAmbientMusic: isAmbientMusic ?? this.isAmbientMusic,
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