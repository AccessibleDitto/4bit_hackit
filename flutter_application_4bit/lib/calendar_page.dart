import 'package:flutter/material.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:flutter_application_4bit/event_parser.dart';
import '../models/calendar_models.dart';
import '../utils/date_utils.dart';
import '../widgets/event_tile_builder.dart';
import '../widgets/custom_timeline.dart';
import '../dialogs/event_dialogs.dart';
import '../dialogs/event_form_dialog.dart';
import '../widgets/navigation_widgets.dart';
import 'package:flutter/foundation.dart';

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
  final bool _condensed = true; // Condensed vertical density

  // Projects storage & color mapping
  final List<String> _projects = [
    'Personal',
    'Work',
    'Health',
    'Education',
    'Family',
    'Hobbies',
  ];

  // bool _condensed = false;
  // bool _isInDayView = false;  // Default: start in Month view
  // int _selectedIndex = 0;     // 0 = Month, 1 = Week

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

    _addSampleEvents('[ { "id": "evt1", "title": "MECHANIC 29MAMT PS12", "description": "BLK 47 # 03-03 ONG CHEE KHOON", "date": null, "startTime": "2023-03-14T10:00:00", "endTime": "2023-03-14T11:00:00", "color": "#FFA500", "priority": "medium", "project": null, "recurring": "weekly" }, { "id": "evt2", "title": "ELECTRO 93PHY1 TS12", "description": "BLK 8 # 03-03 FUNG HO WANG", "date": null, "startTime": "2023-03-16T10:00:00", "endTime": "2023-03-16T11:00:00", "color": "#FFA500", "priority": "medium", "project": null, "recurring": "weekly" }, { "id": "evt3", "title": "ECE 23 440BOP PS12", "description": "BLK 8 # 03-01 HOCK CHUE HA", "date": null, "startTime": "2023-03-17T10:00:00", "endTime": "2023-03-17T11:00:00", "color": "#FFA500", "priority": "medium", "project": null, "recurring": "weekly" }, { "id": "evt4", "title": "MECHANIC 29TMFD TS12", "description": "BLK 8 # 03-03 TAN PECK HOR", "date": null, "startTime": "2023-03-13T13:00:00", "endTime": "2023-03-13T14:00:00", "color": "#FFA500", "priority": "medium", "project": null, "recurring": "weekly" }, { "id": "evt5", "title": "CAEM 838CAEM1 T09", "description": "BLK 8 # 03-02 LI ZHONGQIANG", "date": null, "startTime": "2023-03-14T13:00:00", "endTime": "2023-03-14T14:00:00", "color": "#FFA500", "priority": "medium", "project": null, "recurring": "weekly" }, { "id": "evt6", "title": "C_ENG 23 38EGSU PS12", "description": "BLK 8 # 03-04 KOH FOOK LEONG", "date": null, "startTime": "2023-03-17T13:00:00", "endTime": "2023-03-17T14:00:00", "color": "#FFA500", "priority": "medium", "project": null, "recurring": "weekly" }, { "id": "evt7", "title": "PLP_PS1POHBT08", "description": "BLK 51 #07-02 JEANETTE D/O HOUMAYUNE", "date": null, "startTime": "2023-03-15T16:00:00", "endTime": "2023-03-15T17:00:00", "color": "#FFA500", "priority": "medium", "project": null, "recurring": "weekly" }, { "id": "evt8", "title": "PASTORAL PCSOE2 TS12", "description": "BLK 8 # 03-01 HOCK CHUE HA", "date": null, "startTime": "2023-03-17T09:00:00", "endTime": "2023-03-17T10:00:00", "color": "#FFA500", "priority": "medium", "project": null, "recurring": "weekly" } ]');
    
  }

  void _assignProjectColorIfNeeded(String project) {
    if (project.isEmpty) return;
    if (_projectColors.containsKey(project)) return;
    _projectColors[project] =
        _projectPalette[_paletteIndex % _projectPalette.length];
    _paletteIndex++;
  }

  Color _resolveEventColor({String? project, required Priority priority}) {
    if (project != null && _projectColors.containsKey(project)) {
      return _projectColors[project]!;
    }
    return PriorityHelper.priorityColors[priority]!;
  }

  void _addSampleEvents(jsonString) {
    final now = DateTime.now();
    // final events = parseEventsFromJson(jsonString);

    // // Add each event using your existing method
    // for (final event in events) {
    //   _addEventWithRecurring(event);
    // }
    // Use _addEventWithRecurring() instead of _eventController.add()
    _addEventWithRecurring(
      ExtendedCalendarEventData(
        title: "Team Meeting",
        date: now,
        startTime: DateTime(now.year, now.month, now.day, now.hour, 0),
        endTime: DateTime(
          now.year,
          now.month,
          now.day,
          now.hour,
          0,
        ).add(const Duration(hours: 1)),
        description: "Weekly team sync",
        priority: Priority.high,
        project: 'Work',
        recurring: RecurringType.weekly,
        color: _resolveEventColor(project: 'Work', priority: Priority.high),
      ),
    );

    final tmr = now.add(const Duration(days: 1));

    _addEventWithRecurring(
      ExtendedCalendarEventData(
        title: "Lunch with Client",
        date: tmr,
        startTime: DateTime(tmr.year, tmr.month, tmr.day, 12, 0),
        endTime: DateTime(tmr.year, tmr.month, tmr.day, 13, 0),
        description: "Business lunch meeting",
        priority: Priority.medium,
        project: 'Work',
        recurring: RecurringType.none,
        color: _resolveEventColor(project: 'Work', priority: Priority.medium),
      ),
    );
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
      _deleteAllOccurrences,
      // resolveEventColor: _resolveEventColor,
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
      onDeleteSeries: _deleteAllOccurrences,
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
      onDeleteSeries: _deleteAllOccurrences,
      resolveEventColor: _resolveEventColor,
    );
  }

  void _deleteAllOccurrences(String seriesId) {
    _eventController.removeWhere(
      (e) => e is ExtendedCalendarEventData && e.seriesId == seriesId,
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

  Widget _buildViewToggleButton(String label, bool selected) {
    return TextButton(
      onPressed: () {
        setState(() {
          if (label == 'Day') {
            _isInDayView = true;
          } else {
            _isInDayView = false;
            _selectedIndex = (label == 'Week') ? 1 : 0;
          }
        });
      },
      style: TextButton.styleFrom(
        backgroundColor: selected ? Colors.white.withOpacity(0.2) : null,
        foregroundColor: Colors.white,
      ),
      child: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double heightPerMinute = _condensed
        ? 0.6
        : 1.2; // smaller => more condensed

    // return Scaffold(
    //   appBar: AppBar(
    //     title: Text(_getAppBarTitle()),
    //     backgroundColor: Colors.blue,
    //     foregroundColor: Colors.white,
    //     leading: _isInDayView
    //         ? IconButton(
    //             icon: const Icon(Icons.arrow_back),
    //             onPressed: _exitDayView,
    //           )
    //         : null,
    //     actions: [
    //       IconButton(
    //         tooltip: _condensed ? 'Normal density' : 'Condensed density',
    //         icon: Icon(_condensed ? Icons.expand : Icons.compress),
    //         onPressed: () => setState(() => _condensed = !_condensed),
    //       ),
    //       IconButton(
    //         tooltip: 'Add Event',
    //         icon: const Icon(Icons.add),
    //         onPressed: () => _showAddEventDialog(context),
    //       ),
    //     ],
    //   ),
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        // leading: _isInDayView
        //     ? IconButton(
        //         icon: const Icon(Icons.arrow_back),
        //         onPressed: _exitDayView,
        //       )
        //     : null,
        actions: [
          // View toggle buttons inside AppBar
          Row(
            children: [
              _buildViewToggleButton('Day', _isInDayView),
              _buildViewToggleButton(
                'Week',
                !_isInDayView && _selectedIndex == 1,
              ),
              Padding(
                padding: const EdgeInsets.only(
                  right: 8.0,
                ), // 8 pixels right margin
                child: _buildViewToggleButton(
                  'Month',
                  !_isInDayView && _selectedIndex == 0,
                ),
              ),
            ],
          ),
          // IconButton(
          //   tooltip: _condensed ? 'Normal density' : 'Condensed density',
          //   icon: Icon(_condensed ? Icons.expand : Icons.compress),
          //   onPressed: () => setState(() => _condensed = !_condensed),
          // ),
          // IconButton(
          //   tooltip: 'Add Event',
          //   icon: const Icon(Icons.add),
          //   onPressed: () => _showAddEventDialog(context),
          // ),
        ],
      ),

      body: _isInDayView
          ? DayView(
              controller: _eventController,
              eventTileBuilder:
                  (date, events, boundary, startDuration, endDuration) =>
                      MyEventTileBuilder.buildEventTile(
                        date,
                        events,
                        boundary,
                        startDuration,
                        endDuration,
                        _showEventDetails,
                        _showEventOptions,
                        context,
                      ),
              initialDay: _selectedDayViewDate ?? DateTime.now(),
              onEventTap: (events, date) =>
                  _showEventDetails(context, events.first),
              timeLineBuilder: (date) =>
                  CustomTimeline.buildTimeLineBuilder(date),
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

                LayoutBuilder(
                  builder: (context, constraints) {
                    // Total rows = 6 for full month view (to cover all possible days)
                    // double totalRows = 8; 
                    // double cellHeight = constraints.maxHeight / totalRows;
                    // double cellWidth = constraints.maxWidth / 7; // 7 columns (days in a week)
                    
                    // double dynamicAspectRatio = cellWidth / cellHeight;

                    return MonthView( // Month View
                        controller: _eventController,
                        cellAspectRatio: 0.7,
                        // cellAspectRatio: dynamicAspectRatio,
                        onCellTap: (events, date) => _showDayView(date),
                        onDateLongPress: (date) => EventDialogs.showDayEvents(
                          context,
                          _eventController.getEventsOnDay(date),
                          date,
                          _showEventDetails,
                          _showEventOptions,
                          _showAddEventDialog,
                        ),
                        onEventTap: (event, date) =>
                            _showEventDetails(context, event),
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
                      );
                  },
                ),

                // Week View
                WeekView(
                  controller: _eventController,
                  eventTileBuilder:
                      (date, events, boundary, startDuration, endDuration) =>
                          MyEventTileBuilder.buildEventTile(
                            date,
                            events,
                            boundary,
                            startDuration,
                            endDuration,
                            _showEventDetails,
                            _showEventOptions,
                            context,
                          ),
                  onDateTap: (date) => _showDayView(date),
                  onEventTap: (events, date) =>
                      _showEventDetails(context, events.first),
                  timeLineBuilder: (date) =>
                      CustomTimeline.buildTimeLineBuilder(date),
                  heightPerMinute: heightPerMinute,
                ),
              ],
            ),
      // bottomNavigationBar: _isInDayView
      //     ? null
      //     : BottomNavigationBar(
      //         currentIndex: _selectedIndex,
      //         onTap: (index) => setState(() => _selectedIndex = index),
      //         items: const [
      //           BottomNavigationBarItem(
      //             icon: Icon(Icons.calendar_month),
      //             label: 'Month',
      //           ),
      //           BottomNavigationBarItem(
      //             icon: Icon(Icons.view_week),
      //             label: 'Week',
      //           ),
      //         ],
      //       ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () => _showAddEventDialog(context),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigation(
        selectedIndex: 2,
        isStrictMode: false,
      ),
    );
  }

  String _getAppBarTitle() {
    if (_isInDayView) {
      final date = _selectedDayViewDate ?? DateTime.now();
      return 'Day View';
      // return 'Day View - ${CalendarDateUtils.getMonthName(date.month)} ${date.day}';
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
  void _addEventWithRecurring(
    ExtendedCalendarEventData event, {
    RecurringType? overrideRecurring,
  }) {
    final recurrence = overrideRecurring ?? event.recurring;
    final color = _resolveEventColor(
      project: event.project,
      priority: event.priority,
    );

    final seriesId = event.seriesId; // <-- Capture seriesId for all occurrences

    print("---- Adding Event ----");
    print(
      "Base event: ${event.title}, Date: ${event.date}, Recurring: $recurrence",
    );

    // Add base event
    _eventController.add(
      ExtendedCalendarEventData(
        title: event.title,
        description: event.description,
        date: _normalizeDate(event.date),
        startTime: event.startTime ?? DateTime.now(),
        endTime: event.endTime ?? DateTime.now().add(const Duration(hours: 1)),
        color: color,
        priority: event.priority,
        project: event.project,
        recurring: recurrence,
        seriesId: seriesId, // <-- Assign seriesId
      ),
    );

    if (recurrence == RecurringType.none) {
      print("No recurrence. Only base event added.");
      return;
    }

    // Add recurrences
    final baseDate = _normalizeDate(event.date);
    final baseStart = event.startTime ?? baseDate;
    final baseEnd = event.endTime ?? baseDate.add(Duration(hours: 1));

    const maxDaysAhead = 365;
    int i = 1;
    int addedCount = 0;

    while (true) {
      DateTime nextDate = baseDate;
      DateTime nextStart = baseStart;
      DateTime nextEnd = baseEnd;

      switch (recurrence) {
        case RecurringType.daily:
          nextDate = _normalizeDate(baseDate.add(Duration(days: i)));
          nextStart = baseStart.add(Duration(days: i));
          nextEnd = baseEnd.add(Duration(days: i));
          break;
        case RecurringType.weekly:
          nextDate = _normalizeDate(baseDate.add(Duration(days: i * 7)));
          nextStart = baseStart.add(Duration(days: i * 7));
          nextEnd = baseEnd.add(Duration(days: i * 7));
          break;
        case RecurringType.monthly:
          nextDate = _normalizeDate(CalendarDateUtils.addMonths(baseDate, i));
          nextStart = CalendarDateUtils.addMonths(baseStart, i);
          nextEnd = CalendarDateUtils.addMonths(baseEnd, i);
          break;
        case RecurringType.yearly:
          nextDate = _normalizeDate(
            DateTime(baseDate.year + i, baseDate.month, baseDate.day),
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
          break;
      }

      if (nextDate.difference(baseDate).inDays > maxDaysAhead) {
        print("Reached max recurrence range. Breaking loop.");
        break;
      }

      _eventController.add(
        ExtendedCalendarEventData(
          title: event.title,
          description: event.description,
          date: nextDate,
          startTime: nextStart,
          endTime: nextEnd,
          color: color,
          priority: event.priority,
          project: event.project,
          // recurring: RecurringType.none, // individual event was previously marked as non-recurring
          recurring: recurrence, // <-- Keep same recurrence type,
          seriesId: seriesId, // <-- Keep same seriesId
        ),
      );

      addedCount++;
      i++;
      if (i > 400) break;
    }

    print("Total recurring events added: $addedCount");
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
