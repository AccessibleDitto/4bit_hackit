import 'package:flutter/material.dart';
import 'package:calendar_view/calendar_view.dart';
import '../models/calendar_models.dart';
import '../models/task_models.dart';

class CalendarEventService {
  void addSampleEvents(
    EventController eventController,
    Color Function({String? project, required Priority priority}) resolveEventColor,
  ) {
    final now = DateTime.now();

    try {
      // Weekly Team Meeting
      final teamMeetingStart = DateTime(now.year, now.month, now.day, 10, 0);
      final teamMeetingEnd = teamMeetingStart.add(const Duration(hours: 1));

      final teamMeetingEvent = ExtendedCalendarEventData(
        title: "Team Meeting",
        date: DateTime(now.year, now.month, now.day),
        startTime: teamMeetingStart,
        endTime: teamMeetingEnd,
        description: "weekly team sync",
        priority: Priority.high,
        project: 'Work',
        recurring: RecurringType.weekly,
        color: resolveEventColor(project: 'Work', priority: Priority.high),
        seriesId: 'team-meeting-${DateTime.now().millisecondsSinceEpoch}',
      );

      print("Adding weekly team meeting...");
      addEventWithRecurring(teamMeetingEvent, eventController, resolveEventColor);

      // Daily Standup (shorter meeting)
      final standupStart = DateTime(now.year, now.month, now.day, 9, 0);
      final standupEnd = standupStart.add(const Duration(minutes: 30));

      final standupEvent = ExtendedCalendarEventData(
        title: "daily Standup",
        date: DateTime(now.year, now.month, now.day),
        startTime: standupStart,
        endTime: standupEnd,
        description: "daily team standup",
        priority: Priority.medium,
        project: 'Work',
        recurring: RecurringType.daily,
        color: resolveEventColor(project: 'Work', priority: Priority.medium),
        seriesId: 'standup-${DateTime.now().millisecondsSinceEpoch}',
      );

      print("Adding daily standup...");
      addEventWithRecurring(standupEvent, eventController, resolveEventColor);

      // Monthly Review
      final reviewStart = DateTime(now.year, now.month, now.day, 14, 0);
      final reviewEnd = reviewStart.add(const Duration(hours: 2));

      final reviewEvent = ExtendedCalendarEventData(
        title: "monthly Review",
        date: DateTime(now.year, now.month, now.day),
        startTime: reviewStart,
        endTime: reviewEnd,
        description: "monthly performance review",
        priority: Priority.high,
        project: 'Work',
        recurring: RecurringType.monthly,
        color: resolveEventColor(project: 'Work', priority: Priority.high),
        seriesId: 'review-${DateTime.now().millisecondsSinceEpoch}',
      );

      print("Adding monthly review...");
      addEventWithRecurring(reviewEvent, eventController, resolveEventColor);

      // Non-recurring event for comparison
      final meetingStart = DateTime(now.year, now.month, now.day, 16, 0);
      final meetingEnd = meetingStart.add(const Duration(hours: 1));

      final oneTimeEvent = ExtendedCalendarEventData(
        title: "Client Presentation",
        date: DateTime(now.year, now.month, now.day),
        startTime: meetingStart,
        endTime: meetingEnd,
        description: "One-time client presentation",
        priority: Priority.high,
        project: 'Work',
        recurring: RecurringType.none,
        color: resolveEventColor(project: 'Work', priority: Priority.high),
        seriesId: 'client-${DateTime.now().millisecondsSinceEpoch}',
      );

      print("Adding one-time client presentation...");
      addEventWithRecurring(oneTimeEvent, eventController, resolveEventColor);
    } catch (e, stackTrace) {
      print('Error creating sample events: $e');
      print('Stack trace: $stackTrace');
    }
  }

  void addEventWithRecurring(
    ExtendedCalendarEventData event,
    EventController eventController,
    Color Function({String? project, required Priority priority}) resolveEventColor, {
    RecurringType? overrideRecurring,
  }) {
    try {
      final recurrence = overrideRecurring ?? event.recurring;
      final color = resolveEventColor(
        project: event.project,
        priority: event.priority,
      );

      print("---- Adding Event ----");
      print("Title: ${event.title}");
      print("Date: ${event.date}");
      print("StartTime: ${event.startTime}");
      print("EndTime: ${event.endTime}");
      print("Recurring: $recurrence");
      print("SeriesId: ${event.seriesId}");

      // Validate the event data before adding
      if (event.startTime == null || event.endTime == null) {
        print("ERROR: Event has null startTime or endTime");
        return;
      }

      if (event.startTime!.isAfter(event.endTime!)) {
        print("ERROR: Event startTime is after endTime");
        return;
      }

      // Create all events as NON-RECURRING to avoid library bugs
      // We'll manually create the recurring instances
      final baseEvent = ExtendedCalendarEventData(
        title: event.title,
        description: event.description ?? '',
        date: event.date,
        startTime: event.startTime!,
        endTime: event.endTime!,
        color: color,
        priority: event.priority,
        project: event.project,
        recurring: RecurringType.none, // Always set to none to avoid library bugs
        seriesId: event.seriesId,
        task: event.task,
        event: event.event,
      );

      // Add the base event
      eventController.add(baseEvent);
      print("Base event added successfully");

      // For non-recurring events, we're done
      if (recurrence == RecurringType.none) {
        print("No recurrence. Done.");
        return;
      }

      // Generate recurring instances manually
      print("Generating recurring instances manually...");
      _generateManualRecurringEvents(baseEvent, recurrence, eventController);
    } catch (e, stackTrace) {
      print("ERROR in addEventWithRecurring: $e");
      print("StackTrace: $stackTrace");
    }
  }

  void _generateManualRecurringEvents(
    ExtendedCalendarEventData baseEvent,
    RecurringType recurrence,
    EventController eventController,
  ) {
    try {
      const maxDaysAhead = 365;
      const maxRecurringEvents = 50;

      final baseDate = baseEvent.date;
      final baseStart = baseEvent.startTime!;
      final baseEnd = baseEvent.endTime!;
      final seriesId = baseEvent.seriesId;

      int i = 1;
      int addedCount = 0;

      while (addedCount < maxRecurringEvents) {
        DateTime nextDate;
        DateTime nextStart;
        DateTime nextEnd;

        switch (recurrence) {
          case RecurringType.daily:
            nextDate = baseDate.add(Duration(days: i));
            nextStart = baseStart.add(Duration(days: i));
            nextEnd = baseEnd.add(Duration(days: i));
            break;

          case RecurringType.weekly:
            nextDate = baseDate.add(Duration(days: i * 7));
            nextStart = baseStart.add(Duration(days: i * 7));
            nextEnd = baseEnd.add(Duration(days: i * 7));
            break;

          case RecurringType.monthly:
            nextDate = _addMonths(baseDate, i);
            nextStart = _addMonths(baseStart, i);
            nextEnd = _addMonths(baseEnd, i);
            break;

          case RecurringType.yearly:
            nextDate = DateTime(
              baseDate.year + i,
              baseDate.month,
              baseDate.day,
            );
            nextStart = DateTime(
              baseStart.year + i,
              baseStart.month,
              baseStart.day,
              baseStart.hour,
              baseStart.minute,
            );
            nextEnd = DateTime(
              baseEnd.year + i,
              baseEnd.month,
              baseEnd.day,
              baseEnd.hour,
              baseEnd.minute,
            );
            break;

          case RecurringType.none:
            return; // Should not reach here
        }

        // Check if we've gone too far ahead
        if (nextDate.difference(baseDate).inDays > maxDaysAhead) {
          break;
        }

        // Create recurring event instance - IMPORTANT: Set recurring to NONE
        final recurringEvent = ExtendedCalendarEventData(
          title: "${baseEvent.title}", // Keep original title
          description: baseEvent.description,
          date: nextDate,
          startTime: nextStart,
          endTime: nextEnd,
          color: baseEvent.color,
          priority: baseEvent.priority,
          project: baseEvent.project,
          recurring: RecurringType.none, // CRITICAL: Set to none to avoid library bug
          seriesId: seriesId, // Same series ID for all instances
          task: baseEvent.task,
          event: baseEvent.event,
        );

        eventController.add(recurringEvent);
        addedCount++;
        i++;
      }

      print("Added $addedCount recurring instances");
    } catch (e, stackTrace) {
      print("ERROR in _generateManualRecurringEvents: $e");
      print("StackTrace: $stackTrace");
    }
  }

  // Helper method to add months safely
  DateTime _addMonths(DateTime date, int months) {
    try {
      int newYear = date.year;
      int newMonth = date.month + months;

      while (newMonth > 12) {
        newYear++;
        newMonth -= 12;
      }

      while (newMonth < 1) {
        newYear--;
        newMonth += 12;
      }

      // Handle day overflow (e.g., Jan 31 + 1 month should be Feb 28/29)
      int newDay = date.day;
      int daysInNewMonth = DateTime(newYear, newMonth + 1, 0).day;
      if (newDay > daysInNewMonth) {
        newDay = daysInNewMonth;
      }

      return DateTime(
        newYear,
        newMonth,
        newDay,
        date.hour,
        date.minute,
        date.second,
        date.millisecond,
        date.microsecond,
      );
    } catch (e) {
      print("Error in _addMonths: $e");
      return date; // Return original date if calculation fails
    }
  }

  void deleteAllOccurrences(
    BuildContext context,
    String seriesId,
    EventController eventController,
    VoidCallback onRefresh,
  ) {
    // Count how many events will be deleted
    final eventsToDelete = eventController.allEvents
        .whereType<ExtendedCalendarEventData>()
        .where((e) => e.seriesId == seriesId)
        .toList();

    if (eventsToDelete.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No events found with this series ID.')),
      );
      return;
    }

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recurring Series'),
        content: Text(
          'Are you sure you want to delete all ${eventsToDelete.length} occurrences of this recurring event?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);

              // Remove all events with this seriesId
              eventController.removeWhere(
                (e) => e is ExtendedCalendarEventData && e.seriesId == seriesId,
              );

              onRefresh(); // Refresh the UI

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Deleted ${eventsToDelete.length} recurring events',
                  ),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Delete All',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}