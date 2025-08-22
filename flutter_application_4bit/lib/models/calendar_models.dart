import 'package:flutter/material.dart';
import 'package:calendar_view/calendar_view.dart';

// Priority options storage
enum Priority { low, medium, high, urgent }

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

// Extended CalendarEventData to include custom fields
class ExtendedCalendarEventData extends CalendarEventData {
  final Priority priority;
  final String? project;
  final RecurringType recurring;

  ExtendedCalendarEventData({
    required String title,
    String? description,
    required DateTime date,
    DateTime? startTime,
    DateTime? endTime,
    Color? color,
    this.priority = Priority.medium,
    this.project,
    this.recurring = RecurringType.none,
  }) : super(
          title: title,
          description: description,
          date: date,
          startTime: startTime,
          endTime: endTime,
          color: color ?? Colors.blue,
        );
}