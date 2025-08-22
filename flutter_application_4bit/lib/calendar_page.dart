import 'package:flutter/material.dart';
import 'package:calendar_view/calendar_view.dart';
import '../models/calendar_models.dart';
import '../utils/date_utils.dart';
import '../widgets/event_tile_builder.dart';
import '../widgets/custom_timeline.dart';
import '../dialogs/event_dialogs.dart';
import '../dialogs/event_form_dialog.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  CalendarPageState createState() => CalendarPageState();
}

class CalendarPageState extends State<CalendarPage> {
  int _selectedIndex = 0; // 0 = Month, 1 = Week
  late EventController _eventController;
  DateTime? _selectedDayViewDate;
  bool _isInDayView = false;
  int _previousViewIndex = 0;
  bool _condensed = false; // Condensed vertical density

  // Projects storage & color mapping
  final List<String> _projects = [
    'Personal',
    'Work',
    'Health',
    'Education',
    'Family',
    'Hobbies',
  ];

  final Map<String, Color> _projectColors = {}; // assigned at init
  final List<Color> _projectPalette = const [
    Color(0xFF1E88E5), // Blue
    Color(0xFF43A047), // Green
    Color(0xFFE53935), // Red
    Color(0xFFFB8C00), // Orange
    Color(0xFF8E24AA), // Purple
    Color(0xFF00897B), // Teal
    Color(0xFF5E35B1), // Deep Purple
    Color(0xFF6D4C41), // Brown
    Color(0xFF7CB342), // Light Green
    Color(0xFF00ACC1), // Cyan
  ];
  int _paletteIndex = 0;

  @override
  void initState() {
    super.initState();
    _eventController = EventController();

    // Assign initial colors for predefined projects
    for (final p in _projects) {
      _assignProjectColorIfNeeded(p);
    }

    _addSampleEvents();
  }

  void _assignProjectColorIfNeeded(String project) {
    if (project.isEmpty) return;
    if (_projectColors.containsKey(project)) return;
    _projectColors[project] = _projectPalette[_paletteIndex % _projectPalette.length];
    _paletteIndex++;
  }

  Color _resolveEventColor({String? project, required Priority priority}) {
    if (project != null && _projectColors.containsKey(project)) {
      return _projectColors[project]!;
    }
    return PriorityHelper.priorityColors[priority]!;
  }

  void _addSampleEvents() {
    // Add some sample events
    final now = DateTime.now();

    _eventController.add(ExtendedCalendarEventData(
      title: "Team Meeting",
      date: now,
      startTime: DateTime(now.year, now.month, now.day, now.hour, 0),
      endTime: DateTime(now.year, now.month, now.day, now.hour, 0).add(const Duration(hours: 1)),
      description: "Weekly team sync",
      priority: Priority.high,
      project: 'Work',
      recurring: RecurringType.weekly,
      color: _resolveEventColor(project: 'Work', priority: Priority.high),
    ));

    final tmr = now.add(const Duration(days: 1));
    _eventController.add(ExtendedCalendarEventData(
      title: "Lunch with Client",
      date: tmr,
      startTime: DateTime(tmr.year, tmr.month, tmr.day, 12, 0),
      endTime: DateTime(tmr.year, tmr.month, tmr.day, 13, 0),
      description: "Business lunch meeting",
      priority: Priority.medium,
      project: 'Work',
      recurring: RecurringType.none,
      color: _resolveEventColor(project: 'Work', priority: Priority.medium),
    ));
  }

  void _showDayView(DateTime date) {
    setState(() {
      _selectedDayViewDate = date;
      _isInDayView = true;
      _previousViewIndex = _selectedIndex;
    });
  }

  void _exitDayView() {
    setState(() {
      _isInDayView = false;
      _selectedDayViewDate = null;
    });
  }

  void _showEventDetails(BuildContext context, CalendarEventData event) {
    EventDialogs.showEventDetails(
      context, 
      event, 
      _projectColors, 
      _showEditEventDialog,
      _deleteEvent,
    );
  }

  void _showEventOptions(BuildContext context, CalendarEventData event) {
    EventDialogs.showEventOptions(
      context, 
      event, 
      _showEditEventDialog,
      _deleteEvent,
    );
  }

  void _showAddEventDialog(BuildContext context, {DateTime? selectedDate}) {
    EventFormDialog.showEventDialog(
      context,
      isEdit: false,
      selectedDate: selectedDate,
      projects: _projects,
      projectColors: _projectColors,
      onAddProject: _addProject,
      onSaveEvent: _addEventWithRecurring,
      onDeleteEvent: (event) => _deleteEvent(context, event),
      resolveEventColor: _resolveEventColor,
    );
  }

  void _showEditEventDialog(BuildContext context, CalendarEventData event) {
    EventFormDialog.showEventDialog(
      context,
      isEdit: true,
      event: event,
      projects: _projects,
      projectColors: _projectColors,
      onAddProject: _addProject,
      onSaveEvent: (newEvent, {overrideRecurring}) {
        _eventController.remove(event);
        _addEventWithRecurring(newEvent, overrideRecurring: overrideRecurring);
      },
      onDeleteEvent: (event) => _deleteEvent(context, event),
      resolveEventColor: _resolveEventColor,
    );
  }

  void _addProject(String projectName) {
    setState(() {
      _projects.add(projectName);
      _assignProjectColorIfNeeded(projectName);
    });
  }

  void _deleteEvent(BuildContext context, CalendarEventData event) {
    EventDialogs.showDeleteConfirmation(
      context, 
      event, 
      () => _eventController.remove(event),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double heightPerMinute = _condensed ? 0.6 : 1.2; // smaller => more condensed

    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: _isInDayView
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _exitDayView,
              )
            : null,
        actions: [
          IconButton(
            tooltip: _condensed ? 'Normal density' : 'Condensed density',
            icon: Icon(_condensed ? Icons.expand : Icons.compress),
            onPressed: () => setState(() => _condensed = !_condensed),
          ),
          IconButton(
            tooltip: 'Add Event',
            icon: const Icon(Icons.add),
            onPressed: () => _showAddEventDialog(context),
          ),
        ],
      ),
      body: _isInDayView
          ? DayView(
              controller: _eventController,
              eventTileBuilder: (date, events, boundary, startDuration, endDuration) => 
                EventTileBuilder.buildEventTile(
                  date, events, boundary, startDuration, endDuration,
                  _showEventDetails, _showEventOptions, context,
                ),
              initialDay: _selectedDayViewDate!,
              onEventTap: (events, date) => _showEventDetails(context, events.first),
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
                    if (_previousViewIndex == 0)
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedIndex = 1;
                            _isInDayView = false;
                            _selectedDayViewDate = null;
                          });
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
            )
          : IndexedStack(
              index: _selectedIndex,
              children: [
                // Month View
                MonthView(
                  controller: _eventController,
                  onCellTap: (events, date) => _showDayView(date),
                  onDateLongPress: (date) => EventDialogs.showDayEvents(
                    context, 
                    _eventController.getEventsOnDay(date), 
                    date,
                    _showEventDetails,
                    _showEventOptions,
                    _showAddEventDialog,
                  ),
                  onEventTap: (event, date) => _showEventDetails(context, event),
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
                // Week View
                WeekView(
                  controller: _eventController,
                  eventTileBuilder: (date, events, boundary, startDuration, endDuration) => 
                    EventTileBuilder.buildEventTile(
                      date, events, boundary, startDuration, endDuration,
                      _showEventDetails, _showEventOptions, context,
                    ),
                  onDateTap: (date) => _showDayView(date),
                  onEventTap: (events, date) => _showEventDetails(context, events.first),
                  timeLineBuilder: (date) => CustomTimeline.buildTimeLineBuilder(date),
                  heightPerMinute: heightPerMinute,
                ),
              ],
            ),
      bottomNavigationBar: _isInDayView
          ? null
          : BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) => setState(() => _selectedIndex = index),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_month),
                  label: 'Month',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.view_week),
                  label: 'Week',
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () => _showAddEventDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  String _getAppBarTitle() {
    if (_isInDayView) {
      return 'Day View - ${CalendarDateUtils.getMonthName(_selectedDayViewDate!.month)} ${_selectedDayViewDate!.day}';
    }
    switch (_selectedIndex) {
      case 0:
        return 'Month View';
      case 1:
        return 'Week View';
      default:
        return 'Calendar';
    }
  }

  // Add event + generate future recurrences (color comes from project)
  void _addEventWithRecurring(ExtendedCalendarEventData event, {RecurringType? overrideRecurring}) {
    final recurrence = overrideRecurring ?? event.recurring;

    // Always ensure color is consistent with current project/priority
    final color = _resolveEventColor(project: event.project, priority: event.priority);
    _eventController.add(ExtendedCalendarEventData(
      title: event.title,
      description: event.description,
      date: event.date,
      startTime: event.startTime,
      endTime: event.endTime,
      color: color,
      priority: event.priority,
      project: event.project,
      recurring: recurrence,
    ));

    if (recurrence == RecurringType.none) return;

    final baseDate = event.date;
    final baseStart = event.startTime!;
    final baseEnd = event.endTime!;

    // Generate up to ~1 year of occurrences (tweak as desired)
    final maxDaysAhead = 365;
    int i = 1;
    while (true) {
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
          nextDate = CalendarDateUtils.addMonths(baseDate, i);
          nextStart = CalendarDateUtils.addMonths(baseStart, i);
          nextEnd = CalendarDateUtils.addMonths(baseEnd, i);
          break;
        case RecurringType.yearly:
          nextDate = DateTime(baseDate.year + i, baseDate.month, baseDate.day);
          nextStart = DateTime(baseStart.year + i, baseStart.month, baseStart.day, baseStart.hour, baseStart.minute);
          nextEnd = DateTime(baseEnd.year + i, baseEnd.month, baseEnd.day, baseEnd.hour, baseEnd.minute);
          break;
        case RecurringType.none:
          return;
      }

      if (nextDate.difference(baseDate).inDays > maxDaysAhead) break;

      _eventController.add(ExtendedCalendarEventData(
        title: event.title,
        description: event.description,
        date: nextDate,
        startTime: nextStart,
        endTime: nextEnd,
        color: color, // same project color
        priority: event.priority,
        project: event.project,
        recurring: RecurringType.none, // instances are not themselves recurring
      ));

      i++;
      if (i > 400) break; // hard cap safety
    }
  }
}