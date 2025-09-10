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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(16),
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
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selectedTask,
                style: GoogleFonts.inter(
                  color: selectedTask == 'Select Task' ? const Color(0xFFA1A1AA) : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Color(0xFF9333EA),
              size: 24,
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
    return GestureDetector(
      onTap: () {
        onTap();
        HapticFeedback.selectionClick();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF27272A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: task.color.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: task.color.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            // Task colour indicator
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: task.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 16),
            // Task info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: task.color,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        task.sessionsLeft > 0
                          ? '${task.sessionsLeft} sessions of ${task.sessions} left'
                          : 'All sessions completed!',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFA1A1AA),
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Pomodoro',
                        style: GoogleFonts.inter(
                          color: task.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Select button
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: task.color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 20,
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
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
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
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF71717A),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Select Task',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 24,
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
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Available Tasks section
          Padding(
            padding: const EdgeInsets.all(24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Available Tasks',
                style: GoogleFonts.inter(
                  color: const Color(0xFFA1A1AA),
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          // Task list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
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