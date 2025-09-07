import 'package:flutter/material.dart';
import 'package:calendar_view/calendar_view.dart';
import '../models/calendar_models.dart';

class MyEventTileBuilder {
  // Step 1: Add debug logging to your event tile builder
static Widget buildEventTile(
  DateTime date,
  List<CalendarEventData<Object?>> events,
  Rect boundary,
  DateTime startDuration,
  DateTime endDuration,
  Function(BuildContext, CalendarEventData) onEventDetails,
  Function(BuildContext, CalendarEventData) onEventOptions,
  BuildContext context,
) {
  // Add debug logging
  print('Building event tile for date: $date');
  print('Events count: ${events.length}');
  
  if (events.isEmpty) {
    print('No events for $date');
    return const SizedBox.shrink();
  }
  
  final event = events.first;
  print('Event title: ${event.title}');
  print('Event type: ${event.runtimeType}');
  print('Event color: ${event.color}');
  
  // Add null safety checks
  if (event.title == null) {
    print('ERROR: Event title is null!');
    return Container(
      color: Colors.red,
      child: const Text('NULL TITLE', style: TextStyle(color: Colors.white)),
    );
  }
  
  final isExtended = event is ExtendedCalendarEventData;
  final duration = endDuration.difference(startDuration);
  final isShort = duration.inMinutes < 60;

  return GestureDetector(
    onTap: () => onEventDetails(context, event),
    onLongPress: () => onEventOptions(context, event),
    child: Container(
      decoration: BoxDecoration(
        color: event.color ?? Colors.blue,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white, width: 1),
      ),
      padding: const EdgeInsets.all(2),
      child: isShort
        ? _buildCompactEventTile(event, isExtended)
        : _buildFullEventTile(event, isExtended),
    ),
  );
}

// Step 2: Add null safety to your compact tile builder
static Widget _buildCompactEventTile(CalendarEventData event, bool isExtended) {
  return Row(
    children: [
      if (isExtended) ...[
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _getSafePriorityColor(event as ExtendedCalendarEventData),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1),
          ),
        ),
        const SizedBox(width: 2),
      ],
      Expanded(
        child: Text(
          event.title ?? 'Untitled Event', // Add null safety
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    ],
  );
}

// Step 3: Add null safety to your full tile builder
static Widget _buildFullEventTile(CalendarEventData event, bool isExtended) {
  final extendedEvent = isExtended ? event as ExtendedCalendarEventData : null;
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        event.title ?? 'Untitled Event', // Add null safety
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
      if (isExtended && extendedEvent != null) ...[
        const SizedBox(height: 1),
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: _getSafePriorityColor(extendedEvent),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                extendedEvent.project ?? 
                _getSafePriorityLabel(extendedEvent) ?? 
                'No Project',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 9,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    ],
  );
}

// Helper methods for safe access
static Color _getSafePriorityColor(ExtendedCalendarEventData event) {
  try {
    return PriorityHelper.priorityColors[event.priority] ?? Colors.blue;
  } catch (e) {
    print('Error getting priority color: $e');
    return Colors.blue;
  }
}

static String? _getSafePriorityLabel(ExtendedCalendarEventData event) {
  try {
    return PriorityHelper.priorityLabels[event.priority];
  } catch (e) {
    print('Error getting priority label: $e');
    return 'Unknown Priority';
  }
}
}