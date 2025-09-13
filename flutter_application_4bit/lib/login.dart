import 'package:flutter/material.dart'; // Import Flutter Material widgets and themes
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/task_models.dart'; // Import custom Task model
// Initialize Firestore instance

final db = FirebaseFirestore.instance; // Initialize Firestore instance

// Define a stateful widget for the login page
class LoginPage extends StatefulWidget {
  const LoginPage({super.key}); // Constructor with optional key for widget identity

  @override
  State<LoginPage> createState() => _LoginPageState(); // Link the widget to its state
}

// State class that holds data and logic for the LoginPage widget
class _LoginPageState extends State<LoginPage> {
  List<Task> tasks = [
  Task(
    id: '1',
    title: 'Complete Flutter app',
    description: 'Finish implementing the remaining features for the mobile application',
    estimatedTime: 3.0,
    timeSpent: 2.999,
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
Future<List<Task>> loadTasksFromFirebase(String username) async {
  List<Task> loadedTasks = [];
  final querySnapshot = await db.collection('users').doc(username).collection('tasks').get();
  for (var doc in querySnapshot.docs) {
    loadedTasks.add(Task.fromJson(doc.data()));
  }
  debugPrint('Loaded ${loadedTasks.length} tasks from Firebase for user $username');
  return loadedTasks;
}
Future<void> addTask(Task newTask,String username ) async {
  await db
      .collection('users')
      .doc(username)
      .collection('tasks')
      .doc(newTask.id)
      .set(newTask.toJson());
  debugPrint('Added task ${newTask.title} for user $username');
}
  // Global key to uniquely identify the Form widget and allow form validation/saving
  final _formKey = GlobalKey<FormState>();

  // Variables to store user input
  String _email = '';
  String _password = '';

  // Controls whether the password is hidden or visible
  bool _obscureText = true;

  // Function to handle login button press
  void addAllTasks() {
    for (var task in tasks) {
        debugPrint(task.title);
        addTask(task, "test@gmail.com");
      }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')), // App bar with title
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0), // Add padding around the form
          child: Column(// give me test buttons to add tasks from a task list and get stuff 
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    tasks = await loadTasksFromFirebase('test@gmail.com');
                    setState(() {}); // Refresh the UI
                  },
                  child: const Text('Load Tasks from Firebase'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                      addAllTasks();
                  },
                  child: const Text('Add First Task to Firebase'),
                ),
              ]
             
          )
        ),
      ),
    );
  }
}
