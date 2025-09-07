class AppConstants {
  // API Configuration
  static const String groqApiKey = String.fromEnvironment('groqApiKey');
  static const String groqApiUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const String groqModel = 'llama-3.3-70b-versatile';
  
  // Storage Keys
  static const String tasksStorageKey = 'app_tasks';
  
  // Default Settings
  static const double defaultTaskDuration = 1.0;
  static const int maxSchedulingDaysAhead = 365;
  static const int maxRecurringEvents = 400;
  
  // UI Constants
  static const double condensedHeightPerMinute = 0.6;
  static const double normalHeightPerMinute = 1.2;
  static const double chatHeightRatio = 0.5;
}