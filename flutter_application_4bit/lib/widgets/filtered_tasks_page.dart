import 'package:flutter/material.dart';
import 'package:flutter_application_4bit/widgets/task_detail_modal.dart';
import 'package:google_fonts/google_fonts.dart';

// You'll need to import your task models here
import '../tasks_updated.dart';
import 'package:flutter_application_4bit/models/task_models.dart';

class FilteredTasksPage extends StatefulWidget {
  final String title;
  final List<Task> tasks;
  final Color? accentColor;
  final String? projectName;
  final Function(Task) saveTask;
  final Function(String) deleteTask;

  const FilteredTasksPage({
    Key? key,
    required this.title,
    required this.tasks,
    this.accentColor,
    this.projectName,
    required this.saveTask,
    required this.deleteTask,
  }) : super(key: key);

  @override
  _FilteredTasksPageState createState() => _FilteredTasksPageState();
}

class _FilteredTasksPageState extends State<FilteredTasksPage> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<Task> get filteredTasks {
    if (_searchQuery.trim().isEmpty) return widget.tasks;
    return widget.tasks.where((task) => 
      task.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      (task.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
    ).toList();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  String _formatTime(double hours) {
    if (hours == 0) return '0h';
    int wholeHours = hours.floor();
    int minutes = ((hours - wholeHours) * 60).floor();
    
    if (minutes == 0) {
      return '${wholeHours}h';
    } else if (wholeHours == 0) {
      return '${minutes}m';
    } else {
      return '${wholeHours}h ${minutes}m';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(date.year, date.month, date.day);
    
    if (taskDate.isAtSameMomentAs(today)) {
      return 'Today';
    } else if (taskDate.isAtSameMomentAs(today.add(Duration(days: 1)))) {
      return 'Tomorrow';
    } else if (taskDate.isBefore(today)) {
      final difference = today.difference(taskDate).inDays;
      return '${difference} day${difference == 1 ? '' : 's'} ago';
    } else {
      final difference = taskDate.difference(today).inDays;
      return 'In ${difference} day${difference == 1 ? '' : 's'}';
    }
  }

  void _showTaskDetail(Task task) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => TaskDetailModal(
      task: task,
      projects: projects,
      onTaskUpdate: (updatedTask) {
        widget.saveTask(updatedTask);  // Use your existing saveTask function
        setState(() {}); // Refresh the UI
      },
      onTaskDelete: (taskId) {
        widget.deleteTask(taskId);  // Use the new deleteTask function
        setState(() {}); // Refresh the UI
      },
    ),
  );
}


  Widget _buildTaskCard(Task task) {
    final isOverdue = task.isOverdue;
    final progress = task.completionPercentage;
    
    return GestureDetector(
    onTap: () => _showTaskDetail(task),
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF27272A).withAlpha((0.8 * 255).round()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverdue 
              ? const Color(0xFFEF4444).withAlpha((0.3 * 255).round())
              : (widget.accentColor ?? const Color(0xFF9333EA)).withAlpha((0.2 * 255).round()),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.2 * 255).round()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: task.priority.color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  task.title,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: task.status == TaskStatus.completed
                      ? const Color(0xFF10B981).withAlpha((0.2 * 255).round())
                      : task.status == TaskStatus.inProgress
                          ? const Color(0xFF3B82F6).withAlpha((0.2 * 255).round())
                          : const Color(0xFF71717A).withAlpha((0.2 * 255).round()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  task.status.name.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: task.status == TaskStatus.completed
                        ? const Color(0xFF10B981)
                        : task.status == TaskStatus.inProgress
                            ? const Color(0xFF3B82F6)
                            : const Color(0xFF71717A),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          
          if (task.description != null) ...[
            const SizedBox(height: 8),
            Text(
              task.description!,
              style: GoogleFonts.inter(
                color: const Color(0xFFA1A1AA),
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: const Color(0xFF71717A)),
              const SizedBox(width: 4),
              Text(
                '${_formatTime(task.timeSpent)} / ${_formatTime(task.estimatedTime)}',
                style: GoogleFonts.inter(
                  color: const Color(0xFF71717A),
                  fontSize: 12,
                ),
              ),
              
              if (task.dueDate != null || task.scheduledFor != null) ...[
                const SizedBox(width: 16),
                Icon(
                  task.scheduledFor != null ? Icons.schedule : Icons.event,
                  size: 16,
                  color: isOverdue ? const Color(0xFFEF4444) : const Color(0xFF71717A),
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(task.dueDate ?? task.scheduledFor),
                  style: GoogleFonts.inter(
                    color: isOverdue ? const Color(0xFFEF4444) : const Color(0xFF71717A),
                    fontSize: 12,
                    fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
              
              const Spacer(),
              
              Text(
                task.priority.displayName,
                style: GoogleFonts.inter(
                  color: task.priority.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
          if (progress > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: const Color(0xFF3F3F46),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      task.status == TaskStatus.completed
                          ? const Color(0xFF10B981)
                          : widget.accentColor ?? const Color(0xFF9333EA),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(progress * 100).round()}%',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF71717A),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    )
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.task_alt,
              size: 64,
              color: const Color(0xFF71717A),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty ? 'No tasks found' : 'No tasks yet',
              style: GoogleFonts.inter(
                color: const Color(0xFFA1A1AA),
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty 
                  ? 'Try a different search term'
                  : 'Tasks will appear here when added',
              style: GoogleFonts.inter(
                color: const Color(0xFF71717A),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totalTime = filteredTasks.fold(0.0, (sum, task) => sum + task.estimatedTime);
    final spentTime = filteredTasks.fold(0.0, (sum, task) => sum + task.timeSpent);
    final completedTasks = filteredTasks.where((task) => task.status == TaskStatus.completed).length;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF27272A).withAlpha((0.8 * 255).round()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (widget.accentColor ?? const Color(0xFF9333EA)).withAlpha((0.3 * 255).round()),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${filteredTasks.length} Tasks',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.projectName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'in ${widget.projectName}',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFA1A1AA),
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_formatTime(spentTime)} / ${_formatTime(totalTime)}',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$completedTasks completed',
                style: GoogleFonts.inter(
                  color: const Color(0xFF10B981),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0F0F), Color(0xFF1A1A1A), Color(0xFF0A0A0A)],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF27272A).withAlpha((0.8 * 255).round()),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF9333EA).withAlpha((0.1 * 255).round()),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: const Color(0xFF71717A)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.inter(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search tasks...',
                          hintStyle: GoogleFonts.inter(color: const Color(0xFF71717A)),
                          border: InputBorder.none,
                        ),
                        onChanged: _onSearchChanged,
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      IconButton(
                        icon: Icon(Icons.clear, color: const Color(0xFF71717A)),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      ),
                  ],
                ),
              ),
            ),
            
            Expanded(
              child: filteredTasks.isEmpty
                  ? _buildEmptyState()
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _buildSummaryCard(),
                        ...filteredTasks.map((task) => _buildTaskCard(task)),
                        const SizedBox(height: 100),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}