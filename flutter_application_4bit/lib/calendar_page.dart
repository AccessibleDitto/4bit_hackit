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

// Import the split files
import '../services/calendar_task_service.dart';
import '../services/calendar_event_service.dart';
import '../services/chat_tool_service.dart';
import '../widgets/calendar_views.dart';
import '../widgets/scheduling_results_sheet.dart';
// import '../services/scheduling_service.dart';

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

  late SchedulingService _schedulingService;
  late CalendarTaskService _taskService;
  late CalendarEventService _eventService;
  late ChatToolCallingService? _chatToolService; // Add this line

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
    _initializeProjects();
    _eventService.addSampleEvents(_eventController, _resolveEventColor);
    _taskService.syncTasksToCalendar(_eventController);
  }

  Future<void> _initializeServices() async {
  _schedulingService = SchedulingService();
  _taskService = CalendarTaskService();
  _eventService = CalendarEventService();
  
  // Initialize the chat tool calling service
  try {
    _chatToolService = ChatToolCallingService(
      taskService: _taskService,
      eventService: _eventService,
      schedulingService: _schedulingService,
      eventController: _eventController,
      resolveEventColor: _resolveEventColor,
      refreshCallback: () => setState(() {}),
    );
  } catch (e) {
    print('Failed to initialize chat tool service: $e');
    _chatToolService = null; // Fallback to regular chat
  }
  
  setState(() {});
}

  void _initializeProjects() {
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

  // TASK SCHEDULING METHODS
  Future<void> scheduleUnscheduledTasks() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final result = await _taskService.scheduleUnscheduledTasks(
        _schedulingService,
        _eventController,
      );

      if (result.scheduledCount > 0) {
        await _showSchedulingResults(
          scheduledCount: result.scheduledCount,
          scheduledTasks: result.scheduledTasks,
          reasoning: result.reasoning,
        );
      } else {
        _showMessage('No tasks were scheduled. Please try again.');
      }
    } catch (e) {
      _showMessage('Scheduling failed: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

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

  Future<void> _undoLastScheduling(List<Task> tasksToUndo) async {
    final result = await _taskService.undoScheduling(tasksToUndo, _eventController);
    setState(() {});
    _showMessage('Successfully unscheduled ${result} ${result == 1 ? 'task' : 'tasks'}');
  }

  void _showTasksList() {
    final unscheduledTasks = _taskService.getUnscheduledTasks();

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
                  return _taskService.buildTaskListTile(
                    task,
                    onDelete: () {
                      tasks_source.tasks.removeWhere((t) => t.id == task.id);
                      setState(() {});
                      Navigator.pop(context);
                      _showTasksList();
                    },
                    onTap: () {
                      Navigator.pop(context);
                      _showMessage(
                        'Task: ${task.title}\nDescription: ${task.description ?? "No description"}',
                      );
                    },
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
      onSaveEvent: (event, {overrideRecurring}) => _eventService.addEventWithRecurring(
        event,
        _eventController,
        _resolveEventColor,
        overrideRecurring: overrideRecurring,
      ),
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
        _eventService.addEventWithRecurring(
          newEvent,
          _eventController,
          _resolveEventColor,
          overrideRecurring: overrideRecurring,
        );
      },
      onDeleteEvent: (event) => _deleteEvent(context, event),
      onDeleteSeries: _deleteAllOccurrences,
      resolveEventColor: _resolveEventColor,
    );
  }

  void _deleteAllOccurrences(String seriesId) {
    _eventService.deleteAllOccurrences(context, seriesId, _eventController, () => setState(() {}));
  }

  void _addProject(String projectName) {
    setState(() {
      _projects.add(projectName);
      _assignProjectColorIfNeeded(projectName);
      final newProject = Project.create(
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
        title: Text(
          _getAppBarTitle(), 
          style: TextStyle(
            fontSize: 16,   // 👈 Change this value to adjust title size
            fontWeight: FontWeight.bold, // optional
          ),
          ),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          // // Tasks badge
          // Padding(
          //   padding: const EdgeInsets.only(right: 8),
          //   child: IconButton(
          //     icon: Badge(
          //       label: Text('${_taskService.getUnscheduledTasks().length}'),
          //       isLabelVisible: _taskService.getUnscheduledTasks().isNotEmpty,
          //       child: const Icon(Icons.task),
          //     ),
          //     onPressed: () => _showTasksList(),
          //     tooltip: 'Tasks',
          //   ),
          // ),

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
          CalendarViews(
            isInDayView: _isInDayView,
            selectedIndex: _selectedIndex,
            selectedDayViewDate: _selectedDayViewDate,
            previousViewIndex: _previousViewIndex,
            eventController: _eventController,
            heightPerMinute: heightPerMinute,
            onShowDayView: _showDayView,
            onShowEventDetails: _showEventDetails,
            onShowEventOptions: _showEventOptions,
            onShowAddEventDialog: _showAddEventDialog,
            onSetState: () => setState(() {}),
          ),

          // Chat interface overlay
          // ChatInterface(isVisible: _isChatOpen, onClose: _toggleChat),
          ChatInterface(
            isVisible: _isChatOpen, 
            onClose: _toggleChat,
            toolService: _chatToolService,
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Schedule Tasks FAB
          FloatingActionButton(
            heroTag: "schedule_tasks",
            backgroundColor: Colors.orange,
            onPressed: _taskService.getUnscheduledTasks().isEmpty
                ? null
                : scheduleUnscheduledTasks,
            tooltip: 'Schedule Tasks',
            child: IconButton(
              icon: Badge(
                label: Text('${_taskService.getUnscheduledTasks().length}'),
                isLabelVisible: _taskService.getUnscheduledTasks().isNotEmpty,
                child: const Icon(Icons.task),
              ),
              onPressed: () => _showTasksList(),
              tooltip: 'Tasks',
            ),
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
}