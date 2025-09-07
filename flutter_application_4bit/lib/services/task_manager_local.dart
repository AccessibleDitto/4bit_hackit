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
}