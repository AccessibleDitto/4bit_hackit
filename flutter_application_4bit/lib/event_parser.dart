// lib/models/event_parser.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'models/calendar_models.dart'; // your ExtendedCalendarEventData, Priority, RecurringType, PriorityHelper
import 'models/task_models.dart'; // Import Task model

List<ExtendedCalendarEventData> parseEventsFromJson(String jsonString) {
  final jsonList = jsonDecode(jsonString) as List<dynamic>;

  return jsonList.map((e) {
    final priority = Priority.values.firstWhere(
      (p) => p.toString().split('.').last == e['priority'],
      orElse: () => Priority.low,
    );

    final recurring = RecurringType.values.firstWhere(
      (r) => r.toString().split('.').last == e['recurring'],
      orElse: () => RecurringType.none,
    );

    final colorHex = e['color'] as String;
    final color = Color(int.parse('0xFF${colorHex.substring(1)}'));

    return ExtendedCalendarEventData(
      title: e['title'],
      description: e['description'],
      date: DateTime.parse(e['date']),
      startTime: DateTime.parse(e['startTime']),
      endTime: DateTime.parse(e['endTime']),
      color: color,
      priority: priority,
      project: e['project'],
      recurring: recurring,
      seriesId: e['id'],
    );
  }).toList();
}
