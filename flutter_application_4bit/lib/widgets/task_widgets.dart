import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/timer_models.dart';

class TaskSelector extends StatelessWidget {
  final String selectedTask;
  final VoidCallback onTap;

  const TaskSelector({
    super.key,
    required this.selectedTask,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 16 : 24,
          vertical: isSmallScreen ? 4 : 8
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 16 : 20, 
          vertical: isSmallScreen ? 12 : 16
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF9333EA).withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.task_alt,
              color: selectedTask == 'Select Task' ? const Color(0xFFA1A1AA) : const Color(0xFF9333EA),
              size: isSmallScreen ? 18 : 20,
            ),
            SizedBox(width: isSmallScreen ? 10 : 12),
            Expanded(
              child: Text(
                selectedTask,
                style: GoogleFonts.inter(
                  color: selectedTask == 'Select Task' ? const Color(0xFFA1A1AA) : Colors.white,
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: const Color(0xFF9333EA),
              size: isSmallScreen ? 20 : 24,
            ),
          ],
        ),
      ),
    );
  }
}

class TaskItem extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;

  const TaskItem({
    super.key,
    required this.task,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    
    return GestureDetector(
      onTap: () {
        onTap();
        HapticFeedback.selectionClick();
      },
      child: Container(
        margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 16),
        padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
        decoration: BoxDecoration(
          color: const Color(0xFF27272A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: task.color.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: task.color.withOpacity(0.1),
              blurRadius: isSmallScreen ? 10 : 20,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Task colour indicator
            Container(
              width: isSmallScreen ? 10 : 12,
              height: isSmallScreen ? 10 : 12,
              decoration: BoxDecoration(
                color: task.color,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: isSmallScreen ? 12 : 16),
            // Task info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  SizedBox(height: isSmallScreen ? 4 : 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: task.color,
                        size: isSmallScreen ? 14 : 16,
                      ),
                      SizedBox(width: isSmallScreen ? 4 : 6),
                      Expanded(
                        child: Text(
                          task.sessionsLeft > 0
                            ? '${task.sessionsLeft} sessions of ${task.sessions} left'
                            : 'All sessions completed!',
                          style: GoogleFonts.inter(
                            color: const Color(0xFFA1A1AA),
                            fontSize: isSmallScreen ? 12 : 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 4 : 8),
                      Text(
                        'Pomodoro',
                        style: GoogleFonts.inter(
                          color: task.color,
                          fontSize: isSmallScreen ? 10 : 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: isSmallScreen ? 8 : 16),
            // Select button
            Container(
              width: isSmallScreen ? 32 : 40,
              height: isSmallScreen ? 32 : 40,
              decoration: BoxDecoration(
                color: task.color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: isSmallScreen ? 16 : 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TaskSelectionModal extends StatelessWidget {
  final List<Task> tasks;
  final Function(Task) onTaskSelected;
  final VoidCallback onAddNewTask;

  const TaskSelectionModal({
    super.key,
    required this.tasks,
    required this.onTaskSelected,
    required this.onAddNewTask,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    
    return Container(
      height: isSmallScreen 
          ? screenHeight * 0.55 
          : screenHeight * 0.8,
      decoration: const BoxDecoration(
        color: Color(0xFF18181B),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: isSmallScreen ? 6 : 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF71717A),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 8 : 24),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Select Task',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 20 : 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    onAddNewTask();
                    HapticFeedback.lightImpact();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9333EA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Search bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 2 : 24),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 16, 
                vertical: isSmallScreen ? 8 : 12
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF27272A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF9333EA).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search,
                    color: Color(0xFF9333EA),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Search tasks...',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFA1A1AA),
                        fontSize: isSmallScreen ? 14 : 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Available Tasks section
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 8 : 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Available Tasks',
                style: GoogleFonts.inter(
                  color: const Color(0xFFA1A1AA),
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          // Task list
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 2 : 24),
              physics: const BouncingScrollPhysics(),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return TaskItem(
                  task: task,
                  onTap: () {
                    onTaskSelected(task);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}