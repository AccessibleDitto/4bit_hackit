import 'package:flutter/material.dart';
import 'package:flutter_application_4bit/widgets/date_selection_task.dart';
import 'package:flutter_application_4bit/widgets/navigation_widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_4bit/widgets/filtered_tasks_page.dart';
import 'package:flutter_application_4bit/widgets/navigation_widgets.dart';
import 'models/task_models.dart';

// enum Priority { low, medium, high, urgent }

// enum TaskStatus { 
//   notStarted,
//   inProgress, 
//   completed, 
//   cancelled,
//   blocked
// }

// enum EnergyLevel {
//   low,
//   medium,
//   high
// }

// enum TimePreference {
//   flexible,
//   morning,
//   afternoon,
//   specific
// }

// extension PriorityExtension on Priority {
//   String get displayName {
//     switch (this) {
//       case Priority.low:
//         return 'Low';
//       case Priority.medium:
//         return 'Medium';
//       case Priority.high:
//         return 'High';
//       case Priority.urgent:
//         return 'Urgent';
//     }
//   }
  
//   Color get color {
//     switch (this) {
//       case Priority.low:
//         return const Color(0xFF71717A);
//       case Priority.medium:
//         return const Color(0xFF3B82F6);
//       case Priority.high:
//         return const Color(0xFFF97316);
//       case Priority.urgent:
//         return const Color(0xFFEF4444);
//     }
//   }
// }

class TasksPage extends StatefulWidget {
  @override
  _TasksPageState createState() => _TasksPageState();
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

// Top-level task data for access from other files
List<Project> projects = [
  Project.create(
    name: 'Mobile App Development',
    color: const Color(0xFF9333EA),
  ),
  Project.create(
    name: 'Website Redesign',
    color: const Color(0xFF10B981),
  ),
  Project.create(
    name: 'Marketing Campaign',
    color: const Color(0xFF7C3AED),
  ),
];

List<Task> tasks = [
  Task(
    id: '1',
    title: 'Complete Flutter app',
    description: 'Finish implementing the remaining features for the mobile application',
    estimatedTime: 3.0,
    timeSpent: 2.5,
    dueDate: DateTime.now(),
    status: TaskStatus.inProgress,
    priority: Priority.high,
    projectId: '1',
    createdAt: DateTime.now().subtract(Duration(days: 2)),
    updatedAt: DateTime.now().subtract(Duration(hours: 1)),
  ),
  Task(
    id: '2',
    title: 'Review code',
    description: 'Code review for the new authentication module',
    estimatedTime: 1.0,
    timeSpent: 0.5,
    // scheduledFor: DateTime.now().add(Duration(hours: 2)),
    status: TaskStatus.notStarted,
    priority: Priority.medium,
    projectId: '1',
    createdAt: DateTime.now().subtract(Duration(days: 1)),
    updatedAt: DateTime.now().subtract(Duration(minutes: 30)),
  ),
  Task(
    id: '3',
    title: 'Meeting with team',
    description: 'Weekly standup meeting to discuss project progress',
    estimatedTime: 1.5,
    timeSpent: 1.5,
    dueDate: DateTime.now().add(Duration(days: 1)),
    status: TaskStatus.completed,
    priority: Priority.high,
    projectId: '2',
    createdAt: DateTime.now().subtract(Duration(days: 3)),
    updatedAt: DateTime.now().subtract(Duration(hours: 2)),
  ),
  Task(
    id: '4',
    title: 'Write documentation',
    description: 'Create user documentation for the new features',
    estimatedTime: 2.0,
    timeSpent: 2.0,
    dueDate: DateTime.now().add(Duration(days: 2)),
    status: TaskStatus.completed,
    priority: Priority.low,
    projectId: '2',
    createdAt: DateTime.now().subtract(Duration(days: 4)),
    updatedAt: DateTime.now().subtract(Duration(hours: 3)),
  ),
  Task(
    id: '5',
    title: 'Fix bug #123',
    description: 'Critical bug affecting user login functionality',
    estimatedTime: 1.0,
    timeSpent: 0.0,
    dueDate: DateTime.now().add(Duration(days: 3)),
    status: TaskStatus.notStarted,
    priority: Priority.urgent,
    projectId: '3',
    createdAt: DateTime.now().subtract(Duration(days: 1)),
    updatedAt: DateTime.now().subtract(Duration(minutes: 15)),
  ),
];

// Getter function to expose tasks for other files
List<Task> getTasksList() => tasks;

// Function to update the whole task and save it
void saveTask(Task updatedTask) {
  int index = tasks.indexWhere((task) => task.id == updatedTask.id);
  if (index != -1) {
    tasks[index] = updatedTask;
    // Can add Firebase saving logic here later on
    // For now, just update the local list
  }
}

// Function to update a task's timeSpent by ID
void updateTaskTimeSpent(String taskId, double additionalTimeSpent) {
  int index = tasks.indexWhere((task) => task.id == taskId);
  if (index != -1) {
    final currentTask = tasks[index];
    final updatedTask = currentTask.copyWith(
      timeSpent: currentTask.timeSpent + additionalTimeSpent,
    );
    tasks[index] = updatedTask;
    // Can add Firebase saving logic here later
  }
}

class _TasksPageState extends State<TasksPage> {
  bool _showAddMenu = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  ProjectStats _getProjectStats(String projectId) {
    final projectTasks = tasks.where((task) => task.projectId == projectId).toList();
    final completedTasks = projectTasks.where((task) => task.status == TaskStatus.completed).toList();
    final activeTasks = projectTasks.where((task) => task.status != TaskStatus.completed && task.status != TaskStatus.cancelled).toList();
    
    double totalTimeSpent = projectTasks.fold(0.0, (sum, task) => sum + task.timeSpent);
    double totalEstimatedTime = projectTasks.fold(0.0, (sum, task) => sum + task.estimatedTime);
    
    return ProjectStats(
      totalTasks: projectTasks.length,
      completedTasks: completedTasks.length,
      activeTasks: activeTasks.length,
      totalTimeSpent: totalTimeSpent,
      totalEstimatedTime: totalEstimatedTime,
    );
  }

  List<Task> get filteredTasks {
    if (_searchQuery.trim().isEmpty) return tasks;
    return tasks.where((task) => 
      task.title.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  List<Project> get filteredProjects {
    if (_searchQuery.trim().isEmpty) return projects;
    return projects.where((project) => 
      project.name.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  // Updated to use new Task class properties
  List<Task> get todayTasks => filteredTasks.where((task) => 
    task.shouldScheduleToday && task.status != TaskStatus.completed).toList();
  
  List<Task> get scheduledTasks => filteredTasks.where((task) => 
    task.scheduledFor != null && task.status != TaskStatus.completed).toList();
  
  List<Task> get allTasks => filteredTasks.where((task) => 
    task.status != TaskStatus.completed && task.status != TaskStatus.cancelled).toList();
  
  List<Task> get priorityTasks => filteredTasks.where((task) => 
    (task.priority == Priority.high || task.priority == Priority.urgent) && 
    task.status != TaskStatus.completed).toList();

  double _calculateTotalTime(List<Task> taskList) {
    return taskList.fold(0.0, (sum, task) => sum + task.estimatedTime);
  }

  void _toggleAddMenu() {
    setState(() {
      _showAddMenu = !_showAddMenu;
    });
  }

  void _addTask(Task newTask) {
    setState(() {
      tasks.add(newTask);
    });
  }

  void _addProject(Project newProject) {
    setState(() {
      projects.add(newProject);
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _navigateToFilteredTasks(String title, List<Task> taskList, Color accentColor, {String? projectName}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FilteredTasksPage(
          title: title,
          tasks: taskList,
          accentColor: accentColor,
          projectName: projectName,
        ),
      ),
    );
  }

  void _navigateToProjectTasks(Project project) {
    final projectTasks = tasks.where((task) => task.projectId == project.id).toList();
    _navigateToFilteredTasks(
      '${project.name} Tasks',
      projectTasks,
      project.color,
      projectName: project.name,
    );
  }

  void _showAddTaskDialog() {
    _toggleAddMenu();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF18181B),
      isScrollControlled: true,
      builder: (context) => AddTaskSheet(
        projects: projects,
        onAddTask: _addTask,
      ),
    );
  }

  void _showAddProjectDialog() {
    _toggleAddMenu();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddProjectPage(
          onAddProject: _addProject,
        ),
      ),
    );
  }

  Widget _buildEmptyProjectsState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.folder_open_outlined,
            size: 64,
            color: const Color(0xFF71717A),
          ),
          const SizedBox(height: 16),
          Text(
            projects.isEmpty ? 'No projects yet' : 'No projects found',
            style: GoogleFonts.inter(
              color: const Color(0xFFA1A1AA),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            projects.isEmpty 
                ? 'Create your first project to get started'
                : 'Try a different search term',
            style: GoogleFonts.inter(
              color: const Color(0xFF71717A),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(Project project, String timeSpent, int taskCount) {
    return GestureDetector(
      onTap: () => _navigateToProjectTasks(project),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF27272A).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: project.color.withValues(alpha: 0.3), 
            width: 2
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
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
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: project.color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    project.name,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              '$timeSpent ($taskCount tasks)',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddMenuItem(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF27272A).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF9333EA).withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.inter(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF9333EA), Color(0xFF7C3AED)],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.timer, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Focusify',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          const Icon(Icons.more_vert, color: Colors.white),
          const SizedBox(width: 16),
        ],
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
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF27272A).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF9333EA).withValues(alpha: 0.1),
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
                              hintText: 'Search tasks and projects...',
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
                  
                  const SizedBox(height: 24),
                  
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.8,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      GestureDetector(
                        onTap: () => _navigateToFilteredTasks(
                          'Today\'s Tasks',
                          todayTasks,
                          const Color(0xFF10B981),
                        ),
                        child: _buildCategoryCard(
                          'Today',
                          '${_formatTime(_calculateTotalTime(todayTasks))} (${todayTasks.length})',
                          Icons.wb_sunny_outlined,
                          const Color(0xFF10B981),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _navigateToFilteredTasks(
                          'Scheduled Tasks',
                          scheduledTasks,
                          const Color(0xFF3B82F6),
                        ),
                        child: _buildCategoryCard(
                          'Scheduled',
                          '${_formatTime(_calculateTotalTime(scheduledTasks))} (${scheduledTasks.length})',
                          Icons.schedule,
                          const Color(0xFF3B82F6),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _navigateToFilteredTasks(
                          'All Tasks',
                          allTasks,
                          const Color(0xFFF97316),
                        ),
                        child: _buildCategoryCard(
                          'All',
                          '${_formatTime(_calculateTotalTime(allTasks))} (${allTasks.length})',
                          Icons.list_alt,
                          const Color(0xFFF97316),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _navigateToFilteredTasks(
                          'Priority Tasks',
                          priorityTasks,
                          const Color(0xFF9333EA),
                        ),
                        child: _buildCategoryCard(
                          'Priority',
                          '${_formatTime(_calculateTotalTime(priorityTasks))} (${priorityTasks.length})',
                          Icons.flag_outlined,
                          const Color(0xFF9333EA),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  Text(
                    'Projects',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF71717A),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  filteredProjects.isEmpty
                      ? _buildEmptyProjectsState()
                      : GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.8,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredProjects.length,
                          itemBuilder: (context, index) {
                            final project = filteredProjects[index];
                            final stats = _getProjectStats(project.id);
                            return _buildProjectCard(
                              project,
                              _formatTime(stats.totalTimeSpent),
                              stats.activeTasks,
                            );
                          },
                        ),
                  
                  const SizedBox(height: 100),
                ],
              ),
            ),
            
            if (_showAddMenu)
              GestureDetector(
                onTap: _toggleAddMenu,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.7),
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
                            const SizedBox(height: 12),
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
                          backgroundColor: const Color(0xFF9333EA),
                          child: const Icon(Icons.close, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: _showAddMenu
          ? null
          : FloatingActionButton(
              onPressed: _toggleAddMenu,
              backgroundColor: const Color(0xFF9333EA),
              child: const Icon(Icons.add, color: Colors.white),
            ),
      bottomNavigationBar: const BottomNavigation(selectedIndex: 1),
    );
  }

  Widget _buildCategoryCard(String title, String subtitle, [IconData? icon, Color? color]) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF27272A).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (color ?? Colors.transparent).withValues(alpha: 0.3), 
          width: 2
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
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
              if (icon != null) Icon(icon, color: color ?? Colors.white, size: 20),
              if (icon != null) const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}


class AddTaskSheet extends StatefulWidget {
  final List<Project> projects;
  final Function(Task) onAddTask;

  const AddTaskSheet({super.key, required this.projects, required this.onAddTask});

  @override
  _AddTaskSheetState createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  double _selectedTime = 1.0;
  Priority _selectedPriority = Priority.medium;
  String? _selectedProjectId;
  DateTime? _scheduledDate = DateTime.now();
  final TextEditingController _titleController = TextEditingController();

  String get _dateDisplayText {
    if (_scheduledDate == null) return 'No Date';
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final selectedDay = DateTime(_scheduledDate!.year, _scheduledDate!.month, _scheduledDate!.day);
    
    if (selectedDay == today) {
      return 'Today';
    } else if (selectedDay == tomorrow) {
      return 'Tomorrow';
    } else if (selectedDay.isAfter(today) && selectedDay.isBefore(today.add(const Duration(days: 7)))) {
      const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return 'Later This Week (${dayNames[selectedDay.weekday - 1]})';
    } else if (selectedDay.isAfter(today.add(Duration(days: 7 - today.weekday))) && 
               selectedDay.isBefore(today.add(Duration(days: 14 - today.weekday)))) {
      return 'Next Week';
    } else {
      return '${selectedDay.day} ${_getMonthName(selectedDay.month)}';
    }
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String selectedDateType = 'Today';

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Color(0xFF18181B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: const Color(0xFF71717A),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          TextField(
            controller: _titleController,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 18),
            decoration: InputDecoration(
              hintText: 'Add a Task...',
              hintStyle: GoogleFonts.inter(color: const Color(0xFF71717A)),
              border: InputBorder.none,
            ),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'Estimated Time: ${_formatTime(_selectedTime)}',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFF9333EA),
                    inactiveTrackColor: const Color(0xFF71717A),
                    thumbColor: const Color(0xFF9333EA),
                    overlayColor: const Color(0xFF9333EA).withValues(alpha: 0.2),
                  ),
                  child: Slider(
                    value: _selectedTime,
                    min: 0.5,
                    max: 8.0,
                    divisions: 15,
                    onChanged: (value) {
                      setState(() {
                        _selectedTime = value;
                      });
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 0, right: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('30m', style: GoogleFonts.inter(color: const Color(0xFF71717A), fontSize: 12)),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text('2h', style: GoogleFonts.inter(color: const Color(0xFF71717A), fontSize: 12)),
                      ),
                      Text('4h', style: GoogleFonts.inter(color: const Color(0xFF71717A), fontSize: 12)),
                      Text('6h', style: GoogleFonts.inter(color: const Color(0xFF71717A), fontSize: 12)),
                      Text('8h', style: GoogleFonts.inter(color: const Color(0xFF71717A), fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'Priority',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: Priority.values.map((priority) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPriority = priority;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _selectedPriority == priority 
                        ? priority.color.withValues(alpha: 0.2)
                        : const Color(0xFF27272A),
                    borderRadius: BorderRadius.circular(16),
                    border: _selectedPriority == priority
                        ? Border.all(color: priority.color, width: 2)
                        : Border.all(color: const Color(0xFF71717A).withValues(alpha: 0.3), width: 1),
                  ),
                  child: Text(
                    priority.displayName,
                    style: GoogleFonts.inter(
                      color: _selectedPriority == priority 
                          ? priority.color 
                          : const Color(0xFF71717A),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          
          if (widget.projects.isNotEmpty) ...[
            Text(
              'Project',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF27272A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF71717A).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: DropdownButton<String?>(
                value: _selectedProjectId,
                hint: Text('Select Project', style: GoogleFonts.inter(color: const Color(0xFF71717A))),
                dropdownColor: const Color(0xFF27272A),
                underline: Container(),
                isExpanded: true,
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text('No Project', style: GoogleFonts.inter(color: Colors.white)),
                  ),
                  ...widget.projects.map((project) => DropdownMenuItem<String?>(
                    value: project.id,
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: project.color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(project.name, style: GoogleFonts.inter(color: Colors.white)),
                      ],
                    ),
                  )),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedProjectId = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          Row(
            children: [
              DateTimePickerButton(
                selectedDate: selectedDate,
                selectedTime: selectedTime,
                selectedDateType: selectedDateType,
                onDateTimeSelected: (date, time, dateType) {
                  setState(() {
                    selectedDate = date;
                    selectedTime = time;
                    selectedDateType = dateType;
                  });
                },
              ),
      
              const Spacer(),
              ElevatedButton(
                onPressed: _titleController.text.trim().isEmpty ? null : () {
                  // Determine if the task should be due today or scheduled for a specific time
                  DateTime? dueDate;
                  DateTime? scheduledFor;
                  
                  if (selectedDate != null) {
                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);
                    final selected = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day);
                    
                    if (selected.isAtSameMomentAs(today)) {
                      // If today is selected, set as due date
                      dueDate = selectedDate;
                    } else {
                      // If future date selected, set as due date
                      dueDate = selectedDate;
                    }
                    
                    // If specific time is selected, set scheduledFor
                    if (selectedTime != null) {
                      scheduledFor = DateTime(
                        selectedDate!.year,
                        selectedDate!.month,
                        selectedDate!.day,
                        selectedTime!.hour,
                        selectedTime!.minute,
                      );
                    }
                  }
                  
                  final newTask = Task(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: _titleController.text.trim(),
                    estimatedTime: _selectedTime,
                    timeSpent: 0.0,
                    status: TaskStatus.notStarted,
                    priority: _selectedPriority,
                    dueDate: dueDate,
                    scheduledFor: scheduledFor,
                    projectId: _selectedProjectId,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  widget.onAddTask(newTask);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9333EA),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Add', 
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AddProjectPage extends StatefulWidget {
  final Function(Project) onAddProject;

  const AddProjectPage({super.key, required this.onAddProject});

  @override
  _AddProjectPageState createState() => _AddProjectPageState();
}

class _AddProjectPageState extends State<AddProjectPage> {
  Color _selectedColor = const Color(0xFF9333EA);
  final TextEditingController _nameController = TextEditingController();

  final List<Color> _colorOptions = [
    const Color(0xFF9333EA),
    const Color(0xFF7C3AED),
    const Color(0xFFEC4899),
    const Color(0xFFEF4444),
    const Color(0xFF3B82F6),
    const Color(0xFF06B6D4),
    const Color(0xFF10B981),
    const Color(0xFF84CC16),
    const Color(0xFFF59E0B),
    const Color(0xFFF97316),
    const Color(0xFF8B5CF6),
    const Color(0xFF6366F1),
    const Color(0xFF14B8A6),
    const Color(0xFF22C55E),
    const Color(0xFFFBBF24),
    const Color(0xFF71717A),
    const Color(0xFFA1A1AA),
    const Color(0xFF525252),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add New Project',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          const Icon(Icons.more_vert, color: Colors.white),
          const SizedBox(width: 16),
        ],
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Project Name',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              const SizedBox(height: 12),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF27272A).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF9333EA).withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.folder_outlined, color: const Color(0xFF71717A)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        style: GoogleFonts.inter(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Project Name',
                          hintStyle: GoogleFonts.inter(color: const Color(0xFF71717A)),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              Text(
                'Project Color Mark',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              const SizedBox(height: 16),
              
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  itemCount: _colorOptions.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _colorOptions.length) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedColor = const Color(0xFF9333EA);
                          });
                        },
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFFEF4444),
                                Color(0xFFF97316),
                                Color(0xFFFBBF24),
                                Color(0xFF10B981),
                                Color(0xFF3B82F6),
                                Color(0xFF9333EA),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: _selectedColor == const Color(0xFF9333EA) && index == _colorOptions.length
                              ? Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 3),
                                  ),
                                )
                              : null,
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
              
              const SizedBox(height: 32),
              
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF27272A).withValues(alpha: 0.8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: BorderSide(
                          color: const Color(0xFF71717A).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          color: Colors.white, 
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                     onPressed: _nameController.text.trim().isEmpty ? null : () {
                        final newProject = Project.create(
                          name: _nameController.text.trim(),
                          color: _selectedColor,
                        );
                        widget.onAddProject(newProject);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9333EA),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        disabledBackgroundColor: const Color(0xFF71717A),
                      ),
                      child: Text(
                        'Add',
                        style: GoogleFonts.inter(
                          color: Colors.white, 
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

