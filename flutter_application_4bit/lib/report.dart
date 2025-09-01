import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'widgets/navigation_widgets.dart';

void main() {
  runApp(ProductivityApp());
}

class ProductivityApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Productivity Report',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Color(0xFF1A1A1A),
        primaryColor: Color(0xFFFF4757),
      ),
      home: ReportScreen(),
    );
  }
}

class ReportScreen extends StatefulWidget {
  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  bool isPomodoroTab = true;
  int selectedTabIndex = 0;

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
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4), // Reduced from 8 to 4
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
                      padding: EdgeInsets.symmetric(vertical: 8), // Reduced from 12 to 8
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
                      padding: EdgeInsets.symmetric(vertical: 8), // Reduced from 12 to 8
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
                child: _buildStatCard('2h 5m', 'Focus Time Today'),
              ),
              SizedBox(width: MediaQuery.of(context).size.width * 0.03),
              Expanded(
                child: _buildStatCard('39h 35m', 'Focus Time This Week'),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard('79h 10m', 'Focus Time This Two Weeks'),
              ),
              SizedBox(width: MediaQuery.of(context).size.width * 0.03),
              Expanded(
                child: _buildStatCard('160h 25m', 'Focus Time This Month'),
              ),
            ],
          ),
          
          SizedBox(height: MediaQuery.of(context).size.height * 0.03),
          
          // Pomodoro Records
          _buildSectionHeader('Pomodoro Records', 'Weekly'),
          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
          _buildPomodoroChart(),
          
          SizedBox(height: MediaQuery.of(context).size.height * 0.03),
          
          // Focus Time Goal
          _buildSectionHeader('Focus Time Goal', 'Monthly'),
          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
          _buildCalendarView(),
          
          SizedBox(height: MediaQuery.of(context).size.height * 0.03),
          
          // Focus Time Chart
          _buildSectionHeader('Focus Time Chart', 'Biweekly'),
          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
          _buildFocusTimeChart(),
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
          _buildSectionHeader('Focus Time', 'Tasks'),
          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
          _buildTaskList(),
          
          SizedBox(height: MediaQuery.of(context).size.height * 0.03),
          
          // Project Time Distribution
          _buildSectionHeader('Project Time Distribution', 'Weekly'),
          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
          _buildProjectDistributionChart(),
          
          SizedBox(height: MediaQuery.of(context).size.height * 0.03),

          // Task Chart
          _buildSectionHeader('Task Chart', 'Biweekly'),
          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
          _buildTaskChart(),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Container(
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04), // 4% of screen width
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

  Widget _buildSectionHeader(String title, String subtitle) {
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
            horizontal: MediaQuery.of(context).size.width * 0.03, // 3% of screen width
            vertical: MediaQuery.of(context).size.height * 0.005, // 0.5% of screen height
          ),
          decoration: BoxDecoration(
            color: Color(0xFF2D2D2D),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey[400], fontSize: MediaQuery.of(context).size.width * 0.03),
              ),
              Icon(Icons.keyboard_arrow_down, color: Colors.grey[400], size: 16),
            ],
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
              children: [
                _buildPomodoroBar(Colors.orange, 0.3, 'Today'),
                _buildPomodoroBar(Colors.green, 0.5, 'Yester'),
                _buildPomodoroBar(Colors.yellow, 0.7, 'Dec 18'),
                _buildPomodoroBar(Colors.orange, 0.8, 'Dec 17'),
                _buildPomodoroBar(Colors.blue, 0.6, 'Dec 16'),
                _buildPomodoroBar(Colors.purple, 0.4, 'Dec 15'),
                _buildPomodoroBar(Colors.teal, 0.5, 'Dec 14'),
              ],
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
              Icon(Icons.chevron_left, color: Colors.white),
              Text(
                'December 2023',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              Icon(Icons.chevron_right, color: Colors.white),
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
          _buildCalendarGrid(),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    return Column(
      children: [
        for (int week = 0; week < 5; week++)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (int day = 1; day <= 7; day++)
                  _buildCalendarDay(week * 7 + day - 6),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCalendarDay(int dayNumber) {
    bool isActive = dayNumber > 0 && dayNumber <= 31;
    bool hasActivity = dayNumber > 0 && dayNumber <= 20;
    bool isToday = dayNumber == 1;
    
    return Container(
      width: MediaQuery.of(context).size.width * 0.08, // 8% of screen width
      height: MediaQuery.of(context).size.width * 0.08, // 8% of screen width (square)
      decoration: BoxDecoration(
        color: hasActivity ? Color(0xFFFF4757) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: isToday ? Border.all(color: Colors.white, width: 2) : null,
      ),
      child: Center(
        child: Text(
          isActive ? dayNumber.toString() : '',
          style: TextStyle(
            color: hasActivity ? Colors.white : Colors.grey[600],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildFocusTimeChart() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.25,
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04), // 4% of screen width
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
      height: MediaQuery.of(context).size.height * 0.25,
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