import 'package:flutter/material.dart';
import 'package:calendar_view/calendar_view.dart';
import '../utils/date_utils.dart';
import '../widgets/event_tile_builder.dart';
import '../widgets/custom_timeline.dart';
import '../dialogs/event_dialogs.dart';

class CalendarViews extends StatelessWidget {
  final bool isInDayView;
  final int selectedIndex;
  final DateTime? selectedDayViewDate;
  final int previousViewIndex;
  final EventController eventController;
  final double heightPerMinute;
  final Function(DateTime) onShowDayView;
  final Function(BuildContext, CalendarEventData) onShowEventDetails;
  final Function(BuildContext, CalendarEventData) onShowEventOptions;
  final Function(BuildContext, {DateTime? selectedDate}) onShowAddEventDialog;
  final VoidCallback onSetState;

  const CalendarViews({
    Key? key,
    required this.isInDayView,
    required this.selectedIndex,
    required this.selectedDayViewDate,
    required this.previousViewIndex,
    required this.eventController,
    required this.heightPerMinute,
    required this.onShowDayView,
    required this.onShowEventDetails,
    required this.onShowEventOptions,
    required this.onShowAddEventDialog,
    required this.onSetState,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _buildCalendarContent(context);
  }

  Widget _buildCalendarContent(BuildContext context) {
    if (isInDayView) {
      return Theme(
        data: Theme.of(context).copyWith(
          // Dark theme for day view
          scaffoldBackgroundColor: const Color(0xFF0F0F0F),
          colorScheme: Theme.of(context).colorScheme.copyWith(
            surface: const Color(0xFF0F0F0F),
            onSurface: Colors.white,
            background: const Color(0xFF0F0F0F),
            onBackground: Colors.white,
          ),
          textTheme: Theme.of(context).textTheme.copyWith(
            bodyLarge: const TextStyle(color: Colors.white),
            bodyMedium: const TextStyle(color: Colors.white),
            bodySmall: const TextStyle(color: Colors.white),
            headlineSmall: const TextStyle(color: Colors.white),
            labelMedium: const TextStyle(color: Colors.white),
            labelSmall: const TextStyle(color: Colors.white),
          ),
        ),
        child: DayView(
          controller: eventController,
          eventTileBuilder: (date, events, boundary, startDuration, endDuration) =>
              MyEventTileBuilder.buildEventTile(
                date,
                events,
                boundary,
                startDuration,
                endDuration,
                onShowEventDetails,
                onShowEventOptions,
                context,
              ),
          initialDay: selectedDayViewDate ?? DateTime.now(),
          onEventTap: (events, date) => onShowEventDetails(context, events.first),
          timeLineBuilder: (date) => CustomTimeline.buildTimeLineBuilder(date),
          dayTitleBuilder: (date) => Container(
            color: const Color(0xFF0F0F0F), // Dark header background
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${CalendarDateUtils.getMonthName(date.month)} ${date.day}, ${date.year}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // White text
                  ),
                ),
                if (previousViewIndex == 0)
                  TextButton.icon(
                    onPressed: () {
                      // This would need to be handled by the parent widget
                      onSetState();
                    },
                    icon: const Icon(Icons.view_week, size: 16, color: Colors.white),
                    label: const Text('Week View', style: TextStyle(color: Colors.white)),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
          heightPerMinute: heightPerMinute,
          backgroundColor: const Color(0xFF0F0F0F), // Dark background for day view
        ),
      );
    } else {
      // Ensure selectedIndex is within valid bounds (0-1 for Month/Week)
      final safeIndex = selectedIndex.clamp(0, 1);
      if (selectedIndex != safeIndex) {
        debugPrint('CalendarViews: Invalid selectedIndex $selectedIndex, clamped to $safeIndex');
      }
      return IndexedStack(
        index: safeIndex,
        children: [
          MonthView(
            controller: eventController,
            cellAspectRatio: 0.7,
            onCellTap: (events, date) => onShowDayView(date),
            onDateLongPress: (date) => EventDialogs.showDayEvents(
              context,
              eventController.getEventsOnDay(date),
              date,
              onShowEventDetails,
              onShowEventOptions,
              onShowAddEventDialog,
            ),
            onEventTap: (event, date) => onShowEventDetails(context, event),
            headerBuilder: (date) => Container(
              color: Theme.of(context).colorScheme.surface, // Use theme surface color
              padding: const EdgeInsets.all(16),
              child: Text(
                "${CalendarDateUtils.getMonthName(date.month)} ${date.year}",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface, // Use theme text color
                ),
              ),
            ),
          ),
          Theme(
            data: Theme.of(context).copyWith(
              // Dark theme for week view
              scaffoldBackgroundColor: const Color(0xFF0F0F0F),
              colorScheme: Theme.of(context).colorScheme.copyWith(
                surface: const Color(0xFF0F0F0F),
                onSurface: Colors.white,
                background: const Color(0xFF0F0F0F),
                onBackground: Colors.white,
              ),
              textTheme: Theme.of(context).textTheme.copyWith(
                bodyLarge: const TextStyle(color: Colors.white),
                bodyMedium: const TextStyle(color: Colors.white),
                bodySmall: const TextStyle(color: Colors.white),
                headlineSmall: const TextStyle(color: Colors.white),
                labelMedium: const TextStyle(color: Colors.white),
                labelSmall: const TextStyle(color: Colors.white),
              ),
            ),
            child: WeekView(
              controller: eventController,
              eventTileBuilder: (date, events, boundary, startDuration, endDuration) =>
                  MyEventTileBuilder.buildEventTile(
                    date,
                    events,
                    boundary,
                    startDuration,
                    endDuration,
                    onShowEventDetails,
                    onShowEventOptions,
                    context,
                  ),
              onDateTap: (date) => onShowDayView(date),
              onEventTap: (events, date) => onShowEventDetails(context, events.first),
              timeLineBuilder: (date) => CustomTimeline.buildTimeLineBuilder(date),
              heightPerMinute: heightPerMinute,
              backgroundColor: const Color(0xFF0F0F0F), // Dark background for week view
            ),
          ),
        ],
      );
    }
  }
}