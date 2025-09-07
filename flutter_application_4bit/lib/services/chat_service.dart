import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../utils/constants.dart';

class ChatService {
  static const String _groqApiUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.3-70b-versatile';
  
  final List<Map<String, String>> _conversationHistory = [];
  
  List<Map<String, String>> get conversationHistory => 
      List.unmodifiable(_conversationHistory);
  
  void addUserMessage(String message) {
    _conversationHistory.add({
      'role': 'user',
      'content': message,
    });
  }
  
  void addAssistantMessage(String message) {
    _conversationHistory.add({
      'role': 'assistant',
      'content': message,
    });
  }
  
  void clearHistory() {
    _conversationHistory.clear();
  }
  
  Future<String> sendMessage() async {
    try {
      final headers = {
        'Authorization': 'Bearer ${AppConstants.groqApiKey}',
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
          return data['choices'][0]['message']['content'] as String;
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
}