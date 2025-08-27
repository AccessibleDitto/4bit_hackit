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
  final String seriesId; // <-- NEW FIELD

  ExtendedCalendarEventData({
    required String title,
    String? description,
    required DateTime date,
    required DateTime startTime,
    required DateTime endTime,
    required Color color,
    required this.priority,
    this.project,
    this.recurring = RecurringType.none,
    String? seriesId,
  })  : seriesId = seriesId ?? UniqueKey().toString(), // Auto-generate if not provided
        super(
          title: title,
          description: description,
          date: date,
          startTime: startTime,
          endTime: endTime,
          color: color,
        );
}
