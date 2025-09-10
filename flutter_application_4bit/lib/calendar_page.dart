import 'package:flutter/material.dart';
import 'package:calendar_view/calendar_view.dart';
import '../models/calendar_models.dart';
import '../models/task_models.dart';
import '../models/scheduling_models.dart';
import '../services/scheduling_service.dart';
import '../widgets/chat_interface.dart';
import '../utils/date_utils.dart';
import '../widgets/event_tile_builder.dart';
import '../widgets/custom_timeline.dart';
import '../dialogs/event_dialogs.dart';
import '../dialogs/event_form_dialog.dart';
import '../widgets/navigation_widgets.dart';
import '../utils/constants.dart';
// Import the tasks source of truth
import 'tasks_updated.dart' as tasks_source;

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

  // Remove local TaskManager - we'll use the source of truth
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
    _initializeServices();

    // Assign initial colors for predefined projects
    for (final p in _projects) {
      _assignProjectColorIfNeeded(p);
    }

    // Map existing projects from tasks source
    for (final project in tasks_source.projects) {
      _assignProjectColorIfNeeded(project.name);
      if (!_projects.contains(project.name)) {
        _projects.add(project.name);
      }
    }

    _addSampleEvents();
    _syncTasksToCalendar();
  }

  Future<void> _initializeServices() async {
    _schedulingService = SchedulingService();
    setState(() {});
  }

  void _assignProjectColorIfNeeded(String project) {
    if (project.isEmpty) return;
    if (_projectColors.containsKey(project)) return;
    _projectColors[project] =
        _projectPalette[_paletteIndex % _projectPalette.length];
    _paletteIndex++;
  }

  // Sync tasks from source of truth to calendar
  void _syncTasksToCalendar() {
    // Clear existing task events first
    _eventController.removeWhere(
      (event) =>
          event is ExtendedCalendarEventData && event.title.startsWith('📋'),
    );

    // Add scheduled tasks to calendar
    for (final task in tasks_source.getTasksList()) {
      if (task.scheduledFor != null && task.status != TaskStatus.completed) {
        _addTaskToCalendar(task);
      }
    }
  }

  Color _resolveEventColor({String? project, required Priority priority}) {
    if (project != null && _projectColors.containsKey(project)) {
      return _projectColors[project]!;
    }
    return priority.color;
  }

  Color _resolveTaskColor(Task task) {
    // Try to find project by ID first
    final project = tasks_source.projects.firstWhere(
      (p) => p.id == task.projectId,
      orElse: () => tasks_source.Project(
        id: '', 
        name: '', 
        color: task.priority.color,
      ),
    );

    if (project.name.isNotEmpty && _projectColors.containsKey(project.name)) {
      return _projectColors[project.name]!;
    }
    return task.priority.color;
  }

  // Get unscheduled tasks from source of truth
  List<Task> _getUnscheduledTasks() {
    return tasks_source
        .getTasksList()
        .where(
          (task) =>
              task.scheduledFor == null &&
              task.status != TaskStatus.completed &&
              task.status != TaskStatus.cancelled,
        )
        .toList();
  }

  // TASK SCHEDULING METHODS

// List<ExtendedCalendarEventData> _getRelevantEvents(List<Task> unscheduledTasks) {
//   if (unscheduledTasks.isEmpty) return [];
  
//   // Calculate total hours needed
//   final totalHours = unscheduledTasks.fold<double>(0, (sum, task) => sum + task.estimatedTime);
//   final bufferMultiplier = 3.0; // 3x buffer for realistic scheduling
//   final hoursNeeded = totalHours * bufferMultiplier;
  
//   final now = DateTime.now();
//   final workingHoursPerDay = 8.0; // 9-5 with 1hr lunch = 7hrs, but account for meetings
//   final effectiveHoursPerDay = 4.0; // Realistic available time per day
  
//   final daysNeeded = (hoursNeeded / effectiveHoursPerDay).ceil();
//   final endDate = now.add(Duration(days: daysNeeded + 2)); // +2 days buffer
  
//   // Filter events to only include those within our scheduling window
//   final relevantEvents = _eventController.allEvents
//       .whereType<ExtendedCalendarEventData>()
//       .where((event) => 
//         event.startTime != null && 
//         event.startTime!.isAfter(now.subtract(Duration(hours: 1))) &&
//         event.startTime!.isBefore(endDate))
//       .toList();
  
//   print('🔍 Scheduling window: ${now.toString().split(' ')[0]} to ${endDate.toString().split(' ')[0]}');
//   print('📊 Tasks need ${totalHours}h, with ${bufferMultiplier}x buffer = ${hoursNeeded}h over ${daysNeeded} days');
//   print('📅 Filtered events: ${relevantEvents.length} (was ${_eventController.allEvents.length})');
  
//   return relevantEvents;
// }

  Future<void> scheduleUnscheduledTasks() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final unscheduledTasks = _getUnscheduledTasks();
      if (unscheduledTasks.isEmpty) {
        _showMessage('No unscheduled tasks to process.');
        return;
      }

      final cutoffDate = DateTime.now().add(Duration(days: 14));
      final existingEvents = _eventController.allEvents
          .whereType<ExtendedCalendarEventData>()
          .where((event) => event.startTime != null && event.startTime!.isBefore(cutoffDate))
          .toList();
      // final existingEvents = _getRelevantEvents(unscheduledTasks);

      final constraints = SchedulingConstraints(
        workingHours: WorkingHours(start: "09:00", end: "17:00"),
        energyPeaks: ["09:00-12:00", "14:00-16:00"],
        breaks: [BreakPeriod(start: "12:00", end: "13:00", name: "Lunch")],
      );

      
      // Add this right before calling the scheduling service
print('🔍 DEBUG: Existing events being sent to AI:');
for (final event in existingEvents) {
  print('  📅 ${event.title}');
  print('     Start: ${event.startTime}');
  print('     End: ${event.endTime}');
  print('     Date: ${event.date}');
}
print('📊 Total existing events: ${existingEvents.length}');

      // Convert tasks for scheduling service
      final result = await _schedulingService.scheduleUnscheduledTasks(
        unscheduledTasks: unscheduledTasks,
        existingEvents: existingEvents,
        constraints: constraints,
      );

      // Update tasks with scheduled times using source of truth functions
      final List<Task> scheduledTasks = [];
      int scheduledCount = 0;

      for (final scheduledTask in result.schedule) {
        try {
          final originalTask = tasks_source.getTasksList().firstWhere(
            (t) => t.id == scheduledTask.id,
          );

          final updatedTask = originalTask.copyWith(
            scheduledFor: scheduledTask.scheduledFor,
          );

          // Use the source of truth save function
          tasks_source.saveTask(updatedTask);
          _addTaskToCalendar(updatedTask);
          scheduledTasks.add(updatedTask);
          scheduledCount++;
        } catch (e) {
          print('Error updating task ${scheduledTask.id}: $e');
        }
      }

      // Refresh the UI to reflect changes
      setState(() {});

      // Show results in bottom sheet instead of snackbar
      if (scheduledCount > 0) {
        await _showSchedulingResults(
          scheduledCount: scheduledCount,
          scheduledTasks: scheduledTasks,
          reasoning: result.reasoning,
        );
      } else {
        _showMessage('No tasks were scheduled. Please try again.');
      }
    } catch (e) {
      // Keep snackbar for error cases
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

    // Get project name for display
    final project = tasks_source.projects.firstWhere(
      (p) => p.id == task.projectId,
      orElse: () => tasks_source.Project(
        id: '', 
        name: 'Tasks', 
        color: task.priority.color,
      ),
    );

    final event = ExtendedCalendarEventData(
      title: '📋 ${task.title}',
      description: task.description ?? '',
      date: scheduledTime,
      startTime: scheduledTime,
      endTime: scheduledTime.add(estimatedDuration),
      color: _resolveTaskColor(task),
      priority: task.priority,
      project: project.name.isNotEmpty ? project.name : 'Tasks',
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

  // Add this method to your CalendarPageState class

  Future<void> _showSchedulingResults({
    required int scheduledCount,
    required List<Task> scheduledTasks,
    required String reasoning,
  }) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SchedulingResultsBottomSheet(
        scheduledCount: scheduledCount,
        scheduledTasks: scheduledTasks,
        reasoning: reasoning,
        onViewCalendar: () {
          Navigator.of(context).pop();
          // Jump to week view to better show scheduled tasks
          setState(() {
            _selectedIndex = 1; // Week view
          });
        },
        onUndoScheduling: () {
          Navigator.of(context).pop();
          _undoLastScheduling(scheduledTasks);
        },
      ),
    );
  }

  // Debug version to see exactly what's happening
// Simple undo method using the fixed copyWith method
Future<void> _undoLastScheduling(List<Task> tasksToUndo) async {
  try {
    int unscheduledCount = 0;
    
    for (final task in tasksToUndo) {
      try {
        // Get the current task from source of truth
        final currentTask = tasks_source.getTasksList().firstWhere(
          (t) => t.id == task.id,
          orElse: () => task,
        );
        
        // Use the fixed copyWith method with clearScheduledFor flag
        final updatedTask = currentTask.copyWith(clearScheduledFor: true);
        
        // Save to source of truth
        tasks_source.saveTask(updatedTask);
        
        // Remove from calendar
        _eventController.removeWhere((event) => 
          event is ExtendedCalendarEventData && 
          event.title == '📋 ${task.title}');
        
        unscheduledCount++;
        print('Unscheduled: ${task.title} (scheduledFor is now null)');
        
      } catch (e) {
        print('Error unscheduling task ${task.title}: $e');
      }
    }
    
    // Force UI refresh
    setState(() {});
    
    // Verify the result
    final unscheduledTasks = _getUnscheduledTasks();
    print('Unscheduled tasks now: ${unscheduledTasks.length}');
    
    _showMessage('Successfully unscheduled $unscheduledCount ${unscheduledCount == 1 ? 'task' : 'tasks'}');
    
  } catch (e) {
    _showMessage('Failed to undo scheduling: $e');
    print('Undo error: $e');
  }
}

  void _showTasksList() {
    final unscheduledTasks = _getUnscheduledTasks();

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
                itemCount: unscheduledTasks.length,
                itemBuilder: (context, index) {
                  final task = unscheduledTasks[index];
                  final project = tasks_source.projects.firstWhere(
                    (p) => p.id == task.projectId,
                    orElse: () => tasks_source.Project(
                      id: '', 
                      name: '', 
                      color: task.priority.color,
                    ),
                  );

                  return Card(
                    child: ListTile(
                      title: Text(task.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${task.estimatedTime}h • ${task.priority.displayName}',
                          ),
                          if (project.name.isNotEmpty)
                            Text('Project: ${project.name}'),
                          if (task.dueDate != null)
                            Text(
                              'Due: ${task.dueDate!.toString().split(' ')[0]}',
                              style: TextStyle(
                                color: task.isOverdue
                                    ? Colors.red
                                    : Colors.orange,
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
                              // Remove from source of truth
                              tasks_source.tasks.removeWhere(
                                (t) => t.id == task.id,
                              );
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
                        // You could show task edit dialog here if needed
                        // For now, we'll just show details
                        _showMessage(
                          'Task: ${task.title}\nDescription: ${task.description ?? "No description"}',
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
                    onPressed: unscheduledTasks.isEmpty
                        ? null
                        : () {
                            Navigator.pop(context);
                            scheduleUnscheduledTasks();
                          },
                    icon: const Icon(Icons.schedule),
                    label: Text(
                      'Schedule All Tasks (${unscheduledTasks.length})',
                    ),
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
  }

  // Chat methods
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
              _eventController.removeWhere(
                (e) => e is ExtendedCalendarEventData && e.seriesId == seriesId,
              );

              setState(() {}); // Refresh the UI

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

  void _addProject(String projectName) {
    setState(() {
      _projects.add(projectName);
      _assignProjectColorIfNeeded(projectName);
      // Also add to the tasks source of truth using the factory method
      final newProject = tasks_source.Project.create(
        name: projectName,
        color: _projectColors[projectName]!,
      );
      tasks_source.projects.add(newProject);
    });
  }

  void _deleteEvent(BuildContext context, CalendarEventData event) {
    EventDialogs.showDeleteConfirmation(context, event, () {
      _eventController.remove(event);
      setState(() {}); // Refresh the UI
    });
  }

  Widget _buildViewToggleButton(String label, bool selected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: selected
            ? Colors.white.withOpacity(0.9)
            : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
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
          foregroundColor: selected ? Colors.blue.shade800 : Colors.white,
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
          // Tasks badge - now using source of truth
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Badge(
                label: Text('${_getUnscheduledTasks().length}'),
                isLabelVisible: _getUnscheduledTasks().isNotEmpty,
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
                _buildViewToggleButton(
                  'Week',
                  !_isInDayView && _selectedIndex == 1,
                ),
                _buildViewToggleButton(
                  'Month',
                  !_isInDayView && _selectedIndex == 0,
                ),
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
          ChatInterface(isVisible: _isChatOpen, onClose: _toggleChat),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Schedule Tasks FAB
          FloatingActionButton(
            heroTag: "schedule_tasks",
            backgroundColor: Colors.purple,
            onPressed: _getUnscheduledTasks().isEmpty
                ? null
                : scheduleUnscheduledTasks,
            child: const Icon(Icons.schedule),
            tooltip: 'Schedule Tasks',
          ),
          const SizedBox(height: 16),
          // Add Task FAB - Navigate to tasks page or add directly
          FloatingActionButton(
            heroTag: "add_task",
            backgroundColor: Colors.orange,
            onPressed: () {
              // Navigate to tasks page or show add task dialog
              Navigator.pushNamed(context, '/tasks').then((_) {
                // Refresh calendar after returning from tasks page
                _syncTasksToCalendar();
                setState(() {});
              });
            },
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
        recurring:
            RecurringType.none, // Always set to none to avoid library bugs
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

  void _generateManualRecurringEvents(
    ExtendedCalendarEventData baseEvent,
    RecurringType recurrence,
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
          recurring:
              RecurringType.none, // CRITICAL: Set to none to avoid library bug
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
// Add this new class before the existing SchedulingResultsBottomSheet class in calendar_page.dart

class ReasoningSection {
  final String title;
  final String content;
  final IconData icon;
  final Color color;

  ReasoningSection({
    required this.title,
    required this.content,
    required this.icon,
    required this.color,
  });

  static List<ReasoningSection> parseReasoning(String reasoning) {
    if (reasoning.isEmpty) return [];

    final sections = <ReasoningSection>[];
    final lines = reasoning.split('\n');
    
    String currentSection = '';
    List<String> currentContent = [];
    
    for (final line in lines) {
      if (line.startsWith('## ')) {
        // Save previous section if exists
        if (currentSection.isNotEmpty && currentContent.isNotEmpty) {
          sections.add(_createReasoningSection(currentSection, currentContent.join('\n')));
        }
        
        // Start new section
        currentSection = line.substring(3).trim();
        currentContent = [];
      } else if (line.trim().isNotEmpty) {
        currentContent.add(line);
      }
    }
    
    // Add the last section
    if (currentSection.isNotEmpty && currentContent.isNotEmpty) {
      sections.add(_createReasoningSection(currentSection, currentContent.join('\n')));
    }
    
    // Fallback: if no structured sections found, create a single general section
    if (sections.isEmpty) {
      sections.add(ReasoningSection(
        title: 'Scheduling Analysis',
        content: reasoning,
        icon: Icons.analytics,
        color: Colors.blue,
      ));
    }
    
    return sections;
  }
  
  static ReasoningSection _createReasoningSection(String title, String content) {
    switch (title.toUpperCase()) {
      case 'SCHEDULING SUMMARY':
        return ReasoningSection(
          title: title,
          content: content,
          icon: Icons.summarize,
          color: Colors.blue,
        );
      case 'TASK PRIORITIZATION':
        return ReasoningSection(
          title: title,
          content: content,
          icon: Icons.priority_high,
          color: Colors.red,
        );
      case 'TIME ALLOCATION STRATEGY':
        return ReasoningSection(
          title: title,
          content: content,
          icon: Icons.access_time,
          color: Colors.orange,
        );
      case 'ENERGY MATCHING':
        return ReasoningSection(
          title: title,
          content: content,
          icon: Icons.battery_charging_full,
          color: Colors.green,
        );
      case 'CONFLICT RESOLUTION':
        return ReasoningSection(
          title: title,
          content: content,
          icon: Icons.warning_amber,
          color: Colors.amber,
        );
      case 'DETAILED DECISIONS':
        return ReasoningSection(
          title: title,
          content: content,
          icon: Icons.list_alt,
          color: Colors.purple,
        );
      default:
        return ReasoningSection(
          title: title,
          content: content,
          icon: Icons.info,
          color: Colors.grey,
        );
    }
  }
}

class SchedulingResultsBottomSheet extends StatefulWidget {
  final int scheduledCount;
  final List<Task> scheduledTasks;
  final String reasoning;
  final VoidCallback onViewCalendar;
  final VoidCallback onUndoScheduling;

  const SchedulingResultsBottomSheet({
    Key? key,
    required this.scheduledCount,
    required this.scheduledTasks,
    required this.reasoning,
    required this.onViewCalendar,
    required this.onUndoScheduling,
  }) : super(key: key);

  @override
  State<SchedulingResultsBottomSheet> createState() => _SchedulingResultsBottomSheetState();
}

class _SchedulingResultsBottomSheetState extends State<SchedulingResultsBottomSheet> {
  final Set<int> _expandedSections = <int>{};

  @override
  Widget build(BuildContext context) {
    final reasoningSections = ReasoningSection.parseReasoning(widget.reasoning);
    
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.green[600],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Scheduling Complete!',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Successfully scheduled ${widget.scheduledCount} ${widget.scheduledCount == 1 ? 'task' : 'tasks'}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Scheduled Tasks Section
                      if (widget.scheduledTasks.isNotEmpty) ...[
                        _buildSectionHeader('Scheduled Tasks', Icons.task_alt, Colors.blue),
                        const SizedBox(height: 8),
                        ...widget.scheduledTasks.map(
                          (task) => _buildTaskItem(context, task),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // AI Reasoning Sections
                      if (reasoningSections.isNotEmpty) ...[
                        _buildSectionHeader('AI Scheduling Analysis', Icons.psychology, Colors.purple),
                        const SizedBox(height: 12),
                        ...reasoningSections.asMap().entries.map((entry) {
                          final index = entry.key;
                          final section = entry.value;
                          return _buildReasoningSection(section, index);
                        }),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                ),
              ),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: widget.onUndoScheduling,
                            icon: const Icon(Icons.undo),
                            label: const Text('Undo Scheduling'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: widget.onViewCalendar,
                            icon: const Icon(Icons.calendar_today),
                            label: const Text('View Calendar'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildReasoningSection(ReasoningSection section, int index) {
    final isExpanded = _expandedSections.contains(index);
    final lines = section.content.split('\n').where((line) => line.trim().isNotEmpty).toList();
    final preview = lines.take(2).join('\n');
    final hasMore = lines.length > 2;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: section.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              section.icon,
              color: section.color,
              size: 18,
            ),
          ),
          title: Text(
            section.title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: section.color,
            ),
          ),
          subtitle: !isExpanded && hasMore
              ? Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    preview,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              : null,
          onExpansionChanged: (expanded) {
            setState(() {
              if (expanded) {
                _expandedSections.add(index);
              } else {
                _expandedSections.remove(index);
              }
            });
          },
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFormattedContent(section.content, section.color),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormattedContent(String content, Color accentColor) {
    final lines = content.split('\n').where((line) => line.trim().isNotEmpty);
    final widgets = <Widget>[];

    for (final line in lines) {
      if (line.trim().startsWith('- ')) {
        // Bullet point
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8, right: 8),
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: Text(
                    line.substring(2).trim(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (line.trim().startsWith('Task:')) {
        // Task detail formatting
        widgets.add(
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: accentColor.withOpacity(0.2)),
            ),
            child: Text(
              line,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      } else {
        // Regular text
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              line.trim(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildTaskItem(BuildContext context, Task task) {
    final scheduledTime = task.scheduledFor!;
    final formattedDate =
        '${_getWeekday(scheduledTime.weekday)}, ${_getMonth(scheduledTime.month)} ${scheduledTime.day}';
    final formattedTime =
        '${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: task.priority.color.withOpacity(0.02),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: task.priority.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  task.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: task.priority.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  task.priority.name.toUpperCase(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: task.priority.color,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '$formattedDate at $formattedTime',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
              Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${task.estimatedTime}h',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          if (task.description != null && task.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              task.description!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  String _getWeekday(int weekday) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[weekday - 1];
  }

  String _getMonth(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}