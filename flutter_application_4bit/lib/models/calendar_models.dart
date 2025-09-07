import 'package:flutter/material.dart';
import 'package:calendar_view/calendar_view.dart';
import 'task_models.dart';

// Priority options storage
// enum Priority { low, medium, high, urgent }

class PriorityHelper {
  static const Map<Priority, String> priorityLabels = {
    Priority.low: 'Low',
    Priority.medium: 'Medium',
    Priority.high: 'High',
    Priority.urgent: 'Urgent',
  };

  static const Map<Priority, Color> priorityColors = {
    Priority.low: Colors.green,
    Priority.medium: Colors.orange,
    Priority.high: Colors.red,
    Priority.urgent: Colors.purple,
  };
}

// Recurring options
enum RecurringType { none, daily, weekly, monthly, yearly }

class RecurringHelper {
  static const Map<RecurringType, String> recurringLabels = {
    RecurringType.none: 'No Repeat',
    RecurringType.daily: 'Daily',
    RecurringType.weekly: 'Weekly',
    RecurringType.monthly: 'Monthly',
    RecurringType.yearly: 'Yearly',
  };
}


// === EXTENDED CALENDAR EVENT DATA ===
class ExtendedCalendarEventData extends CalendarEventData {
  final String title;
  final String? description;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final Color color;
  // --- Custom fields ---
  final Priority priority;
  final String? project;
  final RecurringType recurring;
  final String seriesId;
  final Task? task; // Direct reference to Task

  ExtendedCalendarEventData({
    required this.title,
    this.description,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.color,
    required this.priority,
    this.project,
    this.recurring = RecurringType.none,
    String? seriesId,
    this.task,
  }) : seriesId = seriesId ?? UniqueKey().toString(),
       super(
         title: title,
         description: description,
         date: date,
         startTime: startTime,
         endTime: endTime,
         color: color,
       );

  /// Convenience getter for whether this event is linked to a task
  bool get hasTask => task != null;

  /// If linked to a task, check if overdue
  bool get isTaskOverdue => task?.isOverdue ?? false;

  /// If linked to a task, get completion percentage
  double? get taskCompletion => task?.completionPercentage;

  /// Duration of the event
  Duration get duration => endTime.difference(startTime);

  /// Check if event is ongoing at a specific time
  bool isOngoingAt(DateTime time) {
    return time.isAfter(startTime) && time.isBefore(endTime);
  }

  /// Convenience property for recurring check
  bool get isRecurringEvent => recurring != RecurringType.none;
}
