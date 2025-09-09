import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task_models.dart';
import '../models/calendar_models.dart';
import '../models/scheduling_models.dart';
import '../utils/constants.dart';

class SchedulingService {
  static const String _groqApiUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'qwen/qwen3-32b';

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
    } catch (e, stackTrace) {
      // Log the error and stack trace for debugging
      print('⚠️ Scheduling failed: $e');
      print('📜 Stack trace: $stackTrace');
      print('📝 Prompt that caused error:\n$prompt');
      rethrow; // keep throwing so caller knows it failed
    }
  }

  String _buildSchedulingPrompt(
    List<Task> tasks,
    List<ExtendedCalendarEventData> events,
    SchedulingConstraints constraints,
    Map<String, String>? changes,
  ) {
    final tasksJson = tasks
        .map(
          (t) => {
            'id': t.id,
            'title': t.title,
            'description': t.description,
            'estimatedTime': t.estimatedTime,
            'priority': t.priority.name,
            'energyRequired': t.energyRequired.name,
            'dueDate': t.dueDate?.toIso8601String(),
            'dependencies': t.dependencies,
            'timePreference': t.timePreference.name,
          },
        )
        .toList();

    final eventsJson = events
        .map(
          (e) => {
            'title': e.title,
            'startTime': e.startTime?.toIso8601String(),
            'endTime': e.endTime?.toIso8601String(),
            'date': e.date.toIso8601String(),
          },
        )
        .toList();

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
- reasoning: Use pipe characters | to separate sections instead of newlines
- schedule: Array of tasks with updated scheduledFor times

REASONING FORMAT (use pipe | instead of newlines to separate sections):
## SCHEDULING SUMMARY|Brief overview of the scheduling approach and key decisions made.|## TASK PRIORITIZATION|- High-priority/urgent tasks and their placement reasoning|- Dependencies handled and their impact on scheduling|- Due date considerations|## TIME ALLOCATION STRATEGY|- How time blocks were allocated|- Task batching decisions (grouping similar tasks)|- Day theming approach (if applied)|## ENERGY MATCHING|- High-energy tasks scheduled during peak hours|- Low-energy tasks scheduled appropriately|- Energy level considerations per task|## CONFLICT RESOLUTION|- How existing calendar events were avoided|- Any scheduling conflicts resolved|- Constraints respected (working hours, breaks)|## DETAILED DECISIONS|For each scheduled task, provide:|- Task: [Task Name]|- Scheduled: [Date/Time]|- Reasoning: [Specific placement reasoning]

IMPORTANT: Use | (pipe) characters instead of newlines in the reasoning field to avoid JSON parsing errors.

Ensure no conflicts with existing events, respect task dependencies and constraints, and schedule within next 30 days unless specified otherwise.

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
        {'role': 'user', 'content': prompt},
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
      // Log the raw response for debugging
      print('❌ API Error: ${response.statusCode}');
      print('📩 Response body: ${response.body}');
      throw Exception('API Error: ${response.statusCode}');
    }
  }

  SchedulingResult _parseSchedulingResponse(String response) {
    try {
      print('🔍 Raw response received:\n$response');

      // Clean up response: remove markdown fences if present
      String cleaned = response.trim();

      // Remove thinking tags if present (some models include <think> tags)
      // Use a more robust approach to handle multiline thinking tags
      if (cleaned.contains('<think>')) {
        final thinkStart = cleaned.indexOf('<think>');
        final thinkEnd = cleaned.indexOf('</think>');
        if (thinkStart != -1 && thinkEnd != -1) {
          // Remove everything from <think> to </think> inclusive
          cleaned =
              cleaned.substring(0, thinkStart) +
              cleaned.substring(thinkEnd + '</think>'.length);
          cleaned = cleaned.trim();
        }
      }

      print('🧹 After removing think tags:\n$cleaned');

      if (cleaned.startsWith('```')) {
        // Remove ```json or ``` at the start and ending ```
        cleaned = cleaned.replaceAll(RegExp(r'^```[a-zA-Z]*\n?'), '');
        cleaned = cleaned.replaceAll(RegExp(r'```$'), '');
        cleaned = cleaned.trim();
      }

      print('🧹 After removing markdown:\n$cleaned');

      // Find the JSON part - look for the first { and last }
      final firstBrace = cleaned.indexOf('{');
      final lastBrace = cleaned.lastIndexOf('}');

      if (firstBrace != -1 && lastBrace != -1 && firstBrace < lastBrace) {
        cleaned = cleaned.substring(firstBrace, lastBrace + 1);
      }

      print('🎯 Final JSON to parse:\n$cleaned');

      final data = jsonDecode(cleaned);

      // Convert pipe-separated reasoning back to newline format for display
      if (data['reasoning'] != null && data['reasoning'] is String) {
        data['reasoning'] = (data['reasoning'] as String).replaceAll('|', '\n');
      }

      return SchedulingResult.fromJson(data);
    } catch (e, stackTrace) {
      print('❌ Failed to parse response. Raw response:\n$response');
      print('❌ Parse error: $e');
      print('❌ Stack trace: $stackTrace');

      // Try to extract any JSON that might be buried in the response
      final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(response);
      if (jsonMatch != null) {
        try {
          print('🔄 Attempting to parse extracted JSON...');
          final extractedJson = jsonMatch.group(0)!;
          print('📝 Extracted JSON: $extractedJson');

          final data = jsonDecode(extractedJson);
          if (data['reasoning'] != null && data['reasoning'] is String) {
            data['reasoning'] = (data['reasoning'] as String).replaceAll(
              '|',
              '\n',
            );
          }
          return SchedulingResult.fromJson(data);
        } catch (e2) {
          print('❌ Even extracted JSON failed to parse: $e2');
        }
      }

      // If all else fails, return a fallback result
      return SchedulingResult(
        reasoning:
            "Failed to parse AI response. Raw response logged for debugging.",
        schedule: [],
      );
    }
  }
}
