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
      print('⚠️ Scheduling failed: $e');
      print('📜 Stack trace: $stackTrace');
      print('📝 Prompt that caused error:\n$prompt');
      rethrow;
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
- Think through the problem step by step in <think> tags
- Then provide a valid JSON response with two fields: "reasoning" and "schedule"
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
      'max_tokens': 4000, // Increased from 2000
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
      print('❌ API Error: ${response.statusCode}');
      print('📩 Response body: ${response.body}');
      throw Exception('API Error: ${response.statusCode}');
    }
  }

  SchedulingResult _parseSchedulingResponse(String response) {
    try {
      print('🔍 Raw response received:\n$response');

      // Extract thinking content and JSON separately
      final parsedContent = _extractThinkingAndJson(response);
      
      print('💭 Thinking content: ${parsedContent.thinking}');
      print('📦 JSON content: ${parsedContent.json}');

      // If we have valid JSON, parse it
      if (parsedContent.json.isNotEmpty) {
        try {
          final data = jsonDecode(parsedContent.json) as Map<String, dynamic>;
          
          // Combine thinking and reasoning
          String combinedReasoning = '';
          
          if (parsedContent.thinking.isNotEmpty) {
            combinedReasoning += '## AI THINKING PROCESS\n${parsedContent.thinking}\n\n';
          }
          
          if (data['reasoning'] != null && data['reasoning'] is String) {
            String reasoning = (data['reasoning'] as String).replaceAll('|', '\n');
            combinedReasoning += reasoning;
          }

          // Update the data with combined reasoning
          data['reasoning'] = combinedReasoning.trim();
          
          return SchedulingResult.fromJson(data);
        } catch (e) {
          print('❌ JSON parse error: $e');
          // Fall through to thinking-only result
        }
      }

      // If JSON parsing fails or no JSON found, create a result with just thinking content
      if (parsedContent.thinking.isNotEmpty) {
        return SchedulingResult(
          reasoning: '## AI THINKING PROCESS\n${parsedContent.thinking}\n\n## STATUS\nThe AI is still processing the scheduling request. The thinking process shows the analysis in progress.',
          schedule: [],
        );
      }

      // Last fallback
      return SchedulingResult(
        reasoning: "## ERROR\nFailed to parse AI response. The response may have been incomplete or malformed.\n\n## RAW RESPONSE\n$response",
        schedule: [],
      );

    } catch (e, stackTrace) {
      print('❌ Failed to parse response: $e');
      print('❌ Stack trace: $stackTrace');

      return SchedulingResult(
        reasoning: "## PARSING ERROR\nFailed to parse AI response: $e\n\n## RAW RESPONSE\n$response",
        schedule: [],
      );
    }
  }

  ParsedContent _extractThinkingAndJson(String response) {
    String thinking = '';
    String json = '';
    
    // Extract thinking content between <think> tags
    final thinkRegex = RegExp(r'<think>(.*?)</think>', dotAll: true);
    final thinkMatch = thinkRegex.firstMatch(response);
    
    if (thinkMatch != null) {
      thinking = thinkMatch.group(1)?.trim() ?? '';
    }
    
    // Remove thinking content and extract JSON
    String withoutThinking = response.replaceAll(thinkRegex, '').trim();
    
    // Remove markdown fences if present
    withoutThinking = withoutThinking.replaceAll(RegExp(r'^```[a-zA-Z]*\n?'), '');
    withoutThinking = withoutThinking.replaceAll(RegExp(r'```$'), '');
    withoutThinking = withoutThinking.trim();
    
    // Look for JSON content
    final jsonStart = withoutThinking.indexOf('{');
    final jsonEnd = withoutThinking.lastIndexOf('}');
    
    if (jsonStart != -1 && jsonEnd != -1 && jsonStart <= jsonEnd) {
      json = withoutThinking.substring(jsonStart, jsonEnd + 1);
      
      // Validate that this looks like valid JSON structure
      if (_isValidJsonStructure(json)) {
        // Good, we have valid JSON
      } else {
        // Try a more sophisticated approach
        json = _extractJsonWithBraceMatching(withoutThinking);
      }
    }
    
    return ParsedContent(thinking: thinking, json: json);
  }

  String _extractJsonWithBraceMatching(String text) {
    final firstBrace = text.indexOf('{');
    if (firstBrace == -1) return '';
    
    int braceCount = 0;
    int jsonEnd = -1;
    bool inString = false;
    bool escaped = false;
    
    for (int i = firstBrace; i < text.length; i++) {
      final char = text[i];
      
      if (escaped) {
        escaped = false;
        continue;
      }
      
      if (char == '\\') {
        escaped = true;
        continue;
      }
      
      if (char == '"') {
        inString = !inString;
        continue;
      }
      
      if (!inString) {
        if (char == '{') {
          braceCount++;
        } else if (char == '}') {
          braceCount--;
          if (braceCount == 0) {
            jsonEnd = i;
            break;
          }
        }
      }
    }
    
    if (jsonEnd != -1) {
      return text.substring(firstBrace, jsonEnd + 1);
    }
    
    return '';
  }

  bool _isValidJsonStructure(String json) {
    if (json.isEmpty || !json.startsWith('{') || !json.endsWith('}')) {
      return false;
    }
    
    try {
      jsonDecode(json);
      return true;
    } catch (e) {
      return false;
    }
  }
}

class ParsedContent {
  final String thinking;
  final String json;
  
  ParsedContent({required this.thinking, required this.json});
}