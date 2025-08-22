// pubspec.yaml dependencies:
// dependencies:
//   flutter:
//     sdk: flutter
//   calendar_view: ^1.0.4

import 'package:flutter/material.dart';
import 'package:calendar_view/calendar_view.dart';

void main() {
  runApp(MyApp());
}

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
          color: color ?? Colors.blue, // <-- Ensure non-null Color
        );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calendar CRUD App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const CalendarPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

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
              eventTileBuilder: _eventTileBuilder,
              initialDay: _selectedDayViewDate!,
              onEventTap: (events, date) => _showEventDetails(context, events.first),
              timeLineBuilder: (date) => _customTimeLineBuilder(date),
              dayTitleBuilder: (date) => Container(
                color: Colors.blue.shade50,
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${_getMonthName(date.month)} ${date.day}, ${date.year}",
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
                  onDateLongPress: (date) => _showDayEvents(context, _eventController.getEventsOnDay(date), date),
                  onEventTap: (event, date) => _showEventDetails(context, event),
                  headerBuilder: (date) => Container(
                    color: Colors.blue.shade50,
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      "${_getMonthName(date.month)} ${date.year}",
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
                  eventTileBuilder: _eventTileBuilder,
                  onDateTap: (date) => _showDayView(date),
                  onEventTap: (events, date) => _showEventDetails(context, events.first),
                  timeLineBuilder: (date) => _customTimeLineBuilder(date),
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
      return 'Day View - ${_getMonthName(_selectedDayViewDate!.month)} ${_selectedDayViewDate!.day}';
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

  Widget _eventTileBuilder(DateTime date, List<CalendarEventData<Object?>> events, Rect boundary, DateTime startDuration, DateTime endDuration) {
    if (events.isEmpty) return const SizedBox.shrink();

    final event = events.first;
    final isExtended = event is ExtendedCalendarEventData;
    final duration = endDuration.difference(startDuration);
    final isShort = duration.inMinutes < 60; // Less than 1 hour

    return GestureDetector(
      onTap: () => _showEventDetails(context, event),
      onLongPress: () => _showEventOptions(context, event),
      child: Container(
        decoration: BoxDecoration(
          color: event.color ?? Colors.blue,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white, width: 1),
        ),
        padding: const EdgeInsets.all(2),
        child: isShort ? _buildCompactEventTile(event, isExtended) : _buildFullEventTile(event, isExtended),
      ),
    );
  }

  Widget _buildCompactEventTile(CalendarEventData event, bool isExtended) {
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

  Widget _buildFullEventTile(CalendarEventData event, bool isExtended) {
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

  void _showDayEvents(BuildContext context, List<CalendarEventData<Object?>> events, DateTime date) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${_getMonthName(date.month)} ${date.day}, ${date.year}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (events.isEmpty)
                const Text("No events for this day")
              else
                ...events.map((event) => ListTile(
                      title: Text(event.title),
                      subtitle: Text(event.description ?? ''),
                      leading: CircleAvatar(
                        backgroundColor: event.color ?? Colors.blue,
                        radius: 8,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _showEventDetails(context, event);
                      },
                      onLongPress: () {
                        Navigator.pop(context);
                        _showEventOptions(context, event);
                      },
                    )),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showAddEventDialog(context, selectedDate: date);
                },
                icon: const Icon(Icons.add),
                label: const Text("Add Event"),
              ),
            ],
          ),
        ),
      ),
    );
  }

void _showEventDetails(BuildContext context, CalendarEventData event) {
  final extendedEvent = event is ExtendedCalendarEventData ? event : null;

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(16, 16, 0, 0),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                event.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: 380,
            maxWidth: 360,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (event.description?.isNotEmpty == true) ...[
                  _buildSectionTitle("Description"),
                  Text(event.description!),
                  const SizedBox(height: 12),
                ],
                _buildSectionTitle("Date"),
                Text("${_getMonthName(event.date.month)} ${event.date.day}, ${event.date.year}"),
                const SizedBox(height: 12),
                _buildSectionTitle("Time"),
                Text("${_formatTime(event.startTime!)} - ${_formatTime(event.endTime!)}"),
                if (extendedEvent != null) ...[
                  const SizedBox(height: 12),
                  _buildSectionTitle("Priority"),
                  Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: PriorityHelper.priorityColors[extendedEvent.priority],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(PriorityHelper.priorityLabels[extendedEvent.priority]!),
                    ],
                  ),
                  if (extendedEvent.project != null) ...[
                    const SizedBox(height: 12),
                    _buildSectionTitle("Project"),
                    Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: _projectColors[extendedEvent.project] ?? Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            extendedEvent.project!,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (extendedEvent.recurring != RecurringType.none) ...[
                    const SizedBox(height: 12),
                    _buildSectionTitle("Recurring"),
                    Text(RecurringHelper.recurringLabels[extendedEvent.recurring]!),
                  ],
                ],
              ],
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildActionButton(
                icon: Icons.edit,
                text: "Edit",
                color: Colors.blue,
                onPressed: () {
                  Navigator.pop(context);
                  _showEditEventDialog(context, event);
                },
              ),
              _buildActionButton(
                icon: Icons.delete,
                text: "Delete",
                color: Colors.red,
                onPressed: () {
                  Navigator.pop(context);
                  _deleteEvent(context, event);
                },
              ),
            ],
          ),
        ],
      );
    },
  );
}

/// Section Title Widget
Widget _buildSectionTitle(String text) {
  return Text(
    text,
    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
  );
}

/// Custom Action Button (Rounded, Filled)
Widget _buildActionButton({
  required IconData icon,
  required String text,
  required Color color,
  required VoidCallback onPressed,
}) {
  return Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.1),
          foregroundColor: color,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: color.withOpacity(0.3)),
          ),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    ),
  );
}

// String _getMonthName(int month) {
//   const months = [
//     '', 'January', 'February', 'March', 'April', 'May', 'June',
//     'July', 'August', 'September', 'October', 'November', 'December'
//   ];
//   return months[month];
// }

// String _formatTime(DateTime time) {
//   return TimeOfDay.fromDateTime(time).format(context);
// }

  void _showEventOptions(BuildContext context, CalendarEventData event) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text("Edit Event"),
                onTap: () {
                  Navigator.pop(context);
                  _showEditEventDialog(context, event);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text("Delete Event", style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteEvent(context, event);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddEventDialog(BuildContext context, {DateTime? selectedDate}) {
    _showEventDialog(context, isEdit: false, selectedDate: selectedDate);
  }

  void _showEditEventDialog(BuildContext context, CalendarEventData event) {
    _showEventDialog(context, isEdit: true, event: event);
  }

  

  void _showEventDialog(BuildContext context,
      {required bool isEdit, CalendarEventData? event, DateTime? selectedDate}) {
    final isExtended = event is ExtendedCalendarEventData;
    final extendedEvent = isExtended ? event as ExtendedCalendarEventData : null;

    final titleController = TextEditingController(text: event?.title ?? '');
    final descriptionController = TextEditingController(text: event?.description ?? '');
    DateTime eventDate = event?.date ?? selectedDate ?? DateTime.now();
    TimeOfDay startTime = TimeOfDay.fromDateTime(event?.startTime ?? DateTime.now());
    int durationMinutes = event != null ? event.endTime!.difference(event.startTime!).inMinutes : 60;

    Priority selectedPriority = extendedEvent?.priority ?? Priority.medium;
    String? selectedProject = extendedEvent?.project;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEdit ? 'Edit Event' : 'Add Event'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Event Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Date: '),
                    TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: eventDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                        );
                        if (date != null) {
                          setState(() => eventDate = date);
                        }
                      },
                      child: Text("${_getMonthName(eventDate.month)} ${eventDate.day}, ${eventDate.year}"),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Start: '),
                    TextButton(
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: startTime,
                        );
                        if (time != null) {
                          setState(() => startTime = time);
                        }
                      },
                      child: Text(startTime.format(context)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Duration: '),
                    Expanded(
                      child: Slider(
                        value: durationMinutes.toDouble(),
                        min: 15,
                        max: 480, // 8 hours
                        divisions: 31, // 15 min intervals
                        label: '${(durationMinutes / 60).toStringAsFixed(1)} hours',
                        onChanged: (value) {
                          setState(() => durationMinutes = value.round());
                        },
                      ),
                    ),
                    Text('${(durationMinutes / 60).toStringAsFixed(1)}h'),
                  ],
                ),
                const SizedBox(height: 16),

                // Priority Selection
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Priority:', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<Priority>(
                  value: selectedPriority,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: Priority.values
                      .map(
                        (priority) => DropdownMenuItem(
                          value: priority,
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: PriorityHelper.priorityColors[priority],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(PriorityHelper.priorityLabels[priority]!),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => selectedPriority = value!),
                ),
                const SizedBox(height: 16),

                // Project Selection (drives color)
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Project (controls color):', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        value: selectedProject,
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        hint: const Text('Select Project'),
                        items: [
                          const DropdownMenuItem<String?>(value: null, child: Text('No Project')),
                          ..._projects.map(
                            (project) => DropdownMenuItem(
                              value: project,
                              child: Row(
                                children: [
                                  Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: _projectColors[project],
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(project),
                                ],
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) => setState(() => selectedProject = value),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Add Project',
                      icon: const Icon(Icons.add),
                      onPressed: () => _showAddProjectDialog(context, setState),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Recurring Selection
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Recurring:', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<RecurringType>(
                  value: (extendedEvent?.recurring ?? RecurringType.none),
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: RecurringType.values
                      .map((recurring) => DropdownMenuItem(
                            value: recurring,
                            child: Text(RecurringHelper.recurringLabels[recurring]!),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      // if editing, reflect chosen recurring; if adding, we'll create based on this
                      // We don't mutate extendedEvent directly; we use value on save.
                    });
                  },
                ),

                const SizedBox(height: 16),

                // Color preview (read-only; controlled by project)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      const Text('Event Color (from Project): ', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: _resolveEventColor(project: selectedProject, priority: selectedPriority),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isEdit)
                  _buildActionButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteEvent(context, event!);
                    },
                    text: "Delete",
                    icon: Icons.delete,
                    color: Colors.red,
                  ),

            _buildActionButton(
              onPressed: () {
                if (titleController.text.isEmpty) return;

                final startDateTime = DateTime(
                  eventDate.year,
                  eventDate.month,
                  eventDate.day,
                  startTime.hour,
                  startTime.minute,
                );
                final endDateTime = startDateTime.add(Duration(minutes: durationMinutes));

                final chosenRecurring = (extendedEvent?.recurring ?? RecurringType.none);
                final currentRecurring = (chosenRecurring == RecurringType.none)
                    ? RecurringType.none
                    : chosenRecurring; // keep as is if editing

                final computedColor =
                    _resolveEventColor(project: selectedProject, priority: selectedPriority);

                final newEvent = ExtendedCalendarEventData(
                  title: titleController.text,
                  description: descriptionController.text.isEmpty ? null : descriptionController.text,
                  date: DateTime(eventDate.year, eventDate.month, eventDate.day),
                  startTime: startDateTime,
                  endTime: endDateTime,
                  color: computedColor,
                  priority: selectedPriority,
                  project: selectedProject,
                  recurring: isEdit ? (extendedEvent?.recurring ?? RecurringType.none) : currentRecurring,
                );

                if (isEdit && event != null) {
                  _eventController.remove(event);
                }

                _addEventWithRecurring(newEvent, overrideRecurring: isEdit ? RecurringType.none : null);
                Navigator.pop(context);
              },
              text: isEdit ? "Update" : "Add",
              icon: isEdit ? Icons.update : Icons.add,
              color: Colors.blue,
              // child: Text(isEdit ? 'Update' : 'Add'),
            ),

              ]
            )

          ],
        ),
      ),
    );
  }

  void _showAddProjectDialog(BuildContext context, StateSetter parentSetState) {
    final projectController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Project'),
        content: TextField(
          controller: projectController,
          decoration: const InputDecoration(
            labelText: 'Project Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = projectController.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  _projects.add(name);
                  _assignProjectColorIfNeeded(name);
                });
                parentSetState(() {}); // Update parent dialog
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
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
          nextDate = _addMonths(baseDate, i);
          nextStart = _addMonths(baseStart, i);
          nextEnd = _addMonths(baseEnd, i);
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

  // Month add helper: keeps day where possible, clamps to month end
  DateTime _addMonths(DateTime dt, int monthsToAdd) {
    final year = dt.year + ((dt.month - 1 + monthsToAdd) ~/ 12);
    final month = ((dt.month - 1 + monthsToAdd) % 12) + 1;
    final day = dt.day;
    final lastDay = _lastDayOfMonth(year, month);
    final clampedDay = day > lastDay ? lastDay : day;
    return DateTime(year, month, clampedDay, dt.hour, dt.minute);
  }

  int _lastDayOfMonth(int year, int month) {
    final beginningNextMonth = (month == 12) ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
    return beginningNextMonth.subtract(const Duration(days: 1)).day;
  }

  void _deleteEvent(BuildContext context, CalendarEventData event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text('Are you sure you want to delete "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _eventController.remove(event);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event deleted')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month];
  }

  String _formatTime(DateTime time) {
    final hour = time.hour == 0 ? 12 : time.hour > 12 ? time.hour - 12 : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  Widget _customTimeLineBuilder(DateTime date) {
    final hour = date.hour;
    final minute = date.minute;

    // Only show hour labels at the top of each hour
    if (minute != 0) {
      return const SizedBox.shrink();
    }

    String timeLabel;
    if (hour == 0) {
      timeLabel = '12AM';
    } else if (hour < 12) {
      timeLabel = '${hour}AM';
    } else if (hour == 12) {
      timeLabel = '12PM';
    } else {
      timeLabel = '${hour - 12}PM';
    }

    return Container(
      width: 50,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 8),
      child: Text(
        timeLabel,
        style: TextStyle(
          fontSize: 10,
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
