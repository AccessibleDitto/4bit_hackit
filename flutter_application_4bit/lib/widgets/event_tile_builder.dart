import 'package:flutter/material.dart';
import 'package:calendar_view/calendar_view.dart';
import '../models/calendar_models.dart';

class EventTileBuilder {
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
    if (events.isEmpty) return const SizedBox.shrink();

    final event = events.first;
    final isExtended = event is ExtendedCalendarEventData;
    final duration = endDuration.difference(startDuration);
    final isShort = duration.inMinutes < 60; // Less than 1 hour

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

  static Widget _buildCompactEventTile(CalendarEventData event, bool isExtended) {
    return Row(
      children: [
        if (isExtended) ...[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: PriorityHelper.priorityColors[(event as ExtendedCalendarEventData).priority]!,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1),
            ),
          ),
          const SizedBox(width: 2),
        ],
        Expanded(
          child: Text(
            event.title,
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

  static Widget _buildFullEventTile(CalendarEventData event, bool isExtended) {
    final extendedEvent = isExtended ? event as ExtendedCalendarEventData : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          event.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
        if (isExtended) ...[
          const SizedBox(height: 1),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: PriorityHelper.priorityColors[extendedEvent!.priority]!,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  extendedEvent.project ?? PriorityHelper.priorityLabels[extendedEvent.priority]!,
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
}