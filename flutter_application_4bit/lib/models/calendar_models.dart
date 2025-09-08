import 'package:flutter/material.dart';
import 'package:calendar_view/calendar_view.dart';
import 'task_models.dart';

// Priority options storage
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

// Add this class to your models or create a new file for it
class RecurringSeriesInfo {
  final RecurringType originalRecurringType;
  final String baseTitle;
  final String baseDescription;
  final DateTime baseDate;
  final DateTime baseStartTime;
  final DateTime baseEndTime;
  final String seriesId;
  final String? project;
  final Priority priority;

  RecurringSeriesInfo({
    required this.originalRecurringType,
    required this.baseTitle,
    required this.baseDescription,
    required this.baseDate,
    required this.baseStartTime,
    required this.baseEndTime,
    required this.seriesId,
    this.project,
    required this.priority,
  });
}

// Recurring options
enum RecurringType { none, daily, weekly, monthly, yearly }

class RecurringHelper {
  static const Map<RecurringType, String> recurringLabels = {
    RecurringType.none: 'No Repeat',
    RecurringType.daily: 'daily',
    RecurringType.weekly: 'weekly',
    RecurringType.monthly: 'monthly',
    RecurringType.yearly: 'yearly',
  };
}

// === FIXED EXTENDED CALENDAR EVENT DATA ===
class ExtendedCalendarEventData extends CalendarEventData<Object?> {
  // Only define CUSTOM fields here - don't duplicate parent fields
  final Priority priority;
  final String? project;
  final RecurringType recurring;
  final String seriesId;
  final Task? task; // Direct reference to Task

  ExtendedCalendarEventData({
    // Use super parameters for parent class fields
    required String title,
    String? description,
    required DateTime date,
    DateTime? startTime,
    DateTime? endTime,
    required Color color,
    Object? event, // This might be important for recurring events
    
    // Custom fields
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
         event: event, // Pass through the event object
       );

  // Convenience getter for whether this event is linked to a task
  bool get hasTask => task != null;

  // If linked to a task, check if overdue
  bool get isTaskOverdue => task?.isOverdue ?? false;

  // If linked to a task, get completion percentage
  double? get taskCompletion => task?.completionPercentage;

  // Duration of the event
  Duration get duration => (endTime ?? startTime ?? DateTime.now())
      .difference(startTime ?? DateTime.now());

  // Check if event is ongoing at a specific time
  bool isOngoingAt(DateTime time) {
    final start = startTime ?? DateTime.now();
    final end = endTime ?? start.add(Duration(hours: 1));
    return time.isAfter(start) && time.isBefore(end);
  }

  // Convenience property for recurring check
  bool get isRecurringEvent => recurring != RecurringType.none;

  // Override the parent copyWith method properly
  @override
  CalendarEventData<Object?> copyWith({
    String? title,
    String? description,
    DateTime? date,
    DateTime? startTime,
    DateTime? endTime,
    Color? color,
    Object? event,
    // Parent class parameters that we don't use but need to accept
    TextStyle? titleStyle,
    TextStyle? descriptionStyle,
    DateTime? endDate,
    RecurrenceSettings? recurrenceSettings,
  }) {
    return ExtendedCalendarEventData(
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      color: color ?? this.color,
      priority: this.priority, // Keep existing custom fields
      project: this.project,
      recurring: this.recurring,
      seriesId: this.seriesId,
      task: this.task,
      event: event ?? this.event,
    );
  }

  // Custom copyWith method for your extended fields
  ExtendedCalendarEventData copyWithExtended({
    String? title,
    String? description,
    DateTime? date,
    DateTime? startTime,
    DateTime? endTime,
    Color? color,
    Priority? priority,
    String? project,
    RecurringType? recurring,
    String? seriesId,
    Task? task,
    Object? event,
  }) {
    return ExtendedCalendarEventData(
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      color: color ?? this.color,
      priority: priority ?? this.priority,
      project: project ?? this.project,
      recurring: recurring ?? this.recurring,
      seriesId: seriesId ?? this.seriesId,
      task: task ?? this.task,
      event: event ?? this.event,
    );
  }
}