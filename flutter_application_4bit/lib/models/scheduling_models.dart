import '../models/task_models.dart';

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