import 'package:flutter/material.dart';
import 'package:calendar_view/calendar_view.dart';
import '../models/calendar_models.dart';
import '../models/task_models.dart';
import '../models/scheduling_models.dart';
import '../services/scheduling_service.dart';
import '.././tasks_updated.dart' as tasks_source;

class CalendarTaskService {
  // Sync tasks from source of truth to calendar
  void syncTasksToCalendar(EventController eventController) {
    // Clear existing task events first
    eventController.removeWhere(
      (event) =>
          event is ExtendedCalendarEventData && event.title.startsWith('📋'),
    );

    // Add scheduled tasks to calendar
    for (final task in tasks_source.getTasksList()) {
      if (task.scheduledFor != null && task.status != TaskStatus.completed) {
        _addTaskToCalendar(task, eventController);
      }
    }
  }

  Color _resolveTaskColor(Task task) {
    // Try to find project by ID first
    final project = tasks_source.projects.firstWhere(
      (p) => p.id == task.projectId,
      orElse: () => Project.create(name: '', color: task.priority.color),
    );

    // This would need access to project colors from the main class
    // For now, just return the task priority color
    return task.priority.color;
  }

  // Get unscheduled tasks from source of truth
  List<Task> getUnscheduledTasks() {
    return tasks_source
        .getTasksList()
        .where(
          (task) =>
              task.scheduledFor == null &&
              task.status != TaskStatus.completed &&
              task.status != TaskStatus.cancelled,
        )
        .toList();
  }

  Future<SchedulingResult> scheduleUnscheduledTasks(
    SchedulingService schedulingService,
    EventController eventController,
  ) async {
    final unscheduledTasks = getUnscheduledTasks();
    if (unscheduledTasks.isEmpty) {
      throw Exception('No unscheduled tasks to process.');
    }

    final cutoffDate = DateTime.now().add(Duration(days: 14));
    final existingEvents = eventController.allEvents
        .whereType<ExtendedCalendarEventData>()
        .where((event) => event.startTime != null && event.startTime!.isBefore(cutoffDate))
        .toList();

    final constraints = SchedulingConstraints(
      workingHours: WorkingHours(start: "09:00", end: "17:00"),
      energyPeaks: ["09:00-12:00", "14:00-16:00"],
      breaks: [BreakPeriod(start: "12:00", end: "13:00", name: "Lunch")],
    );

    // Debug logging
    print('🔍 DEBUG: Existing events being sent to AI:');
    for (final event in existingEvents) {
      print('  📅 ${event.title}');
      print('     Start: ${event.startTime}');
      print('     End: ${event.endTime}');
      print('     Date: ${event.date}');
    }
    print('📊 Total existing events: ${existingEvents.length}');

    // Convert tasks for scheduling service
    final result = await schedulingService.scheduleUnscheduledTasks(
      unscheduledTasks: unscheduledTasks,
      existingEvents: existingEvents,
      constraints: constraints,
    );

    // Update tasks with scheduled times using source of truth functions
    final List<Task> scheduledTasks = [];
    int scheduledCount = 0;

    for (final scheduledTask in result.schedule) {
      try {
        final originalTask = tasks_source.getTasksList().firstWhere(
          (t) => t.id == scheduledTask.id,
        );

        final updatedTask = originalTask.copyWith(
          scheduledFor: scheduledTask.scheduledFor,
        );

        // Use the source of truth save function
        tasks_source.saveTask(updatedTask);
        _addTaskToCalendar(updatedTask, eventController);
        scheduledTasks.add(updatedTask);
        scheduledCount++;
      } catch (e) {
        print('Error updating task ${scheduledTask.id}: $e');
      }
    }

    return SchedulingResult(
      scheduledCount: scheduledCount,
      scheduledTasks: scheduledTasks,
      reasoning: result.reasoning,
    );
  }

  void _addTaskToCalendar(Task task, EventController eventController) {
    if (task.scheduledFor == null) return;

    final scheduledTime = task.scheduledFor!;
    final estimatedDuration = Duration(
      minutes: (task.estimatedTime * 60).round(),
    );

    // Get project name for display
    final project = tasks_source.projects.firstWhere(
      (p) => p.id == task.projectId,
      orElse: () => Project.create(name: 'Tasks', color: task.priority.color),
    );

    final event = ExtendedCalendarEventData(
      title: '📋 ${task.title}',
      description: task.description ?? '',
      date: scheduledTime,
      startTime: scheduledTime,
      endTime: scheduledTime.add(estimatedDuration),
      color: _resolveTaskColor(task),
      priority: task.priority,
      project: project.name.isNotEmpty ? project.name : 'Tasks',
      recurring: RecurringType.none,
    );

    eventController.add(event);
  }

  Future<int> undoScheduling(List<Task> tasksToUndo, EventController eventController) async {
    int unscheduledCount = 0;
    
    for (final task in tasksToUndo) {
      try {
        // Get the current task from source of truth
        final currentTask = tasks_source.getTasksList().firstWhere(
          (t) => t.id == task.id,
          orElse: () => task,
        );
        
        // Use the fixed copyWith method with clearScheduledFor flag
        final updatedTask = currentTask.copyWith(clearScheduledFor: true);
        
        // Save to source of truth
        tasks_source.saveTask(updatedTask);
        
        // Remove from calendar
        eventController.removeWhere((event) => 
          event is ExtendedCalendarEventData && 
          event.title == '📋 ${task.title}');
        
        unscheduledCount++;
        print('Unscheduled: ${task.title} (scheduledFor is now null)');
        
      } catch (e) {
        print('Error unscheduling task ${task.title}: $e');
      }
    }
    
    return unscheduledCount;
  }

  Widget buildTaskListTile(
    Task task, {
    required VoidCallback onDelete,
    required VoidCallback onTap,
  }) {
    final project = tasks_source.projects.firstWhere(
      (p) => p.id == task.projectId,
      orElse: () => Project.create(name: '', color: task.priority.color),
    );

    return Card(
      child: ListTile(
        title: Text(task.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${task.estimatedTime}h • ${task.priority.displayName}'),
            if (project.name.isNotEmpty) Text('Project: ${project.name}'),
            if (task.dueDate != null)
              Text(
                'Due: ${task.dueDate!.toString().split(' ')[0]}',
                style: TextStyle(
                  color: task.isOverdue ? Colors.red : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (task.isOverdue)
              const Icon(Icons.warning, color: Colors.red),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: onDelete,
            ),
          ],
        ),
        leading: CircleAvatar(
          backgroundColor: task.priority.color,
          child: Text(
            task.energyRequired.name[0].toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

class SchedulingResult {
  final int scheduledCount;
  final List<Task> scheduledTasks;
  final String reasoning;

  SchedulingResult({
    required this.scheduledCount,
    required this.scheduledTasks,
    required this.reasoning,
  });
}