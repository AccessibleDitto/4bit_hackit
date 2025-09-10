import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_models.dart';

class TaskManager {
  static const String _tasksKey = 'app_tasks';
  final List<Task> _tasks = [];
  
  List<Task> get tasks => List.unmodifiable(_tasks);
  
  Future<void> initialize() async {
    await _loadTasks();
  }
  
  void addTask(Task task) {
    _tasks.add(task);
    _saveTasks();
  }
  
  void updateTask(Task updatedTask) {
    final index = _tasks.indexWhere((t) => t.id == updatedTask.id);
    if (index != -1) {
      _tasks[index] = updatedTask;
      _saveTasks();
    }
  }
  
  void removeTask(String taskId) {
    _tasks.removeWhere((t) => t.id == taskId);
    _saveTasks();
  }
  
  List<Task> getUnscheduledTasks() {
    return _tasks.where((task) => 
      task.scheduledFor == null && 
      task.status != TaskStatus.completed &&
      task.status != TaskStatus.cancelled
    ).toList();
  }
  
  List<Task> getTasksForDate(DateTime date) {
    final targetDate = DateTime(date.year, date.month, date.day);
    return _tasks.where((task) {
      if (task.scheduledFor == null) return false;
      final scheduledDate = DateTime(
        task.scheduledFor!.year,
        task.scheduledFor!.month,
        task.scheduledFor!.day
      );
      return scheduledDate.isAtSameMomentAs(targetDate);
    }).toList();
  }
  
  Future<void> _saveTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = _tasks.map((task) => task.toJson()).toList();
      await prefs.setString(_tasksKey, jsonEncode(tasksJson));
    } catch (e) {
      print('Error saving tasks: $e');
    }
  }
  
  Future<void> _loadTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksString = prefs.getString(_tasksKey);
      if (tasksString != null) {
        final List<dynamic> tasksJson = jsonDecode(tasksString);
        _tasks.clear();
        _tasks.addAll(tasksJson.map((json) => Task.fromJson(json)));
      }
    } catch (e) {
      print('Error loading tasks: $e');
    }
  }


  // BELOW IS THE CODE FOR THE TOOL CALLING
    
  void saveTask(Task task) {
    final index = tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      tasks[index] = task;
    } else {
      tasks.add(task);
    }
  }

  Task createTask({
    required String title,
    String? description,
    required double estimatedTime,
    required Priority priority,
    DateTime? dueDate,
    DateTime? scheduledFor,
    String? projectId,
    EnergyLevel energyRequired = EnergyLevel.medium,
    TimePreference timePreference = TimePreference.flexible,
    List<String> tags = const [],
    List<String> dependencies = const [],
    String? location,
  }) {
    final task = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      estimatedTime: estimatedTime,
      priority: priority,
      dueDate: dueDate,
      scheduledFor: scheduledFor,
      projectId: projectId,
      energyRequired: energyRequired,
      timePreference: timePreference,
      tags: tags,
      dependencies: dependencies,
      location: location,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    tasks.add(task);
    return task;
  }

  bool deleteTask(String taskId) {
    final initialLength = tasks.length;
    tasks.removeWhere((task) => task.id == taskId);
    return tasks.length < initialLength;
  }

  Task? findTaskById(String taskId) {
    try {
      return tasks.firstWhere((task) => task.id == taskId);
    } catch (e) {
      return null;
    }
  }

  List<Task> searchTasks(String query) {
    final lowerQuery = query.toLowerCase();
    return tasks.where((task) =>
      task.title.toLowerCase().contains(lowerQuery) ||
      (task.description?.toLowerCase().contains(lowerQuery) ?? false) ||
      task.tags.any((tag) => tag.toLowerCase().contains(lowerQuery))
    ).toList();
  }
}