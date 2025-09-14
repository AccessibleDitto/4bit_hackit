import 'package:flutter/material.dart';
import 'package:calendar_view/calendar_view.dart';
import '../models/calendar_models.dart';
import '../models/task_models.dart';
import '../utils/date_utils.dart';

class SchedulingDialogs {
  
  // 2. Scheduling Results Detail Dialog
  static void showSchedulingResultsDialog(
    BuildContext context,
    dynamic schedulingResult,
    Function(Task) onTaskTap,
    Function() onRescheduleAll,
    Function() onClearSchedule,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.schedule, color: Colors.blue),
            SizedBox(width: 8),
            Text("Scheduling Results"),
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: 500,
            maxWidth: 400,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Summary Stats
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildResultStat(
                            "Scheduled",
                            "${schedulingResult.scheduledCount ?? 0}",
                            Colors.green,
                            Icons.check_circle,
                          ),
                          _buildResultStat(
                            "Failed",
                            "${(schedulingResult.failedTasks?.length ?? 0)}",
                            Colors.red,
                            Icons.error,
                          ),
                          _buildResultStat(
                            "Conflicts",
                            "${schedulingResult.conflictCount ?? 0}",
                            Colors.orange,
                            Icons.warning,
                          ),
                        ],
                      ),
                      if (schedulingResult.totalTimeScheduled != null) ...[
                        SizedBox(height: 12),
                        Text(
                          "Total time scheduled: ${_formatTime(schedulingResult.totalTimeScheduled)}",
                          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                        ),
                      ],
                    ],
                  ),
                ),
                
                SizedBox(height: 16),
                
                // Successfully Scheduled Tasks
                if (schedulingResult.scheduledTasks?.isNotEmpty == true) ...[
                  Text(
                    "Successfully Scheduled (${schedulingResult.scheduledTasks.length})",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  ...schedulingResult.scheduledTasks.map<Widget>((task) => 
                    _buildTaskResultTile(
                      task,
                      Colors.green,
                      Icons.check_circle,
                      "Scheduled for ${_formatDateTime(task.scheduledFor)}",
                      () => onTaskTap(task),
                    ),
                  ).toList(),
                  SizedBox(height: 16),
                ],
                
                // Failed Tasks
                if (schedulingResult.failedTasks?.isNotEmpty == true) ...[
                  Text(
                    "Failed to Schedule (${schedulingResult.failedTasks.length})",
                    style: TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: 8),
                  ...schedulingResult.failedTasks.map<Widget>((taskWithReason) => 
                    _buildTaskResultTile(
                      taskWithReason.task ?? taskWithReason,
                      Colors.red,
                      Icons.error,
                      taskWithReason.reason ?? "No available time slots",
                      () => onTaskTap(taskWithReason.task ?? taskWithReason),
                    ),
                  ).toList(),
                  SizedBox(height: 16),
                ],
                
                // Conflicts
                if (schedulingResult.conflicts?.isNotEmpty == true) ...[
                  Text(
                    "Scheduling Conflicts (${schedulingResult.conflicts.length})",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(height: 8),
                  ...schedulingResult.conflicts.map<Widget>((conflict) => 
                    Container(
                      margin: EdgeInsets.only(bottom: 8),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            conflict.description ?? "Time conflict detected",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "At: ${_formatDateTime(conflict.time)}",
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ).toList(),
                ],
                
                // Recommendations
                if (schedulingResult.recommendations?.isNotEmpty == true) ...[
                  SizedBox(height: 16),
                  Text(
                    "Recommendations",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  ...schedulingResult.recommendations.map<Widget>((rec) =>
                    Container(
                      margin: EdgeInsets.only(bottom: 8),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lightbulb, color: Colors.blue, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              rec.toString(),
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).toList(),
                ],
              ],
            ),
          ),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (schedulingResult.failedTasks?.isNotEmpty == true)
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onRescheduleAll();
                  },
                  icon: Icon(Icons.refresh, size: 18),
                  label: Text("Retry"),
                  style: TextButton.styleFrom(foregroundColor: Colors.orange),
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onClearSchedule();
                    },
                    child: Text("Clear All"),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Done"),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3. Summary Drill-down Dialogs
  static void showTaskListDialog(
    BuildContext context,
    String title,
    List<Task> tasks,
    Color themeColor,
    IconData icon,
    Function(Task) onTaskTap,
    Function(Task) onTaskUpdate,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(icon, color: themeColor),
            SizedBox(width: 8),
            Text(title),
            Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: themeColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "${tasks.length}",
                style: TextStyle(
                  color: themeColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: 400,
            maxWidth: 500,
          ),
          child: tasks.isEmpty
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 64, color: Colors.grey[300]),
                    SizedBox(height: 16),
                    Text(
                      "No ${title.toLowerCase()}",
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return _buildTaskListTile(
                      task,
                      themeColor,
                      () => onTaskTap(task),
                      (newStatus) {
                        final updatedTask = task.copyWith(status: newStatus);
                        onTaskUpdate(updatedTask);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close"),
          ),
        ],
      ),
    );
  }

  static void showEventListDialog(
    BuildContext context,
    String title,
    List<CalendarEventData> events,
    Color themeColor,
    IconData icon,
    Function(CalendarEventData) onEventTap,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(icon, color: themeColor),
            SizedBox(width: 8),
            Text(title),
            Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: themeColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "${events.length}",
                style: TextStyle(
                  color: themeColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: 400,
            maxWidth: 500,
          ),
          child: events.isEmpty
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.event_available, size: 64, color: Colors.grey[300]),
                    SizedBox(height: 16),
                    Text(
                      "No ${title.toLowerCase()}",
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 0),
                      leading: CircleAvatar(
                        backgroundColor: event.color ?? themeColor,
                        radius: 20,
                        child: Icon(Icons.event, color: Colors.white, size: 18),
                      ),
                      title: Text(
                        event.title,
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (event.description?.isNotEmpty == true)
                            Text(
                              event.description!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          Text(
                            "${_formatDate(event.date)} • ${_formatTime(event.startTime)} - ${_formatTime(event.endTime)}",
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        onEventTap(event);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close"),
          ),
        ],
      ),
    );
  }

  // Helper methods
  static Widget _buildResultStat(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  static Widget _buildTaskResultTile(
    Task task,
    Color color,
    IconData icon,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Icon(icon, color: color, size: 20),
        title: Text(
          task.title,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        onTap: onTap,
        tileColor: color.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color.withOpacity(0.2)),
        ),
      ),
    );
  }

  static Widget _buildTaskListTile(
    Task task,
    Color themeColor,
    VoidCallback onTap,
    Function(TaskStatus) onStatusChange,
  ) {
    Color statusColor = _getStatusColor(task.status);
    
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: GestureDetector(
          onTap: () {
            // Cycle through common statuses
            TaskStatus nextStatus;
            switch (task.status) {
              case TaskStatus.notStarted:
                nextStatus = TaskStatus.inProgress;
                break;
              case TaskStatus.inProgress:
                nextStatus = TaskStatus.completed;
                break;
              case TaskStatus.completed:
                nextStatus = TaskStatus.notStarted;
                break;
              default:
                nextStatus = TaskStatus.inProgress;
            }
            onStatusChange(nextStatus);
          },
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: statusColor, width: 2),
            ),
            child: task.status == TaskStatus.completed
                ? Icon(Icons.check, color: statusColor, size: 16)
                : null,
          ),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: task.status == TaskStatus.completed
                ? TextDecoration.lineThrough
                : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description?.isNotEmpty == true)
              Text(
                task.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            Row(
              children: [
                Text(
                  task.priority.displayName,
                  style: TextStyle(
                    fontSize: 11,
                    color: task.priority.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (task.dueDate != null) ...[
                  Text(" • ", style: TextStyle(color: Colors.grey[600])),
                  Text(
                    _formatDate(task.dueDate),
                    style: TextStyle(
                      fontSize: 11,
                      color: task.isOverdue ? Colors.red : Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Text(
          _formatTimeDouble(task.estimatedTime),
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        onTap: onTap,
      ),
    );
  }

  static Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.notStarted:
        return Colors.grey;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.completed:
        return Colors.green;
      case TaskStatus.cancelled:
        return Colors.grey;
      case TaskStatus.blocked:
        return Colors.orange;
    }
  }

  static String _formatTimeDouble(double? hours) {
    if (hours == null || hours == 0) return '0h';
    int wholeHours = hours.floor();
    int minutes = ((hours - wholeHours) * 60).round();
    
    if (minutes == 0) {
      return '${wholeHours}h';
    } else if (wholeHours == 0) {
      return '${minutes}m';
    } else {
      return '${wholeHours}h ${minutes}m';
    }
  }

  static String _formatTime(DateTime? time) {
    if (time == null) return 'Not set';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return 'No date';
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(Duration(days: 1));
    final selectedDay = DateTime(date.year, date.month, date.day);
    
    if (selectedDay == today) {
      return 'Today';
    } else if (selectedDay == tomorrow) {
      return 'Tomorrow';
    } else {
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    }
  }

  static String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Not set';
    
    return "${_formatDate(dateTime)} at ${_formatTime(dateTime)}";
  }
}