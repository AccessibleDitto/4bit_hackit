import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'user_stats_service.dart';
import '../tasks.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  FirebaseService._internal() {
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  // Getters
  String? get userId => _auth.currentUser?.uid;
  User? get currentUser => _auth.currentUser;
  String? get currentUserEmail => _auth.currentUser?.email;

  // Collections
  static const String tasksCollection = 'tasks';
  static const String userStatsCollection = 'userStats';
  static const String achievementsCollection = 'achievements';
  static const String projectsCollection = 'projects';

  // Create user 
  Future<void> createUserWithGmailId(String email, String password) async {
    try {
      String emailAsId = email; 
      
      // Check if user document already exists and clean it up if needed
      final docRef = _firestore.collection('users').doc(emailAsId);
      final existingDoc = await docRef.get();
      
      if (existingDoc.exists) {
        debugPrint('User document already exists for $email, cleaning up...');
        // Delete existing user stats collection
        final statsQuery = await docRef.collection(userStatsCollection).get();
        for (final doc in statsQuery.docs) {
          await doc.reference.delete();
        }
        // Delete the main user document
        await docRef.delete();
        debugPrint('Cleaned up existing user data for $email');
      }
      
      // Create fresh user document
      await docRef.set({
        'email': email,
        'password': password,
        'gmail_based_id': emailAsId,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'registrationMethod': 'gmail_based_id',
      });
            
      // Initialize user stats with email-based ID
      await docRef.collection(userStatsCollection).doc('stats').set({
        'pomodorosCompleted': 0,
        'totalFocusTimeMinutes': 0,
        'streakDays': 0,
        'earnedBadges': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('Successfully created fresh user account for $email');
    } catch (e) {
      debugPrint('Error creating user with Gmail ID: $e');
      rethrow;
    }
  }

  // Clear any authentication state to ensure clean signup
  Future<void> clearAuthState() async {
    try {
      // Sign out from Firebase Auth if there's an active session
      if (_auth.currentUser != null) {
        await _auth.signOut();
        debugPrint('Cleared Firebase Auth state');
      }
    } catch (e) {
      debugPrint('Error clearing auth state: $e');
      // Don't rethrow - this is a cleanup operation
    }
  }

  // Test Firestore connection
  Future<void> testFirestoreConnection() async {
    const int maxRetries = 3;
    const Duration retryDelay = Duration(seconds: 2);
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        debugPrint('Testing Firestore connection (attempt $attempt/$maxRetries)...');
        
        await _firestore.collection('test').doc('connection').set({
          'message': 'Firestore connection successful!',
          'timestamp': FieldValue.serverTimestamp(),
          'testId': 'test_${DateTime.now().millisecondsSinceEpoch}',
          'attempt': attempt,
        }).timeout(const Duration(seconds: 10));

        debugPrint('Success on attempt $attempt!');

        return; 
      } catch (e) {
        debugPrint('Firestore connection failed on attempt $attempt: $e');
        
        if (attempt < maxRetries) {
          debugPrint('⏳ Retrying in ${retryDelay.inSeconds} seconds...');
          await Future.delayed(retryDelay);
        } else {
          debugPrint('All Firestore connection attempts failed');
          rethrow;
        }
      }
    }
  }
  
  // Get all users from Firestore (including registration data)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('users').get();
      
      List<Map<String, dynamic>> users = [];
      for (var doc in snapshot.docs) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        userData['id'] = doc.id;
        users.add(userData);
      }
      
      debugPrint('Retrieved ${users.length} users from Firestore');
      return users;
      
    } catch (e) {
      debugPrint('Error retrieving users: $e');
      rethrow;
    }
  }

  // Create a task in Firestore
  Future<void> createTask(String title, String description, DateTime dueDate) async {
    try {
      await _firestore.collection('tasks').add({
        'title': title,
        'description': description,
        'dueDate': Timestamp.fromDate(dueDate),
        'completed': false,
        'createdAt': FieldValue.serverTimestamp(),
        'priority': 'medium',
      });
      
      debugPrint('Task created successfully: $title');
      
    } catch (e) {
      debugPrint('Error creating task: $e');
      rethrow;
    }
  }
  
  // Get all tasks from Firestore
  Future<List<Map<String, dynamic>>> getAllTasks() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('tasks')
          .orderBy('createdAt', descending: true)
          .get();
      
      List<Map<String, dynamic>> tasks = [];
      for (var doc in snapshot.docs) {
        Map<String, dynamic> taskData = doc.data() as Map<String, dynamic>;
        taskData['id'] = doc.id;
        tasks.add(taskData);
      }
      
      debugPrint('Retrieved ${tasks.length} tasks from Firestore');
      return tasks;
      
    } catch (e) {
      debugPrint('Error retrieving tasks: $e');
      rethrow;
    }
  }
  
  // Sign up with email and password
  Future<UserCredential?> signUpWithEmailPassword(String email, String password) async {
    try {
      debugPrint('Attempting to create user with email: $email');
      
      // Add timeout to handle network issues
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      ).timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw FirebaseAuthException(
            code: 'timeout',
            message: 'Request timed out. Please try again or use a physical device.',
          );
        },
      );
      
      debugPrint('User created successfully: ${userCredential.user?.uid}');
      
      // Create initial user data in Firestore
      await _createUserProfile(userCredential.user!, email);
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Sign up error code: ${e.code}');
      debugPrint('Sign up error message: ${e.message}');
      
      // Handle specific error codes
      switch (e.code) {
        case 'network-request-failed':
          throw FirebaseAuthException(
            code: 'network-error',
            message: 'Network connection failed. Please try using a physical device instead of the emulator.',
          );
        case 'timeout':
          throw FirebaseAuthException(
            code: 'timeout',
            message: 'Request timed out. The emulator may have network issues. Try using a physical device.',
          );
        case 'email-already-in-use':
          throw FirebaseAuthException(
            code: 'email-already-in-use',
            message: 'An account already exists with this email address.',
          );
        case 'invalid-email':
          throw FirebaseAuthException(
            code: 'invalid-email',
            message: 'The email address is not valid.',
          );
        case 'weak-password':
          throw FirebaseAuthException(
            code: 'weak-password',
            message: 'The password is too weak. Please choose a stronger password.',
          );
        default:
          rethrow;
      }
    } catch (e) {
      debugPrint('Unexpected error during sign up: $e');
      throw FirebaseAuthException(code: 'unknown', message: 'An unexpected error occurred: $e');
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Sign in error code: ${e.code}');
      debugPrint('Sign in error message: ${e.message}');
      
      // Handle specific error codes
      switch (e.code) {
        case 'network-request-failed':
          throw FirebaseAuthException(
            code: 'network-error',
            message: 'Network connection failed. Please check your internet connection and try again.',
          );
        case 'user-not-found':
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'No account found with this email address.',
          );
        case 'wrong-password':
          throw FirebaseAuthException(
            code: 'wrong-password',
            message: 'Incorrect password. Please try again.',
          );
        case 'invalid-email':
          throw FirebaseAuthException(
            code: 'invalid-email',
            message: 'The email address is not valid.',
          );
        default:
          rethrow;
      }
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
      rethrow;
    }
  }

  // Create user profile in Firestore
  Future<void> _createUserProfile(User user, String email) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      });

      // Initialize user stats
      await _firestore.collection('users').doc(user.uid).collection(userStatsCollection).doc('stats').set({
        'pomodorosCompleted': 0,
        'totalFocusTimeMinutes': 0,
        'streakDays': 0,
        'earnedBadges': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error creating user profile: $e');
      rethrow;
    }
  }

  // Delete user account
  Future<void> deleteAccount() async {
    try {
      // Get current user info before deletion
      final currentUserId = userId;
      final userEmail = currentUserEmail;
      
      // For Gmail-based authentication, we need to get the current user email differently
      // since users might not be signed into Firebase Auth
      if (currentUserId == null && userEmail == null) {
        // Try to delete based on stored user session or throw a more specific error
        throw Exception('No authenticated user found. Please sign in again.');
      }
      
      // Delete user data from Firestore (both possible document locations)
      if (currentUserId != null) {
        debugPrint('Deleting Firebase Auth user data for UID: $currentUserId');
        await _deleteUserData(currentUserId);
        
        // Delete the Firebase Auth user account
        await _auth.currentUser?.delete();
      }
      
      // Also delete Gmail-based ID document if it exists
      if (userEmail != null) {
        debugPrint('Deleting Gmail-based user data for email: $userEmail');
        await _deleteGmailBasedUserData(userEmail);
      }
      
    } catch (e) {
      debugPrint('Error deleting account: $e');
      rethrow;
    }
  }

  // Delete account for Gmail-based authentication (when no Firebase Auth user exists)
  Future<void> deleteGmailBasedAccount(String email) async {
    try {
      debugPrint('Deleting Gmail-based account for email: $email');
      await _deleteGmailBasedUserData(email);
    } catch (e) {
      debugPrint('Error deleting Gmail-based account: $e');
      rethrow;
    }
  }

  // Delete all user data from Firestore
  Future<void> _deleteUserData(String uid) async {
    try {
      // Delete user document and all subcollections
      WriteBatch batch = _firestore.batch();
      
      // Delete user stats
      batch.delete(_firestore.collection('users').doc(uid).collection(userStatsCollection).doc('stats'));
      
      // Delete tasks
      QuerySnapshot tasksSnapshot = await _firestore.collection('users').doc(uid).collection(tasksCollection).get();
      for (DocumentSnapshot doc in tasksSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete achievements
      QuerySnapshot achievementsSnapshot = await _firestore.collection('users').doc(uid).collection(achievementsCollection).get();
      for (DocumentSnapshot doc in achievementsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete projects
      QuerySnapshot projectsSnapshot = await _firestore.collection('users').doc(uid).collection(projectsCollection).get();
      for (DocumentSnapshot doc in projectsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete user document
      batch.delete(_firestore.collection('users').doc(uid));
      
      await batch.commit();
    } catch (e) {
      debugPrint('Error deleting user data: $e');
      rethrow;
    }
  }

  // Delete Gmail-based user data from Firestore
  Future<void> _deleteGmailBasedUserData(String email) async {
    try {
      // Delete user document with email as ID and all subcollections
      WriteBatch batch = _firestore.batch();
      
      // Delete user stats
      batch.delete(_firestore.collection('users').doc(email).collection(userStatsCollection).doc('stats'));
      
      // Delete tasks
      QuerySnapshot tasksSnapshot = await _firestore.collection('users').doc(email).collection(tasksCollection).get();
      for (DocumentSnapshot doc in tasksSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete achievements
      QuerySnapshot achievementsSnapshot = await _firestore.collection('users').doc(email).collection(achievementsCollection).get();
      for (DocumentSnapshot doc in achievementsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete projects
      QuerySnapshot projectsSnapshot = await _firestore.collection('users').doc(email).collection(projectsCollection).get();
      for (DocumentSnapshot doc in projectsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete user document
      batch.delete(_firestore.collection('users').doc(email));
      
      await batch.commit();
    } catch (e) {
      debugPrint('Error deleting Gmail-based user data: $e');
      rethrow;
    }
  }

  // ========== TASK MANAGEMENT ==========
  
  // Save task to Firebase
  Future<void> saveTask(Task task) async {
    try {
      if (userId == null) throw Exception('User not authenticated');
      
      await _firestore
          .collection('users')
          .doc(userId)
          .collection(tasksCollection)
          .doc(task.id)
          .set({
        'id': task.id,
        'title': task.title,
        'estimatedTime': task.estimatedTime,
        'isCompleted': task.isCompleted,
        'isToday': task.isToday,
        'isPriority': task.isPriority,
        'scheduledDate': task.scheduledDate?.millisecondsSinceEpoch,
        'projectId': task.projectId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('Task saved to Firebase: ${task.title}');
    } catch (e) {
      debugPrint('Error saving task to Firebase: $e');
      rethrow;
    }
  }

  // Load all tasks from Firebase
  Future<List<Task>> loadTasks() async {
    try {
      if (userId == null) throw Exception('User not authenticated');
      
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection(tasksCollection)
          .orderBy('createdAt', descending: false)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Task(
          id: data['id'] ?? doc.id,
          title: data['title'] ?? '',
          estimatedTime: data['estimatedTime'] ?? 1,
          isCompleted: data['isCompleted'] ?? false,
          isToday: data['isToday'] ?? false,
          isPriority: data['isPriority'] ?? false,
          scheduledDate: data['scheduledDate'] != null 
              ? DateTime.fromMillisecondsSinceEpoch(data['scheduledDate'])
              : null,
          projectId: data['projectId'],
        );
      }).toList();
    } catch (e) {
      debugPrint('Error loading tasks: $e');
      return [];
    }
  }

  // Update task completion status
  Future<void> updateTaskCompletion(String taskId, bool isCompleted) async {
    try {
      if (userId == null) throw Exception('User not authenticated');
      
      await _firestore
          .collection('users')
          .doc(userId)
          .collection(tasksCollection)
          .doc(taskId)
          .update({
        'isCompleted': isCompleted,
        'updatedAt': FieldValue.serverTimestamp(),
        'completedAt': isCompleted ? FieldValue.serverTimestamp() : null,
      });
    } catch (e) {
      debugPrint('Error updating task completion: $e');
      rethrow;
    }
  }

  // Delete task from Firebase
  Future<void> deleteTask(String taskId) async {
    try {
      if (userId == null) throw Exception('User not authenticated');
      
      await _firestore
          .collection('users')
          .doc(userId)
          .collection(tasksCollection)
          .doc(taskId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting task: $e');
      rethrow;
    }
  }

  // ========== USER STATS MANAGEMENT ==========
  
  // Save user stats to Firebase
  Future<void> saveUserStats(UserStats userStats) async {
    try {
      if (userId == null) throw Exception('User not authenticated');
      
      await _firestore
          .collection('users')
          .doc(userId)
          .collection(userStatsCollection)
          .doc('stats')
          .set({
        'pomodorosCompleted': userStats.pomodorosCompleted,
        'totalFocusTimeMinutes': userStats.totalFocusTimeMinutes,
        'streakDays': userStats.streakDays,
        'lastActiveDate': userStats.lastActiveDate?.millisecondsSinceEpoch,
        'earnedBadges': userStats.earnedBadges,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      debugPrint('User stats saved to Firebase successfully');
    } catch (e) {
      debugPrint('Error saving user stats: $e');
      rethrow;
    }
  }

  // Load user stats from Firebase
  Future<Map<String, dynamic>?> loadUserStats() async {
    try {
      if (userId == null) throw Exception('User not authenticated');
      
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection(userStatsCollection)
          .doc('stats')
          .get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      debugPrint('Error loading user stats: $e');
      return null;
    }
  }

  // ========== ACHIEVEMENTS MANAGEMENT ==========
  
  // Save achievement to Firebase
  Future<void> saveAchievement(Achievement achievement) async {
    try {
      if (userId == null) throw Exception('User not authenticated');
      
      await _firestore
          .collection('users')
          .doc(userId)
          .collection(achievementsCollection)
          .add({
        'emoji': achievement.emoji,
        'title': achievement.title,
        'description': achievement.description,
        'timestamp': achievement.timestamp.millisecondsSinceEpoch,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('Achievement saved to Firebase: ${achievement.title}');
    } catch (e) {
      debugPrint('Error saving achievement: $e');
      rethrow;
    }
  }

  // Load achievements from Firebase
  Future<List<Achievement>> loadAchievements() async {
    try {
      if (userId == null) throw Exception('User not authenticated');
      
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection(achievementsCollection)
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Achievement(
          emoji: data['emoji'] ?? '🏆',
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp'] ?? 0),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error loading achievements: $e');
      return [];
    }
  }

  // ========== PROJECT MANAGEMENT ==========
  
  // Save project to Firebase
  Future<void> saveProject(Project project) async {
    try {
      if (userId == null) throw Exception('User not authenticated');
      
      await _firestore
          .collection('users')
          .doc(userId)
          .collection(projectsCollection)
          .doc(project.name)
          .set({
        'name': project.name,
        'timeSpent': project.timeSpent,
        'taskCount': project.taskCount,
        'color': project.color.value,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error saving project: $e');
      rethrow;
    }
  }

  // Load projects from Firebase
  Future<List<Project>> loadProjects() async {
    try {
      if (userId == null) throw Exception('User not authenticated');
      
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection(projectsCollection)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Project(
          name: data['name'] ?? '',
          timeSpent: data['timeSpent'] ?? '0h',
          taskCount: data['taskCount'] ?? 0,
          color: Color(data['color'] ?? Colors.blue.value),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error loading projects: $e');
      return [];
    }
  }
}