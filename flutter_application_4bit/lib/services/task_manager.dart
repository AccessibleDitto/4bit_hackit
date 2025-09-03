// Task and Project Management
import 'package:flutter/material.dart';
import '../models/task_models.dart';
import 'firebase_service.dart';
import 'user_stats_service.dart';

class TaskManager {
  static final TaskManager _instance = TaskManager._internal();
  factory TaskManager() => _instance;
  TaskManager._internal();

  List<Task> _tasks = [];
  List<Project> _projects = [];
  final FirebaseService _firebaseService = FirebaseService();

  // Getters
  List<Task> get tasks => List.unmodifiable(_tasks);
  List<Project> get projects => List.unmodifiable(_projects);
  List<Task> get completedTasks => _tasks.where((task) => task.status == TaskStatus.completed).toList();
  List<Task> get incompleteTasks => _tasks.where((task) => task.status != TaskStatus.completed).toList();
  List<Task> get todayTasks => _tasks.where((task) => task.shouldScheduleToday && task.status != TaskStatus.completed).toList();
  List<Task> get priorityTasks => _tasks.where((task) => (task.priority == Priority.high || task.priority == Priority.urgent) && task.status != TaskStatus.completed).toList();

  // Task statistics
  int get totalTasksCompleted => completedTasks.length;
  int get totalFocusTimeFromTasks {
    return completedTasks.fold(0, (sum, task) => sum + (task.timeSpent * 60).round()); // Convert hours to minutes
  }
  int get todayCompletedTasks {
    final today = DateTime.now();
    return completedTasks.where((task) {
      return task.scheduledFor != null &&
             task.scheduledFor!.year == today.year &&
             task.scheduledFor!.month == today.month &&
             task.scheduledFor!.day == today.day;
    }).length;
  }

  // Methods to update tasks
  void updateTasks(List<Task> newTasks) {
    _tasks = List.from(newTasks);
  }

  void updateProjects(List<Project> newProjects) {
    _projects = List.from(newProjects);
  }

  void addTask(Task task) {
    _tasks.add(task);
    _saveTaskToFirebase(task);
  }

  void addProject(Project project) {
    _projects.add(project);
    _saveProjectToFirebase(project);
  }

  void completeTask(String taskId) {
    final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex != -1) {
      final task = _tasks[taskIndex];
      final updatedTask = task.copyWith(status: TaskStatus.completed);
      _tasks[taskIndex] = updatedTask;
      
      // Notify UserStats about task completion for achievements
      final userStats = UserStats();
      userStats.onTaskCompleted(task.title);
      
      _saveTaskToFirebase(updatedTask);
    }
  }

  void removeTask(String taskId) {
    _tasks.removeWhere((task) => task.id == taskId);
  }

  void removeProject(String projectName) {
    _projects.removeWhere((project) => project.name == projectName);
  }

  // Get task by ID
  Task? getTaskById(String id) {
    try {
      return _tasks.firstWhere((task) => task.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get project by name
  Project? getProjectByName(String name) {
    try {
      return _projects.firstWhere((project) => project.name == name);
    } catch (e) {
      return null;
    }
  }

  // Firebase integration methods
  Future<void> loadTasksFromFirebase() async {
    try {
      _tasks = await _firebaseService.loadTasks();
      _projects = await _firebaseService.loadProjects();
      debugPrint('Tasks and projects loaded from Firebase successfully');
    } catch (e) {
      debugPrint('Error loading tasks from Firebase: $e');
    }
  }

  Future<void> _saveTaskToFirebase(Task task) async {
    try {
      await _firebaseService.saveTask(task);
      debugPrint('Task saved to Firebase: ${task.title}');
    } catch (e) {
      debugPrint('Error saving task to Firebase: $e');
    }
  }

  Future<void> _saveProjectToFirebase(Project project) async {
    try {
      await _firebaseService.saveProject(project);
      debugPrint('Project saved to Firebase: ${project.name}');
    } catch (e) {
      debugPrint('Error saving project to Firebase: $e');
    }
  }

  Future<void> initializeFromFirebase() async {
    try {
      await loadTasksFromFirebase();
      
      if (_tasks.isEmpty) {
        debugPrint('No Firebase tasks found, using sample data for demo');
        initializeSampleData();
      }
    } catch (e) {
      debugPrint('Error initializing tasks from Firebase: $e');
      initializeSampleData();
    }
  }

  // Sample data for development
  void initializeSampleData() {
    final now = DateTime.now();
    _tasks = [
      Task(
        id: '1',
        title: 'Complete Flutter app',
        estimatedTime: 3,
        status: TaskStatus.notStarted,
        priority: Priority.urgent,
        scheduledFor: now,
        createdAt: now,
        updatedAt: now,
      ),
      Task(
        id: '2',
        title: 'Review code',
        estimatedTime: 1,
        status: TaskStatus.notStarted,
        priority: Priority.medium,
        createdAt: now,
        updatedAt: now,
      ),
      Task(
        id: '3',
        title: 'Meeting with team',
        estimatedTime: 1,
        status: TaskStatus.notStarted,
        priority: Priority.high,
        scheduledFor: now.add(const Duration(days: 1)),
        createdAt: now,
        updatedAt: now,
      ),
      Task(
        id: '4',
        title: 'Write documentation',
        estimatedTime: 2,
        status: TaskStatus.completed,
        priority: Priority.low,
        scheduledFor: now.add(const Duration(days: 2)),
        createdAt: now,
        updatedAt: now,
      ),
      Task(
        id: '5',
        title: 'Fix bug #123',
        estimatedTime: 1,
        status: TaskStatus.notStarted,
        priority: Priority.high,
        scheduledFor: now.add(const Duration(days: 3)),
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}
