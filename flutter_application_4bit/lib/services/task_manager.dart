// Task and Project Management
import 'package:flutter/material.dart';
import '../tasks.dart';
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
  List<Task> get completedTasks => _tasks.where((task) => task.isCompleted).toList();
  List<Task> get incompleteTasks => _tasks.where((task) => !task.isCompleted).toList();
  List<Task> get todayTasks => _tasks.where((task) => task.isToday && !task.isCompleted).toList();
  List<Task> get priorityTasks => _tasks.where((task) => task.isPriority && !task.isCompleted).toList();

  // Task statistics
  int get totalTasksCompleted => completedTasks.length;
  int get totalFocusTimeFromTasks {
    return completedTasks.fold(0, (sum, task) => sum + task.estimatedTime * 60); // Convert hours to minutes
  }
  int get todayCompletedTasks {
    final today = DateTime.now();
    return completedTasks.where((task) {
      return task.scheduledDate != null &&
             task.scheduledDate!.year == today.year &&
             task.scheduledDate!.month == today.month &&
             task.scheduledDate!.day == today.day;
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
      task.isCompleted = true;
      
      // Notify UserStats about task completion for achievements
      final userStats = UserStats();
      userStats.onTaskCompleted(task.title);
      
      _saveTaskToFirebase(task);
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
    _tasks = [
      Task(
        id: '1',
        title: 'Complete Flutter app',
        estimatedTime: 3,
        isCompleted: false,
        isToday: true,
        isPriority: true,
        scheduledDate: DateTime.now(),
      ),
      Task(
        id: '2',
        title: 'Review code',
        estimatedTime: 1,
        isCompleted: false,
        isToday: true,
        isPriority: false,
        scheduledDate: null,
      ),
      Task(
        id: '3',
        title: 'Meeting with team',
        estimatedTime: 1,
        isCompleted: false,
        isToday: false,
        isPriority: true,
        scheduledDate: DateTime.now().add(const Duration(days: 1)),
      ),
      Task(
        id: '4',
        title: 'Write documentation',
        estimatedTime: 2,
        isCompleted: true,
        isToday: false,
        isPriority: false,
        scheduledDate: DateTime.now().add(const Duration(days: 2)),
      ),
      Task(
        id: '5',
        title: 'Fix bug #123',
        estimatedTime: 1,
        isCompleted: false,
        isToday: false,
        isPriority: true,
        scheduledDate: DateTime.now().add(const Duration(days: 3)),
      ),
    ];
  }
}
