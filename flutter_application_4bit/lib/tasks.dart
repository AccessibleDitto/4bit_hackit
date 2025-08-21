import 'package:flutter/material.dart';

class TasksPage extends StatefulWidget {
  @override
  _TasksPageState createState() => _TasksPageState();
}
String _formatTime(int hours) {
  if (hours == 0) return '0h';
  return '${hours}h';
}
class _TasksPageState extends State<TasksPage> {
  bool _showAddMenu = false;
  List<Project> projects = []; // Start with empty projects list
  List<Task> tasks = [
    // Sample tasks to test functionality
    Task(
      id: '1',
      title: 'Complete Flutter app',
      estimatedTime: 3,
      isCompleted: false,
      isToday: true,
      isPriority: true,
      scheduledDate: DateTime.now(),
    ),
    Task(
      id: '2',
      title: 'Review code',
      estimatedTime: 1,
      isCompleted: false,
      isToday: true,
      isPriority: false,
      scheduledDate: null,
    ),
    Task(
      id: '3',
      title: 'Meeting with team',
      estimatedTime: 1,
      isCompleted: false,
      isToday: false,
      isPriority: true,
      scheduledDate: DateTime.now().add(Duration(days: 1)),
    ),
    Task(
      id: '4',
      title: 'Write documentation',
      estimatedTime: 2,
      isCompleted: true,
      isToday: false,
      isPriority: false,
      scheduledDate: DateTime.now().add(Duration(days: 2)),
    ),
    Task(
      id: '5',
      title: 'Fix bug #123',
      estimatedTime: 1,
      isCompleted: false,
      isToday: false,
      isPriority: true,
      scheduledDate: DateTime.now().add(Duration(days: 3)),
    ),
  ];

  // Helper methods to calculate dynamic data
  List<Task> get todayTasks => tasks.where((task) => task.isToday && !task.isCompleted).toList();
  List<Task> get scheduledTasks => tasks.where((task) => task.scheduledDate != null && !task.isCompleted).toList();
  List<Task> get allTasks => tasks.where((task) => !task.isCompleted).toList();
  List<Task> get priorityTasks => tasks.where((task) => task.isPriority && !task.isCompleted).toList();

  int _calculateTotalTime(List<Task> taskList) {
    return taskList.fold(0, (sum, task) => sum + task.estimatedTime);
  }

  void _toggleAddMenu() {
    setState(() {
      _showAddMenu = !_showAddMenu;
    });
  }

  void _showAddTaskDialog() {
    _toggleAddMenu();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      builder: (context) => AddTaskSheet(),
    );
  }

  void _showAddProjectDialog() {
    _toggleAddMenu();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddProjectPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.timer, color: Colors.white, size: 20),
            ),
            SizedBox(width: 12),
            Text(
              'Focusify',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          Icon(Icons.more_vert, color: Colors.white),
          SizedBox(width: 16),
        ],
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: Colors.grey[400]),
                      SizedBox(width: 12),
                      Text(
                        'Search',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 24),
                
                // Main Categories Grid
                // Main Categories Grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.8,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    _buildCategoryCard(
                      'Today',
                      '${_formatTime(_calculateTotalTime(todayTasks))} (${todayTasks.length})',
                      Icons.wb_sunny_outlined,
                      Colors.green,
                    ),
                    _buildCategoryCard(
                      'Scheduled',
                      '${_formatTime(_calculateTotalTime(scheduledTasks))} (${scheduledTasks.length})',
                      Icons.schedule,
                      Colors.blue,
                    ),
                    _buildCategoryCard(
                      'All',
                      '${_formatTime(_calculateTotalTime(allTasks))} (${allTasks.length})',
                      Icons.list_alt,
                      Colors.orange,
                    ),
                    _buildCategoryCard(
                      'Priority',
                      '${_formatTime(_calculateTotalTime(priorityTasks))} (${priorityTasks.length})',
                      Icons.flag_outlined,
                      Colors.purple,
                    ),
                  ],
                ),
                
                SizedBox(height: 32),
                
                // Projects Section
                Text(
                  'Projects',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                SizedBox(height: 16),
                
                // Projects Grid or Empty State
                projects.isEmpty
                    ? _buildEmptyProjectsState()
                    : GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.8,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: projects.length,
                        itemBuilder: (context, index) {
                          final project = projects[index];
                          return _buildProjectCard(
                            project.name,
                            project.timeSpent,
                            project.taskCount,
                            project.color,
                          );
                        },
                      ),
                
                SizedBox(height: 100), // Space for FAB
              ],
            ),
          ),
          
          // Add Menu Overlay
          if (_showAddMenu)
            GestureDetector(
              onTap: _toggleAddMenu,
              child: Container(
                color: Colors.black54,
                child: Stack(
                  children: [
                    Positioned(
                      bottom: 100,
                      right: 20,
                      child: Column(
                        children: [
                          _buildAddMenuItem(
                            'Task',
                            Icons.task_alt,
                            _showAddTaskDialog,
                          ),
                          SizedBox(height: 12),
                          _buildAddMenuItem(
                            'Project',
                            Icons.folder_outlined,
                            _showAddProjectDialog,
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      right: 20,
                      child: FloatingActionButton(
                        onPressed: _toggleAddMenu,
                        backgroundColor: Colors.red,
                        child: Icon(Icons.close, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _showAddMenu
          ? null
          : FloatingActionButton(
              onPressed: _toggleAddMenu,
              backgroundColor: Colors.red,
              child: Icon(Icons.add, color: Colors.white),
            ),
    );
  }

  Widget _buildCategoryCard(String title, String subtitle, [IconData? icon, Color? color]) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color ?? Colors.transparent, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) Icon(icon, color: color ?? Colors.white, size: 20),
              if (icon != null) SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Spacer(),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(String name, String timeSpent, int taskCount, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Spacer(),
          Text(
            '$timeSpent ($taskCount)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyProjectsState() {
    return Container(
      padding: EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.folder_open_outlined,
            size: 64,
            color: Colors.grey[600],
          ),
          SizedBox(height: 16),
          Text(
            'No projects yet',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Create your first project to get started',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAddMenuItem(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddTaskSheet extends StatefulWidget {
  @override
  _AddTaskSheetState createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  int _selectedPomodoros = 1;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          TextField(
            style: TextStyle(color: Colors.white, fontSize: 18),
            decoration: InputDecoration(
              hintText: 'Add a Task...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: InputBorder.none,
            ),
          ),
          
          SizedBox(height: 24),
          
          Text(
            'Estimated Pomodoros',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          SizedBox(height: 16),
          
          Row(
            children: List.generate(8, (index) {
              final number = index + 1;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPomodoros = number;
                  });
                },
                child: Container(
                  margin: EdgeInsets.only(right: 12),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _selectedPomodoros == number ? Colors.red : Colors.grey[700],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '$number',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          
          SizedBox(height: 32),
          
          Row(
            children: [
              Icon(Icons.wb_sunny_outlined, color: Colors.grey[400]),
              SizedBox(width: 32),
              Icon(Icons.flag_outlined, color: Colors.grey[400]),
              SizedBox(width: 32),
              Icon(Icons.label_outline, color: Colors.grey[400]),
              SizedBox(width: 32),
              Icon(Icons.folder_outlined, color: Colors.grey[400]),
              Spacer(),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('Add', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AddProjectPage extends StatefulWidget {
  @override
  _AddProjectPageState createState() => _AddProjectPageState();
}

class _AddProjectPageState extends State<AddProjectPage> {
  Color _selectedColor = Colors.red;
  final TextEditingController _nameController = TextEditingController();

  final List<Color> _colorOptions = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.redAccent,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add New Project',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Icon(Icons.more_vert, color: Colors.white),
          SizedBox(width: 16),
        ],
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Project Name',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            
            SizedBox(height: 12),
            
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.folder_outlined, color: Colors.grey[400]),
                  SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Project Name',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 32),
            
            Text(
              'Project Color Mark',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            
            SizedBox(height: 16),
            
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: _colorOptions.length + 1,
                itemBuilder: (context, index) {
                  if (index == _colorOptions.length) {
                    // Rainbow/gradient option
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedColor = Colors.red; // Default for rainbow
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Colors.red, Colors.orange, Colors.yellow, Colors.green, Colors.blue, Colors.purple],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    );
                  }
                  
                  final color = _colorOptions[index];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = color;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: _selectedColor == color
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
            
            SizedBox(height: 32),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Add',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class Task {
  final String id;
  final String title;
  final int estimatedTime; // in hours
  final bool isCompleted;
  final bool isToday;
  final bool isPriority;
  final DateTime? scheduledDate;
  final String? projectId;

  Task({
    required this.id,
    required this.title,
    required this.estimatedTime,
    required this.isCompleted,
    required this.isToday,
    required this.isPriority,
    this.scheduledDate,
    this.projectId,
  });
}

class Project {
  final String name;
  final String timeSpent;
  final int taskCount;
  final Color color;

  Project({
    required this.name,
    required this.timeSpent,
    required this.taskCount,
    required this.color,
  });
}