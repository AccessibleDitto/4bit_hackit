import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_4bit/models/task_models.dart';

class TaskDetailModal extends StatefulWidget {
  final Task task;
  final List<Project> projects;
  final Function(Task) onTaskUpdate;

  const TaskDetailModal({
    super.key,
    required this.task,
    required this.projects,
    required this.onTaskUpdate,
  });

  @override
  _TaskDetailModalState createState() => _TaskDetailModalState();
}

class _TaskDetailModalState extends State<TaskDetailModal> {
  late Task _currentTask;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _currentTask = widget.task;
    _titleController.text = _currentTask.title;
    _descriptionController.text = _currentTask.description ?? '';
    _locationController.text = _currentTask.location ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  String _formatTime(double hours) {
    if (hours == 0) return '0h';
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

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not set';
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final selectedDay = DateTime(date.year, date.month, date.day);
    
    if (selectedDay == today) {
      return 'Today';
    } else if (selectedDay == tomorrow) {
      return 'Tomorrow';
    } else if (selectedDay.year == now.year) {
      return '${date.day} ${_getMonthName(date.month)}';
    } else {
      return '${date.day} ${_getMonthName(date.month)} ${date.year}';
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Not set';
    
    final dateStr = _formatDate(dateTime);
    final timeStr = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    
    return '$dateStr at $timeStr';
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Project? _getProject() {
    if (_currentTask.projectId == null) return null;
    try {
      return widget.projects.firstWhere((p) => p.id == _currentTask.projectId);
    } catch (e) {
      return null;
    }
  }

  void _saveChanges() {
    final updatedTask = _currentTask.copyWith(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
    );
    
    widget.onTaskUpdate(updatedTask);
    setState(() {
      _currentTask = updatedTask;
      _isEditing = false;
    });
  }

  void _updateTaskStatus(TaskStatus newStatus) {
    final updatedTask = _currentTask.copyWith(status: newStatus);
    widget.onTaskUpdate(updatedTask);
    setState(() {
      _currentTask = updatedTask;
    });
  }

  void _updateTaskPriority(Priority newPriority) {
    final updatedTask = _currentTask.copyWith(priority: newPriority);
    widget.onTaskUpdate(updatedTask);
    setState(() {
      _currentTask = updatedTask;
    });
  }

  Widget _buildInfoRow(String label, String value, {IconData? icon, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, color: const Color(0xFF71717A), size: 20),
            const SizedBox(width: 12),
          ],
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: const Color(0xFF71717A),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                color: valueColor ?? Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: const Color(0xFF71717A),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF27272A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF71717A).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: TextField(
              controller: controller,
              style: GoogleFonts.inter(color: Colors.white),
              maxLines: maxLines,
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(TaskStatus status, bool isSelected) {
    Color getStatusColor() {
      switch (status) {
        case TaskStatus.notStarted:
          return const Color(0xFF71717A);
        case TaskStatus.inProgress:
          return const Color(0xFF3B82F6);
        case TaskStatus.completed:
          return const Color(0xFF10B981);
        case TaskStatus.cancelled:
          return const Color(0xFF71717A);
        case TaskStatus.blocked:
          return const Color(0xFFF97316);
      }
    }

    final color = getStatusColor();
    
    return GestureDetector(
      onTap: () => _updateTaskStatus(status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        margin: const EdgeInsets.only(right: 8, bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : const Color(0xFF27272A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : const Color(0xFF71717A).withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          status.displayName,
          style: GoogleFonts.inter(
            color: isSelected ? color : const Color(0xFF71717A),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final project = _getProject();
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF18181B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFF71717A).withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF71717A),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Task Details',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        if (_isEditing) {
                          _saveChanges();
                        } else {
                          setState(() {
                            _isEditing = true;
                          });
                        }
                      },
                      icon: Icon(
                        _isEditing ? Icons.check : Icons.edit,
                        color: const Color(0xFF9333EA),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  if (_isEditing)
                    _buildEditableField('Title', _titleController)
                  else
                    Text(
                      _currentTask.title,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Description
                  if (_isEditing)
                    _buildEditableField('Description', _descriptionController, maxLines: 3)
                  else if (_currentTask.description != null && _currentTask.description!.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Description',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF71717A),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _currentTask.description!,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),

                  // Status
                  Text(
                    'Status',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF71717A),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    children: TaskStatus.values.map((status) {
                      return _buildStatusChip(status, status == _currentTask.status);
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // Priority
                  Row(
                    children: [
                      Text(
                        'Priority',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF71717A),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Wrap(
                          children: Priority.values.map((priority) {
                            final isSelected = priority == _currentTask.priority;
                            return GestureDetector(
                              onTap: () => _updateTaskPriority(priority),
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isSelected ? priority.color.withOpacity(0.2) : const Color(0xFF27272A),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? priority.color : const Color(0xFF71717A).withOpacity(0.3),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Text(
                                  priority.displayName,
                                  style: GoogleFonts.inter(
                                    color: isSelected ? priority.color : const Color(0xFF71717A),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Task Details
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF27272A).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF71717A).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          'Estimated',
                          _formatTime(_currentTask.estimatedTime),
                          icon: Icons.schedule,
                        ),
                        _buildInfoRow(
                          'Time Spent',
                          _formatTime(_currentTask.timeSpent),
                          icon: Icons.timer,
                          valueColor: _currentTask.timeSpent > _currentTask.estimatedTime 
                              ? const Color(0xFFF97316) 
                              : Colors.white,
                        ),
                        _buildInfoRow(
                          'Remaining',
                          _formatTime(_currentTask.remainingTime),
                          icon: Icons.hourglass_empty,
                        ),
                        _buildInfoRow(
                          'Progress',
                          '${(_currentTask.completionPercentage * 100).toStringAsFixed(0)}%',
                          icon: Icons.trending_up,
                          valueColor: _currentTask.completionPercentage == 1.0 
                              ? const Color(0xFF10B981) 
                              : Colors.white,
                        ),
                        if (_currentTask.dueDate != null)
                          _buildInfoRow(
                            'Due Date',
                            _formatDate(_currentTask.dueDate),
                            icon: Icons.event,
                            valueColor: _currentTask.isOverdue 
                                ? const Color(0xFFEF4444) 
                                : Colors.white,
                          ),
                        if (_currentTask.scheduledFor != null)
                          _buildInfoRow(
                            'Scheduled',
                            _formatDateTime(_currentTask.scheduledFor),
                            icon: Icons.access_time,
                          ),
                        if (project != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Icon(Icons.folder, color: const Color(0xFF71717A), size: 20),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 100,
                                  child: Text(
                                    'Project',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF71717A),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: project.color,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  project.name,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        _buildInfoRow(
                          'Energy Level',
                          _currentTask.energyRequired.displayName,
                          icon: Icons.bolt,
                        ),
                        if (_isEditing)
                          _buildEditableField('Location', _locationController)
                        else if (_currentTask.location != null)
                          _buildInfoRow(
                            'Location',
                            _currentTask.location!,
                            icon: Icons.location_on,
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Tags
                  if (_currentTask.tags.isNotEmpty) ...[
                    Text(
                      'Tags',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF71717A),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      children: _currentTask.tags.map((tag) {
                        return Container(
                          margin: const EdgeInsets.only(right: 8, bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF9333EA).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF9333EA).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            tag,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF9333EA),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Timestamps
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF27272A).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          'Created',
                          _formatDateTime(_currentTask.createdAt),
                        ),
                        _buildInfoRow(
                          'Updated',
                          _formatDateTime(_currentTask.updatedAt),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}