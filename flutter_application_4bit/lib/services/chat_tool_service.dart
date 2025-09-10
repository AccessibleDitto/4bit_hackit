import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:calendar_view/calendar_view.dart';
import '../models/task_models.dart';
import '../models/calendar_models.dart';
import '../models/chat_models.dart';
import '../services/calendar_task_service.dart';
import '../services/calendar_event_service.dart';
import '../services/scheduling_service.dart';
import '../tasks_updated.dart' as tasks_source;
import '../utils/constants.dart';

class ChatToolCallingService {
  final CalendarTaskService _taskService;
  final CalendarEventService _eventService;
  final SchedulingService _schedulingService;
  final EventController _eventController;
  final Color Function({required Priority priority, String? project}) _resolveEventColor;  final Function() _refreshCallback;

  ChatToolCallingService({
    required CalendarTaskService taskService,
    required CalendarEventService eventService,
    required SchedulingService schedulingService,
    required EventController eventController,
    required Color Function({String? project, required Priority priority}) resolveEventColor,
    required Function() refreshCallback,
  }) : _taskService = taskService,
       _eventService = eventService,
       _schedulingService = schedulingService,
       _eventController = eventController,
       _resolveEventColor = resolveEventColor,
       _refreshCallback = refreshCallback;

  // Main method to process natural language and call appropriate tools
  Future<ChatResponse> processNaturalLanguage(String userInput) async {
    try {
      final toolCall = await _determineToolFromNaturalLanguage(userInput);
      
      switch (toolCall.tool) {
        case 'create_task':
          return await _createTask(toolCall.parameters);
        case 'create_event':
          return await _createEvent(toolCall.parameters);
        case 'schedule_tasks':
          return await _scheduleTasks(toolCall.parameters);
        case 'get_tasks':
          return await _getTasks(toolCall.parameters);
        case 'get_events':
          return await _getEvents(toolCall.parameters);
        case 'update_task':
          return await _updateTask(toolCall.parameters);
        case 'delete_task':
          return await _deleteTask(toolCall.parameters);
        case 'delete_event':
          return await _deleteEvent(toolCall.parameters);
        case 'get_calendar_summary':
          return await _getCalendarSummary(toolCall.parameters);
        case 'reschedule_task':
          return await _rescheduleTask(toolCall.parameters);
        default:
          return ChatResponse(
            text: "I couldn't understand that request. Please try asking about tasks, events, or scheduling.",
            success: false,
          );
      }
    } catch (e) {
      return ChatResponse(
        text: "Sorry, I encountered an error: $e",
        success: false,
      );
    }
  }

  Future<ToolCall> _determineToolFromNaturalLanguage(String input) async {
    const apiUrl = 'https://api.groq.com/openai/v1/chat/completions';
    
    final tools = [
      {
        "type": "function",
        "function": {
          "name": "create_task",
          "description": "Create a new task with title, description, priority, estimated time, due date, etc.",
          "parameters": {
            "type": "object",
            "properties": {
              "title": {"type": "string", "description": "Task title"},
              "description": {"type": "string", "description": "Task description"},
              "estimatedTime": {"type": "number", "description": "Estimated hours to complete"},
              "priority": {"type": "string", "enum": ["low", "medium", "high", "urgent"]},
              "dueDate": {"type": "string", "description": "Due date in ISO format"},
              "scheduledFor": {"type": "string", "description": "Scheduled time in ISO format"},
              "projectId": {"type": "string", "description": "Project ID"},
              "energyRequired": {"type": "string", "enum": ["low", "medium", "high"]},
              "timePreference": {"type": "string", "enum": ["flexible", "morning", "afternoon", "specific"]}
            },
            "required": ["title", "estimatedTime", "priority"]
          }
        }
      },
      {
        "type": "function", 
        "function": {
          "name": "create_event",
          "description": "Create a new calendar event with title, time, duration, etc.",
          "parameters": {
            "type": "object",
            "properties": {
              "title": {"type": "string", "description": "Event title"},
              "description": {"type": "string", "description": "Event description"},
              "startTime": {"type": "string", "description": "Start time in ISO format"},
              "endTime": {"type": "string", "description": "End time in ISO format"},
              "priority": {"type": "string", "enum": ["low", "medium", "high", "urgent"]},
              "project": {"type": "string", "description": "Project name"},
              "recurring": {"type": "string", "enum": ["none", "daily", "weekly", "monthly", "yearly"]}
            },
            "required": ["title", "startTime", "endTime"]
          }
        }
      },
      {
        "type": "function",
        "function": {
          "name": "schedule_tasks", 
          "description": "Automatically schedule unscheduled tasks",
          "parameters": {
            "type": "object",
            "properties": {
              "specificTasks": {"type": "array", "items": {"type": "string"}, "description": "Specific task IDs to schedule"},
              "timeRange": {"type": "string", "description": "Time range for scheduling (e.g., 'this week', 'next 3 days')"}
            }
          }
        }
      },
      {
        "type": "function",
        "function": {
          "name": "get_tasks",
          "description": "Retrieve tasks based on criteria",
          "parameters": {
            "type": "object", 
            "properties": {
              "status": {"type": "string", "enum": ["notStarted", "inProgress", "completed", "cancelled", "blocked"]},
              "priority": {"type": "string", "enum": ["low", "medium", "high", "urgent"]},
              "dueDate": {"type": "string", "description": "Filter by due date"},
              "projectId": {"type": "string", "description": "Filter by project"},
              "scheduled": {"type": "boolean", "description": "Filter by scheduled/unscheduled"}
            }
          }
        }
      },
      {
        "type": "function",
        "function": {
          "name": "get_events",
          "description": "Retrieve calendar events",
          "parameters": {
            "type": "object",
            "properties": {
              "startDate": {"type": "string", "description": "Start date for range in ISO format"},
              "endDate": {"type": "string", "description": "End date for range in ISO format"},
              "project": {"type": "string", "description": "Filter by project"}
            }
          }
        }
      },
      {
        "type": "function",
        "function": {
          "name": "update_task",
          "description": "Update an existing task",
          "parameters": {
            "type": "object",
            "properties": {
              "taskId": {"type": "string", "description": "Task ID to update"},
              "title": {"type": "string"},
              "status": {"type": "string", "enum": ["notStarted", "inProgress", "completed", "cancelled", "blocked"]},
              "priority": {"type": "string", "enum": ["low", "medium", "high", "urgent"]},
              "scheduledFor": {"type": "string", "description": "New scheduled time"},
              "progressPercentage": {"type": "number", "description": "Progress from 0 to 1"}
            },
            "required": ["taskId"]
          }
        }
      },
      {
        "type": "function",
        "function": {
          "name": "delete_task",
          "description": "Delete a task",
          "parameters": {
            "type": "object",
            "properties": {
              "taskId": {"type": "string", "description": "Task ID to delete"}
            },
            "required": ["taskId"]
          }
        }
      },
      {
        "type": "function",
        "function": {
          "name": "delete_event", 
          "description": "Delete a calendar event",
          "parameters": {
            "type": "object",
            "properties": {
              "eventTitle": {"type": "string", "description": "Event title or partial title"},
              "startTime": {"type": "string", "description": "Event start time to help identify"}
            }
          }
        }
      },
      {
        "type": "function",
        "function": {
          "name": "get_calendar_summary",
          "description": "Get overview of upcoming tasks and events",
          "parameters": {
            "type": "object",
            "properties": {
              "days": {"type": "number", "description": "Number of days to look ahead", "default": 7}
            }
          }
        }
      },
      {
        "type": "function",
        "function": {
          "name": "reschedule_task",
          "description": "Reschedule a specific task to a new time",
          "parameters": {
            "type": "object",
            "properties": {
              "taskId": {"type": "string", "description": "Task ID to reschedule"},
              "newTime": {"type": "string", "description": "New scheduled time in ISO format"}
            },
            "required": ["taskId", "newTime"]
          }
        }
      }
    ];

    final requestBody = {
      "model": "llama-3.3-70b-versatile",
      "messages": [
        {
          "role": "system",
          "content": "You are a calendar and task management assistant. Based on the user's input, determine the appropriate tool to call. Always call exactly one function that best matches the user's intent."
        },
        {
          "role": "user", 
          "content": input
        }
      ],
      "tools": tools,
      "tool_choice": "auto",
      "temperature": 0.1
    };

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer ${AppConstants.groqApiKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode != 200) {
      throw Exception('API Error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    final message = data['choices'][0]['message'];

    if (message['tool_calls'] != null && message['tool_calls'].isNotEmpty) {
      final toolCall = message['tool_calls'][0];
      final functionName = toolCall['function']['name'];
      final arguments = jsonDecode(toolCall['function']['arguments']);
      
      return ToolCall(tool: functionName, parameters: arguments);
    } else {
      // Fallback to text analysis
      return _parseNaturalLanguageFallback(input);
    }
  }

  ToolCall _parseNaturalLanguageFallback(String input) {
    final lowerInput = input.toLowerCase();
    
    if (lowerInput.contains('create') && lowerInput.contains('task')) {
      return ToolCall(tool: 'create_task', parameters: _extractTaskParams(input));
    } else if (lowerInput.contains('create') && (lowerInput.contains('event') || lowerInput.contains('meeting'))) {
      return ToolCall(tool: 'create_event', parameters: _extractEventParams(input));
    } else if (lowerInput.contains('schedule')) {
      return ToolCall(tool: 'schedule_tasks', parameters: {});
    } else if (lowerInput.contains('show') || lowerInput.contains('get') || lowerInput.contains('list')) {
      if (lowerInput.contains('task')) {
        return ToolCall(tool: 'get_tasks', parameters: {});
      } else {
        return ToolCall(tool: 'get_events', parameters: {});
      }
    } else if (lowerInput.contains('summary') || lowerInput.contains('overview')) {
      return ToolCall(tool: 'get_calendar_summary', parameters: {});
    } else {
      return ToolCall(tool: 'get_calendar_summary', parameters: {});
    }
  }

  Map<String, dynamic> _extractTaskParams(String input) {
    // Simple extraction logic - could be enhanced with NLP
    return {
      'title': _extractQuotedText(input) ?? 'New Task',
      'estimatedTime': 1.0,
      'priority': 'medium',
    };
  }

  Map<String, dynamic> _extractEventParams(String input) {
    return {
      'title': _extractQuotedText(input) ?? 'New Event', 
      'startTime': DateTime.now().add(Duration(hours: 1)).toIso8601String(),
      'endTime': DateTime.now().add(Duration(hours: 2)).toIso8601String(),
    };
  }

  String? _extractQuotedText(String input) {
    final regex = RegExp(r'"([^"]*)"');
    final match = regex.firstMatch(input);
    return match?.group(1);
  }

  // Tool implementation methods
  Future<ChatResponse> _createTask(Map<String, dynamic> params) async {
    try {
      final task = Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: params['title'] ?? 'New Task',
        description: params['description'],
        estimatedTime: (params['estimatedTime'] ?? 1.0).toDouble(),
        priority: Priority.values.firstWhere(
          (p) => p.name == params['priority'],
          orElse: () => Priority.medium,
        ),
        dueDate: params['dueDate'] != null ? DateTime.parse(params['dueDate']) : null,
        scheduledFor: params['scheduledFor'] != null ? DateTime.parse(params['scheduledFor']) : null,
        projectId: params['projectId'],
        energyRequired: EnergyLevel.values.firstWhere(
          (e) => e.name == params['energyRequired'],
          orElse: () => EnergyLevel.medium,
        ),
        timePreference: TimePreference.values.firstWhere(
          (t) => t.name == params['timePreference'],
          orElse: () => TimePreference.flexible,
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save task using your existing system
      tasks_source.tasks.add(task);
      
      // If scheduled, add to calendar
      if (task.scheduledFor != null) {
        _taskService.syncTasksToCalendar(_eventController);
      }
      
      _refreshCallback();

      return ChatResponse(
        text: "Created task: ${task.title}",
        success: true,
        taskWidget: _buildTaskWidget(task),
      );
    } catch (e) {
      return ChatResponse(text: "Failed to create task: $e", success: false);
    }
  }

  Future<ChatResponse> _createEvent(Map<String, dynamic> params) async {
    try {
      final event = ExtendedCalendarEventData(
        title: params['title'] ?? 'New Event',
        description: params['description'] ?? '',
        date: DateTime.parse(params['startTime']),
        startTime: DateTime.parse(params['startTime']),
        endTime: DateTime.parse(params['endTime']),
        priority: Priority.values.firstWhere(
          (p) => p.name == params['priority'],
          orElse: () => Priority.medium,
        ),
        project: params['project'],
        recurring: RecurringType.values.firstWhere(
          (r) => r.name == params['recurring'],
          orElse: () => RecurringType.none,
        ),
        color: Colors.blue, // Will be resolved by _resolveEventColor
      );

      _eventService.addEventWithRecurring(event, _eventController, _resolveEventColor);
      _refreshCallback();

      return ChatResponse(
        text: "Created event: ${event.title}",
        success: true,
        eventWidget: _buildEventWidget(event),
      );
    } catch (e) {
      return ChatResponse(text: "Failed to create event: $e", success: false);
    }
  }

  Future<ChatResponse> _scheduleTasks(Map<String, dynamic> params) async {
    try {
      final result = await _taskService.scheduleUnscheduledTasks(
        _schedulingService,
        _eventController,
      );

      _refreshCallback();

      return ChatResponse(
        text: "Scheduled ${result.scheduledCount} tasks successfully!\n\n${result.reasoning}",
        success: true,
        schedulingResultWidget: _buildSchedulingResultWidget(result),
      );
    } catch (e) {
      return ChatResponse(text: "Failed to schedule tasks: $e", success: false);
    }
  }

  Future<ChatResponse> _getTasks(Map<String, dynamic> params) async {
    try {
      List<Task> tasks = tasks_source.getTasksList();

      // Apply filters
      if (params['status'] != null) {
        final status = TaskStatus.values.firstWhere((s) => s.name == params['status']);
        tasks = tasks.where((t) => t.status == status).toList();
      }

      if (params['priority'] != null) {
        final priority = Priority.values.firstWhere((p) => p.name == params['priority']);
        tasks = tasks.where((t) => t.priority == priority).toList();
      }

      if (params['scheduled'] != null) {
        final scheduled = params['scheduled'] as bool;
        tasks = tasks.where((t) => (t.scheduledFor != null) == scheduled).toList();
      }

      if (tasks.isEmpty) {
        return ChatResponse(text: "No tasks found matching your criteria.", success: true);
      }

      final taskList = tasks.map((t) => "• ${t.title} (${t.priority.name})").join('\n');
      
      return ChatResponse(
        text: "Found ${tasks.length} tasks:\n\n$taskList",
        success: true,
        taskListWidget: _buildTaskListWidget(tasks),
      );
    } catch (e) {
      return ChatResponse(text: "Failed to get tasks: $e", success: false);
    }
  }

  Future<ChatResponse> _getEvents(Map<String, dynamic> params) async {
    try {
      List<CalendarEventData> events = _eventController.allEvents;

      // Apply date range filter
      if (params['startDate'] != null && params['endDate'] != null) {
        final startDate = DateTime.parse(params['startDate']);
        final endDate = DateTime.parse(params['endDate']);
        events = events.where((e) => 
          e.date.isAfter(startDate.subtract(Duration(days: 1))) &&
          e.date.isBefore(endDate.add(Duration(days: 1)))
        ).toList();
      }

      if (events.isEmpty) {
        return ChatResponse(text: "No events found in the specified range.", success: true);
      }

      final eventList = events.map((e) => "• ${e.title} (${e.date.toString().split(' ')[0]})").join('\n');

      return ChatResponse(
        text: "Found ${events.length} events:\n\n$eventList",
        success: true,
        eventListWidget: _buildEventListWidget(events),
      );
    } catch (e) {
      return ChatResponse(text: "Failed to get events: $e", success: false);
    }
  }

  Future<ChatResponse> _updateTask(Map<String, dynamic> params) async {
    try {
      final taskId = params['taskId'] as String;
      final task = tasks_source.getTasksList().firstWhere((t) => t.id == taskId);
      
      final updatedTask = task.copyWith(
        title: params['title'],
        status: params['status'] != null ? 
          TaskStatus.values.firstWhere((s) => s.name == params['status']) : null,
        priority: params['priority'] != null ?
          Priority.values.firstWhere((p) => p.name == params['priority']) : null,
        scheduledFor: params['scheduledFor'] != null ? 
          DateTime.parse(params['scheduledFor']) : null,
        progressPercentage: params['progressPercentage']?.toDouble(),
      );

      tasks_source.saveTask(updatedTask);
      _taskService.syncTasksToCalendar(_eventController);
      _refreshCallback();

      return ChatResponse(
        text: "Updated task: ${updatedTask.title}",
        success: true,
        taskWidget: _buildTaskWidget(updatedTask),
      );
    } catch (e) {
      return ChatResponse(text: "Failed to update task: $e", success: false);
    }
  }

  Future<ChatResponse> _deleteTask(Map<String, dynamic> params) async {
    try {
      final taskId = params['taskId'] as String;
      final task = tasks_source.getTasksList().firstWhere((t) => t.id == taskId);
      
      tasks_source.tasks.removeWhere((t) => t.id == taskId);
      _taskService.syncTasksToCalendar(_eventController);
      _refreshCallback();

      return ChatResponse(
        text: "Deleted task: ${task.title}",
        success: true,
      );
    } catch (e) {
      return ChatResponse(text: "Failed to delete task: $e", success: false);
    }
  }

  Future<ChatResponse> _deleteEvent(Map<String, dynamic> params) async {
    try {
      final eventTitle = params['eventTitle'] as String;
      final events = _eventController.allEvents.where((e) => 
        e.title.toLowerCase().contains(eventTitle.toLowerCase())
      ).toList();

      if (events.isEmpty) {
        return ChatResponse(text: "No events found with title: $eventTitle", success: false);
      }

      final event = events.first;
      _eventController.remove(event);
      _refreshCallback();

      return ChatResponse(
        text: "Deleted event: ${event.title}",
        success: true,
      );
    } catch (e) {
      return ChatResponse(text: "Failed to delete event: $e", success: false);
    }
  }

  Future<ChatResponse> _getCalendarSummary(Map<String, dynamic> params) async {
    try {
      final days = params['days'] as int? ?? 7;
      final endDate = DateTime.now().add(Duration(days: days));
      
      // Get upcoming tasks
      final upcomingTasks = tasks_source.getTasksList()
          .where((t) => t.scheduledFor != null && t.scheduledFor!.isBefore(endDate))
          .toList();
      
      // Get upcoming events
      final upcomingEvents = _eventController.allEvents
          .where((e) => e.date.isBefore(endDate))
          .toList();

      final unscheduledTasks = _taskService.getUnscheduledTasks();
      final overdueTasks = tasks_source.getTasksList()
          .where((t) => t.isOverdue)
          .toList();

      final summary = '''
Calendar Summary (Next $days days)

**Upcoming Tasks:** ${upcomingTasks.length}
**Upcoming Events:** ${upcomingEvents.length}
**Unscheduled Tasks:** ${unscheduledTasks.length}
**Overdue Tasks:** ${overdueTasks.length}

${overdueTasks.isNotEmpty ? '**Overdue:**\n${overdueTasks.map((t) => '• ${t.title}').join('\n')}\n\n' : ''}

${unscheduledTasks.isNotEmpty ? '**Need Scheduling:**\n${unscheduledTasks.take(5).map((t) => '• ${t.title}').join('\n')}${unscheduledTasks.length > 5 ? '\n...and ${unscheduledTasks.length - 5} more' : ''}\n\n' : ''}

**Today's Schedule:**
${_getTodaySchedule()}
''';

      return ChatResponse(
        text: summary,
        success: true,
        summaryWidget: _buildSummaryWidget(upcomingTasks, upcomingEvents, unscheduledTasks, overdueTasks),
      );
    } catch (e) {
      return ChatResponse(text: "Failed to get calendar summary: $e", success: false);
    }
  }

  Future<ChatResponse> _rescheduleTask(Map<String, dynamic> params) async {
    try {
      final taskId = params['taskId'] as String;
      final newTime = DateTime.parse(params['newTime']);
      
      final task = tasks_source.getTasksList().firstWhere((t) => t.id == taskId);
      final updatedTask = task.copyWith(scheduledFor: newTime);
      
      tasks_source.saveTask(updatedTask);
      _taskService.syncTasksToCalendar(_eventController);
      _refreshCallback();

      return ChatResponse(
        text: "Rescheduled ${task.title} to ${newTime.toString().split('.')[0]}",
        success: true,
        taskWidget: _buildTaskWidget(updatedTask),
      );
    } catch (e) {
      return ChatResponse(text: "Failed to reschedule task: $e", success: false);
    }
  }

  String _getTodaySchedule() {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(Duration(days: 1));

    final todayTasks = tasks_source.getTasksList()
        .where((t) => t.scheduledFor != null && 
                     t.scheduledFor!.isAfter(todayStart) && 
                     t.scheduledFor!.isBefore(todayEnd))
        .toList();

    final todayEvents = _eventController.allEvents
        .where((e) => e.date.isAfter(todayStart.subtract(Duration(days: 1))) && 
                     e.date.isBefore(todayEnd))
        .toList();

    if (todayTasks.isEmpty && todayEvents.isEmpty) {
      return "No scheduled items for today.";
    }

    final schedule = <String>[];
    
    for (final task in todayTasks) {
      schedule.add("• ${task.scheduledFor!.hour.toString().padLeft(2, '0')}:${task.scheduledFor!.minute.toString().padLeft(2, '0')} - ${task.title} (Task)");
    }
    
    for (final event in todayEvents) {
      final time = event.startTime != null 
          ? "${event.startTime!.hour.toString().padLeft(2, '0')}:${event.startTime!.minute.toString().padLeft(2, '0')}" 
          : "All day";
      schedule.add("• $time - ${event.title} (Event)");
    }

    schedule.sort();
    return schedule.join('\n');
  }

  // Widget builders for chat display
  Widget _buildTaskWidget(Task task) {
    return _taskService.buildTaskListTile(
      task,
      onDelete: () {},
      onTap: () {},
    );
  }

  Widget _buildEventWidget(ExtendedCalendarEventData event) {
    return Card(
      child: ListTile(
        title: Text(event.title),
        subtitle: Text(event.description ?? 'No description'),
        leading: CircleAvatar(
          backgroundColor: event.color,
          child: Icon(Icons.event, color: Colors.white),
        ),
        trailing: Text(
          "${event.startTime?.hour.toString().padLeft(2, '0') ?? ''}:${event.startTime?.minute.toString().padLeft(2, '0') ?? ''}",
        ),
      ),
    );
  }

  Widget _buildTaskListWidget(List<Task> tasks) {
    return Column(
      children: tasks.map((task) => _buildTaskWidget(task)).toList(),
    );
  }

  Widget _buildEventListWidget(List<CalendarEventData> events) {
    return Column(
      children: events.map((event) => 
        event is ExtendedCalendarEventData 
          ? _buildEventWidget(event)
          : Card(child: ListTile(title: Text(event.title)))
      ).toList(),
    );
  }

  Widget _buildSchedulingResultWidget(dynamic result) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Scheduling Results",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text("Tasks scheduled: ${result.scheduledCount}"),
            if (result.scheduledTasks.isNotEmpty) ...[
              SizedBox(height: 8),
              Text("Scheduled tasks:", style: TextStyle(fontWeight: FontWeight.bold)),
              ...result.scheduledTasks.map((task) => Padding(
                padding: EdgeInsets.only(left: 16, top: 4),
                child: Text("• ${task.title}"),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryWidget(List<Task> upcomingTasks, List<CalendarEventData> upcomingEvents, 
                            List<Task> unscheduledTasks, List<Task> overdueTasks) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Calendar Overview",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard("Tasks", upcomingTasks.length.toString(), Colors.blue),
                _buildStatCard("Events", upcomingEvents.length.toString(), Colors.green),
                _buildStatCard("Unscheduled", unscheduledTasks.length.toString(), Colors.orange),
                _buildStatCard("Overdue", overdueTasks.length.toString(), Colors.red),
              ],
            ),
            if (overdueTasks.isNotEmpty) ...[
              SizedBox(height: 12),
              Text(
                "Overdue Tasks:",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
              ),
              ...overdueTasks.take(3).map((task) => Padding(
                padding: EdgeInsets.only(left: 8, top: 4),
                child: Row(
                  children: [
                    Icon(Icons.warning, size: 16, color: Colors.red),
                    SizedBox(width: 4),
                    Expanded(child: Text(task.title, style: TextStyle(fontSize: 12))),
                  ],
                ),
              )),
              if (overdueTasks.length > 3)
                Padding(
                  padding: EdgeInsets.only(left: 8, top: 4),
                  child: Text(
                    "...and ${overdueTasks.length - 3} more",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
            ],
            if (unscheduledTasks.isNotEmpty) ...[
              SizedBox(height: 12),
              Text(
                "Need Scheduling:",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
              ),
              ...unscheduledTasks.take(3).map((task) => Padding(
                padding: EdgeInsets.only(left: 8, top: 4),
                child: Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: Colors.orange),
                    SizedBox(width: 4),
                    Expanded(child: Text(task.title, style: TextStyle(fontSize: 12))),
                  ],
                ),
              )),
              if (unscheduledTasks.length > 3)
                Padding(
                  padding: EdgeInsets.only(left: 8, top: 4),
                  child: Text(
                    "...and ${unscheduledTasks.length - 3} more",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}

// Models for tool calling
class ToolCall {
  final String tool;
  final Map<String, dynamic> parameters;

  ToolCall({required this.tool, required this.parameters});
}

class ChatResponse {
  final String text;
  final bool success;
  final Widget? taskWidget;
  final Widget? eventWidget;
  final Widget? taskListWidget;
  final Widget? eventListWidget;
  final Widget? schedulingResultWidget;
  final Widget? summaryWidget;

  ChatResponse({
    required this.text,
    required this.success,
    this.taskWidget,
    this.eventWidget,
    this.taskListWidget,
    this.eventListWidget,
    this.schedulingResultWidget,
    this.summaryWidget,
  });
}