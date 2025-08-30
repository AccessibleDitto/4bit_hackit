// User performance statistics and gamification system
import 'package:flutter/material.dart';
import 'task_manager.dart';
import 'firebase_service.dart';

class UserStats {
  static final UserStats _instance = UserStats._internal();
  factory UserStats() => _instance;
  UserStats._internal();

  // Statistics
  int _pomodorosCompleted = 0;
  int _totalFocusTimeMinutes = 0;
  int _streakDays = 0;
  DateTime? _lastActiveDate;
  List<String> _earnedBadges = [];
  List<Achievement> _recentAchievements = [];

  final TaskManager _taskManager = TaskManager();
  final FirebaseService _firebaseService = FirebaseService();

  // Getters
  int get pomodorosCompleted => _pomodorosCompleted;
  int get tasksCompleted => _taskManager.totalTasksCompleted;
  int get streakDays => _streakDays;
  int get totalFocusTimeMinutes => _totalFocusTimeMinutes;
  DateTime? get lastActiveDate => _lastActiveDate;
  String get totalFocusTime {
    final totalMinutes = _totalFocusTimeMinutes + (_taskManager.totalFocusTimeFromTasks);
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
  List<String> get earnedBadges => List.unmodifiable(_earnedBadges);
  List<Achievement> get recentAchievements => List.unmodifiable(_recentAchievements);

  List<String> get allAvailableBadges => [
    'first_timer',
    'on_fire', 
    'time_master',
    'focused',
    'goal_crusher',
    'consistency',
    'first_task',
    'task_warrior',
    'task_master_daily',
    'priority_master'
  ];

  // Firebase Integration
  Future<void> loadFromFirebase() async {
    try {
      final data = await _firebaseService.loadUserStats();
      if (data != null) {
        _pomodorosCompleted = data['pomodorosCompleted'] ?? 0;
        _totalFocusTimeMinutes = data['totalFocusTimeMinutes'] ?? 0;
        _streakDays = data['streakDays'] ?? 0;
        _lastActiveDate = data['lastActiveDate'] != null 
            ? DateTime.fromMillisecondsSinceEpoch(data['lastActiveDate'])
            : null;
        _earnedBadges = List<String>.from(data['earnedBadges'] ?? []);
        _recentAchievements = await _firebaseService.loadAchievements();
        
        debugPrint('User Stats loaded successfully');
      } else {
        debugPrint('No user stats found, using defaults');
      }
    } catch (e) {
      debugPrint('Error loading user stats from Firebase: $e');
    }
  }

  Future<void> saveToFirebase() async {
    try {
      await _firebaseService.saveUserStats(this);
      debugPrint('UserStats saved to Firebase successfully');
    } catch (e) {
      debugPrint('Error saving user stats to Firebase: $e');
    }
  }

  // Main stat update methods
  void completedPomodoro({int durationMinutes = 25}) {
    _pomodorosCompleted++;
    _totalFocusTimeMinutes += durationMinutes;
    _updateStreak();
    _checkForNewBadges();
    saveToFirebase();
  }

  void addFocusTime(int minutes) {
    _totalFocusTimeMinutes += minutes;
    _checkForNewBadges();
    saveToFirebase();
  }

  void onTaskCompleted(String taskTitle) {
    _addAchievement('✅', 'Task Completed', 'Completed: $taskTitle');
    _updateStreak();
    _checkForNewBadges();
    saveToFirebase();
  }

  // Private helper methods
  void _updateStreak() {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    if (_lastActiveDate == null) {
      _streakDays = 1;
      _lastActiveDate = todayDate;
    } else {
      final lastActiveDate = DateTime(_lastActiveDate!.year, _lastActiveDate!.month, _lastActiveDate!.day);
      final difference = todayDate.difference(lastActiveDate).inDays;
      
      if (difference == 1) {
        _streakDays++;
        _lastActiveDate = todayDate;
      } else if (difference == 0) {
        _lastActiveDate = todayDate;
      } else {
        _streakDays = 1;
        _lastActiveDate = todayDate;
      }
    }
  }

  void _checkForNewBadges() {
    final newBadges = <String>[];
    
    // Pomodoro achievements
    if (_pomodorosCompleted >= 1 && !_earnedBadges.contains('first_timer')) {
      newBadges.add('first_timer');
      _addAchievement('🏆', 'First Timer', 'Complete your first pomodoro');
    }
    
    if (_streakDays >= 7 && !_earnedBadges.contains('on_fire')) {
      newBadges.add('on_fire');
      _addAchievement('🔥', 'On Fire', 'Maintain a 7-day streak');
    }
    
    if (_pomodorosCompleted >= 50 && !_earnedBadges.contains('time_master')) {
      newBadges.add('time_master');
      _addAchievement('⏰', 'Time Master', 'Complete 50 pomodoros');
    }
    
    if (_totalFocusTimeMinutes >= 600 && !_earnedBadges.contains('focused')) {
      newBadges.add('focused');
      _addAchievement('📚', 'Focused', 'Study for 10 hours total');
    }
    
    if (_streakDays >= 30 && !_earnedBadges.contains('consistency')) {
      newBadges.add('consistency');
      _addAchievement('💎', 'Consistency', 'Use app for 30 days');
    }

    // Task achievements
    if (tasksCompleted >= 1 && !_earnedBadges.contains('first_task')) {
      newBadges.add('first_task');
      _addAchievement('✅', 'First Task', 'Complete your first task');
    }
    
    if (tasksCompleted >= 25 && !_earnedBadges.contains('task_warrior')) {
      newBadges.add('task_warrior');
      _addAchievement('⚔️', 'Task Warrior', 'Complete 25 tasks');
    }
    
    if (tasksCompleted >= 100 && !_earnedBadges.contains('goal_crusher')) {
      newBadges.add('goal_crusher');
      _addAchievement('🎯', 'Goal Crusher', 'Complete 100 tasks');
    }

    if (_taskManager.todayCompletedTasks >= 10 && !_earnedBadges.contains('task_master_daily')) {
      newBadges.add('task_master_daily');
      _addAchievement('🎯', 'Task Master', 'Completed 10 tasks in one day');
    }
    
    if (_taskManager.priorityTasks.isEmpty && _taskManager.tasks.isNotEmpty && !_earnedBadges.contains('priority_master')) {
      newBadges.add('priority_master');
      _addAchievement('⭐', 'Priority Master', 'Complete all priority tasks');
    }

    _earnedBadges.addAll(newBadges);
  }

  void _addAchievement(String emoji, String title, String description) {
    final achievement = Achievement(
      emoji: emoji,
      title: title,
      description: description,
      timestamp: DateTime.now(),
    );
    
    _recentAchievements.insert(0, achievement);
    
    if (_recentAchievements.length > 10) {
      _recentAchievements = _recentAchievements.take(10).toList();
    }
    
    _firebaseService.saveAchievement(achievement);
  }

  // Badge information
  BadgeInfo getBadgeInfo(String badgeId) {
    switch (badgeId) {
      case 'first_timer':
        return BadgeInfo('🏆', 'First Timer', 'Complete your first pomodoro');
      case 'on_fire':
        return BadgeInfo('🔥', 'On Fire', 'Maintain a 7-day streak');
      case 'time_master':
        return BadgeInfo('⏰', 'Time Master', 'Complete 50 pomodoros');
      case 'focused':
        return BadgeInfo('📚', 'Focused', 'Study for 10 hours total');
      case 'goal_crusher':
        return BadgeInfo('🎯', 'Goal Crusher', 'Complete 100 tasks');
      case 'consistency':
        return BadgeInfo('💎', 'Consistency', 'Use app for 30 days');
      case 'first_task':
        return BadgeInfo('✅', 'First Task', 'Complete your first task');
      case 'task_warrior':
        return BadgeInfo('⚔️', 'Task Warrior', 'Complete 25 tasks');
      case 'task_master_daily':
        return BadgeInfo('🎯', 'Task Master', 'Complete 10 tasks in one day');
      case 'priority_master':
        return BadgeInfo('⭐', 'Priority Master', 'Complete all priority tasks');
      default:
        return BadgeInfo('🏅', 'Unknown', 'Unknown achievement');
    }
  }

  // Initialization
  Future<void> initializeFromFirebase() async {
    try {
      await loadFromFirebase();
      
      if (_pomodorosCompleted == 0 && _earnedBadges.isEmpty) {
        debugPrint('No Firebase data found, using sample data for demo');
        initializeSampleData();
      }
    } catch (e) {
      debugPrint('Error initializing from Firebase: $e');
      initializeSampleData();
    }
  }

  void initializeSampleData() {
    _pomodorosCompleted = 127;
    _totalFocusTimeMinutes = 2535; // 42h 15m
    _streakDays = 12;
    _lastActiveDate = DateTime.now();
    _earnedBadges = ['first_timer', 'on_fire', 'time_master', 'focused'];
    
    _taskManager.initializeSampleData();
    
    _recentAchievements = [
      Achievement(
        emoji: '🎯',
        title: 'Task Master',
        description: 'Completed 10 tasks in one day',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Achievement(
        emoji: '⚡',
        title: 'Speed Runner',
        description: 'Completed 5 pomodoros in a row',
        timestamp: DateTime.now().subtract(const Duration(days: 7)),
      ),
      Achievement(
        emoji: '🌟',
        title: 'Early Bird',
        description: 'Started session before 7 AM',
        timestamp: DateTime.now().subtract(const Duration(days: 14)),
      ),
    ];
  }
}

class Achievement {
  final String emoji;
  final String title;
  final String description;
  final DateTime timestamp;

  Achievement({
    required this.emoji,
    required this.title,
    required this.description,
    required this.timestamp,
  });
}

class BadgeInfo {
  final String emoji;
  final String title;
  final String description;

  BadgeInfo(this.emoji, this.title, this.description);
}
