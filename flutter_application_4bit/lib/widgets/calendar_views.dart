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
    if (isInDayView) {
      return DayView(
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
          color: Colors.blue.shade50,
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${CalendarDateUtils.getMonthName(date.month)} ${date.day}, ${date.year}",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
              if (previousViewIndex == 0)
                TextButton.icon(
                  onPressed: () {
                    // This would need to be handled by the parent widget
                    onSetState();
                  },
                  icon: const Icon(Icons.view_week, size: 16),
                  label: const Text('Week View'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue.shade800,
                  ),
                ),
            ],
          ),
        ),
        heightPerMinute: heightPerMinute,
      );
    } else {
      return IndexedStack(
        index: selectedIndex,
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
              color: Colors.blue.shade50,
              padding: const EdgeInsets.all(16),
              child: Text(
                "${CalendarDateUtils.getMonthName(date.month)} ${date.year}",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
            ),
          ),
          WeekView(
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
          ),
        ],
      );
    }
  }
}