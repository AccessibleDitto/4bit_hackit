import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'widgets/navigation_widgets.dart';
import 'widgets/standard_app_bar.dart';
import 'tasks_updated.dart' as TaskData;
import 'models/task_models.dart' show TaskStatus, Project, Task;

class ReportScreen extends StatefulWidget {
  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  // Helper: Get completed tasks for a time range
  int _getCompletedTasksForRange(String range) {
    final now = DateTime.now();
    final allTasks = TaskData.getTasksList();
    if (range == 'today') {
      return allTasks.where((t) => t.status == TaskStatus.completed && t.updatedAt.year == now.year && t.updatedAt.month == now.month && t.updatedAt.day == now.day).length;
    } else if (range == 'week') {
      final startOfWeek = now.subtract(Duration(days: 7));
      return allTasks.where((t) => t.status == TaskStatus.completed && t.updatedAt.isAfter(startOfWeek)).length;
    } else if (range == 'biweekly') {
      final startOfBiweek = now.subtract(Duration(days: 13));
      return allTasks.where((t) => t.status == TaskStatus.completed && t.updatedAt.isAfter(startOfBiweek)).length;
    } else if (range == 'month') {
      final startOfMonth = DateTime(now.year, now.month, 1);
      return allTasks.where((t) => t.status == TaskStatus.completed && t.updatedAt.isAfter(startOfMonth)).length;
    }
    return 0;
  }

  // Helper: Get project time distribution data
  List<Map<String, dynamic>> _getProjectTimeDistribution(String range) {
    final now = DateTime.now();
    final allTasks = TaskData.getTasksList();
    final allProjects = TaskData.getProjectsList();
    
    // Filter tasks based on time range
    List<Task> filteredTasks;
    if (range == 'Weekly') {
      final startOfWeek = now.subtract(Duration(days: 7));
      filteredTasks = allTasks.where((t) => t.updatedAt.isAfter(startOfWeek)).toList();
    } else {
      // Monthly
      final startOfMonth = DateTime(now.year, now.month, 1);
      filteredTasks = allTasks.where((t) => t.updatedAt.isAfter(startOfMonth)).toList();
    }
    
    // Calculate total time spent per project
    Map<String, double> projectTimes = {};
    double totalTime = 0.0;
    
    for (final task in filteredTasks) {
      if (task.projectId != null && task.projectId!.isNotEmpty) {
        projectTimes[task.projectId!] = (projectTimes[task.projectId!] ?? 0.0) + task.timeSpent;
        totalTime += task.timeSpent;
      }
    }
    
    // Create project distribution data
    List<Map<String, dynamic>> projectData = [];
    for (final project in allProjects) {
      double timeSpent = projectTimes[project.id] ?? 0.0;
      if (timeSpent > 0) {
        double percentage = totalTime > 0 ? (timeSpent / totalTime) * 100 : 0;
        projectData.add({
          'name': project.name,
          'timeSpent': timeSpent,
          'percentage': percentage,
          'color': project.color,
          'formattedTime': TaskData.formatTime(timeSpent),
        });
      }
    }
    
    // Sort by time spent (descending)
    projectData.sort((a, b) => b['timeSpent'].compareTo(a['timeSpent']));
    
    return projectData;
  }

  // Helper: Get tasks with focus time based on time range
  List<Map<String, dynamic>> _getTasksWithFocusTime(String range) {
    final now = DateTime.now();
    final allTasks = TaskData.getTasksList();
    
    // Filter tasks based on time range
    List<Task> filteredTasks;
    if (range == 'Weekly') {
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      filteredTasks = allTasks.where((t) => t.updatedAt.isAfter(startOfWeek) && t.timeSpent > 0).toList();
    } else {
      // Monthly
      final startOfMonth = DateTime(now.year, now.month, 1);
      filteredTasks = allTasks.where((t) => t.updatedAt.isAfter(startOfMonth) && t.timeSpent > 0).toList();
    }
    
    // Sort tasks by time spent (descending)
    filteredTasks.sort((a, b) => b.timeSpent.compareTo(a.timeSpent));
    
    // Create task data with predefined color sequence
    final colorSequence = [Colors.teal, Color(0xFFFF4757), Colors.blue, Colors.orange, Colors.pink];
    List<Map<String, dynamic>> taskData = [];
    
    for (int i = 0; i < filteredTasks.length; i++) {
      final task = filteredTasks[i];
      Color taskColor = colorSequence[i % colorSequence.length];
      
      taskData.add({
        'name': task.title,
        'time': TaskData.formatTime(task.timeSpent),
        'color': taskColor,
        'timeSpent': task.timeSpent,
      });
    }
    
    return taskData;
  }

  String _formatTimeAsHoursMinutes(double totalMinutes) {
    if (totalMinutes <= 0) return '0m';
    
    int hours = (totalMinutes / 60).floor();
    int minutes = (totalMinutes % 60).round();
    
    if (minutes >= 60) {
      hours += 1;
      minutes = 0;
    }
    
    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}m';
    }
  }

  // Helper: Get focus time for a time range
  String _getFocusTimeForRange(String range) {
    final now = DateTime.now();
    final allTasks = TaskData.getTasksList();
    double total = 0.0;
    if (range == 'today') {
      total = allTasks.where((t) => t.updatedAt.year == now.year && t.updatedAt.month == now.month && t.updatedAt.day == now.day).fold(0.0, (a, b) => a + b.timeSpent);
    } else if (range == 'week') {
      final startOfWeek = now.subtract(Duration(days: 7));
      total = allTasks.where((t) => t.updatedAt.isAfter(startOfWeek)).fold(0.0, (a, b) => a + b.timeSpent);
    } else if (range == 'biweekly') {
      final startOfBiweek = now.subtract(Duration(days: 13));
      total = allTasks.where((t) => t.updatedAt.isAfter(startOfBiweek)).fold(0.0, (a, b) => a + b.timeSpent);
    } else if (range == 'month') {
      final startOfMonth = DateTime(now.year, now.month, 1);
      total = allTasks.where((t) => t.updatedAt.isAfter(startOfMonth)).fold(0.0, (a, b) => a + b.timeSpent);
    }
    return _formatTimeAsHoursMinutes(total);
  }

  // Helper: Get pomodoro counts based on time range
  List<BarChartGroupData> _generatePomodoroBarGroups(String range) {
    final now = DateTime.now();
    final allTasks = TaskData.getTasksList();
    final colorList = [Color(0xFF9333EA), Color(0xFF10B981), Color(0xFF3B82F6), Color(0xFFEF4444), Color(0xFFF59E0B)];
    
    if (range == 'Monthly') {
      // Show monthly data
      return List.generate(7, (i) {
        final monthsAgo = 6 - i;
        final targetDate = DateTime(now.year, now.month - monthsAgo, 1);
        
        // Count completed tasks for this month
        int pomodoroCount = allTasks.where((task) => 
          task.status == TaskStatus.completed &&
          task.updatedAt.year == targetDate.year &&
          task.updatedAt.month == targetDate.month
        ).length;
        
        return BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: pomodoroCount.toDouble(),
              color: colorList[i % colorList.length],
              width: 12,
              borderRadius: BorderRadius.circular(2),
            ),
          ],
        );
      });
    } else {
      // Show daily data (Weekly)
      return List.generate(7, (i) {
        final daysAgo = 6 - i;
        final targetDate = DateTime(now.year, now.month, now.day - daysAgo);
        
        // Count completed tasks for this day
        int pomodoroCount = allTasks.where((task) => 
          task.status == TaskStatus.completed &&
          task.updatedAt.year == targetDate.year &&
          task.updatedAt.month == targetDate.month &&
          task.updatedAt.day == targetDate.day
        ).length;
        
        return BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: pomodoroCount.toDouble(),
              color: colorList[i % colorList.length],
              width: 12,
              borderRadius: BorderRadius.circular(2),
            ),
          ],
        );
      });
    }
  }

  // Helper: Get task completion counts based on time range
  List<BarChartGroupData> _generateTaskBarGroups(String range) {
    final now = DateTime.now();
    final allTasks = TaskData.getTasksList();
    final colors = [Color(0xFF9333EA), Color(0xFF10B981), Color(0xFF3B82F6), Color(0xFFEF4444), Color(0xFFF59E0B)];
    
    if (range == 'Monthly') {
      // Show monthly data
      return List.generate(7, (i) {
        final monthsAgo = 6 - i;
        final targetDate = DateTime(now.year, now.month - monthsAgo, 1);
        
        // Get completed tasks for this month
        final monthTasks = allTasks.where((task) => 
          task.status == TaskStatus.completed &&
          task.updatedAt.year == targetDate.year &&
          task.updatedAt.month == targetDate.month
        ).toList();
        
        final taskCount = monthTasks.length.toDouble();
        
        return BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: taskCount,
              color: colors[i % colors.length],
              width: 12,
              borderRadius: BorderRadius.circular(2),
            ),
          ],
        );
      });
    } else {
      // Show daily data (Weekly)
      return List.generate(7, (i) {
        final daysAgo = 6 - i;
        final targetDate = DateTime(now.year, now.month, now.day - daysAgo);
        
        // Get completed tasks for this day
        final dayTasks = allTasks.where((task) => 
          task.status == TaskStatus.completed &&
          task.updatedAt.year == targetDate.year &&
          task.updatedAt.month == targetDate.month &&
          task.updatedAt.day == targetDate.day
        ).toList();
        
        final taskCount = dayTasks.length.toDouble();
        
        return BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: taskCount,
              color: colors[i % colors.length],
              width: 12,
              borderRadius: BorderRadius.circular(2),
            ),
          ],
        );
      });
    }
  }
  bool isPomodoroTab = true;
  int selectedTabIndex = 0;

  // Dropdown selections for each section
  String pomodoroRecordsRange = 'Weekly';
  String focusTimeGoalRange = 'Monthly';
  String focusTimeChartRange = 'Weekly';
  String focusTimeTasksRange = 'Weekly';
  String projectTimeDistributionRange = 'Weekly';
  String taskChartRange = 'Weekly';
  final List<String> rangeOptions = ['Weekly', 'Monthly'];
  final List<String> monthlyOnlyOptions = ['Monthly'];

  // Calendar state
  int displayedMonth = DateTime.now().month;
  int displayedYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: const StandardAppBar(
        title: 'Report',
        type: AppBarType.standard,
        backgroundColor: Color(0xFF1A1A1A),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Tab Selector
            Container(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Color(0xFF2D2D2D),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => isPomodoroTab = true),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isPomodoroTab ? Color(0xFFFF4757) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Pomodoro',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => isPomodoroTab = false),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: !isPomodoroTab ? Color(0xFFFF4757) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Tasks',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: isPomodoroTab ? _buildPomodoroTab() : _buildTasksTab(),
          ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigation(
        selectedIndex: 3,
        isStrictMode: false,
      ),
    );
  }

  Widget _buildPomodoroTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Grid
          Row(
            children: [
              Expanded(
                child: _buildStatCard(_getFocusTimeForRange('today'), 'Focus Time Today'),
              ),
              SizedBox(width: MediaQuery.of(context).size.width * 0.03),
              Expanded(
                child: _buildStatCard(_getFocusTimeForRange('week'), 'Focus Time This Week'),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(_getFocusTimeForRange('biweekly'), 'Focus Time This Two Weeks'),
              ),
              SizedBox(width: MediaQuery.of(context).size.width * 0.03),
              Expanded(
                child: _buildStatCard(_getFocusTimeForRange('month'), 'Focus Time This Month'),
              ),
            ],
          ),
          
          SizedBox(height: MediaQuery.of(context).size.height * 0.03),
          
          // Pomodoro Records
          _buildSectionHeaderWithDropdown('Pomodoro Records', pomodoroRecordsRange, (String? newValue) {
            setState(() {
              pomodoroRecordsRange = newValue!;
            });
          }),
          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
          _buildPomodoroChart(),

          SizedBox(height: MediaQuery.of(context).size.height * 0.03),

          // Focus Time Goal
          _buildSectionHeaderWithMonthlyDropdown('Focus Time Goal', focusTimeGoalRange, (String? newValue) {
            setState(() {
              focusTimeGoalRange = newValue!;
            });
          }),
          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
          _buildCalendarView(),

          SizedBox(height: MediaQuery.of(context).size.height * 0.03),

          // Focus Time Chart
          _buildSectionHeaderWithDropdown('Focus Time Chart', focusTimeChartRange, (String? newValue) {
            setState(() {
              focusTimeChartRange = newValue!;
            });
          }),
          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
          _buildFocusTimeChart(),
          Padding(
            padding: EdgeInsets.only(top: 4, left: 8),
            child: Text('in hours', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Task Stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(_getCompletedTasksForRange('today').toString(), 'Task Completed Today'),
              ),
              SizedBox(width: MediaQuery.of(context).size.width * 0.03),
              Expanded(
                child: _buildStatCard(_getCompletedTasksForRange('week').toString(), 'Task Completed This Week'),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(_getCompletedTasksForRange('biweekly').toString(), 'Task Completed This Two Weeks'),
              ),
              SizedBox(width: MediaQuery.of(context).size.width * 0.03),
              Expanded(
                child: _buildStatCard(_getCompletedTasksForRange('month').toString(), 'Task Completed This Month'),
              ),
            ],
          ),
          
          SizedBox(height: MediaQuery.of(context).size.height * 0.03),
          
          // Focus Time Tasks
          _buildSectionHeaderWithDropdown('Focus Time', focusTimeTasksRange, (String? newValue) {
            setState(() {
              focusTimeTasksRange = newValue!;
            });
          }),
          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
          _buildTaskList(),

          SizedBox(height: MediaQuery.of(context).size.height * 0.03),

          // Project Time Distribution
          _buildSectionHeaderWithDropdown('Project Time Distribution', projectTimeDistributionRange, (String? newValue) {
            setState(() {
              projectTimeDistributionRange = newValue!;
            });
          }),
          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
          _buildProjectDistributionChart(),

          SizedBox(height: MediaQuery.of(context).size.height * 0.03),

          // Task Chart
          _buildSectionHeaderWithDropdown('Task Chart', taskChartRange, (String? newValue) {
            setState(() {
              taskChartRange = newValue!;
            });
          }),
          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
          _buildTaskChart(),
          Padding(
            padding: EdgeInsets.only(top: 4, left: 8),
            child: Text('no. of tasks completed', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.15,
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
      decoration: BoxDecoration(
        color: Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              color: Color(0xFFFF4757),
              fontSize: MediaQuery.of(context).size.width * 0.06,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 14),
          Container(
            height: 30, // Fixed height for description area
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: MediaQuery.of(context).size.width * 0.03,
              ),
              maxLines: 2, // Up to 2 lines for longer labels
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeaderWithDropdown(String title, String selectedValue, ValueChanged<String?> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: MediaQuery.of(context).size.width * 0.04,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.03,
            vertical: MediaQuery.of(context).size.height * 0.005,
          ),
          decoration: BoxDecoration(
            color: Color(0xFF2D2D2D),
            borderRadius: BorderRadius.circular(16),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedValue,
              icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[400], size: 16),
              dropdownColor: Color(0xFF2D2D2D),
              style: TextStyle(color: Colors.grey[400], fontSize: MediaQuery.of(context).size.width * 0.03),
              itemHeight: 48,
              items: rangeOptions.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeaderWithMonthlyDropdown(String title, String selectedValue, ValueChanged<String?> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: MediaQuery.of(context).size.width * 0.04,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.03,
            vertical: MediaQuery.of(context).size.height * 0.005,
          ),
          decoration: BoxDecoration(
            color: Color(0xFF2D2D2D),
            borderRadius: BorderRadius.circular(16),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedValue,
              icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[400], size: 16),
              dropdownColor: Color(0xFF2D2D2D),
              style: TextStyle(color: Colors.grey[400], fontSize: MediaQuery.of(context).size.width * 0.03),
              itemHeight: 48,
              items: monthlyOnlyOptions.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPomodoroChart() {
    final pomodoroBarGroups = _generatePomodoroBarGroups(pomodoroRecordsRange);
    final maxY = pomodoroBarGroups.isEmpty ? 10.0 : pomodoroBarGroups.map((g) => g.barRods.first.toY).reduce((a, b) => a > b ? a : b);
    
    double finalMaxY;
    if (maxY <= 1) {
      finalMaxY = 1.0;
    } else if (maxY <= 6) {
      finalMaxY = 6.0;
    } else if (maxY <= 12) {
      finalMaxY = 12.0;
    } else if (maxY <= 24) {
      finalMaxY = 24.0;
    } else {
      finalMaxY = (maxY * 1.2).ceilToDouble();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: MediaQuery.of(context).size.height * 0.25,
          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
          decoration: BoxDecoration(
            color: Color(0xFF2D2D2D),
            borderRadius: BorderRadius.circular(12),
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              minY: 0,
              maxY: finalMaxY,
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      final now = DateTime.now();
                      
                      if (pomodoroRecordsRange == 'Monthly') {
                        final monthsAgo = 6 - i;
                        final targetDate = DateTime(now.year, now.month - monthsAgo, 1);
                        final monthName = _monthName(targetDate.month);
                        return Text(
                          monthName.substring(0, 3), // short month name
                          style: TextStyle(color: Colors.grey[600], fontSize: MediaQuery.of(context).size.width * 0.025)
                        );
                      } else {
                        // Daily labels for Weekly
                        final date = DateTime.now().subtract(Duration(days: 6 - i));
                        final label = i == 6
                          ? 'Today'
                          : i == 5
                            ? 'Yesterday'
                            : '${date.month}/${date.day}';
                        return Text(label, style: TextStyle(color: Colors.grey[600], fontSize: MediaQuery.of(context).size.width * 0.025));
                      }
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: finalMaxY <= 1 ? 0.2 : finalMaxY <= 6 ? 1 : finalMaxY <= 12 ? 2 : finalMaxY <= 24 ? 4 : finalMaxY / 6,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      // Only show values within the range
                      if (value < 0 || value > finalMaxY) return Container();
                      
                      // Format based on the scale
                      String label;
                      if (finalMaxY <= 1) {
                        // For small values, show one decimal place
                        label = value.toStringAsFixed(1);
                      } else if (value == value.toInt()) {
                        // For whole numbers, show as integer
                        label = value.toInt().toString();
                      } else {
                        // For decimal values, show one decimal place
                        label = value.toStringAsFixed(1);
                      }
                      
                      return Text(
                        label,
                        style: TextStyle(color: Colors.grey[600], fontSize: 10),
                      );
                    },
                  ),
                ),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: pomodoroBarGroups,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: 4, left: 8),
          child: Text('no. of pomodoros completed', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildCalendarView() {
    final monthName = _monthName(displayedMonth);
    final year = displayedYear;
    return Container(
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
      decoration: BoxDecoration(
        color: Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (displayedMonth == 1) {
                      displayedMonth = 12;
                      displayedYear--;
                    } else {
                      displayedMonth--;
                    }
                  });
                },
                child: Icon(Icons.chevron_left, color: Colors.white),
              ),
              Text(
                '$monthName $year',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (displayedMonth == 12) {
                      displayedMonth = 1;
                      displayedYear++;
                    } else {
                      displayedMonth++;
                    }
                  });
                },
                child: Icon(Icons.chevron_right, color: Colors.white),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su']
                .map((day) => Text(
                      day,
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ))
                .toList(),
          ),
          SizedBox(height: 8),
          _buildCalendarGridDynamic(displayedYear, displayedMonth),
        ],
      ),
    );
  }

  Widget _buildCalendarGridDynamic(int year, int month) {
  final firstDayOfMonth = DateTime(year, month, 1);
  final lastDayOfMonth = DateTime(year, month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final firstWeekday = (firstDayOfMonth.weekday == 7) ? 0 : firstDayOfMonth.weekday;
    final today = DateTime.now();
    List<Widget> rows = [];
    int dayCounter = 1;
    for (int week = 0; week < 6; week++) {
      List<Widget> days = [];
      for (int weekday = 1; weekday <= 7; weekday++) {
        if (week == 0 && weekday < firstWeekday) {
          days.add(_buildCalendarDayDynamic(null, false, false, false));
        } else if (dayCounter > daysInMonth) {
          days.add(_buildCalendarDayDynamic(null, false, false, false));
        } else {
          bool isToday = (dayCounter == today.day && month == today.month && year == today.year);
          // TODO: Replace hasActivity with real data if available
          bool hasActivity = false;
          days.add(_buildCalendarDayDynamic(dayCounter, true, hasActivity, isToday));
          dayCounter++;
        }
      }
      rows.add(Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: days,
        ),
      ));
      if (dayCounter > daysInMonth) break;
    }
    return Column(children: rows);
  }

  Widget _buildCalendarDayDynamic(int? dayNumber, bool isActive, bool hasActivity, bool isToday) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.08,
      height: MediaQuery.of(context).size.width * 0.08,
      decoration: BoxDecoration(
        color: hasActivity ? Color(0xFFFF4757) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: isToday ? Border.all(color: Colors.white, width: 2) : null,
      ),
      child: Center(
        child: Text(
          isActive && dayNumber != null ? dayNumber.toString() : '',
          style: TextStyle(
            color: hasActivity ? Colors.white : Colors.grey[600],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
  String _monthName(int month) {
    const months = [
      '',
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month];
  }

  Widget _buildFocusTimeChart() {
    // Use focus time bar chart data based on selected range
    final focusTimeBarGroups = _generateFocusTimeBarGroups(focusTimeChartRange);
    final maxY = focusTimeBarGroups.isEmpty ? 10.0 : focusTimeBarGroups.map((g) => g.barRods.map((r) => r.toY).reduce((a, b) => a > b ? a : b)).reduce((a, b) => a > b ? a : b);
    
    // Dynamic y-axis scaling with appropriate intervals
    double finalMaxY;
    if (maxY <= 1) {
      finalMaxY = 1.0;
    } else if (maxY <= 6) {
      finalMaxY = 6.0;
    } else if (maxY <= 12) {
      finalMaxY = 12.0;
    } else if (maxY <= 24) {
      finalMaxY = 24.0;
    } else {
      finalMaxY = (maxY * 1.2).ceilToDouble();
    }
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.25,
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
      decoration: BoxDecoration(
        color: Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          minY: 0,
          maxY: finalMaxY,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  final now = DateTime.now();
                  
                  if (focusTimeChartRange == 'Monthly') {
                    final monthsAgo = 6 - i;
                    final targetDate = DateTime(now.year, now.month - monthsAgo, 1);
                    final monthName = _monthName(targetDate.month);
                    return Text(
                      monthName.substring(0, 3), // short month name
                      style: TextStyle(color: Colors.grey[600], fontSize: 10),
                    );
                  } else {
                    // Daily labels for Weekly
                    final daysAgo = 6 - i;
                    String label;
                    if (daysAgo == 0) {
                      label = 'Today';
                    } else if (daysAgo == 1) {
                      label = 'Yesterday';
                    } else {
                      final date = DateTime.now().subtract(Duration(days: daysAgo));
                      label = '${date.month}/${date.day}';
                    }
                    return Text(
                      label,
                      style: TextStyle(color: Colors.grey[600], fontSize: 10),
                    );
                  }
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: finalMaxY <= 1 ? 0.2 : finalMaxY <= 6 ? 1 : finalMaxY <= 12 ? 2 : finalMaxY <= 24 ? 4 : finalMaxY / 6,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  // Only show values within the range
                  if (value < 0 || value > finalMaxY) return Container();
                  
                  // Format based on the scale
                  String label;
                  if (finalMaxY <= 1) {
                    // For small values, show one decimal place
                    label = value.toStringAsFixed(1);
                  } else if (value == value.toInt()) {
                    // For whole numbers, show as integer
                    label = value.toInt().toString();
                  } else {
                    // For decimal values, show one decimal place
                    label = value.toStringAsFixed(1);
                  }
                  
                  return Text(
                    label,
                    style: TextStyle(color: Colors.grey[600], fontSize: 10),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: focusTimeBarGroups,
        ),
      ),
    );
  }

  List<BarChartGroupData> _generateFocusTimeBarGroups(String range){
    final now = DateTime.now();
    final allTasks = <Task>[];
    TaskData.fetchTasks().then((tasks) {
      allTasks.addAll(tasks);
    });

    if (range == 'Monthly') {
      // Show monthly data
      return List.generate(7, (index) {
        final monthsAgo = 6 - index;
        final targetDate = DateTime(now.year, now.month - monthsAgo, 1);
        
        // Get total time spent for tasks in this month
        double totalTimeInHours = 0.0;
        for (final task in allTasks) {
          if (task.updatedAt.year == targetDate.year && 
              task.updatedAt.month == targetDate.month) {
            totalTimeInHours += task.timeSpent / 60.0;
          }
        }
        
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: totalTimeInHours,
              color: Color(0xFFFF4757),
              width: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        );
      });
    } else {
      debugPrint(allTasks.length.toString());
      // Show daily data (Weekly)
      return List.generate(7, (index) {
        final daysAgo = 6 - index;
        DateTime targetDate = now.subtract( Duration(days: daysAgo));
        debugPrint('Calculating for date: $targetDate');
        // Get total time spent for tasks in this day
        double totalTimeInHours = 0.0;
        for (final task in allTasks) {
          debugPrint( 'Checking task updated at: ${task.updatedAt.day} at $targetDate');
          if (task.updatedAt.year == targetDate.year && 
              task.updatedAt.month == targetDate.month &&
              task.updatedAt.day == targetDate.day) {
            totalTimeInHours += task.timeSpent / 60.0;
          }
        }
        
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: totalTimeInHours,
              color: Color(0xFFFF4757),
              width: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        );
      });
    }
  }



  Widget _buildTaskList() {
    final tasks = _getTasksWithFocusTime(focusTimeTasksRange);
    
    // If no tasks, show empty state
    if (tasks.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFF2D2D2D),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'No focus time data available',
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: tasks.map((task) => _buildTaskItem(
          task['name'] as String,
          task['time'] as String,
          task['color'] as Color,
        )).toList(),
      ),
    );
  }

  Widget _buildTaskItem(String name, String time, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              time,
              style: TextStyle(color: color, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectDistributionChart() {
    final projectData = _getProjectTimeDistribution(projectTimeDistributionRange);
    
    // If no data, show empty state
    if (projectData.isEmpty) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.30,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFF2D2D2D),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'No project data available',
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
        ),
      );
    }
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.30,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: PieChart(
              PieChartData(
                sections: projectData.map((project) => PieChartSectionData(
                  value: project['percentage'],
                  color: project['color'],
                  radius: 80,
                  showTitle: false,
                )).toList(),
                centerSpaceRadius: 30,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: projectData.map((project) => _buildLegendItem(
                project['color'],
                project['name'],
                '${project['formattedTime']} - ${project['percentage'].toInt()}%',
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String title, String subtitle) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[400], fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskChart() {
    final taskBarGroups = _generateTaskBarGroups(taskChartRange);
    final maxY = taskBarGroups.isEmpty ? 10.0 : taskBarGroups.map((g) => g.barRods.first.toY).reduce((a, b) => a > b ? a : b);
    
    double finalMaxY;
    if (maxY <= 1) {
      finalMaxY = 1.0;
    } else if (maxY <= 6) {
      finalMaxY = 6.0;
    } else if (maxY <= 12) {
      finalMaxY = 12.0;
    } else if (maxY <= 24) {
      finalMaxY = 24.0;
    } else {
      finalMaxY = (maxY * 1.2).ceilToDouble();
    }
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.25,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: finalMaxY,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  final now = DateTime.now();
                  
                  if (taskChartRange == 'Monthly') {
                    final monthsAgo = 6 - i;
                    final targetDate = DateTime(now.year, now.month - monthsAgo, 1);
                    final monthName = _monthName(targetDate.month);
                    return Text(
                      monthName.substring(0, 3), // short month name
                      style: TextStyle(color: Colors.grey[600], fontSize: 10, fontWeight: FontWeight.w600),
                    );
                  } else {
                    // Daily labels for Weekly
                    final daysAgo = 6 - i;
                    String label;
                    if (daysAgo == 0) {
                      label = 'Today';
                    } else if (daysAgo == 1) {
                      label = 'Yesterday';
                    } else {
                      final date = DateTime.now().subtract(Duration(days: daysAgo));
                      label = '${date.month}/${date.day}';
                    }
                    return Text(
                      label,
                      style: TextStyle(color: Colors.grey[600], fontSize: 10, fontWeight: FontWeight.w600),
                    );
                  }
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: finalMaxY <= 6 ? 1 : finalMaxY <= 12 ? 2 : finalMaxY <= 24 ? 4 : finalMaxY / 6,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(color: Colors.grey[600], fontSize: 10, fontWeight: FontWeight.w500),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: taskBarGroups,
        ),
      ),
    );
  }
}