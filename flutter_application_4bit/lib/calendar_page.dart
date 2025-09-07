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
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_models.dart';

// TASK MANAGEMENT CLASSES
class TaskManager {
  static const String _tasksKey = 'app_tasks';
  final List<Task> _tasks = [];
  
  List<Task> get tasks => List.unmodifiable(_tasks);
  
  Future<void> initialize() async {
    await _loadTasks();
  }
  
  void addTask(Task task) {
    _tasks.add(task);
    _saveTasks();
  }
  
  void updateTask(Task updatedTask) {
    final index = _tasks.indexWhere((t) => t.id == updatedTask.id);
    if (index != -1) {
      _tasks[index] = updatedTask;
      _saveTasks();
    }
  }
  
  void removeTask(String taskId) {
    _tasks.removeWhere((t) => t.id == taskId);
    _saveTasks();
  }
  
  List<Task> getUnscheduledTasks() {
    return _tasks.where((task) => 
      task.scheduledFor == null && 
      task.status != TaskStatus.completed &&
      task.status != TaskStatus.cancelled
    ).toList();
  }
  
  List<Task> getTasksForDate(DateTime date) {
    final targetDate = DateTime(date.year, date.month, date.day);
    return _tasks.where((task) {
      if (task.scheduledFor == null) return false;
      final scheduledDate = DateTime(
        task.scheduledFor!.year,
        task.scheduledFor!.month,
        task.scheduledFor!.day
      );
      return scheduledDate.isAtSameMomentAs(targetDate);
    }).toList();
  }
  
  Future<void> _saveTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = _tasks.map((task) => task.toJson()).toList();
      await prefs.setString(_tasksKey, jsonEncode(tasksJson));
    } catch (e) {
      print('Error saving tasks: $e');
    }
  }
  
  Future<void> _loadTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksString = prefs.getString(_tasksKey);
      if (tasksString != null) {
        final List<dynamic> tasksJson = jsonDecode(tasksString);
        _tasks.clear();
        _tasks.addAll(tasksJson.map((json) => Task.fromJson(json)));
      }
    } catch (e) {
      print('Error loading tasks: $e');
    }
  }
}

class SchedulingService {
  static const String _groqApiKey = String.fromEnvironment('groqApiKey');
  static const String _groqApiUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.3-70b-versatile';
  
  Future<SchedulingResult> scheduleUnscheduledTasks({
    required List<Task> unscheduledTasks,
    required List<ExtendedCalendarEventData> existingEvents,
    required SchedulingConstraints constraints,
    Map<String, String>? changes,
  }) async {
    if (unscheduledTasks.isEmpty) {
      return SchedulingResult(
        reasoning: "No unscheduled tasks to process.",
        schedule: [],
      );
    }
    
    final prompt = _buildSchedulingPrompt(
      unscheduledTasks,
      existingEvents,
      constraints,
      changes,
    );
    
    try {
      final response = await _makeGroqApiCall(prompt);
      return _parseSchedulingResponse(response);
    } catch (e) {
      throw Exception('Scheduling failed: $e');
    }
  }
  
  String _buildSchedulingPrompt(
    List<Task> tasks,
    List<ExtendedCalendarEventData> events,
    SchedulingConstraints constraints,
    Map<String, String>? changes,
  ) {
    final tasksJson = tasks.map((t) => {
      'id': t.id,
      'title': t.title,
      'description': t.description,
      'estimatedTime': t.estimatedTime,
      'priority': t.priority.name,
      'energyRequired': t.energyRequired.name,
      'dueDate': t.dueDate?.toIso8601String(),
      'dependencies': t.dependencies,
      'timePreference': t.timePreference.name,
    }).toList();
    
    final eventsJson = events.map((e) => {
      'title': e.title,
      'startTime': e.startTime?.toIso8601String(),
      'endTime': e.endTime?.toIso8601String(),
      'date': e.date.toIso8601String(),
    }).toList();
    
    return '''
You are an expert scheduling assistant. Your job is to create an optimized calendar schedule using these principles:

1. Time blocking: Allocate focused blocks for tasks
2. Task batching: Group similar tasks together  
3. Day theming: Assign related tasks to the same day if possible
4. Prioritization: Urgent and high-priority tasks go first
5. Respect constraints: Working hours, breaks, energy peaks, and existing calendar events
6. Energy matching: High-energy tasks during energy peaks, low-energy tasks otherwise
7. Dependencies: Schedule dependent tasks after their dependencies
8. Time preferences: Respect morning/afternoon preferences

Current date: ${DateTime.now().toIso8601String()}

EXISTING CALENDAR EVENTS:
${jsonEncode(eventsJson)}

UNSCHEDULED TASKS:
${jsonEncode(tasksJson)}

CONSTRAINTS:
${jsonEncode(constraints.toJson())}

${changes != null ? 'REQUESTED CHANGES:\n${jsonEncode(changes)}' : ''}

OUTPUT REQUIREMENTS:
- Valid JSON only, no extra text
- Two fields: "reasoning" and "schedule"
- reasoning: Explain scheduling decisions
- schedule: Array of tasks with updated scheduledFor times
- Ensure no conflicts with existing events
- Respect task dependencies and constraints
- Schedule within next 30 days unless specified otherwise

Task Schema for schedule array:
{
  "id": "string",
  "title": "string", 
  "scheduledFor": "ISO 8601 datetime",
  "estimatedTime": "number (hours)",
  "priority": "low|medium|high|urgent",
  "energyRequired": "low|medium|high"
}
''';
  }
  
  Future<String> _makeGroqApiCall(String prompt) async {
    final headers = {
      'Authorization': 'Bearer $_groqApiKey',
      'Content-Type': 'application/json',
    };
    
    final body = {
      'model': _model,
      'messages': [
        {'role': 'user', 'content': prompt}
      ],
      'temperature': 0.3,
      'max_tokens': 2000,
    };
    
    final response = await http.post(
      Uri.parse(_groqApiUrl),
      headers: headers,
      body: jsonEncode(body),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception('API Error: ${response.statusCode}');
    }
  }
  
  SchedulingResult _parseSchedulingResponse(String response) {
    try {
      final data = jsonDecode(response);
      return SchedulingResult.fromJson(data);
    } catch (e) {
      throw Exception('Failed to parse scheduling response: $e');
    }
  }
}

// SCHEDULING MODELS
class SchedulingConstraints {
  final WorkingHours workingHours;
  final List<String> energyPeaks;
  final List<BreakPeriod> breaks;
  final List<String> preferredDays;
  
  SchedulingConstraints({
    required this.workingHours,
    this.energyPeaks = const [],
    this.breaks = const [],
    this.preferredDays = const [],
  });
  
  Map<String, dynamic> toJson() => {
    'workingHours': workingHours.toJson(),
    'energyPeaks': energyPeaks,
    'breaks': breaks.map((b) => b.toJson()).toList(),
    'preferredDays': preferredDays,
  };
}

class WorkingHours {
  final String start;
  final String end;
  
  WorkingHours({required this.start, required this.end});
  
  Map<String, dynamic> toJson() => {
    'start': start,
    'end': end,
  };
}

class BreakPeriod {
  final String start;
  final String end;
  final String? name;
  
  BreakPeriod({required this.start, required this.end, this.name});
  
  Map<String, dynamic> toJson() => {
    'start': start,
    'end': end,
    if (name != null) 'name': name,
  };
}

class SchedulingResult {
  final String reasoning;
  final List<ScheduledTask> schedule;
  
  SchedulingResult({required this.reasoning, required this.schedule});
  
  factory SchedulingResult.fromJson(Map<String, dynamic> json) {
    return SchedulingResult(
      reasoning: json['reasoning'] ?? '',
      schedule: (json['schedule'] as List?)
          ?.map((item) => ScheduledTask.fromJson(item))
          .toList() ?? [],
    );
  }
}

class ScheduledTask {
  final String id;
  final String title;
  final DateTime scheduledFor;
  final double estimatedTime;
  final Priority priority;
  final EnergyLevel energyRequired;
  
  ScheduledTask({
    required this.id,
    required this.title,
    required this.scheduledFor,
    required this.estimatedTime,
    required this.priority,
    required this.energyRequired,
  });
  
  factory ScheduledTask.fromJson(Map<String, dynamic> json) {
    return ScheduledTask(
      id: json['id'],
      title: json['title'],
      scheduledFor: DateTime.parse(json['scheduledFor']),
      estimatedTime: json['estimatedTime'].toDouble(),
      priority: Priority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => Priority.medium,
      ),
      energyRequired: EnergyLevel.values.firstWhere(
        (e) => e.name == json['energyRequired'],
        orElse: () => EnergyLevel.medium,
      ),
    );
  }
}

// TASK FORM DIALOG
class TaskFormDialog {
  static void showTaskDialog(
    BuildContext context, {
    Task? existingTask,
    required Function(Task) onSaveTask,
  }) {
    showDialog(
      context: context,
      builder: (context) => TaskFormWidget(
        existingTask: existingTask,
        onSaveTask: onSaveTask,
      ),
    );
  }
}

class TaskFormWidget extends StatefulWidget {
  final Task? existingTask;
  final Function(Task) onSaveTask;
  
  const TaskFormWidget({
    Key? key,
    this.existingTask,
    required this.onSaveTask,
  }) : super(key: key);
  
  @override
  _TaskFormWidgetState createState() => _TaskFormWidgetState();
}

class _TaskFormWidgetState extends State<TaskFormWidget> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _estimatedTimeController;
  Priority _priority = Priority.medium;
  EnergyLevel _energyRequired = EnergyLevel.medium;
  TimePreference _timePreference = TimePreference.flexible;
  DateTime? _dueDate;
  
  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.existingTask?.title ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.existingTask?.description ?? '',
    );
    _estimatedTimeController = TextEditingController(
      text: widget.existingTask?.estimatedTime.toString() ?? '1.0',
    );
    
    if (widget.existingTask != null) {
      _priority = widget.existingTask!.priority;
      _energyRequired = widget.existingTask!.energyRequired;
      _timePreference = widget.existingTask!.timePreference;
      _dueDate = widget.existingTask!.dueDate;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existingTask == null ? 'Add Task' : 'Edit Task'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Task Title'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _estimatedTimeController,
              decoration: const InputDecoration(labelText: 'Estimated Time (hours)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Priority>(
              value: _priority,
              decoration: const InputDecoration(labelText: 'Priority'),
              items: Priority.values.map((priority) {
                return DropdownMenuItem(
                  value: priority,
                  child: Text(priority.displayName),
                );
              }).toList(),
              onChanged: (value) => setState(() => _priority = value!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<EnergyLevel>(
              value: _energyRequired,
              decoration: const InputDecoration(labelText: 'Energy Required'),
              items: EnergyLevel.values.map((energy) {
                return DropdownMenuItem(
                  value: energy,
                  child: Text(energy.displayName),
                );
              }).toList(),
              onChanged: (value) => setState(() => _energyRequired = value!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TimePreference>(
              value: _timePreference,
              decoration: const InputDecoration(labelText: 'Time Preference'),
              items: TimePreference.values.map((pref) {
                return DropdownMenuItem(
                  value: pref,
                  child: Text(pref.name.toLowerCase()),
                );
              }).toList(),
              onChanged: (value) => setState(() => _timePreference = value!),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Due Date'),
              subtitle: Text(_dueDate?.toString().split(' ')[0] ?? 'No due date'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _dueDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _dueDate = date);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_titleController.text.trim().isEmpty) return;
            
            final task = Task(
              id: widget.existingTask?.id ?? 'task_${DateTime.now().millisecondsSinceEpoch}',
              title: _titleController.text.trim(),
              description: _descriptionController.text.trim().isEmpty 
                  ? null 
                  : _descriptionController.text.trim(),
              estimatedTime: double.tryParse(_estimatedTimeController.text) ?? 1.0,
              priority: _priority,
              energyRequired: _energyRequired,
              timePreference: _timePreference,
              dueDate: _dueDate,
              createdAt: widget.existingTask?.createdAt ?? DateTime.now(),
              updatedAt: DateTime.now(),
            );
            
            widget.onSaveTask(task);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _estimatedTimeController.dispose();
    super.dispose();
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
  final bool _condensed = true; // Condensed vertical density
  
  // Task Management
  late TaskManager _taskManager;
  late SchedulingService _schedulingService;
  
  // Chat-related variables
  bool _isChatOpen = false;
  bool _isLoading = false;
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = <ChatMessage>[];
  final ScrollController _scrollController = ScrollController();
  
  // API configuration
  static const String _groqApiKey = String.fromEnvironment('groqApiKey');
  static const String _groqApiUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.3-70b-versatile';
  
  // Store conversation history for context
  final List<Map<String, String>> _conversationHistory = [];

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
    setState(() {}); // Refresh UI after loading tasks
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
      priority: task.priority, // Direct assignment since they're the same enum
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
    
    print('Adding sample events...');
    
    try {
      final teamMeetingStart = DateTime(now.year, now.month, now.day, 10, 0);
      final teamMeetingEnd = teamMeetingStart.add(const Duration(hours: 1));
      
      final teamMeetingEvent = ExtendedCalendarEventData(
        title: "Team Meeting",
        date: DateTime(now.year, now.month, now.day),
        startTime: teamMeetingStart,
        endTime: teamMeetingEnd,
        description: "Weekly team sync",
        priority: Priority.high,
        project: 'Work',
        recurring: RecurringType.weekly,
        color: _resolveEventColor(project: 'Work', priority: Priority.high),
      );
      
      print('Created team meeting event: ${teamMeetingEvent.title}');
      _addEventWithRecurring(teamMeetingEvent);
      
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

  void _handleChatSubmitted(String text) async {
    if (text.trim().isEmpty) return;
    
    _textController.clear();
    ChatMessage message = ChatMessage(
      text: text,
      isUserMessage: true,
    );
    setState(() {
      _messages.add(message);
    });

    _scrollToBottomWithDelay(
      const Duration(milliseconds: 200),
    );

    await _sendMessage(text);
  }

  _scrollToBottomWithDelay(Duration delay) async {
    await Future.delayed(delay);
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _sendMessage(String text) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Add user message to conversation history
      _conversationHistory.add({
        'role': 'user',
        'content': text,
      });

      final response = await _makeGroqApiCall();
      
      if (response != null) {
        // Add assistant response to conversation history
        _conversationHistory.add({
          'role': 'assistant',
          'content': response,
        });

        ChatMessage responseMessage = ChatMessage(
          text: response,
          isUserMessage: false,
        );

        setState(() {
          _messages.add(responseMessage);
        });
      }
    } catch (error) {
      ErrorMessage errorMessage = ErrorMessage(
        text: 'Failed to get response: ${error.toString()}',
      );

      setState(() {
        _messages.add(errorMessage);
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottomWithDelay(
        const Duration(milliseconds: 300),
      );
    }
  }

  Future<String?> _makeGroqApiCall() async {
    try {
      final headers = {
        'Authorization': 'Bearer $_groqApiKey',
        'Content-Type': 'application/json',
      };

      final body = {
        'model': _model,
        'messages': _conversationHistory,
        'temperature': 0.7,
        'max_tokens': 1000,
        'stream': false,
      };

      final response = await http.post(
        Uri.parse(_groqApiUrl),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['choices'] != null && data['choices'].isNotEmpty) {
          return data['choices'][0]['message']['content'] as String?;
        } else {
          throw Exception('No response from API');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception('API Error (${response.statusCode}): ${errorData['error']?.toString() ?? 'Unknown error'}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error making API call: $e');
      }
      rethrow;
    }
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      _conversationHistory.clear();
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
            ? Colors.blue.shade800  // Dark text on light background
            : Colors.white,         // White text on dark background
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

  Widget _buildChatInterface() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Chat header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'AI Assistant',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _clearChat,
                      icon: Icon(Icons.delete, color: Colors.blue.shade800),
                    ),
                    IconButton(
                      onPressed: _toggleChat,
                      icon: Icon(Icons.close, color: Colors.blue.shade800),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (_, int index) {
                if (index == _messages.length && _isLoading) {
                  // Loading indicator
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'AI is thinking...',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return _messages[index];
              },
            ),
          ),
          // Chat input
          const Divider(height: 1.0),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Ask about your calendar or anything else...',
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                      border: InputBorder.none,
                    ),
                    onSubmitted: _handleChatSubmitted,
                    enabled: !_isLoading,
                  ),
                ),
                IconButton(
                  icon: Icon(_isLoading ? Icons.hourglass_empty : Icons.send),
                  onPressed: _isLoading ? null : () => _handleChatSubmitted(_textController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double heightPerMinute = _condensed ? 0.6 : 1.2;

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
          
          // View toggle buttons with better spacing
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
          _isInDayView
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
                        return MonthView(
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
          
          // Chat interface overlay
          if (_isChatOpen)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildChatInterface(),
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
    print('=== _addEventWithRecurring called ===');
    print('Event title: ${event.title}');
    print('Event date: ${event.date}');
    print('Event startTime: ${event.startTime}');
    print('Event endTime: ${event.endTime}');
    print('Event recurring: ${event.recurring}');
    
    final recurrence = overrideRecurring ?? event.recurring;
    final color = _resolveEventColor(
      project: event.project,
      priority: event.priority,
    );

    final seriesId = event.seriesId;

    print("---- Adding Event ----");
    print(
      "Base event: ${event.title}, Date: ${event.date}, Recurring: $recurrence",
    );

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
        seriesId: seriesId,
      ),
    );

    if (recurrence == RecurringType.none) {
      print("No recurrence. Only base event added.");
      return;
    }

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
          recurring: recurrence,
          seriesId: seriesId,
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

// Chat message widgets
class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUserMessage;

  const ChatMessage({
    super.key,
    required this.text,
    this.isUserMessage = false,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final CrossAxisAlignment crossAxisAlignment =
        isUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: isUserMessage
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.tertiaryContainer,
            borderRadius: isUserMessage
                ? const BorderRadius.only(
                    topLeft: Radius.circular(8.0),
                    topRight: Radius.circular(8.0),
                    bottomLeft: Radius.circular(8.0),
                    bottomRight: Radius.circular(0.0),
                  )
                : const BorderRadius.only(
                    topLeft: Radius.circular(0.0),
                    topRight: Radius.circular(8.0),
                    bottomLeft: Radius.circular(8.0),
                    bottomRight: Radius.circular(8.0),
                  ),
          ),
          child: Text(
            text,
            style: theme.textTheme.titleMedium,
          ),
        ),
      ],
    );
  }
}

class ErrorMessage extends ChatMessage {
  const ErrorMessage({super.key, required super.text});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(0.0),
              topRight: Radius.circular(8.0),
              bottomLeft: Radius.circular(8.0),
              bottomRight: Radius.circular(8.0),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.error_outline,
                color: theme.colorScheme.onErrorContainer,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}