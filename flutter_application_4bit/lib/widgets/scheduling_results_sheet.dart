import 'package:flutter/material.dart';
import '../models/task_models.dart';

class ReasoningSection {
  final String title;
  final String content;
  final IconData icon;
  final Color color;

  ReasoningSection({
    required this.title,
    required this.content,
    required this.icon,
    required this.color,
  });

  static List<ReasoningSection> parseReasoning(String reasoning) {
    if (reasoning.isEmpty) return [];

    final sections = <ReasoningSection>[];
    final lines = reasoning.split('\n');
    
    String currentSection = '';
    List<String> currentContent = [];
    
    for (final line in lines) {
      if (line.startsWith('## ')) {
        // Save previous section if exists
        if (currentSection.isNotEmpty && currentContent.isNotEmpty) {
          sections.add(_createReasoningSection(currentSection, currentContent.join('\n')));
        }
        
        // Start new section
        currentSection = line.substring(3).trim();
        currentContent = [];
      } else if (line.trim().isNotEmpty) {
        currentContent.add(line);
      }
    }
    
    // Add the last section
    if (currentSection.isNotEmpty && currentContent.isNotEmpty) {
      sections.add(_createReasoningSection(currentSection, currentContent.join('\n')));
    }
    
    // Fallback: if no structured sections found, create a single general section
    if (sections.isEmpty) {
      sections.add(ReasoningSection(
        title: 'Analysis',
        content: reasoning,
        icon: Icons.analytics,
        color: Colors.blue,
      ));
    }
    
    return sections;
  }
  
  static ReasoningSection _createReasoningSection(String title, String content) {
    switch (title.toUpperCase()) {
      case 'AI THINKING PROCESS':
        return ReasoningSection(
          title: title,
          content: content,
          icon: Icons.psychology,
          color: Colors.deepPurple,
        );
      case 'SCHEDULING SUMMARY':
        return ReasoningSection(
          title: title,
          content: content,
          icon: Icons.summarize,
          color: Colors.blue,
        );
      case 'TASK PRIORITIZATION':
        return ReasoningSection(
          title: title,
          content: content,
          icon: Icons.priority_high,
          color: Colors.red,
        );
      case 'TIME ALLOCATION STRATEGY':
        return ReasoningSection(
          title: title,
          content: content,
          icon: Icons.access_time,
          color: Colors.orange,
        );
      case 'ENERGY MATCHING':
        return ReasoningSection(
          title: title,
          content: content,
          icon: Icons.battery_charging_full,
          color: Colors.green,
        );
      case 'CONFLICT RESOLUTION':
        return ReasoningSection(
          title: title,
          content: content,
          icon: Icons.warning_amber,
          color: Colors.amber,
        );
      case 'DETAILED DECISIONS':
        return ReasoningSection(
          title: title,
          content: content,
          icon: Icons.list_alt,
          color: Colors.purple,
        );
      case 'STATUS':
        return ReasoningSection(
          title: title,
          content: content,
          icon: Icons.info_outline,
          color: Colors.blue,
        );
      case 'ERROR':
      case 'PARSING ERROR':
        return ReasoningSection(
          title: title,
          content: content,
          icon: Icons.error_outline,
          color: Colors.red,
        );
      case 'RAW RESPONSE':
        return ReasoningSection(
          title: title,
          content: content,
          icon: Icons.code,
          color: Colors.grey,
        );
      default:
        return ReasoningSection(
          title: title,
          content: content,
          icon: Icons.info,
          color: Colors.grey,
        );
    }
  }
}

class SchedulingResultsBottomSheet extends StatefulWidget {
  final int scheduledCount;
  final List<Task> scheduledTasks;
  final String reasoning;
  final VoidCallback onViewCalendar;
  final VoidCallback onUndoScheduling;

  const SchedulingResultsBottomSheet({
    Key? key,
    required this.scheduledCount,
    required this.scheduledTasks,
    required this.reasoning,
    required this.onViewCalendar,
    required this.onUndoScheduling,
  }) : super(key: key);

  @override
  State<SchedulingResultsBottomSheet> createState() => _SchedulingResultsBottomSheetState();
}

class _SchedulingResultsBottomSheetState extends State<SchedulingResultsBottomSheet> {
  final Set<int> _expandedSections = <int>{};

  @override
  void initState() {
    super.initState();
    
    // Auto-expand the thinking process section if present
    final sections = ReasoningSection.parseReasoning(widget.reasoning);
    for (int i = 0; i < sections.length; i++) {
      if (sections[i].title.toUpperCase().contains('THINKING') || 
          sections[i].title.toUpperCase().contains('ERROR') ||
          sections[i].title.toUpperCase().contains('STATUS')) {
        _expandedSections.add(i);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reasoningSections = ReasoningSection.parseReasoning(widget.reasoning);
    final bool hasScheduledTasks = widget.scheduledTasks.isNotEmpty;
    final bool isProcessing = widget.scheduledCount == 0 && reasoningSections.any(
      (section) => section.title.toUpperCase().contains('THINKING') || 
                   section.title.toUpperCase().contains('STATUS')
    );
    
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isProcessing ? Colors.orange[100] : 
                               hasScheduledTasks ? Colors.green[100] : Colors.red[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isProcessing ? Icons.hourglass_empty :
                        hasScheduledTasks ? Icons.check_circle : Icons.error_outline,
                        color: isProcessing ? Colors.orange[600] :
                               hasScheduledTasks ? Colors.green[600] : Colors.red[600],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isProcessing ? 'Processing...' :
                            hasScheduledTasks ? 'Scheduling Complete!' : 'Scheduling Failed',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            isProcessing ? 'AI is analyzing your tasks and constraints' :
                            hasScheduledTasks ? 
                            'Successfully scheduled ${widget.scheduledCount} ${widget.scheduledCount == 1 ? 'task' : 'tasks'}' :
                            'Unable to complete scheduling - see details below',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Scheduled Tasks Section (only show if tasks were scheduled)
                      if (hasScheduledTasks) ...[
                        _buildSectionHeader('Scheduled Tasks', Icons.task_alt, Colors.blue),
                        const SizedBox(height: 8),
                        ...widget.scheduledTasks.map((task) => _buildTaskItem(task)),
                        const SizedBox(height: 24),
                      ],

                      // AI Analysis Sections
                      if (reasoningSections.isNotEmpty) ...[
                        _buildSectionHeader(
                          isProcessing ? 'AI Analysis (In Progress)' : 'AI Analysis', 
                          Icons.psychology, 
                          isProcessing ? Colors.orange : Colors.purple
                        ),
                        const SizedBox(height: 12),
                        ...reasoningSections.asMap().entries.map((entry) {
                          final index = entry.key;
                          final section = entry.value;
                          return _buildReasoningSection(section, index);
                        }),
                        const SizedBox(height: 24),
                      ],
                      
                      // Processing message if no sections
                      if (reasoningSections.isEmpty) ...[
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Column(
                              children: [
                                CircularProgressIndicator(color: Colors.orange),
                                const SizedBox(height: 16),
                                Text(
                                  'AI is processing your request...',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (hasScheduledTasks) ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: widget.onUndoScheduling,
                              icon: const Icon(Icons.undo),
                              label: const Text('Undo Scheduling'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: widget.onViewCalendar,
                              icon: const Icon(Icons.calendar_today),
                              label: const Text('View Calendar'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ] else if (isProcessing) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Could add retry logic here
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Could add retry logic here
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry Scheduling'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildReasoningSection(ReasoningSection section, int index) {
    final isExpanded = _expandedSections.contains(index);
    final lines = section.content.split('\n').where((line) => line.trim().isNotEmpty).toList();
    final preview = lines.take(3).join('\n'); // Show more lines in preview for thinking process
    final hasMore = lines.length > 3;
    final isThinkingSection = section.title.toUpperCase().contains('THINKING');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _expandedSections.contains(index),
          leading: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: section.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              section.icon,
              color: section.color,
              size: 18,
            ),
          ),
          title: Text(
            section.title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: section.color,
            ),
          ),
          subtitle: !isExpanded && hasMore
              ? Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    preview,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontFamily: isThinkingSection ? 'monospace' : null,
                    ),
                    maxLines: isThinkingSection ? 5 : 2, // More lines for thinking
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              : null,
          onExpansionChanged: (expanded) {
            setState(() {
              if (expanded) {
                _expandedSections.add(index);
              } else {
                _expandedSections.remove(index);
              }
            });
          },
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildFormattedContent(section.content, section.color, isThinkingSection),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormattedContent(String content, Color accentColor, bool isThinkingSection) {
    final lines = content.split('\n').where((line) => line.trim().isNotEmpty);
    final widgets = <Widget>[];

    for (final line in lines) {
      if (line.trim().startsWith('- ')) {
        // Bullet point
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8, right: 8),
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: Text(
                    line.substring(2).trim(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: isThinkingSection ? 'monospace' : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (line.trim().startsWith('Task:')) {
        // Task detail formatting
        widgets.add(
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: accentColor.withOpacity(0.2)),
            ),
            child: Text(
              line,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                fontFamily: isThinkingSection ? 'monospace' : null,
              ),
            ),
          ),
        );
      } else {
        // Regular text
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              line.trim(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: isThinkingSection ? 'monospace' : null,
              ),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildTaskItem(Task task) {
    if (task.scheduledFor == null) {
      return const SizedBox.shrink();
    }

    final scheduledTime = task.scheduledFor!;
    final formattedDate = '${_getWeekday(scheduledTime.weekday)}, ${_getMonth(scheduledTime.month)} ${scheduledTime.day}';
    final formattedTime = '${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: task.priority.color.withOpacity(0.02),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: task.priority.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  task.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: task.priority.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  task.priority.name.toUpperCase(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: task.priority.color,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '$formattedDate at $formattedTime',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
              Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${task.estimatedTime}h',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          if (task.description != null && task.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              task.description!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  String _getWeekday(int weekday) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[weekday - 1];
  }

  String _getMonth(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month - 1];
  }
}