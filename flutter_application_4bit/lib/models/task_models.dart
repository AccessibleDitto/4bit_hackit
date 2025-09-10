// COMPREHENSIVE TASK MODEL FOR 4BIT PRODUCTIVITY APP
// ===================================================

import 'package:flutter/material.dart';

enum Priority { low, medium, high, urgent }

enum TaskStatus { 
  notStarted,
  inProgress, 
  completed, 
  cancelled,
  blocked  // For tasks waiting on dependencies
}

enum EnergyLevel {
  low,    // Administrative, routine tasks
  medium, // Regular focused work
  high    // Deep work, creative tasks, complex problem-solving
}

enum TimePreference {
  flexible,    // Can be scheduled anytime
  morning,     // Prefer AM hours
  afternoon,   // Prefer PM hours
  specific     // Must be at specific time (use scheduledFor)
}

// Extension for Priority display
extension PriorityExtension on Priority {
  String get displayName {
    switch (this) {
      case Priority.low:
        return 'Low';
      case Priority.medium:
        return 'Medium';
      case Priority.high:
        return 'High';
      case Priority.urgent:
        return 'Urgent';
    }
  }
  
  Color get color {
    switch (this) {
      case Priority.low:
        return const Color(0xFF71717A); // Grey
      case Priority.medium:
        return const Color(0xFF3B82F6); // Blue
      case Priority.high:
        return const Color(0xFFF97316); // Orange
      case Priority.urgent:
        return const Color(0xFFEF4444); // Red
    }
  }
}

// Extension for TaskStatus display
extension TaskStatusExtension on TaskStatus {
  String get displayName {
    switch (this) {
      case TaskStatus.notStarted:
        return 'Not Started';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.cancelled:
        return 'Cancelled';
      case TaskStatus.blocked:
        return 'Blocked';
    }
  }
}

// Extension for EnergyLevel display
extension EnergyLevelExtension on EnergyLevel {
  String get displayName {
    switch (this) {
      case EnergyLevel.low:
        return 'Low Energy';
      case EnergyLevel.medium:
        return 'Medium Energy';
      case EnergyLevel.high:
        return 'High Energy';
    }
  }
}

class Task {
    int get sessions {
    // Calculate number of sessions based on estimated time and default focusMinutes (25)
    int focusMinutes = 25;
    if (estimatedTime <= 0) return 1;
    return (estimatedTime * 60 / focusMinutes).ceil();
  }

  int get sessionsLeft {
    // Calculate sessions left based on remaining time and default focusMinutes (25)
    int focusMinutes = 25;
    double remaining = remainingTime;
    if (remaining <= 0) return 0;
    return (remaining * 60 / focusMinutes).ceil();
  }

  // === CORE PROPERTIES ===
  final String id;
  final String title;
  final String? description;
  
  // === TIME MANAGEMENT ===
  final double estimatedTime;        // in hours
  final double timeSpent;           // in hours (for progress tracking)
  final DateTime? dueDate;          // DEADLINE - when it must be completed
  final DateTime? scheduledFor;     // SCHEDULED TIME - when you plan to do it
  final TimePreference timePreference; // When you prefer to do it
  
  // === STATUS & PROGRESS ===
  final TaskStatus status;
  final Priority priority;
  final double? progressPercentage; // 0.0 to 1.0 for partial completion
  
  // === ORGANIZATION ===
  final String? projectId;
  final List<String> tags;          // Flexible categorization
  final EnergyLevel energyRequired; // Energy requirement
  
  // === CONSTRAINTS ===
  final List<String> dependencies;  // Task IDs this depends on
  final String? location;           // Where task must be performed
  final bool isRecurring;           // Is this a recurring task?
  final String? recurrencePattern;  // "daily", "weekly", etc.
  
  // === METADATA ===
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;          // User who created the task
  
  Task({
    required this.id,
    required this.title,
    this.description,
    required this.estimatedTime,
    this.timeSpent = 0.0,
    this.dueDate,
    this.scheduledFor,
    this.timePreference = TimePreference.flexible,
    this.status = TaskStatus.notStarted,
    required this.priority,
    this.progressPercentage,
    this.projectId,
    this.tags = const [],
    this.energyRequired = EnergyLevel.medium,
    this.dependencies = const [],
    this.location,
    this.isRecurring = false,
    this.recurrencePattern,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
  });

  // === COMPUTED PROPERTIES ===
  
  /// Is this task overdue?
  bool get isOverdue {
    if (dueDate == null || status == TaskStatus.completed) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  /// Should this task be scheduled today?
  bool get shouldScheduleToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // If it has a specific scheduled time today
    if (scheduledFor != null) {
      final scheduledDay = DateTime(
        scheduledFor!.year, 
        scheduledFor!.month, 
        scheduledFor!.day
      );
      return scheduledDay.isAtSameMomentAs(today);
    }
    
    // If it's due today or overdue
    if (dueDate != null) {
      final dueDay = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
      return dueDay.isBefore(today.add(Duration(days: 1)));
    }
    
    return false;
  }

  /// How many days until due date?
  int? get daysUntilDue {
    if (dueDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return due.difference(today).inDays;
  }

  /// Is this task ready to be scheduled? (no blocking dependencies)
  bool get isReady {
    return status != TaskStatus.blocked && 
           status != TaskStatus.completed &&
           status != TaskStatus.cancelled;
  }

  /// Remaining time to complete
  double get remainingTime {
    return estimatedTime - timeSpent;
  }

  /// Progress as percentage
  double get completionPercentage {
    if (progressPercentage != null) return progressPercentage!;
    if (estimatedTime <= 0) return status == TaskStatus.completed ? 1.0 : 0.0;
    return (timeSpent / estimatedTime).clamp(0.0, 1.0);
  }

  // === METHODS ===
  
  // Replace your existing copyWith method in the Task class with this fixed version

Task copyWith({
  String? title,
  String? description,
  double? estimatedTime,
  double? timeSpent,
  DateTime? dueDate,
  DateTime? scheduledFor,  // This can be explicitly null
  TimePreference? timePreference,
  TaskStatus? status,
  Priority? priority,
  double? progressPercentage,
  String? projectId,
  List<String>? tags,
  EnergyLevel? energyRequired,
  List<String>? dependencies,
  String? location,
  bool? isRecurring,
  String? recurrencePattern,
  // Add explicit flags for nullable fields that need to be set to null
  bool clearDueDate = false,
  bool clearScheduledFor = false,
  bool clearProgressPercentage = false,
  bool clearProjectId = false,
  bool clearLocation = false,
  bool clearRecurrencePattern = false,
}) {
  return Task(
    id: id,
    title: title ?? this.title,
    description: description ?? this.description,
    estimatedTime: estimatedTime ?? this.estimatedTime,
    timeSpent: timeSpent ?? this.timeSpent,
    dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
    scheduledFor: clearScheduledFor ? null : (scheduledFor ?? this.scheduledFor),
    timePreference: timePreference ?? this.timePreference,
    status: status ?? this.status,
    priority: priority ?? this.priority,
    progressPercentage: clearProgressPercentage ? null : (progressPercentage ?? this.progressPercentage),
    projectId: clearProjectId ? null : (projectId ?? this.projectId),
    tags: tags ?? this.tags,
    energyRequired: energyRequired ?? this.energyRequired,
    dependencies: dependencies ?? this.dependencies,
    location: clearLocation ? null : (location ?? this.location),
    isRecurring: isRecurring ?? this.isRecurring,
    recurrencePattern: clearRecurrencePattern ? null : (recurrencePattern ?? this.recurrencePattern),
    createdAt: createdAt,
    updatedAt: DateTime.now(),
    createdBy: createdBy,
  );
}

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'estimatedTime': estimatedTime,
    'timeSpent': timeSpent,
    'dueDate': dueDate?.toIso8601String(),
    'scheduledFor': scheduledFor?.toIso8601String(),
    'timePreference': timePreference.name,
    'status': status.name,
    'priority': priority.name,
    'progressPercentage': progressPercentage,
    'projectId': projectId,
    'tags': tags,
    'energyRequired': energyRequired.name,
    'dependencies': dependencies,
    'location': location,
    'isRecurring': isRecurring,
    'recurrencePattern': recurrencePattern,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'createdBy': createdBy,
  };

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      estimatedTime: json['estimatedTime'].toDouble(),
      timeSpent: json['timeSpent']?.toDouble() ?? 0.0,
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      scheduledFor: json['scheduledFor'] != null ? DateTime.parse(json['scheduledFor']) : null,
      timePreference: TimePreference.values.firstWhere(
        (e) => e.name == json['timePreference'],
        orElse: () => TimePreference.flexible,
      ),
      status: TaskStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TaskStatus.notStarted,
      ),
      priority: Priority.values.firstWhere((e) => e.name == json['priority']),
      progressPercentage: json['progressPercentage']?.toDouble(),
      projectId: json['projectId'],
      tags: List<String>.from(json['tags'] ?? []),
      energyRequired: EnergyLevel.values.firstWhere(
        (e) => e.name == json['energyRequired'],
        orElse: () => EnergyLevel.medium,
      ),
      dependencies: List<String>.from(json['dependencies'] ?? []),
      location: json['location'],
      isRecurring: json['isRecurring'] ?? false,
      recurrencePattern: json['recurrencePattern'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      createdBy: json['createdBy'],
    );
  }

  @override
  String toString() {
    final dueInfo = dueDate != null ? ' (due: ${dueDate!.toString().substring(0, 10)})' : '';
    final overdue = isOverdue ? ' [OVERDUE]' : '';
    return '$title - ${estimatedTime}h [${priority.name}]$dueInfo$overdue';
  }
}

// ===================================================
// 🎯 USAGE EXAMPLES & MIGRATION STRATEGY
// ===================================================

void demonstrateImprovedTaskClass() {
  print('=== IMPROVED TASK CLASS DEMO ===\n');

  // Create sample tasks
  final tasks = [
    // Urgent task due today
    Task(
      id: 'task_001',
      title: 'Submit quarterly report',
      description: 'Compile Q3 financial data and submit to management',
      estimatedTime: 2.0,
      dueDate: DateTime.now(), // Due today!
      priority: Priority.urgent,
      energyRequired: EnergyLevel.high,
      projectId: 'quarterly-reporting',
      tags: ['finance', 'deadline', 'management'],
      createdAt: DateTime.now().subtract(Duration(days: 5)),
      updatedAt: DateTime.now().subtract(Duration(days: 2)),
    ),

    // Task scheduled for specific time
    Task(
      id: 'task_002',
      title: 'Team standup meeting',
      estimatedTime: 0.5,
      scheduledFor: DateTime.now().add(Duration(hours: 2)), // Specific time
      timePreference: TimePreference.specific,
      priority: Priority.medium,
      energyRequired: EnergyLevel.low,
      location: 'Conference Room A',
      isRecurring: true,
      recurrencePattern: 'daily',
      createdAt: DateTime.now().subtract(Duration(days: 30)),
      updatedAt: DateTime.now(),
    ),

    // Flexible task with dependencies
    Task(
      id: 'task_003',
      title: 'Code review - authentication module',
      description: 'Review pull request #247 for security vulnerabilities',
      estimatedTime: 1.0,
      timeSpent: 0.25, // 15 minutes already spent
      dueDate: DateTime.now().add(Duration(days: 2)),
      timePreference: TimePreference.morning, // Prefer morning
      priority: Priority.high,
      energyRequired: EnergyLevel.high,
      dependencies: ['task_004'], // Depends on another task
      projectId: 'auth-system',
      tags: ['code-review', 'security', 'backend'],
      createdAt: DateTime.now().subtract(Duration(hours: 8)),
      updatedAt: DateTime.now().subtract(Duration(hours: 2)),
    ),

    // Low priority, flexible task
    Task(
      id: 'task_004',
      title: 'Update project documentation',
      estimatedTime: 1.5,
      dueDate: DateTime.now().add(Duration(days: 7)), // Due next week
      priority: Priority.low,
      energyRequired: EnergyLevel.medium,
      timePreference: TimePreference.afternoon,
      projectId: 'documentation',
      tags: ['docs', 'maintenance'],
      createdAt: DateTime.now().subtract(Duration(days: 3)),
      updatedAt: DateTime.now().subtract(Duration(days: 1)),
    ),
  ];

  // Demonstrate computed properties
  for (final task in tasks) {
    print('📋 ${task.title}');
    print('   Should schedule today: ${task.shouldScheduleToday}');
    print('   Is overdue: ${task.isOverdue}');
    print('   Days until due: ${task.daysUntilDue}');
    print('   Is ready: ${task.isReady}');
    print('   Completion: ${(task.completionPercentage * 100).toStringAsFixed(1)}%');
    print('   Remaining time: ${task.remainingTime}h');
    print('');
  }

  // Show scheduling priority
  print('📊 SCHEDULING PRIORITY ORDER:');
  final sortedTasks = [...tasks];
  sortedTasks.sort((a, b) {
    // First: Overdue tasks
    if (a.isOverdue && !b.isOverdue) return -1;
    if (b.isOverdue && !a.isOverdue) return 1;
    
    // Then: Tasks due today
    if (a.shouldScheduleToday && !b.shouldScheduleToday) return -1;
    if (b.shouldScheduleToday && !a.shouldScheduleToday) return 1;
    
    // Then: By priority
    const priorityOrder = {Priority.urgent: 0, Priority.high: 1, Priority.medium: 2, Priority.low: 3};
    final aPriority = priorityOrder[a.priority]!;
    final bPriority = priorityOrder[b.priority]!;
    if (aPriority != bPriority) return aPriority.compareTo(bPriority);
    
    // Finally: By due date
    if (a.dueDate != null && b.dueDate != null) {
      return a.dueDate!.compareTo(b.dueDate!);
    }
    
    return 0;
  });

  for (int i = 0; i < sortedTasks.length; i++) {
    final task = sortedTasks[i];
    print('${i + 1}. ${task.title} [${task.priority.name}]${task.isOverdue ? " ⚠️" : ""}${task.shouldScheduleToday ? " 📅" : ""}');
  }
}

// ===================================================
// 🎯 PROJECT MODEL
// ===================================================
class Project {
  final String id;
  final String name;
  final Color color;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  Project({
    required this.id,
    required this.name,
    required this.color,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });
  
  // Helper method for creating new projects
  factory Project.create({
    required String name,
    required Color color,
    String? description,
  }) {
    final now = DateTime.now();
    return Project(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Generate ID
      name: name,
      color: color,
      description: description,
      createdAt: now,
      updatedAt: now,
    );
  }
  
  // Helper method for updating projects
  Project copyWith({
    String? name,
    Color? color,
    String? description,
  }) {
    return Project(
      id: id,
      name: name ?? this.name,
      color: color ?? this.color,
      description: description ?? this.description,
      createdAt: createdAt, // Keep original
      updatedAt: DateTime.now(), // Update timestamp
    );
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'color': color.value,
    'description': description,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
  
  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      name: json['name'],
      color: Color(json['color']),
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

class ProjectStats {
  final int totalTasks;
  final int completedTasks;
  final int activeTasks;
  final double totalTimeSpent;
  final double totalEstimatedTime;

  ProjectStats({
    required this.totalTasks,
    required this.completedTasks,
    required this.activeTasks,
    required this.totalTimeSpent,
    required this.totalEstimatedTime,
  });
}