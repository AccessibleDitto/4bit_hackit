import 'package:flutter/material.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:flutter_application_4bit/event_parser.dart';
import '../models/calendar_models.dart';
import '../models/task_models.dart';
import '../models/scheduling_models.dart';
import '../services/task_manager_local.dart';
import '../services/scheduling_service.dart';
import '../widgets/task_form_widget.dart';
import '../widgets/chat_interface.dart';
import '../utils/date_utils.dart';
import '../widgets/event_tile_builder.dart';
import '../widgets/custom_timeline.dart';
import '../dialogs/event_dialogs.dart';
import '../dialogs/event_form_dialog.dart';
import '../widgets/navigation_widgets.dart';
import '../utils/constants.dart';

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
  final bool _condensed = true;
  
  // Task Management
  late TaskManager _taskManager;
  late SchedulingService _schedulingService;
  
  // Chat-related variables
  bool _isChatOpen = false;
  bool _isLoading = false;

  // Projects storage & color mapping
  final List<String> _projects = [
    'Personal',
    'Work',
    'Health',
    'Education',
    'Family',
    'Hobbies',
  ];

  final Map<String, Color> _projectColors = {};
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
    _initializeTaskManagement();

    // Assign initial colors for predefined projects
    for (final p in _projects) {
      _assignProjectColorIfNeeded(p);
    }

    _addSampleEvents();
  }

  Future<void> _initializeTaskManagement() async {
    _taskManager = TaskManager();
    _schedulingService = SchedulingService();
    await _taskManager.initialize();
    setState(() {});
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
    return priority.color;
  }

  Color _resolveTaskColor(Task task) {
    if (task.projectId != null && _projectColors.containsKey(task.projectId)) {
      return _projectColors[task.projectId]!;
    }
    return task.priority.color;
  }

  // TASK SCHEDULING METHODS
  Future<void> scheduleUnscheduledTasks() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final unscheduledTasks = _taskManager.getUnscheduledTasks();
      if (unscheduledTasks.isEmpty) {
        _showMessage('No unscheduled tasks to process.');
        return;
      }
      
      final existingEvents = _eventController.allEvents
          .whereType<ExtendedCalendarEventData>()
          .toList();
      
      final constraints = SchedulingConstraints(
        workingHours: WorkingHours(start: "09:00", end: "17:00"),
        energyPeaks: ["09:00-12:00", "14:00-16:00"],
        breaks: [
          BreakPeriod(start: "12:00", end: "13:00", name: "Lunch"),
        ],
      );
      
      final result = await _schedulingService.scheduleUnscheduledTasks(
        unscheduledTasks: unscheduledTasks,
        existingEvents: existingEvents,
        constraints: constraints,
      );
      
      // Update tasks with scheduled times
      int scheduledCount = 0;
      for (final scheduledTask in result.schedule) {
        try {
          final originalTask = _taskManager.tasks.firstWhere(
            (t) => t.id == scheduledTask.id,
          );
          
          final updatedTask = originalTask.copyWith(
            scheduledFor: scheduledTask.scheduledFor,
          );
          
          _taskManager.updateTask(updatedTask);
          _addTaskToCalendar(updatedTask);
          scheduledCount++;
        } catch (e) {
          print('Error updating task ${scheduledTask.id}: $e');
        }
      }
      
      _showMessage('Successfully scheduled $scheduledCount tasks!\n\n${result.reasoning}');
      
    } catch (e) {
      _showMessage('Scheduling failed: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addTaskToCalendar(Task task) {
    if (task.scheduledFor == null) return;
    
    final scheduledTime = task.scheduledFor!;
    final estimatedDuration = Duration(
      minutes: (task.estimatedTime * 60).round(),
    );
    
    final event = ExtendedCalendarEventData(
      title: '📋 ${task.title}',
      description: task.description ?? '',
      date: scheduledTime,
      startTime: scheduledTime,
      endTime: scheduledTime.add(estimatedDuration),
      color: _resolveTaskColor(task),
      priority: task.priority,
      project: task.projectId ?? 'Tasks',
      recurring: RecurringType.none,
    );
    
    _eventController.add(event);
  }
  
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _showTasksList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Unscheduled Tasks',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _taskManager.getUnscheduledTasks().length,
                itemBuilder: (context, index) {
                  final task = _taskManager.getUnscheduledTasks()[index];
                  return Card(
                    child: ListTile(
                      title: Text(task.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${task.estimatedTime}h • ${task.priority.displayName}'),
                          if (task.dueDate != null)
                            Text(
                              'Due: ${task.dueDate!.toString().split(' ')[0]}',
                              style: TextStyle(
                                color: task.isOverdue ? Colors.red : Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (task.isOverdue) 
                            const Icon(Icons.warning, color: Colors.red),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              _taskManager.removeTask(task.id);
                              setState(() {});
                              Navigator.pop(context);
                              _showTasksList();
                            },
                          ),
                        ],
                      ),
                      leading: CircleAvatar(
                        backgroundColor: task.priority.color,
                        child: Text(
                          task.energyRequired.name[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        TaskFormDialog.showTaskDialog(
                          context,
                          existingTask: task,
                          onSaveTask: (updatedTask) {
                            _taskManager.updateTask(updatedTask);
                            setState(() {});
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _taskManager.getUnscheduledTasks().isEmpty ? null : () {
                      Navigator.pop(context);
                      scheduleUnscheduledTasks();
                    },
                    icon: const Icon(Icons.schedule),
                    label: Text('Schedule All Tasks (${_taskManager.getUnscheduledTasks().length})'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
void _addSampleEvents() {
  final now = DateTime.now();
  
  try {
    // weekly Team Meeting
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
      color: _resolveEventColor(project: 'Work', priority: Priority.high),
      seriesId: 'team-meeting-${DateTime.now().millisecondsSinceEpoch}',
    );
    
    print("Adding weekly team meeting...");
    _addEventWithRecurring(teamMeetingEvent);

    // daily Standup (shorter meeting)
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
      color: _resolveEventColor(project: 'Work', priority: Priority.medium),
      seriesId: 'standup-${DateTime.now().millisecondsSinceEpoch}',
    );
    
    print("Adding daily standup...");
    _addEventWithRecurring(standupEvent);

    // monthly Review
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
      color: _resolveEventColor(project: 'Work', priority: Priority.high),
      seriesId: 'review-${DateTime.now().millisecondsSinceEpoch}',
    );
    
    print("Adding monthly review...");
    _addEventWithRecurring(reviewEvent);

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
      color: _resolveEventColor(project: 'Work', priority: Priority.high),
      seriesId: 'client-${DateTime.now().millisecondsSinceEpoch}',
    );
    
    print("Adding one-time client presentation...");
    _addEventWithRecurring(oneTimeEvent);
    
  } catch (e, stackTrace) {
    print('Error creating sample events: $e');
    print('Stack trace: $stackTrace');
  }
}  // Chat methods
  void _toggleChat() {
    setState(() {
      _isChatOpen = !_isChatOpen;
    });
  }

  // Calendar methods
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

  // void _deleteAllOccurrences(String seriesId) {
  //   _eventController.removeWhere(
  //     (e) => e is ExtendedCalendarEventData && e.seriesId == seriesId,
  //   );
  // }
  // Also make sure your _deleteAllOccurrences method shows confirmation:
void _deleteAllOccurrences(String seriesId) {
  // Count how many events will be deleted
  final eventsToDelete = _eventController.allEvents
      .whereType<ExtendedCalendarEventData>()
      .where((e) => e.seriesId == seriesId)
      .toList();
  
  if (eventsToDelete.isEmpty) {
    _showMessage('No events found with this series ID.');
    return;
  }

  // Show confirmation dialog
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Recurring Series'),
      content: Text('Are you sure you want to delete all ${eventsToDelete.length} occurrences of this recurring event?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            
            // Remove all events with this seriesId
            _eventController.removeWhere(
              (e) => e is ExtendedCalendarEventData && e.seriesId == seriesId,
            );
            
            setState(() {}); // Refresh the UI
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Deleted ${eventsToDelete.length} recurring events'),
                duration: const Duration(seconds: 3),
              ),
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Delete All', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

  void _addProject(String projectName) {
    setState(() {
      _projects.add(projectName);
      _assignProjectColorIfNeeded(projectName);
    });
  }

  // void _deleteEvent(BuildContext context, CalendarEventData event) {
  //   EventDialogs.showDeleteConfirmation(
  //     context,
  //     event,
  //     () => _eventController.remove(event),
  //   );
  // }

  void _deleteEvent(BuildContext context, CalendarEventData event) {
  EventDialogs.showDeleteConfirmation(
    context,
    event,
    () {
      _eventController.remove(event);
      setState(() {}); // Refresh the UI
    },
  );
}

  Widget _buildViewToggleButton(String label, bool selected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: selected 
          ? Colors.white.withOpacity(0.9) 
          : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: TextButton(
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
          backgroundColor: Colors.transparent,
          foregroundColor: selected 
            ? Colors.blue.shade800
            : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: const Size(60, 32),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double heightPerMinute = _condensed 
        ? AppConstants.condensedHeightPerMinute 
        : AppConstants.normalHeightPerMinute;

    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          // Tasks badge
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Badge(
                label: Text('${_taskManager.getUnscheduledTasks().length}'),
                isLabelVisible: _taskManager.getUnscheduledTasks().isNotEmpty,
                child: const Icon(Icons.task),
              ),
              onPressed: () => _showTasksList(),
              tooltip: 'Tasks',
            ),
          ),
          
          // View toggle buttons
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildViewToggleButton('Day', _isInDayView),
                _buildViewToggleButton('Week', !_isInDayView && _selectedIndex == 1),
                _buildViewToggleButton('Month', !_isInDayView && _selectedIndex == 0),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Calendar interface
          _buildCalendarView(heightPerMinute),
          
          // Chat interface overlay
          ChatInterface(
            isVisible: _isChatOpen,
            onClose: _toggleChat,
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Schedule Tasks FAB
          FloatingActionButton(
            heroTag: "schedule_tasks",
            backgroundColor: Colors.purple,
            onPressed: _taskManager.getUnscheduledTasks().isEmpty ? null : scheduleUnscheduledTasks,
            child: const Icon(Icons.schedule),
            tooltip: 'Schedule Tasks',
          ),
          const SizedBox(height: 16),
          // Add Task FAB
          FloatingActionButton(
            heroTag: "add_task",
            backgroundColor: Colors.orange,
            onPressed: () => TaskFormDialog.showTaskDialog(
              context,
              onSaveTask: (task) {
                _taskManager.addTask(task);
                setState(() {});
              },
            ),
            child: const Icon(Icons.task_alt),
            tooltip: 'Add Task',
          ),
          const SizedBox(height: 16),
          // Chat FAB
          FloatingActionButton(
            heroTag: "chat",
            backgroundColor: Colors.green,
            onPressed: _toggleChat,
            child: Icon(_isChatOpen ? Icons.chat_bubble : Icons.chat),
          ),
          const SizedBox(height: 16),
          // Add Event FAB
          FloatingActionButton(
            heroTag: "add_event",
            backgroundColor: Colors.blue,
            onPressed: () => _showAddEventDialog(context),
            child: const Icon(Icons.add),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigation(
        selectedIndex: 2,
        isStrictMode: false,
      ),
    );
  }

  Widget _buildCalendarView(double heightPerMinute) {
    if (_isInDayView) {
      return DayView(
        controller: _eventController,
        eventTileBuilder: (date, events, boundary, startDuration, endDuration) =>
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
      );
    } else {
      return IndexedStack(
        index: _selectedIndex,
        children: [
          MonthView(
            controller: _eventController,
            cellAspectRatio: 0.7,
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
          WeekView(
            controller: _eventController,
            eventTileBuilder: (date, events, boundary, startDuration, endDuration) =>
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
            onEventTap: (events, date) => _showEventDetails(context, events.first),
            timeLineBuilder: (date) => CustomTimeline.buildTimeLineBuilder(date),
            heightPerMinute: heightPerMinute,
          ),
        ],
      );
    }
  }

  String _getAppBarTitle() {
    if (_isInDayView) {
      return 'Day View';
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

  // void _addEventWithRecurring(
  //   ExtendedCalendarEventData event, {
  //   RecurringType? overrideRecurring,
  // }) {
  //   final recurrence = overrideRecurring ?? event.recurring;
  //   final color = _resolveEventColor(
  //     project: event.project,
  //     priority: event.priority,
  //   );

  //   final seriesId = event.seriesId;

  //   _eventController.add(
  //     ExtendedCalendarEventData(
  //       title: event.title,
  //       description: event.description,
  //       date: _normalizeDate(event.date),
  //       startTime: event.startTime ?? DateTime.now(),
  //       endTime: event.endTime ?? DateTime.now().add(const Duration(hours: 1)),
  //       color: color,
  //       priority: event.priority,
  //       project: event.project,
  //       recurring: recurrence,
  //       seriesId: seriesId,
  //     ),
  //   );

  //   if (recurrence == RecurringType.none) return;

  //   final baseDate = _normalizeDate(event.date);
  //   final baseStart = event.startTime ?? baseDate;
  //   final baseEnd = event.endTime ?? baseDate.add(Duration(hours: 1));

  //   const maxDaysAhead = AppConstants.maxSchedulingDaysAhead;
  //   int i = 1;
  //   int addedCount = 0;

  //   while (true) {
  //     DateTime nextDate = baseDate;
  //     DateTime nextStart = baseStart;
  //     DateTime nextEnd = baseEnd;

  //     switch (recurrence) {
  //       case RecurringType.daily:
  //         nextDate = _normalizeDate(baseDate.add(Duration(days: i)));
  //         nextStart = baseStart.add(Duration(days: i));
  //         nextEnd = baseEnd.add(Duration(days: i));
  //         break;
  //       case RecurringType.weekly:
  //         nextDate = _normalizeDate(baseDate.add(Duration(days: i * 7)));
  //         nextStart = baseStart.add(Duration(days: i * 7));
  //         nextEnd = baseEnd.add(Duration(days: i * 7));
  //         break;
  //       case RecurringType.monthly:
  //         nextDate = _normalizeDate(CalendarDateUtils.addMonths(baseDate, i));
  //         nextStart = CalendarDateUtils.addMonths(baseStart, i);
  //         nextEnd = CalendarDateUtils.addMonths(baseEnd, i);
  //         break;
  //       case RecurringType.yearly:
  //         nextDate = _normalizeDate(
  //           DateTime(baseDate.year + i, baseDate.month, baseDate.day),
  //         );
  //         nextStart = DateTime(
  //           baseStart.year + i,
  //           baseStart.month,
  //           baseStart.day,
  //           baseStart.hour,
  //           baseStart.minute,
  //         );
  //         nextEnd = DateTime(
  //           baseEnd.year + i,
  //           baseEnd.month,
  //           baseEnd.day,
  //           baseEnd.hour,
  //           baseEnd.minute,
  //         );
  //         break;
  //       case RecurringType.none:
  //         break;
  //     }

  //     if (nextDate.difference(baseDate).inDays > maxDaysAhead) break;

  //     _eventController.add(
  //       ExtendedCalendarEventData(
  //         title: event.title,
  //         description: event.description,
  //         date: nextDate,
  //         startTime: nextStart,
  //         endTime: nextEnd,
  //         color: color,
  //         priority: event.priority,
  //         project: event.project,
  //         recurring: recurrence,
  //         seriesId: seriesId,
  //       ),
  //     );

  //     addedCount++;
  //     i++;
  //     if (i > AppConstants.maxRecurringEvents) break;
  //   }
  // }

void _addEventWithRecurring(
  ExtendedCalendarEventData event, {
  RecurringType? overrideRecurring,
}) {
  try {
    final recurrence = overrideRecurring ?? event.recurring;
    final color = _resolveEventColor(
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
    _eventController.add(baseEvent);
    print("Base event added successfully");

    // For non-recurring events, we're done
    if (recurrence == RecurringType.none) {
      print("No recurrence. Done.");
      return;
    }

    // Generate recurring instances manually
    print("Generating recurring instances manually...");
    _generateManualRecurringEvents(baseEvent, recurrence);
    
  } catch (e, stackTrace) {
    print("ERROR in _addEventWithRecurring: $e");
    print("StackTrace: $stackTrace");
  }
}

void _generateManualRecurringEvents(ExtendedCalendarEventData baseEvent, RecurringType recurrence) {
  try {
    const maxDaysAhead = 365; // AppConstants.maxSchedulingDaysAhead
    const maxRecurringEvents = 50; // AppConstants.maxRecurringEvents
    
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
          nextDate = DateTime(baseDate.year + i, baseDate.month, baseDate.day);
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

      _eventController.add(recurringEvent);
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
}