import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'widgets/navigation_widgets.dart';
import 'services/user_stats_service.dart';

class ReportScreen extends StatefulWidget {
  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  bool isPomodoroTab = true;
  int selectedTabIndex = 0;

  // Dropdown selections for each section
  String pomodoroRecordsRange = 'Weekly';
  String focusTimeGoalRange = 'Monthly';
  String focusTimeChartRange = 'Biweekly';
  String focusTimeTasksRange = 'Weekly';
  String projectTimeDistributionRange = 'Weekly';
  String taskChartRange = 'Weekly';
  final List<String> rangeOptions = ['Weekly', 'Monthly', 'Biweekly'];

  // Calendar state
  int displayedMonth = DateTime.now().month;
  int displayedYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Color(0xFF1A1A1A),
        elevation: 0,
        leading: Icon(Icons.timer, color: Color(0xFFFF4757)),
        title: Text('Report', style: TextStyle(color: Colors.white, fontSize: MediaQuery.of(context).size.width * 0.045)),
        actions: [
          Icon(Icons.more_vert, color: Colors.white),
          SizedBox(width: MediaQuery.of(context).size.width * 0.04),
        ],
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
                child: _buildStatCard(UserStats().todayFocusTime, 'Focus Time Today'),
              ),
              SizedBox(width: MediaQuery.of(context).size.width * 0.03),
              Expanded(
                child: _buildStatCard(UserStats().weekFocusTime, 'Focus Time This Week'),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(UserStats().twoWeeksFocusTime, 'Focus Time This Two Weeks'),
              ),
              SizedBox(width: MediaQuery.of(context).size.width * 0.03),
              Expanded(
                child: _buildStatCard(UserStats().monthFocusTime, 'Focus Time This Month'),
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
          _buildSectionHeaderWithDropdown('Focus Time Goal', focusTimeGoalRange, (String? newValue) {
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
                child: _buildStatCard('2', 'Task Completed Today'),
              ),
              SizedBox(width: MediaQuery.of(context).size.width * 0.03),
              Expanded(
                child: _buildStatCard('25', 'Task Completed This Week'),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard('58', 'Task Completed This Two Weeks'),
              ),
              SizedBox(width: MediaQuery.of(context).size.width * 0.03),
              Expanded(
                child: _buildStatCard('124', 'Task Completed This Month'),
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
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
      decoration: BoxDecoration(
        color: Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: Color(0xFFFF4757),
              fontSize: MediaQuery.of(context).size.width * 0.06,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.005),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: MediaQuery.of(context).size.width * 0.03,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeaderWithDropdown(String title, String selectedValue, ValueChanged<String?> onChanged, {List<String>? options}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: MediaQuery.of(context).size.width * 0.045,
            fontWeight: FontWeight.w600,
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

  Widget _buildPomodoroChart() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.25,
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
      decoration: BoxDecoration(
        color: Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Time labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (int i = 8; i <= 20; i += 2)
                Text(
                  '${i.toString().padLeft(2, '0')}:00',
                  style: TextStyle(color: Colors.grey[600], fontSize: MediaQuery.of(context).size.width * 0.025),
                ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final date = DateTime.now().subtract(Duration(days: 6 - i));
                final label = i == 6
                  ? 'Today'
                  : i == 5
                    ? 'Yester'
                    : '${date.month}/${date.day}';
                // TODO: Replace 0.3 + i*0.1 with actual focus time value for that day
                final value = 0.3 + i * 0.1;
                final colorList = [Colors.orange, Colors.green, Colors.yellow, Colors.orange, Colors.blue, Colors.purple, Colors.teal];
                return _buildPomodoroBar(colorList[i % colorList.length], value, label);
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPomodoroBar(Color color, double height, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.05,
            margin: EdgeInsets.only(bottom: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: MediaQuery.of(context).size.width * 0.05,
                  height: height * 120,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: MediaQuery.of(context).size.width * 0.025),
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
    final firstWeekday = (firstDayOfMonth.weekday == 7) ? 0 : firstDayOfMonth.weekday; // Monday=1, Sunday=7
    final today = DateTime.now();
    List<Widget> rows = [];
    int dayCounter = 1;
    for (int week = 0; week < 6; week++) {
      List<Widget> days = [];
      for (int weekday = 1; weekday <= 7; weekday++) {
    // cellIndex not used, removed
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
          maxY: 7,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(color: Colors.grey[600], fontSize: 10),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
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
          barGroups: _generateBarGroups(),
        ),
      ),
    );
  }

  List<BarChartGroupData> _generateBarGroups() {
    final colors = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.purple,
      Colors.teal,
    ];
    
    return List.generate(14, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: (index % 7 + 1).toDouble(),
            color: colors[index % colors.length],
            width: 12,
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      );
    });
  }

  Widget _buildTaskList() {
    final tasks = [
      {'name': 'UI/UX Design Research', 'time': '7h 25m', 'color': Colors.green},
      {'name': 'Design User Interface (UI)', 'time': '6h 30m', 'color': Color(0xFFFF4757)},
      {'name': 'Create a Design Wireframe', 'time': '5h 40m', 'color': Colors.yellow},
      {'name': 'Market Research and Analysis', 'time': '4h 45m', 'color': Colors.blue},
      {'name': 'Write a Report & Proposal', 'time': '4h 30m', 'color': Colors.purple},
      {'name': 'Write a Research Paper', 'time': '4h 5m', 'color': Colors.orange},
      {'name': 'Read Articles', 'time': '3h 40m', 'color': Colors.red},
    ];

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
                sections: [
                  PieChartSectionData(
                    value: 35,
                    color: Colors.green,
                    radius: 80,
                    showTitle: false,
                  ),
                  PieChartSectionData(
                    value: 20,
                    color: Color(0xFFFF4757),
                    radius: 80,
                    showTitle: false,
                  ),
                  PieChartSectionData(
                    value: 15,
                    color: Colors.blue,
                    radius: 80,
                    showTitle: false,
                  ),
                  PieChartSectionData(
                    value: 12,
                    color: Colors.orange,
                    radius: 80,
                    showTitle: false,
                  ),
                  PieChartSectionData(
                    value: 10,
                    color: Colors.pink,
                    radius: 80,
                    showTitle: false,
                  ),
                  PieChartSectionData(
                    value: 8,
                    color: Colors.teal,
                    radius: 80,
                    showTitle: false,
                  ),
                ],
                centerSpaceRadius: 30,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(Colors.green, 'General', '18h 15m - 35%'),
                _buildLegendItem(Color(0xFFFF4757), 'Pomodoro App', '8h 5m - 20%'),
                _buildLegendItem(Colors.blue, 'Flight App', '6h 10m - 15%'),
                _buildLegendItem(Colors.orange, 'Work Project', '4h 48m - 12%'),
                _buildLegendItem(Colors.pink, 'Dating App', '4h 10m - 10%'),
                _buildLegendItem(Colors.teal, 'AI Chatbot App', '3h 12m - 8%'),
              ],
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
    return Container(
      height: MediaQuery.of(context).size.height * 0.25,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 7,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(color: Colors.grey[600], fontSize: 10),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
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
          barGroups: _generateTaskBarGroups(),
        ),
      ),
    );
  }

  List<BarChartGroupData> _generateTaskBarGroups() {
    final colors = [
      Colors.orange,
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.yellow,
      Colors.red,
      Colors.teal,
    ];
    
    return List.generate(14, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: (index % 6 + 2).toDouble(),
            color: colors[index % colors.length],
            width: 12,
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      );
    });
  }
}