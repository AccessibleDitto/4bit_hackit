import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task_models.dart';
import '../models/calendar_models.dart';
import '../models/scheduling_models.dart';
import '../utils/constants.dart';

class SchedulingService {
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
      'Authorization': 'Bearer ${AppConstants.groqApiKey}',
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