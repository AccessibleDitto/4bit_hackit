// User performance statistics and gamification system
import 'package:flutter/material.dart';
import 'task_manager.dart';
import 'firebase_service.dart';
import '../models/task_models.dart';

class UserStats {
  // Store and calculate in minutes; display in hours + minutes
  int get weekFocusTimeMinutes {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return _taskManager.completedTasks.where((task) {
      if (task.scheduledFor == null) return false;
      final d = task.scheduledFor!;
      return d.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) && d.isBefore(now.add(const Duration(days: 1)));
    }).fold(0, (sum, task) => sum + (task.timeSpent * 60).round());
  }

  String get weekFocusTime {
    final minutes = weekFocusTimeMinutes;
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }

  int get twoWeeksFocusTimeMinutes {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 13));
    return _taskManager.completedTasks.where((task) {
      if (task.scheduledFor == null) return false;
      final d = task.scheduledFor!;
      return d.isAfter(start.subtract(const Duration(seconds: 1))) && d.isBefore(now.add(const Duration(days: 1)));
    }).fold(0, (sum, task) => sum + (task.timeSpent * 60).round());
  }

  String get twoWeeksFocusTime {
    final minutes = twoWeeksFocusTimeMinutes;
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }

  int get monthFocusTimeMinutes {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    return _taskManager.completedTasks.where((task) {
      if (task.scheduledFor == null) return false;
      final d = task.scheduledFor!;
      return d.isAfter(start.subtract(const Duration(seconds: 1))) && d.isBefore(now.add(const Duration(days: 1)));
    }).fold(0, (sum, task) => sum + (task.timeSpent * 60).round());
  }

  String get monthFocusTime {
    final minutes = monthFocusTimeMinutes;
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }
  // Returns total focus time for today (in minutes)
  int get todayFocusTimeMinutes {
    // If track by pomodoros per day, add that here. For now, it only sums up by tasks, not pomodoros.
    return _taskManager.todayFocusTimeFromTasks;
  }

  String get todayFocusTime {
    final minutes = todayFocusTimeMinutes;
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }
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
        
        displayFirebaseData();
      }
      
      await _loadTaskStatsFromFirebase();
    } catch (e) {
      debugPrint('Error loading user stats from Firebase: $e');
    }
  }

  Future<void> _loadTaskStatsFromFirebase() async {
    try {
      final taskStats = await _firebaseService.loadTaskStats();
      if (taskStats != null) {
      }
    } catch (e) {
      debugPrint('Error loading task stats from Firebase: $e');
    }
  }

  Future<void> saveToFirebase() async {
    try {
      // Save user stats
      await _firebaseService.saveUserStats(this);
      
      // Save task statistics
      final taskStats = {
        'totalTasks': _taskManager.tasks.length,
        'completedTasks': _taskManager.totalTasksCompleted,
        'inProgressTasks': _taskManager.tasks.where((t) => t.status == TaskStatus.inProgress).length,
        'priorityTasksCompleted': _taskManager.completedTasks.where((t) => t.priority == Priority.high || t.priority == Priority.urgent).length,
        'todayCompletedTasks': _taskManager.todayCompletedTasks,
        'totalFocusTimeFromTasks': _taskManager.totalFocusTimeFromTasks,
        'todayFocusTimeFromTasks': _taskManager.todayFocusTimeFromTasks,
      };
      await _firebaseService.saveTaskStats(taskStats);
      
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

    _firebaseService.updatePomodoroCount(_pomodorosCompleted, _totalFocusTimeMinutes, _streakDays);
    saveToFirebase();
  }

  void completedTask() {
    _checkForTaskBadges();
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
    _checkForTaskBadges();
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

    if (newBadges.isNotEmpty) {
      _earnedBadges.addAll(newBadges);
      _firebaseService.updateBadges(_earnedBadges);
      saveToFirebase();
    }
  }

  void _checkForTaskBadges() {
    final newBadges = <String>[];

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

    if (newBadges.isNotEmpty) {
      _earnedBadges.addAll(newBadges);
      _firebaseService.updateBadges(_earnedBadges);
      saveToFirebase();
    }
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

  Map<String, dynamic> getComprehensiveStats() {
    return {
      'pomodorosCompleted': _pomodorosCompleted,
      'tasksCompleted': tasksCompleted,
      'streakDays': _streakDays,
      'totalFocusTimeMinutes': _totalFocusTimeMinutes,
      
      // time 
      'todayFocusTime': todayFocusTime,
      'weekFocusTime': weekFocusTime,
      'monthFocusTime': monthFocusTime,
      'totalFocusTime': totalFocusTime,
      
      // achievement
      'totalBadges': _earnedBadges.length,
      'totalAchievements': _recentAchievements.length,
      'earnedBadges': _earnedBadges,
      'recentAchievements': _recentAchievements,
      
      // tasks
      'todayFocusTimeMinutes': todayFocusTimeMinutes,
      'weekFocusTimeMinutes': weekFocusTimeMinutes,
      'monthFocusTimeMinutes': monthFocusTimeMinutes,
      
      // status
      'lastActiveDate': _lastActiveDate,
      'lastSyncTime': DateTime.now(),
    };
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
      await _firebaseService.migrateToConsolidatedStructure();
      
      await loadFromFirebase();
      
      if (_pomodorosCompleted == 0 && _earnedBadges.isEmpty) {
        initializeSampleData();
        await saveToFirebase();
      }
      
      debugPrint('UserStats initialization complete. Stats loaded: ${getComprehensiveStats()}');
      
    } catch (e) {
      debugPrint('Error initializing from Firebase: $e');
      initializeSampleData();
    }
  }

  bool validateDataConsistency() {
    final isValid = _pomodorosCompleted >= 0 && 
                   _totalFocusTimeMinutes >= 0 && 
                   _streakDays >= 0 &&
                   _earnedBadges.isNotEmpty || _pomodorosCompleted == 0;
    
    if (!isValid) {
      debugPrint('Data consistency check failed!');
      debugPrint('Pomodoros: $_pomodorosCompleted, Focus: $_totalFocusTimeMinutes, Streak: $_streakDays');
    }
    
    return isValid;
  }

  void displayFirebaseData() {
    debugPrint('=== FIREBASE USER STATS ===');
    debugPrint('Pomodoros Completed: $_pomodorosCompleted');
    debugPrint('Total Focus Time: $_totalFocusTimeMinutes minutes ($totalFocusTime)');
    debugPrint('Streak Days: $_streakDays');
    debugPrint('Tasks Completed: $tasksCompleted');
    debugPrint('Today Focus Time: $todayFocusTime');
    debugPrint('Week Focus Time: $weekFocusTime');
    debugPrint('Month Focus Time: $monthFocusTime');
    debugPrint('Earned Badges (${_earnedBadges.length}): ${_earnedBadges.join(', ')}');
    debugPrint('Recent Achievements (${_recentAchievements.length}): ${_recentAchievements.map((a) => a.title).join(', ')}');
    debugPrint('Last Active: $_lastActiveDate');
    debugPrint('=== END FIREBASE DATA ===');
  }

  // Get comprehensive Firebase integration status
  Future<Map<String, dynamic>> getFirebaseIntegrationStatus() async {
    final status = <String, dynamic>{};
    
    try {
      final firebaseStatus = _firebaseService.getSyncStatus();
      status['firebase'] = firebaseStatus;
      status['currentStats'] = getComprehensiveStats();
      
      final integrationTest = await _firebaseService.testFirebaseIntegration();
      status['integrationTest'] = integrationTest;
      status['dataConsistency'] = validateDataConsistency();
      status['lastSyncAttempt'] = DateTime.now().toIso8601String();
      
      debugPrint('Firebase Integration Status: $status');
      
    } catch (e) {
      status['error'] = e.toString();
      debugPrint('Error getting Firebase integration status: $e');
    }
    
    return status;
  }

  void initializeSampleData() {
    _pomodorosCompleted = 0; 
    _totalFocusTimeMinutes = 0; 
    _streakDays = 0; 
    _lastActiveDate = null; 
    _earnedBadges = []; 
    
    _taskManager.initializeSampleData();
    _recentAchievements = []; 
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
