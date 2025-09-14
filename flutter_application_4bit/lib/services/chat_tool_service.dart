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
import '../widgets/task_detail_modal.dart';
import '../dialogs/event_dialogs.dart';
import '../dialogs/event_form_dialog.dart';
import '../dialogs/scheduling_dialogs.dart';

class ChatToolCallingService {
  final CalendarTaskService _taskService;
  final CalendarEventService _eventService;
  final SchedulingService _schedulingService;
  final EventController _eventController;
  final Color Function({required Priority priority, String? project})
  _resolveEventColor;
  final Function() _refreshCallback;

  // Add these required dependencies for widget building
  final BuildContext? _context;
  final List<Project> _projects;
  final Map<String?, Color> _projectColors;
  final Function(Task)? _onTaskUpdate;
  final Function(Task)? _onTaskDelete;
  final Function(BuildContext, ExtendedCalendarEventData)? _onEditEvent;
  final Function(BuildContext, ExtendedCalendarEventData)? _onDeleteEvent;
  final Function(String)? _onDeleteSeries;
  final Function()? _onRescheduleAll;
  final Function()? _onClearSchedule;

  ChatToolCallingService({
    required CalendarTaskService taskService,
    required CalendarEventService eventService,
    required SchedulingService schedulingService,
    required EventController eventController,
    required Color Function({String? project, required Priority priority})
    resolveEventColor,
    required Function() refreshCallback,
    BuildContext? context,
    List<Project>? projects,
    Map<String?, Color>? projectColors,
    Function(Task)? onTaskUpdate,
    Function(Task)? onTaskDelete,
    Function(BuildContext, ExtendedCalendarEventData)? onEditEvent,
    Function(BuildContext, ExtendedCalendarEventData)? onDeleteEvent,
    Function(String)? onDeleteSeries,
    Function()? onRescheduleAll,
    Function()? onClearSchedule,
  }) : _taskService = taskService,
       _eventService = eventService,
       _schedulingService = schedulingService,
       _eventController = eventController,
       _resolveEventColor = resolveEventColor,
       _refreshCallback = refreshCallback,
       _context = context,
       _projects = projects ?? [],
       _projectColors = projectColors ?? {},
       _onTaskUpdate = onTaskUpdate,
       _onTaskDelete = onTaskDelete,
       _onEditEvent = onEditEvent,
       _onDeleteEvent = onDeleteEvent,
       _onDeleteSeries = onDeleteSeries,
       _onRescheduleAll = onRescheduleAll,
       _onClearSchedule = onClearSchedule;

  final List<ChatHistoryEntry> _chatHistory = [];
  static const int MAX_HISTORY_ENTRIES = 10;
  static const int MAX_CONTEXT_TOKENS = 2000;
  // Future<ChatResponse> processNaturalLanguage(String userInput) async {
  //   try {
  //     final toolCall = await _determineToolFromNaturalLanguage(userInput);
  //     ChatResponse response;

  //     switch (toolCall.tool) {
  //       case 'create_task':
  //         response = await _createTask(toolCall);
  //         break;
  //       case 'create_event':
  //         response = await _createEvent(toolCall);
  //         break;
  //       case 'schedule_tasks':
  //         response = await _scheduleTasks(toolCall);
  //         break;
  //       case 'get_tasks':
  //         response = await _getTasks(toolCall);
  //         break;
  //       case 'get_events':
  //         response = await _getEvents(toolCall);
  //         break;
  //       case 'update_task':
  //         response = await _updateTask(toolCall);
  //         break;
  //       case 'update_event': // NEW
  //         response = await _updateEvent(toolCall);
  //         break;
  //       case 'find_task_to_update': // NEW
  //         response = await _findTaskToUpdate(toolCall);
  //         break;
  //       case 'find_event_to_update': // NEW
  //         response = await _findEventToUpdate(toolCall);
  //         break;
  //       case 'delete_task':
  //         response = await _deleteTask(toolCall);
  //         break;
  //       case 'delete_event':
  //         response = await _deleteEvent(toolCall);
  //         break;
  //       case 'get_calendar_summary':
  //         response = await _getCalendarSummary(toolCall);
  //         break;
  //       case 'reschedule_task':
  //         response = await _rescheduleTask(toolCall);
  //         break;
  //       case 'clarify_before_action':
  //         final claimedText = toolCall.parameters['claimedText'] ?? '';
  //         return ChatResponse(
  //           text:
  //               "I detected a message that claims an action was performed but I did not run any tool. "
  //               "I will NOT perform changes without your confirmation.\n\n"
  //               "Assistant claimed:\n$claimedText\n\n"
  //               "Do you want me to perform this action now? Reply 'yes' to proceed or 'no' to cancel.",
  //           success: false,
  //           caption: "Action requires confirmation",
  //         );
  //       default:
  //         response = ChatResponse(
  //           text:
  //               "I couldn't understand that request. Please try asking about tasks, events, or scheduling.",
  //           success: false,
  //           caption: toolCall.caption,
  //         );
  //     }

  //     // NEW: Add to history after processing
  //     addToHistory(userInput, response);
  //     return response;
  //   } catch (e) {
  //     final errorResponse = ChatResponse(
  //       text: "Sorry, I encountered an error: $e",
  //       success: false,
  //       caption: "Error occurred",
  //     );
  //     addToHistory(userInput, errorResponse);
  //     return errorResponse;
  //   }
  // }

  // Helper method to execute tool calls
  Future<ChatResponse> _executeToolCall(ToolCall toolCall) async {
    ChatResponse response;

    switch (toolCall.tool) {
      case 'create_task':
        response = await _createTask(toolCall);
        break;
      case 'find_task_to_update':
        response = await _findTaskToUpdate(toolCall);
        break;
      case 'update_task':
        response = await _updateTask(toolCall);
        break;
      // case 'create_task':
      //   response = await _createTask(toolCall);
      //   break;
      case 'create_event':
        response = await _createEvent(toolCall);
        break;
      case 'schedule_tasks':
        response = await _scheduleTasks(toolCall);
        break;
      case 'get_tasks':
        response = await _getTasks(toolCall);
        break;
      case 'get_events':
        response = await _getEvents(toolCall);
        break;
      // case 'update_task':
      //   response = await _updateTask(toolCall);
      //   break;
      case 'update_event': // NEW
        response = await _updateEvent(toolCall);
        break;
      // case 'find_task_to_update': // NEW
      //   response = await _findTaskToUpdate(toolCall);
      //   break;
      case 'find_event_to_update': // NEW
        response = await _findEventToUpdate(toolCall);
        break;
      case 'delete_task':
        response = await _deleteTask(toolCall);
        break;
      case 'delete_event':
        response = await _deleteEvent(toolCall);
        break;
      case 'get_calendar_summary':
        response = await _getCalendarSummary(toolCall);
        break;
      case 'reschedule_task':
        response = await _rescheduleTask(toolCall);
        break;
      case 'clarify_before_action':
        final claimedText = toolCall.parameters['claimedText'] ?? '';
        return ChatResponse(
          text:
              "I detected a message that claims an action was performed but I did not run any tool. "
              "I will NOT perform changes without your confirmation.\n\n"
              "Assistant claimed:\n$claimedText\n\n"
              "Do you want me to perform this action now? Reply 'yes' to proceed or 'no' to cancel.",
          success: false,
          caption: "Action requires confirmation",
        );
      default:
        response = ChatResponse(
          text:
              "I couldn't understand that request. Please try asking about tasks, events, or scheduling.",
          success: false,
          caption: toolCall.caption,
        );
    }

    return response;
  }

  Future<ChatResponse> processNaturalLanguage(String userInput) async {
    try {
      final toolCall = await _determineToolFromNaturalLanguage(userInput);

      // ADDED: Extra validation to catch text responses
      if (toolCall.tool == 'clarify_before_action') {
        print('⚠️ Model returned clarify_before_action - forcing correct tool');
        final forcedToolCall = _forceCorrectToolCall(
          userInput,
          toolCall.parameters['claimedText'] ?? '',
        );
        return await _executeToolCall(forcedToolCall);
      }

      print('Executing tool: ${toolCall.tool}');
      return await _executeToolCall(toolCall);
    } catch (e) {
      final errorResponse = ChatResponse(
        text: "Sorry, I encountered an error: $e",
        success: false,
        caption: "Error occurred",
      );
      addToHistory(userInput, errorResponse);
      return errorResponse;
    }
  }

  // STEP 3: Add these NEW methods after your existing methods
  void addToHistory(String userMessage, ChatResponse response) {
    _chatHistory.add(
      ChatHistoryEntry(
        userMessage: userMessage,
        assistantResponse: response.text,
        timestamp: DateTime.now(),
        toolUsed: response.caption?.split('...')[0],
        success: response.success,
      ),
    );

    if (_chatHistory.length > MAX_HISTORY_ENTRIES) {
      _chatHistory.removeRange(0, _chatHistory.length - MAX_HISTORY_ENTRIES);
    }
  }

  String _buildContextualPrompt(String currentInput) {
  if (_chatHistory.isEmpty) return currentInput;

  final contextParts = <String>[];
  int estimatedTokens = 0;

  // Get the last few interactions
  final recentEntries = _chatHistory.take(3).toList().reversed.toList();
  print(recentEntries);
  
  for (final entry in recentEntries) {
    final contextSnippet = "Previous: User said \"${entry.userMessage}\" -> Assistant used ${entry.toolUsed} ${entry.success ? 'successfully' : 'failed'}";
    if (estimatedTokens + contextSnippet.length * 0.75 < MAX_CONTEXT_TOKENS) {
      contextParts.add(contextSnippet);
      estimatedTokens += (contextSnippet.length * 0.75).round();
    }
  }

  // IMPORTANT: Check if last action was find_task_to_update or find_event_to_update
  if (_chatHistory.isNotEmpty) {
    final lastEntry = _chatHistory.last;
    if (lastEntry.toolUsed == 'find_task_to_update' && lastEntry.success) {
      contextParts.add("CONTEXT: User just found tasks and now wants to update one of them.");
    } else if (lastEntry.toolUsed == 'find_event_to_update' && lastEntry.success) {
      contextParts.add("CONTEXT: User just found events and now wants to update one of them.");
    }
  }

  if (contextParts.isEmpty) return currentInput;
  return "${contextParts.join(' ')}\n\nCurrent request: $currentInput";
}

  List<ChatHistoryEntry> getChatHistory() => List.from(_chatHistory);
  void clearChatHistory() => _chatHistory.clear();

  // String getRecentActionsSummary() {
  //   final recentActions = _chatHistory
  //       .where((entry) => entry.success && entry.toolUsed != null)
  //       .take(5)
  //       .map((entry) => "• ${entry.toolUsed}: ${entry.userMessage}")
  //       .join('\n');

  //   return recentActions.isEmpty
  //       ? "No recent actions"
  //       : "Recent actions:\n$recentActions";
  // }

  // STEP 4: Add these 4 NEW tools to your tools array in _determineToolFromNaturalLanguage
  // Add them after your existing "reschedule_task" tool:
  Future<ToolCall> _determineToolFromNaturalLanguage(String input) async {
    const apiUrl = 'https://api.groq.com/openai/v1/chat/completions';

    final tools = [
      {
        "type": "function",
        "function": {
          "name": "create_task",
          "description":
              "Create a new task with title, description, priority, estimated time, due date, etc.",
          "parameters": {
            "type": "object",
            "properties": {
              "title": {"type": "string", "description": "Task title"},
              "description": {
                "type": "string",
                "description": "Task description",
              },
              "estimatedTime": {
                "type": "number",
                "description": "Estimated hours to complete",
              },
              "priority": {
                "type": "string",
                "enum": ["low", "medium", "high", "urgent"],
              },
              "dueDate": {
                "type": "string",
                "description": "Due date in ISO format",
              },
              "scheduledFor": {
                "type": "string",
                "description": "Scheduled time in ISO format",
              },
              "projectId": {"type": "string", "description": "Project ID"},
              "energyRequired": {
                "type": "string",
                "enum": ["low", "medium", "high"],
              },
              "timePreference": {
                "type": "string",
                "enum": ["flexible", "morning", "afternoon", "specific"],
              },
            },
            "required": ["title", "estimatedTime", "priority"],
          },
        },
      },
      {
        "type": "function",
        "function": {
          "name": "create_event",
          "description":
              "Create a new calendar event with title, time, duration, etc.",
          "parameters": {
            "type": "object",
            "properties": {
              "title": {"type": "string", "description": "Event title"},
              "description": {
                "type": "string",
                "description": "Event description",
              },
              "startTime": {
                "type": "string",
                "description": "Start time in ISO format",
              },
              "endTime": {
                "type": "string",
                "description": "End time in ISO format",
              },
              "priority": {
                "type": "string",
                "enum": ["low", "medium", "high", "urgent"],
              },
              "project": {"type": "string", "description": "Project name"},
              "recurring": {
                "type": "string",
                "enum": ["none", "daily", "weekly", "monthly", "yearly"],
              },
            },
            "required": ["title", "startTime", "endTime"],
          },
        },
      },
      {
        "type": "function",
        "function": {
          "name": "schedule_tasks",
          "description": "Automatically schedule unscheduled tasks",
          "parameters": {
            "type": "object",
            "properties": {
              "specificTasks": {
                "type": "array",
                "items": {"type": "string"},
                "description": "Specific task IDs to schedule",
              },
              "timeRange": {
                "type": "string",
                "description":
                    "Time range for scheduling (e.g., 'this week', 'next 3 days')",
              },
            },
          },
        },
      },
      {
        "type": "function",
        "function": {
          "name": "get_tasks",
          "description": "Retrieve tasks based on criteria",
          "parameters": {
            "type": "object",
            "properties": {
              "status": {
                "type": "string",
                "enum": [
                  "notStarted",
                  "inProgress",
                  "completed",
                  "cancelled",
                  "blocked",
                ],
              },
              "priority": {
                "type": "string",
                "enum": ["low", "medium", "high", "urgent"],
              },
              "dueDate": {
                "type": "string",
                "description": "Filter by due date",
              },
              "projectId": {
                "type": "string",
                "description": "Filter by project",
              },
              "scheduled": {
                "type": "boolean",
                "description": "Filter by scheduled/unscheduled",
              },
            },
          },
        },
      },
      {
        "type": "function",
        "function": {
          "name": "get_events",
          "description": "Retrieve calendar events",
          "parameters": {
            "type": "object",
            "properties": {
              "startDate": {
                "type": "string",
                "description": "Start date for range in ISO format",
              },
              "endDate": {
                "type": "string",
                "description": "End date for range in ISO format",
              },
              "project": {"type": "string", "description": "Filter by project"},
            },
          },
        },
      },
      // {
      //   "type": "function",
      //   "function": {
      //     "name": "update_task",
      //     "description": "Update an existing task",
      //     "parameters": {
      //       "type": "object",
      //       "properties": {
      //         "taskId": {"type": "string", "description": "Task ID to update"},
      //         "title": {"type": "string"},
      //         "status": {
      //           "type": "string",
      //           "enum": [
      //             "notStarted",
      //             "inProgress",
      //             "completed",
      //             "cancelled",
      //             "blocked",
      //           ],
      //         },
      //         "priority": {
      //           "type": "string",
      //           "enum": ["low", "medium", "high", "urgent"],
      //         },
      //         "scheduledFor": {
      //           "type": "string",
      //           "description": "New scheduled time",
      //         },
      //         "progressPercentage": {
      //           "type": "number",
      //           "description": "Progress from 0 to 1",
      //         },
      //       },
      //       "required": ["taskId"],
      //     },
      //   },
      // },
      {
        "type": "function",
        "function": {
          "name": "delete_task",
          "description": "Delete a task",
          "parameters": {
            "type": "object",
            "properties": {
              "taskId": {"type": "string", "description": "Task ID to delete"},
            },
            "required": ["taskId"],
          },
        },
      },
      {
        "type": "function",
        "function": {
          "name": "delete_event",
          "description": "Delete a calendar event",
          "parameters": {
            "type": "object",
            "properties": {
              "eventTitle": {
                "type": "string",
                "description": "Event title or partial title",
              },
              "startTime": {
                "type": "string",
                "description": "Event start time to help identify",
              },
            },
          },
        },
      },
      {
        "type": "function",
        "function": {
          "name": "get_calendar_summary",
          "description": "Get overview of upcoming tasks and events",
          "parameters": {
            "type": "object",
            "properties": {
              "days": {
                "type": "number",
                "description": "Number of days to look ahead",
                "default": 7,
              },
            },
          },
        },
      },
      {
        "type": "function",
        "function": {
          "name": "reschedule_task",
          "description": "Reschedule a specific task to a new time",
          "parameters": {
            "type": "object",
            "properties": {
              "taskId": {
                "type": "string",
                "description": "Task ID to reschedule",
              },
              "newTime": {
                "type": "string",
                "description": "New scheduled time in ISO format",
              },
            },
            "required": ["taskId", "newTime"],
          },
        },
      },
      // {
      //   "type": "function",
      //   "function": {
      //     "name": "update_event",
      //     "description": "Update an existing calendar event",
      //     "parameters": {
      //       "type": "object",
      //       "properties": {
      //         "eventTitle": {
      //           "type": "string",
      //           "description":
      //               "Current event title or partial title to find event",
      //         },
      //         "newTitle": {"type": "string", "description": "New event title"},
      //         "newDescription": {
      //           "type": "string",
      //           "description": "New event description",
      //         },
      //         "newStartTime": {
      //           "type": "string",
      //           "description": "New start time in ISO format",
      //         },
      //         "newEndTime": {
      //           "type": "string",
      //           "description": "New end time in ISO format",
      //         },
      //         "newPriority": {
      //           "type": "string",
      //           "enum": ["low", "medium", "high", "urgent"],
      //           "description": "New priority level",
      //         },
      //         "newProject": {
      //           "type": "string",
      //           "description": "New project name",
      //         },
      //       },
      //       "required": ["eventTitle"],
      //     },
      //   },
      // },
      // {
      //   "type": "function",
      //   "function": {
      //     "name": "find_task_to_update",
      //     "description":
      //         "Find and suggest tasks to update based on partial information",
      //     "parameters": {
      //       "type": "object",
      //       "properties": {
      //         "searchTerm": {
      //           "type": "string",
      //           "description":
      //               "Partial task title or description to search for",
      //         },
      //         "status": {
      //           "type": "string",
      //           "enum": [
      //             "notStarted",
      //             "inProgress",
      //             "completed",
      //             "cancelled",
      //             "blocked",
      //           ],
      //           "description": "Filter by status",
      //         },
      //         "priority": {
      //           "type": "string",
      //           "enum": ["low", "medium", "high", "urgent"],
      //           "description": "Filter by priority",
      //         },
      //       },
      //       "required": ["searchTerm"],
      //     },
      //   },
      // },
      // {
      //   "type": "function",
      //   "function": {
      //     "name": "find_event_to_update",
      //     "description":
      //         "Find and suggest events to update based on partial information",
      //     "parameters": {
      //       "type": "object",
      //       "properties": {
      //         "searchTerm": {
      //           "type": "string",
      //           "description":
      //               "Partial event title or description to search for",
      //         },
      //         "date": {
      //           "type": "string",
      //           "description": "Filter by specific date",
      //         },
      //         "project": {"type": "string", "description": "Filter by project"},
      //       },
      //       "required": ["searchTerm"],
      //     },
      //   },
      // },
    ];

    final isoNow = DateTime.now().toIso8601String();

    //  final isoNow = DateTime.now().toIso8601String();

    // ENHANCED: Even more explicit system prompt
    String systemPrompt = '''You are a function-calling assistant for calendar and task management.
Based on the user's input, determine the appropriate tool to call. Always call exactly one function that best matches the user's intent.

WORKFLOW RULES:
- If the previous action was "find_task_to_update" and user provides update details, call "update_task" with the task information
- If the previous action was "find_event_to_update" and user provides update details, call "update_event" with the event information
- For initial update requests without specific task/event identified, use "find_task_to_update" or "find_event_to_update"

IMPORTANT CONTEXT RULES:
- If the user says "update it" or "change that" or uses pronouns, refer to the recent context to understand what they mean
- If they mention "the task" or "the event" without specifics, use recent successful tool calls to infer what they're referring to  
- For ambiguous requests, prioritize the most recent successful action as the likely subject

PATTERN RECOGNITION:
- "update it to high priority" after finding tasks → call update_task
- "change that to tomorrow" after finding events → call update_event  
- "mark it as completed" after finding tasks → call update_task
- "reschedule that to 3pm" after finding events → call update_event

CRITICAL TOOL-CALL RULES:
- If you intend to perform any action (create / update / delete / reschedule / schedule), you MUST return exactly one function/tool call using the provided tools schema. Do NOT produce assistant-visible text that claims the action was performed.
- If you return a tool call, DO NOT include assistant text describing the result in the same response. The platform will run the tool and produce the final text after execution.
- If you are uncertain which tool or parameters to use, ask a clarifying question (assistant text only). Never assert that a change was made if you haven't returned a tool call.

Example: 'Creating a task named "Buy groceries"...' or 'Updating the presentation task...';


ALWAYS call functions, never return plain text. Current date/time: $isoNow''';


    final contextualInput = _buildContextualPrompt(input);

    final requestBody = {
      "model": "deepseek-r1-distill-llama-70b",
      "messages": [
        {"role": "system", "content": systemPrompt},
            ...buildFullConversationHistory(),
        {"role": "user", "content": contextualInput},
      ],
      "tools": tools,
      "tool_choice": "required", // Force tool usage
      "temperature": 0.0, // Make it more deterministic
      "max_tokens": 500, // Limit response to reduce chance of text generation
    };

    print('=== TOOL CALLING DEBUG ===');
    print('User input: $input');
    print('Contextual input: $contextualInput');

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer ${AppConstants.groqApiKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode != 200) {
      print('API Error: ${response.statusCode} - ${response.body}');
      throw Exception('API Error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    print('Full API response: ${jsonEncode(data)}');

    final message = data['choices'][0]['message'];
    print('Message content: ${message['content']}');
    print('Tool calls: ${message['tool_calls']}');

    final toolCalls = message['tool_calls'] ?? [];

    if (toolCalls.isEmpty) {
      print('❌ NO TOOL CALLS FOUND - Using fallback parsing');

      // Check if there's any text content that suggests an action
      final content = message['content']?.toString() ?? '';
      if (content.isNotEmpty) {
        print('Model returned text instead of tool call: $content');

        // Force the correct tool call based on the input
        return _forceCorrectToolCall(input, content);
      }

      return _parseNaturalLanguageFallback(input);
    }

    print('✅ Tool call found: ${toolCalls[0]['function']['name']}');

    final toolCall = toolCalls[0];
    final functionName = toolCall['function']['name'];
    final arguments = jsonDecode(toolCall['function']['arguments']);

    print('Function: $functionName');
    print('Arguments: $arguments');

    return ToolCall(tool: functionName, parameters: arguments);
  }

List<Map<String, dynamic>> buildFullConversationHistory() {
  final messages = <Map<String, dynamic>>[];
  
  // Get last 3 entries
  final recentEntries = _chatHistory.length <= 3 
    ? _chatHistory 
    : _chatHistory.sublist(_chatHistory.length - 3);
  
  for (final entry in recentEntries) {
    messages.add({"role": "user", "content": entry.userMessage});
    messages.add({"role": "assistant", "content": entry.assistantResponse});
  }
  
  return messages;
}
  // NEW: Force the correct tool call when model returns text instead
  ToolCall _forceCorrectToolCall(String input, String modelResponse) {
    final lowerInput = input.toLowerCase();
    final lowerResponse = modelResponse.toLowerCase();

    print('Forcing tool call for input: $input');
    print('Model tried to respond with: $modelResponse');

    // If the model claims it updated something, force the correct update flow
    if (lowerResponse.contains('updated') ||
        lowerResponse.contains('changed')) {
      if (lowerInput.contains('it') || lowerInput.contains('that')) {
        // Contextual reference - find what to update from history
        if (_chatHistory.isNotEmpty) {
          final lastSuccessful = _chatHistory.reversed.firstWhere(
            (entry) =>
                entry.success &&
                (entry.toolUsed == 'create_task' ||
                    entry.toolUsed == 'create_event'),
            orElse: () => _chatHistory.last,
          );

          if (lastSuccessful.toolUsed == 'create_task') {
            final taskName = _extractTaskNameFromHistory(
              lastSuccessful.userMessage,
            );
            print('Forcing find_task_to_update with searchTerm: $taskName');
            return ToolCall(
              tool: 'find_task_to_update',
              parameters: {'searchTerm': taskName},
            );
          } else if (lastSuccessful.toolUsed == 'create_event') {
            final eventName = _extractEventNameFromHistory(
              lastSuccessful.userMessage,
            );
            print('Forcing find_event_to_update with searchTerm: $eventName');
            return ToolCall(
              tool: 'find_event_to_update',
              parameters: {'searchTerm': eventName},
            );
          }
        }
      }

      // Direct update command
      if (lowerInput.contains('task')) {
        final searchTerm = _extractTaskNameFromInput(input);
        print('Forcing find_task_to_update with searchTerm: $searchTerm');
        return ToolCall(
          tool: 'find_task_to_update',
          parameters: {'searchTerm': searchTerm},
        );
      }
    }

    // If model claims it created something, force creation
    if (lowerResponse.contains('created')) {
      if (lowerInput.contains('task')) {
        print('Forcing create_task');
        return ToolCall(
          tool: 'create_task',
          parameters: _extractTaskParams(input),
        );
      } else if (lowerInput.contains('event')) {
        print('Forcing create_event');
        return ToolCall(
          tool: 'create_event',
          parameters: _extractEventParams(input),
        );
      }
    }

    // If model claims it scheduled something
    if (lowerResponse.contains('scheduled')) {
      print('Forcing schedule_tasks');
      return ToolCall(tool: 'schedule_tasks', parameters: {});
    }

    // Fallback to parsing the input
    print('Using fallback parsing');
    return _parseNaturalLanguageFallback(input);
  }

  // STEP 7: Replace your existing _parseNaturalLanguageFallback method:
  // ENHANCED: Better fallback parsing with context awareness
  ToolCall _parseNaturalLanguageFallback(String input) {
  final lowerInput = input.toLowerCase();

  // CHECK WORKFLOW CONTEXT FIRST
  if (_chatHistory.isNotEmpty) {
    final lastEntry = _chatHistory.last;
    
    // If last action was find_task_to_update, and user provides update info
    if (lastEntry.toolUsed == 'find_task_to_update' && lastEntry.success) {
      if (_containsUpdateInstructions(input)) {
        // Extract task identifier from the last response
        final taskInfo = _extractTaskFromLastResponse(lastEntry.assistantResponse);
        return ToolCall(
          tool: 'update_task',
          parameters: _buildUpdateTaskParams(input, taskInfo),
        );
      }
    }
    
    // If last action was find_event_to_update, and user provides update info  
    if (lastEntry.toolUsed == 'find_event_to_update' && lastEntry.success) {
      if (_containsUpdateInstructions(input)) {
        final eventInfo = _extractEventFromLastResponse(lastEntry.assistantResponse);
        return ToolCall(
          tool: 'update_event', 
          parameters: _buildUpdateEventParams(input, eventInfo),
        );
      }
    }

    // Handle contextual references like "update it", "change that"
    if (lowerInput.contains(RegExp(r'\b(update|change|modify|edit)\s+(it|that|this)\b'))) {
      final lastSuccessful = _chatHistory.reversed.firstWhere(
        (entry) => entry.success && entry.toolUsed != null,
        orElse: () => _chatHistory.last,
      );

      if (lastSuccessful.toolUsed == 'create_task' || 
          lastSuccessful.toolUsed == 'get_tasks' ||
          lowerInput.contains('task')) {
        final taskName = _extractTaskNameFromHistory(lastSuccessful.userMessage);
        return ToolCall(
          tool: 'find_task_to_update',
          parameters: {'searchTerm': taskName},
        );
      } else if (lastSuccessful.toolUsed == 'create_event' || 
                 lastSuccessful.toolUsed == 'get_events' ||
                 lowerInput.contains('event')) {
        final eventName = _extractEventNameFromHistory(lastSuccessful.userMessage);
        return ToolCall(
          tool: 'find_event_to_update',
          parameters: {'searchTerm': eventName},
        );
      }
    }
  }

  

  // Continue with existing logic for new requests...
  if (lowerInput.contains(RegExp(r'\b(update|change|modify|edit)\b'))) {
    if (lowerInput.contains('task')) {
      final searchTerm = _extractQuotedText(input) ?? _extractTaskNameFromInput(input) ?? 'task';
      return ToolCall(
        tool: 'find_task_to_update',
        parameters: {'searchTerm': searchTerm},
      );
    } else if (lowerInput.contains(RegExp(r'\b(event|meeting|appointment)\b'))) {
      final searchTerm = _extractQuotedText(input) ?? _extractEventNameFromInput(input) ?? 'event';
      return ToolCall(
        tool: 'find_event_to_update',
        parameters: {'searchTerm': searchTerm},
      );
    }
  }

  // Rest of existing logic...
  if (lowerInput.contains('create') && lowerInput.contains('task')) {
    return ToolCall(tool: 'create_task', parameters: _extractTaskParams(input));
    } else if (lowerInput.contains('create') &&
        lowerInput.contains(RegExp(r'\b(event|meeting|appointment)\b'))) {
      return ToolCall(
        tool: 'create_event',
        parameters: _extractEventParams(input),
      );
    } else if (lowerInput.contains('schedule')) {
      return ToolCall(tool: 'schedule_tasks', parameters: {});
    } else if (lowerInput.contains(RegExp(r'\b(show|get|list|find)\b'))) {
      if (lowerInput.contains('task')) {
        return ToolCall(tool: 'get_tasks', parameters: {});
      } else {
        return ToolCall(tool: 'get_events', parameters: {});
      }
    } else if (lowerInput.contains(RegExp(r'\b(summary|overview)\b'))) {
      return ToolCall(tool: 'get_calendar_summary', parameters: {});
    } else {
      return ToolCall(tool: 'get_calendar_summary', parameters: {});
    }
  }

  // 4. NEW HELPER METHODS for workflow automation:

bool _containsUpdateInstructions(String input) {
  final lowerInput = input.toLowerCase();
  
  final updatePatterns = [
    // Priority changes
    RegExp(r'\b(high|low|medium|urgent)\s+priority\b'),
    RegExp(r'\bpriority\s+to\s+(high|low|medium|urgent)\b'),
    RegExp(r'\bmake\s+it\s+(high|low|medium|urgent)\b'),
    
    // Status changes  
    RegExp(r'\b(completed?|finished?|done)\b'),
    RegExp(r'\b(in\s+progress|started?|working)\b'),
    RegExp(r'\b(blocked?|cancelled?)\b'),
    RegExp(r'\bmark\s+(it|that)\s+as\s+\w+\b'),
    
    // Time/date changes
    RegExp(r'\b(tomorrow|today|next\s+\w+)\b'),
    RegExp(r'\b\d{1,2}:\d{2}\b'), // Time like 3:30
    RegExp(r'\b(morning|afternoon|evening)\b'),
    RegExp(r'\breschedule\s+(it|that)\b'),
    
    // General update indicators
    RegExp(r'\bchange\s+(it|that)\s+to\b'),
    RegExp(r'\bupdate\s+(it|that)\s+to\b'),
    RegExp(r'\bset\s+(it|that)\s+to\b'),
  ];
  
  return updatePatterns.any((pattern) => pattern.hasMatch(lowerInput));
}
Map<String, String> _extractTaskFromLastResponse(String response) {
  // Parse the assistant's last response to extract task info
  // Look for patterns like "• Task Name (ID: abc123, Status: notStarted, Priority: high)"
  
  final taskPattern = RegExp(r'•\s*(.+?)\s*\(ID:\s*(\w+),\s*Status:\s*(\w+),\s*Priority:\s*(\w+)\)');
  final match = taskPattern.firstMatch(response);
  
  if (match != null) {
    return {
      'title': match.group(1)?.trim() ?? '',
      'id': match.group(2) ?? '',
      'status': match.group(3) ?? '',
      'priority': match.group(4) ?? '',
    };
  }
  
  // Fallback: just extract the first task title mentioned
  final simplePattern = RegExp(r'•\s*(.+?)(?:\s*\(|$)');
  final simpleMatch = simplePattern.firstMatch(response);
  return {
    'title': simpleMatch?.group(1)?.trim() ?? '',
  };
}

Map<String, String> _extractEventFromLastResponse(String response) {
  // Similar logic for events
  final eventPattern = RegExp(r'•\s*(.+?)\s*\(([^)]+)\)');
  final match = eventPattern.firstMatch(response);
  
  if (match != null) {
    return {
      'title': match.group(1)?.trim() ?? '',
      'details': match.group(2) ?? '',
    };
  }
  
  final simplePattern = RegExp(r'•\s*(.+?)(?:\s*\(|$)');
  final simpleMatch = simplePattern.firstMatch(response);
  return {
    'title': simpleMatch?.group(1)?.trim() ?? '',
  };
}

Map<String, dynamic> _buildUpdateTaskParams(String input, Map<String, String> taskInfo) {
  final params = <String, dynamic>{};
  final lowerInput = input.toLowerCase();
  
  // Use the task ID if available, otherwise use title for searching
  if (taskInfo['id']?.isNotEmpty == true) {
    params['taskId'] = taskInfo['id'];
  } else if (taskInfo['title']?.isNotEmpty == true) {
    params['taskTitle'] = taskInfo['title'];
  }
  
  // Extract what to update
  if (lowerInput.contains(RegExp(r'\b(high|urgent)\s+priority\b')) || 
    lowerInput.contains(RegExp(r'\bpriority\s+to\s+(high|urgent)\b'))) {
    params['priority'] = 'high';
  } else if (lowerInput.contains(RegExp(r'\blow\s+priority\b'))) {
    params['priority'] = 'low';
  } else if (lowerInput.contains(RegExp(r'\bmedium\s+priority\b'))) {
    params['priority'] = 'medium';
  }
  
  if (lowerInput.contains(RegExp(r'\b(completed?|finished?|done)\b'))) {
    params['status'] = 'completed';
  } else if (lowerInput.contains(RegExp(r'\bin\s+progress\b'))) {
    params['status'] = 'inProgress';
  } else if (lowerInput.contains(RegExp(r'\bblocked?\b'))) {
    params['status'] = 'blocked';
  }
  
  // Extract time changes
  if (lowerInput.contains('tomorrow')) {
    final tomorrow = DateTime.now().add(Duration(days: 1));
    params['scheduledFor'] = tomorrow.toIso8601String();
  }
  
  return params;
}

Map<String, dynamic> _buildUpdateEventParams(String input, Map<String, String> eventInfo) {
  final params = <String, dynamic>{};
  final lowerInput = input.toLowerCase();
  
  if (eventInfo['title']?.isNotEmpty == true) {
    params['eventTitle'] = eventInfo['title'];
  }
  
  // Similar logic for events...
  if (lowerInput.contains('tomorrow')) {
    final tomorrow = DateTime.now().add(Duration(days: 1));
    params['newStartTime'] = tomorrow.toIso8601String();
  }
  
  return params;
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

  // STEP 8: Add these helper methods after your existing _extractQuotedText method:
  String _extractTaskNameFromHistory(String message) {
    final titleRegex = RegExp(r'"([^"]*)"');
    final match = titleRegex.firstMatch(message);
    return match?.group(1) ?? 'recent task';
  }

  String _extractEventNameFromHistory(String message) {
    final titleRegex = RegExp(r'"([^"]*)"');
    final match = titleRegex.firstMatch(message);
    return match?.group(1) ?? 'recent event';
  }

  Map<String, dynamic> _extractUpdateTaskParams(String input) {
    final params = <String, dynamic>{};
    final titleRegex = RegExp(r'task["\s]*([^"]+)["\s]', caseSensitive: false);
    final titleMatch = titleRegex.firstMatch(input);
    if (titleMatch != null) {
      params['taskTitle'] = titleMatch.group(1)?.trim();
    }

    if (input.toLowerCase().contains('complete')) {
      params['status'] = 'completed';
    } else if (input.toLowerCase().contains('in progress') ||
        input.toLowerCase().contains('working')) {
      params['status'] = 'inProgress';
    } else if (input.toLowerCase().contains('block')) {
      params['status'] = 'blocked';
    } else if (input.toLowerCase().contains('cancel')) {
      params['status'] = 'cancelled';
    }

    if (input.toLowerCase().contains('high priority') ||
        input.toLowerCase().contains('urgent')) {
      params['priority'] = 'high';
    } else if (input.toLowerCase().contains('low priority')) {
      params['priority'] = 'low';
    } else if (input.toLowerCase().contains('medium priority')) {
      params['priority'] = 'medium';
    }

    return params;
  }

  Map<String, dynamic> _extractUpdateEventParams(String input) {
    final params = <String, dynamic>{};
    final titleRegex = RegExp(r'event["\s]*([^"]+)["\s]', caseSensitive: false);
    final titleMatch = titleRegex.firstMatch(input);
    if (titleMatch != null) {
      params['eventTitle'] = titleMatch.group(1)?.trim();
    }
    return params;
  }

  String _extractTaskNameFromInput(String input) {
    // Look for patterns like "update Review code task" or "change the Review code task"
    final taskPattern = RegExp(
      r'\b(?:update|change|modify|edit)\s+(?:the\s+)?(.+?)(?:\s+task)?$',
      caseSensitive: false,
    );
    final match = taskPattern.firstMatch(input);
    return match?.group(1)?.trim() ?? 'task';
  }

  String _extractEventNameFromInput(String input) {
    final eventPattern = RegExp(
      r'\b(?:update|change|modify|edit)\s+(?:the\s+)?(.+?)(?:\s+(?:event|meeting))?$',
      caseSensitive: false,
    );
    final match = eventPattern.firstMatch(input);
    return match?.group(1)?.trim() ?? 'event';
  }

  // Tool implementation methods
  Future<ChatResponse> _createTask(ToolCall toolcall) async {
    Map<String, dynamic> params = toolcall.parameters;
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
        dueDate: params['dueDate'] != null
            ? DateTime.parse(params['dueDate'])
            : null,
        scheduledFor: params['scheduledFor'] != null
            ? DateTime.parse(params['scheduledFor'])
            : null,
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
      // tasks_source.tasks.add(task);
      tasks_source.addTask(task);

      // If scheduled, add to calendar
      if (task.scheduledFor != null) {
        _taskService.syncTasksToCalendar(_eventController);
      }

      _refreshCallback();
      print("contezt: $_context");
      return ChatResponse(
        text: "Created task: ${task.title}",
        success: true,
        taskWidget: _context != null ? _buildTaskWidget(task) : null,
        caption: toolcall.caption,
      );
    } catch (e) {
      return ChatResponse(
        text: "Failed to create task: $e",
        success: false,
        caption: toolcall.caption,
      );
    }
  }

  Future<ChatResponse> _createEvent(ToolCall toolcall) async {
    Map<String, dynamic> params = toolcall.parameters;
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

      _eventService.addEventWithRecurring(
        event,
        _eventController,
        _resolveEventColor,
      );
      _refreshCallback();

      return ChatResponse(
        text: "Created event: ${event.title}",
        success: true,
        eventWidget: _context != null ? _buildEventWidget(event) : null,
      );
    } catch (e) {
      return ChatResponse(
        text: "Failed to create event: $e",
        success: false,
        caption: toolcall.caption,
      );
    }
  }

  Future<ChatResponse> _scheduleTasks(ToolCall toolcall) async {
    Map<String, dynamic> params = toolcall.parameters;
    try {
      final result = await _taskService.scheduleUnscheduledTasks(
        _schedulingService,
        _eventController,
      );

      _refreshCallback();

      return ChatResponse(
        text:
            "Scheduled ${result.scheduledCount} tasks successfully!\n\n${result.reasoning}",
        success: true,
        schedulingResultWidget: _context != null
            ? _buildSchedulingResultWidget(result)
            : null,
        caption: toolcall.caption,
      );
    } catch (e) {
      return ChatResponse(
        text: "Failed to schedule tasks: $e",
        success: false,
        caption: toolcall.caption,
      );
    }
  }

  Future<ChatResponse> _getTasks(ToolCall toolcall) async {
    Map<String, dynamic> params = toolcall.parameters;
    try {
      List<Task> tasks = tasks_source.getTasksList();

      // Apply filters
      if (params['status'] != null) {
        final status = TaskStatus.values.firstWhere(
          (s) => s.name == params['status'],
        );
        tasks = tasks.where((t) => t.status == status).toList();
      }

      if (params['priority'] != null) {
        final priority = Priority.values.firstWhere(
          (p) => p.name == params['priority'],
        );
        tasks = tasks.where((t) => t.priority == priority).toList();
      }

      if (params['scheduled'] != null) {
        final scheduled = params['scheduled'] as bool;
        tasks = tasks
            .where((t) => (t.scheduledFor != null) == scheduled)
            .toList();
      }

      if (tasks.isEmpty) {
        return ChatResponse(
          text: "No tasks found matching your criteria.",
          success: true,
          caption: toolcall.caption,
        );
      }

      final taskList = tasks
          .map((t) => "• ${t.title} (${t.priority.name})")
          .join('\n');

      return ChatResponse(
        text: "Found ${tasks.length} tasks:\n\n$taskList",
        success: true,
        taskListWidget: _context != null ? _buildTaskListWidget(tasks) : null,
        caption: toolcall.caption,
      );
    } catch (e) {
      return ChatResponse(
        text: "Failed to get tasks: $e",
        success: false,
        caption: toolcall.caption,
      );
    }
  }

  Future<ChatResponse> _getEvents(ToolCall toolcall) async {
    Map<String, dynamic> params = toolcall.parameters;
    try {
      List<CalendarEventData> events = _eventController.allEvents;

      // Apply date range filter
      if (params['startDate'] != null && params['endDate'] != null) {
        final startDate = DateTime.parse(params['startDate']);
        final endDate = DateTime.parse(params['endDate']);
        events = events
            .where(
              (e) =>
                  e.date.isAfter(startDate.subtract(Duration(days: 1))) &&
                  e.date.isBefore(endDate.add(Duration(days: 1))),
            )
            .toList();
      }

      if (events.isEmpty) {
        return ChatResponse(
          text: "No events found in the specified range.",
          success: true,
          caption: toolcall.caption,
        );
      }

      final eventList = events
          .map((e) => "• ${e.title} (${e.date.toString().split(' ')[0]})")
          .join('\n');

      return ChatResponse(
        text: "Found ${events.length} events:\n\n$eventList",
        success: true,
        eventListWidget: _context != null
            ? _buildEventListWidget(events.cast<ExtendedCalendarEventData>())
            : null,
        caption: toolcall.caption,
      );
    } catch (e) {
      return ChatResponse(
        text: "Failed to get events: $e",
        success: false,
        caption: toolcall.caption,
      );
    }
  }

  Future<ChatResponse> _deleteTask(ToolCall toolcall) async {
    Map<String, dynamic> params = toolcall.parameters;
    try {
      final taskId = params['taskId'] as String;
      final task = tasks_source.getTasksList().firstWhere(
        (t) => t.id == taskId,
      );

      // tasks_source.tasks.removeWhere((t) => t.id == taskId);
      tasks_source.deleteTask(taskId);
      _taskService.syncTasksToCalendar(_eventController);
      _refreshCallback();

      return ChatResponse(
        text: "Deleted task: ${task.title}",
        success: true,
        caption: toolcall.caption,
      );
    } catch (e) {
      return ChatResponse(
        text: "Failed to delete task: $e",
        success: false,
        caption: toolcall.caption,
      );
    }
  }

  Future<ChatResponse> _deleteEvent(ToolCall toolcall) async {
    Map<String, dynamic> params = toolcall.parameters;
    try {
      final eventTitle = params['eventTitle'] as String;
      final events = _eventController.allEvents
          .where(
            (e) => e.title.toLowerCase().contains(eventTitle.toLowerCase()),
          )
          .toList();

      if (events.isEmpty) {
        return ChatResponse(
          text: "No events found with title: $eventTitle",
          success: false,
          caption: toolcall.caption,
        );
      }

      final event = events.first;
      _eventController.remove(event);
      _refreshCallback();

      return ChatResponse(
        text: "Deleted event: ${event.title}",
        success: true,
        caption: toolcall.caption,
      );
    } catch (e) {
      return ChatResponse(
        text: "Failed to delete event: $e",
        success: false,
        caption: toolcall.caption,
      );
    }
  }

  Future<ChatResponse> _getCalendarSummary(ToolCall toolcall) async {
    Map<String, dynamic> params = toolcall.parameters;
    try {
      final days = params['days'] as int? ?? 7;
      final endDate = DateTime.now().add(Duration(days: days));

      // Get upcoming tasks
      final upcomingTasks = tasks_source
          .getTasksList()
          .where(
            (t) => t.scheduledFor != null && t.scheduledFor!.isBefore(endDate),
          )
          .toList();

      // Get upcoming events
      final upcomingEvents = _eventController.allEvents
          .where((e) => e.date.isBefore(endDate))
          .toList();

      final unscheduledTasks = _taskService.getUnscheduledTasks();
      final overdueTasks = tasks_source
          .getTasksList()
          .where((t) => t.isOverdue)
          .toList();

      final summary =
          '''
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
        summaryWidget: _context != null
            ? _buildSummaryWidget(
                upcomingTasks,
                upcomingEvents,
                unscheduledTasks,
                overdueTasks,
              )
            : null,
        caption: toolcall.caption,
      );
    } catch (e) {
      return ChatResponse(
        text: "Failed to get calendar summary: $e",
        success: false,
        caption: toolcall.caption,
      );
    }
  }

  Future<ChatResponse> _rescheduleTask(ToolCall toolcall) async {
    Map<String, dynamic> params = toolcall.parameters;
    try {
      final taskId = params['taskId'] as String;
      final newTime = DateTime.parse(params['newTime']);

      final task = tasks_source.getTasksList().firstWhere(
        (t) => t.id == taskId,
      );
      final updatedTask = task.copyWith(scheduledFor: newTime);

      tasks_source.saveTask(updatedTask);
      _taskService.syncTasksToCalendar(_eventController);
      _refreshCallback();

      return ChatResponse(
        text:
            "Rescheduled ${task.title} to ${newTime.toString().split('.')[0]}",
        success: true,
        taskWidget: _context != null ? _buildTaskWidget(updatedTask) : null,
        caption: toolcall.caption,
      );
    } catch (e) {
      return ChatResponse(
        text: "Failed to reschedule task: $e",
        success: false,
        caption: toolcall.caption,
      );
    }
  }

  String _getTodaySchedule() {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(Duration(days: 1));

    final todayTasks = tasks_source
        .getTasksList()
        .where(
          (t) =>
              t.scheduledFor != null &&
              t.scheduledFor!.isAfter(todayStart) &&
              t.scheduledFor!.isBefore(todayEnd),
        )
        .toList();

    final todayEvents = _eventController.allEvents
        .where(
          (e) =>
              e.date.isAfter(todayStart.subtract(Duration(days: 1))) &&
              e.date.isBefore(todayEnd),
        )
        .toList();

    if (todayTasks.isEmpty && todayEvents.isEmpty) {
      return "No scheduled items for today.";
    }

    final schedule = <String>[];

    for (final task in todayTasks) {
      schedule.add(
        "• ${task.scheduledFor!.hour.toString().padLeft(2, '0')}:${task.scheduledFor!.minute.toString().padLeft(2, '0')} - ${task.title} (Task)",
      );
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
    if (_context == null) {
      print('[TaskWidget] ❌ Context is null — returning empty Container.');
      return Container();
    }

    return InkWell(
      onTap: () {},
      child: _taskService.buildTaskListTile(
        task,
        onDelete: () {},
        onTap: () {
          print(
            '[TaskWidget] Tap detected on task: ${task.id} (${task.title})',
          );

          if (_onTaskUpdate != null && _onTaskDelete != null) {
            print(
              '[TaskWidget] ✅ Both callbacks are non-null, showing bottom sheet.',
            );

            try {
              showModalBottomSheet(
                context: _context!,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) {
                  print('[TaskWidget] Building TaskDetailModal for ${task.id}');
                  return TaskDetailModal(
                    task: task,
                    projects: _projects,
                    onTaskUpdate: _onTaskUpdate!,
                    onTaskDelete: (taskId) {
                      print('[TaskWidget] onTaskDelete called with id=$taskId');
                      try {
                        final t = tasks_source.getTasksList().firstWhere(
                          (t) => t.id == taskId,
                        );
                        print('[TaskWidget] Found task in source: ${t.title}');
                        _onTaskDelete!(t);
                      } catch (e) {
                        print(
                          '[TaskWidget] ⚠️ Error finding task in source: $e',
                        );
                      }
                    },
                  );
                },
              );
            } catch (e, st) {
              print('[TaskWidget] ❌ Error showing modal: $e\n$st');
            }
          } else {
            print(
              '[TaskWidget] ❌ Not opening modal — '
              '_onTaskUpdate=${_onTaskUpdate != null}, '
              '_onTaskDelete=${_onTaskDelete != null}',
            );
          }
        },
      ),
    );
  }

  Widget _buildEventWidget(ExtendedCalendarEventData event) {
    if (_context == null) return Container();

    return Card(
      child: InkWell(
        onTap: () {
          if (_onEditEvent != null &&
              _onDeleteEvent != null &&
              _onDeleteSeries != null) {
            EventDialogs.showEventDetails(
              _context!,
              event,
              _projectColors,
              (ctx, e) => _onEditEvent!(ctx, e as ExtendedCalendarEventData),
              (ctx, e) => _onDeleteEvent!(ctx, e as ExtendedCalendarEventData),
              _onDeleteSeries!,
            );
          }
        },
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
      ),
    );
  }

  Widget _buildTaskListWidget(List<Task> tasks) {
    if (_context == null) return Container();

    return Column(
      children: tasks.map((task) => _buildTaskWidget(task)).toList(),
    );
  }

  Widget _buildEventListWidget(List<ExtendedCalendarEventData> events) {
    if (_context == null) return Container();

    return Column(
      children: events.map((event) => _buildEventWidget(event)).toList(),
    );
  }

  Widget _buildSchedulingResultWidget(dynamic result) {
    if (_context == null) return Container();

    return Card(
      child: InkWell(
        onTap: () {
          if (_onRescheduleAll != null && _onClearSchedule != null) {
            SchedulingDialogs.showSchedulingResultsDialog(
              _context!,
              result,
              (task) {
                if (_onTaskUpdate != null && _onTaskDelete != null) {
                  showModalBottomSheet(
                    context: _context!,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => TaskDetailModal(
                      task: task,
                      projects: _projects,
                      onTaskUpdate: _onTaskUpdate!,
                      onTaskDelete: (taskId) {
                        final task = tasks_source.getTasksList().firstWhere(
                          (t) => t.id == taskId,
                        );
                        _onTaskDelete!(task);
                      },
                    ),
                  );
                }
              },
              _onRescheduleAll!,
              _onClearSchedule!,
            );
          }
        },
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
                Text(
                  "Scheduled tasks:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...result.scheduledTasks.map(
                  (task) => Padding(
                    padding: EdgeInsets.only(left: 16, top: 4),
                    child: Text("• ${task.title}"),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryWidget(
    List<Task> upcomingTasks,
    List<CalendarEventData> upcomingEvents,
    List<Task> unscheduledTasks,
    List<Task> overdueTasks,
  ) {
    if (_context == null) return Container();

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
                _buildStatCard(
                  "Tasks",
                  upcomingTasks.length.toString(),
                  Colors.blue,
                  upcomingTasks,
                  upcomingEvents,
                  unscheduledTasks,
                  overdueTasks,
                ),
                _buildStatCard(
                  "Events",
                  upcomingEvents.length.toString(),
                  Colors.green,
                  upcomingTasks,
                  upcomingEvents,
                  unscheduledTasks,
                  overdueTasks,
                ),
                _buildStatCard(
                  "Unscheduled",
                  unscheduledTasks.length.toString(),
                  Colors.orange,
                  upcomingTasks,
                  upcomingEvents,
                  unscheduledTasks,
                  overdueTasks,
                ),
                _buildStatCard(
                  "Overdue",
                  overdueTasks.length.toString(),
                  Colors.red,
                  upcomingTasks,
                  upcomingEvents,
                  unscheduledTasks,
                  overdueTasks,
                ),
              ],
            ),
            if (overdueTasks.isNotEmpty) ...[
              SizedBox(height: 12),
              Text(
                "Overdue Tasks:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              ...overdueTasks
                  .take(3)
                  .map(
                    (task) => Padding(
                      padding: EdgeInsets.only(left: 8, top: 4),
                      child: Row(
                        children: [
                          Icon(Icons.warning, size: 16, color: Colors.red),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              task.title,
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              ...unscheduledTasks
                  .take(3)
                  .map(
                    (task) => Padding(
                      padding: EdgeInsets.only(left: 8, top: 4),
                      child: Row(
                        children: [
                          Icon(Icons.schedule, size: 16, color: Colors.orange),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              task.title,
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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

  // ADD THESE METHODS TO YOUR ChatToolCallingService CLASS
  // Place them after your existing tool methods

  // Enhanced update task method - REPLACE your existing _updateTask method with this
  Future<ChatResponse> _updateTask(ToolCall toolcall) async {
    Map<String, dynamic> params = toolcall.parameters;
    try {
      Task? task;

      // Find task by ID or title
      if (params['taskId'] != null) {
        task = tasks_source.getTasksList().firstWhere(
          (t) => t.id == params['taskId'],
          orElse: () =>
              throw Exception('Task not found with ID: ${params['taskId']}'),
        );
      } else if (params['taskTitle'] != null) {
        final matchingTasks = tasks_source
            .getTasksList()
            .where(
              (t) => t.title.toLowerCase().contains(
                params['taskTitle'].toLowerCase(),
              ),
            )
            .toList();

        if (matchingTasks.isEmpty) {
          return ChatResponse(
            text:
                "No tasks found matching '${params['taskTitle']}'. Try being more specific or check the task title.",
            success: false,
            caption: toolcall.caption,
          );
        } else if (matchingTasks.length > 1) {
          final taskList = matchingTasks
              .map((t) => "• ${t.title} (${t.priority.name})")
              .join('\n');
          return ChatResponse(
            text:
                "Found multiple tasks matching '${params['taskTitle']}':\n\n$taskList\n\nPlease be more specific about which task to update.",
            success: false,
            taskListWidget: _context != null
                ? _buildTaskListWidget(matchingTasks)
                : null,
            caption: toolcall.caption,
          );
        }
        task = matchingTasks.first;
      } else {
        return ChatResponse(
          text: "Please specify either a task ID or task title to update.",
          success: false,
          caption: toolcall.caption,
        );
      }

      // Build update summary for user feedback
      List<String> updates = [];

      // Create updated task with only non-null parameters
      final updatedTask = task.copyWith(
        title: params['newTitle'] ?? params['title'] ?? task.title,
        description: params['newDescription'] ?? task.description,
        status: params['newStatus'] != null
            ? TaskStatus.values.firstWhere((s) => s.name == params['newStatus'])
            : (params['status'] != null
                  ? TaskStatus.values.firstWhere(
                      (s) => s.name == params['status'],
                    )
                  : task.status),
        priority: params['newPriority'] != null
            ? Priority.values.firstWhere((p) => p.name == params['newPriority'])
            : (params['priority'] != null
                  ? Priority.values.firstWhere(
                      (p) => p.name == params['priority'],
                    )
                  : task.priority),
        scheduledFor: params['newScheduledFor'] != null
            ? DateTime.parse(params['newScheduledFor'])
            : (params['scheduledFor'] != null
                  ? DateTime.parse(params['scheduledFor'])
                  : task.scheduledFor),
        dueDate: params['newDueDate'] != null
            ? DateTime.parse(params['newDueDate'])
            : task.dueDate,
        estimatedTime:
            params['newEstimatedTime']?.toDouble() ?? task.estimatedTime,
        progressPercentage:
            params['newProgressPercentage']?.toDouble() ??
            (params['progressPercentage']?.toDouble() ??
                task.progressPercentage),
        projectId: params['newProjectId'] ?? task.projectId,
        // updatedAt: DateTime.now(),
      );

      // Track what was updated for user feedback
      if ((params['newTitle'] ?? params['title']) != null &&
          (params['newTitle'] ?? params['title']) != task.title) {
        updates.add(
          "Title: '${task.title}' → '${params['newTitle'] ?? params['title']}'",
        );
      }
      if ((params['newStatus'] ?? params['status']) != null &&
          (params['newStatus'] ?? params['status']) != task.status.name) {
        updates.add(
          "Status: ${task.status.name} → ${params['newStatus'] ?? params['status']}",
        );
      }
      if ((params['newPriority'] ?? params['priority']) != null &&
          (params['newPriority'] ?? params['priority']) != task.priority.name) {
        updates.add(
          "Priority: ${task.priority.name} → ${params['newPriority'] ?? params['priority']}",
        );
      }
      if (params['newScheduledFor'] != null) {
        final newTime = DateTime.parse(params['newScheduledFor']);
        updates.add(
          "Scheduled: ${task.scheduledFor?.toString().split('.')[0] ?? 'None'} → ${newTime.toString().split('.')[0]}",
        );
      }
      if (params['newDueDate'] != null) {
        final newDue = DateTime.parse(params['newDueDate']);
        updates.add(
          "Due date: ${task.dueDate?.toString().split(' ')[0] ?? 'None'} → ${newDue.toString().split(' ')[0]}",
        );
      }
      if (params['newEstimatedTime'] != null &&
          params['newEstimatedTime'] != task.estimatedTime) {
        updates.add(
          "Estimated time: ${task.estimatedTime}h → ${params['newEstimatedTime']}h",
        );
      }
      if ((params['newProgressPercentage'] ?? params['progressPercentage']) !=
              null &&
          (params['newProgressPercentage'] ?? params['progressPercentage']) !=
              task.progressPercentage) {
        updates.add(
          "Progress: ${(task.progressPercentage! * 100).round()}% → ${((params['newProgressPercentage'] ?? params['progressPercentage']) * 100).round()}%",
        );
      }

      // Save the updated task
      tasks_source.saveTask(updatedTask);
      _taskService.syncTasksToCalendar(_eventController);
      _refreshCallback();

      String responseText = "Updated task: ${updatedTask.title}";
      if (updates.isNotEmpty) {
        responseText += "\n\nChanges made:\n${updates.join('\n')}";
      }

      return ChatResponse(
        text: responseText,
        success: true,
        taskWidget: _context != null ? _buildTaskWidget(updatedTask) : null,
        caption: toolcall.caption,
      );
    } catch (e) {
      return ChatResponse(
        text: "Failed to update task: $e",
        success: false,
        caption: toolcall.caption,
      );
    }
  }

  // NEW: Update event method
  Future<ChatResponse> _updateEvent(ToolCall toolcall) async {
    Map<String, dynamic> params = toolcall.parameters;
    try {
      final eventTitle = params['eventTitle'] as String;

      final matchingEvents = _eventController.allEvents
          .where(
            (e) => e.title.toLowerCase().contains(eventTitle.toLowerCase()),
          )
          .cast<ExtendedCalendarEventData>()
          .toList();

      if (matchingEvents.isEmpty) {
        return ChatResponse(
          text:
              "No events found matching '${eventTitle}'. Try being more specific or check the event title.",
          success: false,
          caption: toolcall.caption,
        );
      } else if (matchingEvents.length > 1) {
        final eventList = matchingEvents
            .map((e) => "• ${e.title} (${e.date.toString().split(' ')[0]})")
            .join('\n');
        return ChatResponse(
          text:
              "Found multiple events matching '${eventTitle}':\n\n$eventList\n\nPlease be more specific about which event to update.",
          success: false,
          eventListWidget: _context != null
              ? _buildEventListWidget(matchingEvents)
              : null,
          caption: toolcall.caption,
        );
      }

      final event = matchingEvents.first;
      List<String> updates = [];

      final updatedEvent = ExtendedCalendarEventData(
        title: params['newTitle'] ?? event.title,
        description: params['newDescription'] ?? event.description,
        date: params['newStartTime'] != null
            ? DateTime.parse(params['newStartTime'])
            : event.date,
        startTime: params['newStartTime'] != null
            ? DateTime.parse(params['newStartTime'])
            : event.startTime,
        endTime: params['newEndTime'] != null
            ? DateTime.parse(params['newEndTime'])
            : event.endTime,
        priority: params['newPriority'] != null
            ? Priority.values.firstWhere((p) => p.name == params['newPriority'])
            : event.priority,
        project: params['newProject'] ?? event.project,
        recurring: event.recurring,
        color: _resolveEventColor(
          priority: params['newPriority'] != null
              ? Priority.values.firstWhere(
                  (p) => p.name == params['newPriority'],
                )
              : event.priority,
          project: params['newProject'] ?? event.project,
        ),
      );

      // Track changes for user feedback
      if (params['newTitle'] != null && params['newTitle'] != event.title) {
        updates.add("Title: '${event.title}' → '${params['newTitle']}'");
      }
      if (params['newDescription'] != null &&
          params['newDescription'] != event.description) {
        updates.add("Description updated");
      }
      if (params['newStartTime'] != null) {
        final newStart = DateTime.parse(params['newStartTime']);
        updates.add(
          "Start time: ${event.startTime?.toString().split('.')[0] ?? 'None'} → ${newStart.toString().split('.')[0]}",
        );
      }
      if (params['newEndTime'] != null) {
        final newEnd = DateTime.parse(params['newEndTime']);
        updates.add(
          "End time: ${event.endTime?.toString().split('.')[0] ?? 'None'} → ${newEnd.toString().split('.')[0]}",
        );
      }
      if (params['newPriority'] != null &&
          params['newPriority'] != event.priority.name) {
        updates.add(
          "Priority: ${event.priority.name} → ${params['newPriority']}",
        );
      }
      if (params['newProject'] != null &&
          params['newProject'] != event.project) {
        updates.add(
          "Project: ${event.project ?? 'None'} → ${params['newProject']}",
        );
      }

      _eventController.remove(event);
      _eventController.add(updatedEvent);
      _refreshCallback();

      String responseText = "Updated event: ${updatedEvent.title}";
      if (updates.isNotEmpty) {
        responseText += "\n\nChanges made:\n${updates.join('\n')}";
      }

      return ChatResponse(
        text: responseText,
        success: true,
        eventWidget: _context != null ? _buildEventWidget(updatedEvent) : null,
        caption: toolcall.caption,
      );
    } catch (e) {
      return ChatResponse(
        text: "Failed to update event: $e",
        success: false,
        caption: toolcall.caption,
      );
    }
  }

  // NEW: Find task to update method
  Future<ChatResponse> _findTaskToUpdate(ToolCall toolcall) async {
    Map<String, dynamic> params = toolcall.parameters;
    try {
      final searchTerm = params['searchTerm'] as String;
      List<Task> matchingTasks = tasks_source
          .getTasksList()
          .where(
            (t) =>
                t.title.toLowerCase().contains(searchTerm.toLowerCase()) ||
                (t.description?.toLowerCase().contains(
                      searchTerm.toLowerCase(),
                    ) ??
                    false),
          )
          .toList();

      if (params['status'] != null) {
        final status = TaskStatus.values.firstWhere(
          (s) => s.name == params['status'],
        );
        matchingTasks = matchingTasks.where((t) => t.status == status).toList();
      }

      if (params['priority'] != null) {
        final priority = Priority.values.firstWhere(
          (p) => p.name == params['priority'],
        );
        matchingTasks = matchingTasks
            .where((t) => t.priority == priority)
            .toList();
      }

      if (matchingTasks.isEmpty) {
        return ChatResponse(
          text:
              "No tasks found matching '$searchTerm'${params['status'] != null ? ' with status ${params['status']}' : ''}${params['priority'] != null ? ' with priority ${params['priority']}' : ''}.",
          success: false,
          caption: toolcall.caption,
        );
      }

      final taskList = matchingTasks
          .map(
            (t) =>
                "• ${t.title} (ID: ${t.id}, Status: ${t.status.name}, Priority: ${t.priority.name})",
          )
          .join('\n');

      return ChatResponse(
        text:
            "Found ${matchingTasks.length} task(s) matching '$searchTerm':\n\n$taskList\n\nWhich task would you like to update?",
        success: true,
        taskListWidget: _context != null
            ? _buildTaskListWidget(matchingTasks)
            : null,
        caption: toolcall.caption,
      );
    } catch (e) {
      return ChatResponse(
        text: "Failed to search for tasks: $e",
        success: false,
        caption: toolcall.caption,
      );
    }
  }

  // NEW: Find event to update method
  Future<ChatResponse> _findEventToUpdate(ToolCall toolcall) async {
    Map<String, dynamic> params = toolcall.parameters;
    try {
      final searchTerm = params['searchTerm'] as String;
      List<ExtendedCalendarEventData> matchingEvents = _eventController
          .allEvents
          .where(
            (e) =>
                e.title.toLowerCase().contains(searchTerm.toLowerCase()) ||
                (e.description?.toLowerCase().contains(
                      searchTerm.toLowerCase(),
                    ) ??
                    false),
          )
          .cast<ExtendedCalendarEventData>()
          .toList();

      if (params['date'] != null) {
        final filterDate = DateTime.parse(params['date']);
        matchingEvents = matchingEvents
            .where(
              (e) =>
                  e.date.year == filterDate.year &&
                  e.date.month == filterDate.month &&
                  e.date.day == filterDate.day,
            )
            .toList();
      }

      if (params['project'] != null) {
        matchingEvents = matchingEvents
            .where(
              (e) =>
                  e.project?.toLowerCase().contains(
                    params['project'].toLowerCase(),
                  ) ??
                  false,
            )
            .toList();
      }

      if (matchingEvents.isEmpty) {
        return ChatResponse(
          text:
              "No events found matching '$searchTerm'${params['date'] != null ? ' on ${params['date']}' : ''}${params['project'] != null ? ' in project ${params['project']}' : ''}.",
          success: false,
          caption: toolcall.caption,
        );
      }

      final eventList = matchingEvents
          .map(
            (e) =>
                "• ${e.title} (${e.date.toString().split(' ')[0]}${e.project != null ? ', Project: ${e.project}' : ''})",
          )
          .join('\n');

      return ChatResponse(
        text:
            "Found ${matchingEvents.length} event(s) matching '$searchTerm':\n\n$eventList\n\nWhich event would you like to update?",
        success: true,
        eventListWidget: _context != null
            ? _buildEventListWidget(matchingEvents)
            : null,
        caption: toolcall.caption,
      );
    } catch (e) {
      return ChatResponse(
        text: "Failed to search for events: $e",
        success: false,
        caption: toolcall.caption,
      );
    }
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    List<Task> upcomingTasks,
    List<CalendarEventData> upcomingEvents,
    List<Task> unscheduledTasks,
    List<Task> overdueTasks,
  ) {
    if (_context == null) return Container();

    return GestureDetector(
      onTap: () {
        // Define callback functions for tap handling
        void Function(Task) onTaskTap = (task) {
          if (_onTaskUpdate != null && _onTaskDelete != null) {
            showModalBottomSheet(
              context: _context!,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => TaskDetailModal(
                task: task,
                projects: _projects,
                onTaskUpdate: _onTaskUpdate!,
                onTaskDelete: (taskId) {
                  final task = tasks_source.getTasksList().firstWhere(
                    (t) => t.id == taskId,
                  );
                  _onTaskDelete!(task);
                },
              ),
            );
          }
        };

        void Function(CalendarEventData) onEventTap = (event) {
          if (event is ExtendedCalendarEventData &&
              _onEditEvent != null &&
              _onDeleteEvent != null &&
              _onDeleteSeries != null) {
            EventDialogs.showEventDetails(
              _context!,
              event,
              _projectColors,
              (ctx, e) => _onEditEvent!(ctx, e as ExtendedCalendarEventData),
              (ctx, e) => _onDeleteEvent!(ctx, e as ExtendedCalendarEventData),
              _onDeleteSeries!,
            );
          }
        };

        switch (label) {
          case "Tasks":
            SchedulingDialogs.showTaskListDialog(
              _context!,
              "Upcoming Tasks",
              upcomingTasks,
              Colors.blue,
              Icons.task,
              onTaskTap,
              _onTaskUpdate ?? (task) {},
            );
            break;
          case "Events":
            SchedulingDialogs.showEventListDialog(
              _context!,
              "Upcoming Events",
              upcomingEvents,
              Colors.green,
              Icons.event,
              onEventTap,
            );
            break;
          case "Unscheduled":
            SchedulingDialogs.showTaskListDialog(
              _context!,
              "Unscheduled Tasks",
              unscheduledTasks,
              Colors.orange,
              Icons.schedule,
              onTaskTap,
              _onTaskUpdate ?? (task) {},
            );
            break;
          case "Overdue":
            SchedulingDialogs.showTaskListDialog(
              _context!,
              "Overdue Tasks",
              overdueTasks,
              Colors.red,
              Icons.warning,
              onTaskTap,
              _onTaskUpdate ?? (task) {},
            );
            break;
        }
      },
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
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
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

// Models for tool calling
class ToolCall {
  final String tool;
  final Map<String, dynamic> parameters;
  final String? caption;

  ToolCall({required this.tool, required this.parameters, this.caption});
}

// STEP 9: Add this new data model class at the bottom of your file:
class ChatHistoryEntry {
  final String userMessage;
  final String assistantResponse;
  final DateTime timestamp;
  final String? toolUsed;
  final bool success;

  ChatHistoryEntry({
    required this.userMessage,
    required this.assistantResponse,
    required this.timestamp,
    this.toolUsed,
    required this.success,
  });

  Map<String, dynamic> toJson() => {
    'userMessage': userMessage,
    'assistantResponse': assistantResponse,
    'timestamp': timestamp.toIso8601String(),
    'toolUsed': toolUsed,
    'success': success,
  };
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
  final String? caption;

  ChatResponse({
    required this.text,
    required this.success,
    this.taskWidget,
    this.eventWidget,
    this.taskListWidget,
    this.eventListWidget,
    this.schedulingResultWidget,
    this.summaryWidget,
    this.caption,
  });
}
