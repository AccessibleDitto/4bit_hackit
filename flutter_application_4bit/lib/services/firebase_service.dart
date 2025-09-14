import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_stats_service.dart';
import '../models/task_models.dart';

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

  Future<void> _ensureAuthenticated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString('current_user_email');

      if (userEmail != null && userEmail.isNotEmpty) {
        _currentEmailUser = userEmail;
        return;
      }

      _currentEmailUser = 'user@gmail.com';
    } catch (e) {
      _currentEmailUser = 'user@gmail.com';
    }
  }

  String? get effectiveUserId {
    return _currentEmailUser;
  }

  String? _currentEmailUser;

  // Collections
  static const String tasksCollection = 'tasks';
  static const String userStatsCollection = 'userStats';
  static const String achievementsCollection = 'achievements';
  static const String projectsCollection = 'projects';

  // Create user
  Future<void> createUserWithGmailId(String email, String password) async {
    try {
      String emailAsId = email;
      final docRef = _firestore.collection('users').doc(emailAsId);
      final existingDoc = await docRef.get();

      if (existingDoc.exists) {
        // Delete existing user stats collection
        final statsQuery = await docRef.collection(userStatsCollection).get();
        for (final doc in statsQuery.docs) {
          await doc.reference.delete();
        }
        // Delete the main user document
        await docRef.delete();
      }

      // Create fresh user document
      await docRef.set({
        'email': email,
        'password': password,
        'gmail_based_id': emailAsId,
        'createdAt': DateTime.now(),
        'lastLoginAt': DateTime.now(),
        'registrationMethod': 'gmail_based_id',
      });

      // consolidated user stats
      await docRef.collection(userStatsCollection).doc('stats').set({
        'pomodorosCompleted': 0,
        'totalFocusTimeMinutes': 0,
        'todayFocusTimeMinutes': 0,
        'weekFocusTimeMinutes': 0,
        'monthFocusTimeMinutes': 0,
        'totalFocusTime': '0m',

        // steak, activity
        'streakDays': 0,
        'lastActiveDate': null,

        // badge, achievemnt
        'earnedBadges': [],
        'totalBadges': 0,
        'totalAchievements': 0,

        // tasks
        'totalTasks': 0,
        'completedTasks': 0,
        'inProgressTasks': 0,
        'todayCompletedTasks': 0,
        'priorityTasksCompleted': 0,
        'totalFocusTimeFromTasks': 0,
        'todayFocusTimeFromTasks': 0,

        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      debugPrint('Error creating user with Gmail ID: $e');
      rethrow;
    }
  }

  Future<void> clearAuthState() async {
    try {
      if (_auth.currentUser != null) {
        await _auth.signOut();
      }
    } catch (e) {
      debugPrint('Error clearing auth state: $e');
    }
  }

  Future<void> testFirestoreConnection() async {
    const int maxRetries = 3;
    const Duration retryDelay = Duration(seconds: 2);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        debugPrint(
          'Testing Firestore connection (attempt $attempt/$maxRetries)...',
        );

        await _firestore
            .collection('test')
            .doc('connection')
            .set({
              'message': 'Firestore connection successful!',
              'timestamp': DateTime.now(),
              'testId': 'test_${DateTime.now().millisecondsSinceEpoch}',
              'attempt': attempt,
            })
            .timeout(const Duration(seconds: 10));

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

  // Get all users from Firestore, incl registration data
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('users').get();

      List<Map<String, dynamic>> users = [];
      for (var doc in snapshot.docs) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        userData['id'] = doc.id;
        users.add(userData);
      }

      return users;
    } catch (e) {
      debugPrint('Error retrieving users: $e');
      rethrow;
    }
  }

  Future<UserCredential?> signUpWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password)
          .timeout(
            Duration(seconds: 30),
            onTimeout: () {
              throw FirebaseAuthException(
                code: 'timeout',
                message: 'Request timed out. Please try again.',
              );
            },
          );

      await _createUserProfile(userCredential.user!, email);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'network-request-failed':
          throw FirebaseAuthException(
            code: 'network-error',
            message:
                'Network connection failed. Please try using a physical device instead of the emulator.',
          );
        case 'timeout':
          throw FirebaseAuthException(
            code: 'timeout',
            message:
                'Request timed out. The emulator may have network issues. Try using a physical device.',
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
            message:
                'The password is too weak. Please choose a stronger password.',
          );
        default:
          rethrow;
      }
    } catch (e) {
      throw FirebaseAuthException(
        code: 'unknown',
        message: 'An unexpected error occurred: $e',
      );
    }
  }

  Future<UserCredential?> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'network-request-failed':
          throw FirebaseAuthException(
            code: 'network-error',
            message:
                'Network connection failed. Please check your internet connection and try again.',
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
        'createdAt': DateTime.now(),
        'lastLoginAt': DateTime.now(),
      });

      // consolidated user stats
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection(userStatsCollection)
          .doc('stats')
          .set({
            'pomodorosCompleted': 0,
            'totalFocusTimeMinutes': 0,
            'todayFocusTimeMinutes': 0,
            'weekFocusTimeMinutes': 0,
            'monthFocusTimeMinutes': 0,
            'totalFocusTime': '0m',

            // streak, activity
            'streakDays': 0,
            'lastActiveDate': null,

            // badges, achievements
            'earnedBadges': [],
            'totalBadges': 0,
            'totalAchievements': 0,

            // task stats
            'totalTasks': 0,
            'completedTasks': 0,
            'inProgressTasks': 0,
            'todayCompletedTasks': 0,
            'priorityTasksCompleted': 0,
            'totalFocusTimeFromTasks': 0,
            'todayFocusTimeFromTasks': 0,

            'createdAt': DateTime.now(),
            'updatedAt': DateTime.now(),
          });
    } catch (e) {
      debugPrint('Error creating user profile: $e');
      rethrow;
    }
  }

  // Delete user account
  Future<void> deleteAccount() async {
    try {
      final currentUserId = userId;
      final userEmail = currentUserEmail;

      if (currentUserId == null && userEmail == null) {
        throw Exception('No authenticated user found. Please sign in again.');
      }
      if (currentUserId != null) {
        await _deleteUserData(currentUserId);
        await _auth.currentUser?.delete();
      }
      // Fallback
      else if (userEmail != null) {
        await _deleteUserData(userEmail);
      }
    } catch (e) {
      debugPrint('Error deleting account: $e');
      rethrow;
    }
  }

  Future<void> deleteGmailBasedAccount(String email) async {
    try {
      await _deleteUserData(email);
    } catch (e) {
      debugPrint('Error deleting Gmail-based account: $e');
      rethrow;
    }
  }

  // Delete all user data
  Future<void> _deleteUserData(String documentId) async {
    try {
      WriteBatch batch = _firestore.batch();

      // Delete user stats
      batch.delete(
        _firestore
            .collection('users')
            .doc(documentId)
            .collection(userStatsCollection)
            .doc('stats'),
      );

      // Delete tasks
      QuerySnapshot tasksSnapshot = await _firestore
          .collection('users')
          .doc(documentId)
          .collection(tasksCollection)
          .get();
      for (DocumentSnapshot doc in tasksSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete achievements
      QuerySnapshot achievementsSnapshot = await _firestore
          .collection('users')
          .doc(documentId)
          .collection(achievementsCollection)
          .get();
      for (DocumentSnapshot doc in achievementsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete projects
      QuerySnapshot projectsSnapshot = await _firestore
          .collection('users')
          .doc(documentId)
          .collection(projectsCollection)
          .get();
      for (DocumentSnapshot doc in projectsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete user document
      batch.delete(_firestore.collection('users').doc(documentId));

      await batch.commit();
      debugPrint('Successfully deleted all user data for: $documentId');
    } catch (e) {
      debugPrint('Error deleting user data: $e');
      rethrow;
    }
  }

  // ========== TASK MANAGEMENT ==========

  // Save task to Firebase
  Future<void> saveTask(Task task) async {
    try {
      await _ensureAuthenticated();

      final userDoc = effectiveUserId;
      if (userDoc == null) throw Exception('No user identifier available');

      // tasks model
      final taskData = task.toJson();

      await _firestore
          .collection('users')
          .doc(userDoc)
          .collection(tasksCollection)
          .doc(task.id)
          .set(taskData);

      await _updateUserTaskStats();
    } catch (e) {
      debugPrint('Error saving task to Firebase: $e');
      rethrow;
    }
  }
  Future<void> updatetask() => _updateUserTaskStats();
  // Update user task statistics
  Future<void> _updateUserTaskStats() async {
    try {
      await _ensureAuthenticated();

      final userDoc = effectiveUserId;
      if (userDoc == null) return;

      // Get all tasks for the user
      final tasksSnapshot = await _firestore
          .collection('users')
          .doc(userDoc)
          .collection(tasksCollection)
          .get();

      int totalTasks = tasksSnapshot.docs.length;
      int completedTasks = 0;
      int inProgressTasks = 0;
      int notStartedTasks = 0;
      double totalTimeSpent = 0.0;
      double totalEstimatedTime = 0.0;

      for (var doc in tasksSnapshot.docs) {
        final data = doc.data();
        final status = data['status'] ?? 'notStarted';
        final timeSpent = (data['timeSpent'] ?? 0.0).toDouble();
        final estimatedTime = (data['estimatedTime'] ?? 0.0).toDouble();

        totalTimeSpent += timeSpent;
        totalEstimatedTime += estimatedTime;

        switch (status) {
          case 'completed':
            completedTasks++;
            break;
          case 'inProgress':
            inProgressTasks++;
            break;
          default:
            notStartedTasks++;
            break;
        }
      }

      // Update user stats
      await _firestore
          .collection('users')
          .doc(userDoc)
          .collection(userStatsCollection)
          .doc('stats')
          .update({
            'totalTasks': totalTasks,
            'completedTasks': completedTasks,
            'inProgressTasks': inProgressTasks,
            'notStartedTasks': notStartedTasks,
            'totalTimeSpent': totalTimeSpent,
            'totalEstimatedTime': totalEstimatedTime,
            'lastUpdated': DateTime.now(),
          });
    } catch (e) {
      debugPrint('Error updating user task stats: $e');
    }
  }

  Future<void> addTask(Task newTask) async {
    final username = _currentEmailUser;
    await _firestore
        .collection('users')
        .doc(username)
        .collection('tasks')
        .doc(newTask.id)
        .set(newTask.toJson());
    debugPrint('Added task ${newTask.title} for user $username');
  }

  // Load all tasks from Firebase
  Future<List<Task>> loadTasks() async {
    try {
      await _ensureAuthenticated();

      final userDoc = effectiveUserId;
      if (userDoc == null) throw Exception('No user identifier available');

      final querySnapshot = await _firestore
          .collection('users')
          .doc(userDoc)
          .collection(tasksCollection)
          .orderBy('createdAt', descending: false)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();

        // if (data['createdAt'] is Timestamp) {
        //   data['createdAt'] = (data['createdAt'] as Timestamp)
        //       .toDate()
        //       .toIso8601String();
        // }
        // if (data['updatedAt'] is Timestamp) {
        //   data['updatedAt'] = (data['updatedAt'] as Timestamp)
        //       .toDate()
        //       .toIso8601String();
        // }

        // use task model
        return Task.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('Error loading tasks: $e');
      return [];
    }
  }

  // Update task completion status
  Future<void> updateTaskCompletion(String taskId, TaskStatus newStatus) async {
    try {
      await _ensureAuthenticated();

      final userDoc = effectiveUserId;
      if (userDoc == null) throw Exception('No user identifier available');

      await _firestore
          .collection('users')
          .doc(userDoc)
          .collection(tasksCollection)
          .doc(taskId)
          .update({
            'status': newStatus.name,
            'updatedAt': DateTime.now(),
            'completedAt': newStatus == TaskStatus.completed
                ? DateTime.now()
                : null,
          });

      // Update user task statistics
      await _updateUserTaskStats();
    } catch (e) {
      debugPrint('Error updating task status: $e');
      rethrow;
    }
  }

  // Update task progress
  Future<void> updateTaskProgress(
    String taskId,
    double timeSpent, {
    double? progressPercentage,
  }) async {
    try {
      await _ensureAuthenticated();

      final userDoc = effectiveUserId;
      if (userDoc == null) throw Exception('No user identifier available');

      Map<String, dynamic> updates = {
        'timeSpent': timeSpent,
        'updatedAt': DateTime.now(),
      };

      if (progressPercentage != null) {
        updates['progressPercentage'] = progressPercentage;
      }

      await _firestore
          .collection('users')
          .doc(userDoc)
          .collection(tasksCollection)
          .doc(taskId)
          .update(updates);

      // Update user task statistics
      await _updateUserTaskStats();
    } catch (e) {
      debugPrint('Error updating task progress: $e');
      rethrow;
    }
  }
  
  // Delete task from Firebase
  Future<void> deleteTask(String taskId) async {
    try {
      await _ensureAuthenticated();

      final userDoc = effectiveUserId;
      if (userDoc == null) throw Exception('No user identifier available');

      await _firestore
          .collection('users')
          .doc(userDoc)
          .collection(tasksCollection)
          .doc(taskId)
          .delete();

      // Update user task statistics
      await _updateUserTaskStats();
    } catch (e) {
      debugPrint('Error deleting task: $e');
      rethrow;
    }
  }

  // ========== USER STATS MANAGEMENT ==========

  // Save user stats to Firebase
  Future<void> saveUserStats(UserStats userStats) async {
    try {
      await _ensureAuthenticated();

      final userDoc = effectiveUserId;
      if (userDoc == null) throw Exception('No user identifier available');

      // userstats consolidated
      await _firestore
          .collection('users')
          .doc(userDoc)
          .collection('userStats')
          .doc('stats')
          .set({
            'pomodorosCompleted': userStats.pomodorosCompleted,
            'totalFocusTimeMinutes': userStats.totalFocusTimeMinutes,
            'todayFocusTimeMinutes': userStats.todayFocusTimeMinutes,
            'weekFocusTimeMinutes': userStats.weekFocusTimeMinutes,
            'monthFocusTimeMinutes': userStats.monthFocusTimeMinutes,
            'totalFocusTime': userStats.totalFocusTime,

            // steak, activity
            'streakDays': userStats.streakDays,
            'lastActiveDate': userStats.lastActiveDate?.millisecondsSinceEpoch,

            // badges, achievements
            'earnedBadges': userStats.earnedBadges,
            'totalBadges': userStats.earnedBadges.length,
            'totalAchievements': userStats.recentAchievements.length,

            // tasks stats
            'totalTasks': userStats.tasksCompleted, // Use existing data
            'completedTasks': userStats.tasksCompleted,
            // task manager handle
            'inProgressTasks': 0,
            'todayCompletedTasks': 0,
            'priorityTasksCompleted': 0,

            'createdAt': DateTime.now(),
            'updatedAt': DateTime.now(),
          }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving user stats: $e');
      rethrow;
    }
  }

  // Load user stats from Firebase
  Future<Map<String, dynamic>?> loadUserStats() async {
    try {
      await _ensureAuthenticated();

      final userDoc = effectiveUserId;
      if (userDoc == null) throw Exception('No user identifier available');

      final doc = await _firestore
          .collection('users')
          .doc(userDoc)
          .collection('userStats')
          .doc('stats')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        return data;
      }
      return null;
    } catch (e) {
      debugPrint('Error loading user stats: $e');
      return null;
    }
  }

  // ========== CONSOLIDATED STATS MANAGEMENT ==========

  Future<void> saveTaskStats(Map<String, dynamic> taskStats) async {
    try {
      await _ensureAuthenticated();

      final userDoc = effectiveUserId;
      if (userDoc == null) throw Exception('No user identifier available');

      // save task stats to consolidated userStats doc
      await _firestore
          .collection('users')
          .doc(userDoc)
          .collection('userStats')
          .doc('stats')
          .update({
            // Task Statistics
            'totalTasks': taskStats['totalTasks'] ?? 0,
            'completedTasks': taskStats['completedTasks'] ?? 0,
            'inProgressTasks': taskStats['inProgressTasks'] ?? 0,
            'priorityTasksCompleted': taskStats['priorityTasksCompleted'] ?? 0,
            'todayCompletedTasks': taskStats['todayCompletedTasks'] ?? 0,

            // Focus time from consolidated tasks
            'totalFocusTimeFromTasks':
                taskStats['totalFocusTimeFromTasks'] ?? 0,
            'todayFocusTimeFromTasks':
                taskStats['todayFocusTimeFromTasks'] ?? 0,

            'updatedAt': DateTime.now(),
          });
    } catch (e) {
      debugPrint('Error saving task stats to userStats: $e');
      rethrow;
    }
  }

  // consolidated userStats
  Future<Map<String, dynamic>?> loadTaskStats() async {
    try {
      await _ensureAuthenticated();

      final userDoc = effectiveUserId;
      if (userDoc == null) throw Exception('No user identifier available');

      // from userStats doc
      final doc = await _firestore
          .collection('users')
          .doc(userDoc)
          .collection('userStats')
          .doc('stats')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        return {
          'totalTasks': data['totalTasks'] ?? 0,
          'completedTasks': data['completedTasks'] ?? 0,
          'inProgressTasks': data['inProgressTasks'] ?? 0,
          'priorityTasksCompleted': data['priorityTasksCompleted'] ?? 0,
          'todayCompletedTasks': data['todayCompletedTasks'] ?? 0,
          'totalFocusTimeFromTasks': data['totalFocusTimeFromTasks'] ?? 0,
          'todayFocusTimeFromTasks': data['todayFocusTimeFromTasks'] ?? 0,
        };
      }
      return null;
    } catch (e) {
      debugPrint('Error loading task stats from userStats: $e');
      return null;
    }
  }

  // ========== COMBINE HELPER ==========

  // combine task and user stats structure
  Future<void> migrateToConsolidatedStructure() async {
    try {
      await _ensureAuthenticated();

      final userDoc = effectiveUserId;
      if (userDoc == null) throw Exception('No user identifier available');

      // Check if old taskStats collection exists
      final taskStatsDoc = await _firestore
          .collection('users')
          .doc(userDoc)
          .collection('taskStats')
          .doc('stats')
          .get();

      if (taskStatsDoc.exists) {
        final taskStatsData = taskStatsDoc.data()!;

        // Merge taskStats into userStats
        await _firestore
            .collection('users')
            .doc(userDoc)
            .collection('userStats')
            .doc('stats')
            .update({
              'totalTasks': taskStatsData['totalTasks'] ?? 0,
              'completedTasks': taskStatsData['completedTasks'] ?? 0,
              'inProgressTasks': taskStatsData['inProgressTasks'] ?? 0,
              'priorityTasksCompleted':
                  taskStatsData['priorityTasksCompleted'] ?? 0,
              'todayCompletedTasks': taskStatsData['todayCompletedTasks'] ?? 0,
              'totalFocusTimeFromTasks':
                  taskStatsData['totalFocusTimeFromTasks'] ?? 0,
              'todayFocusTimeFromTasks':
                  taskStatsData['todayFocusTimeFromTasks'] ?? 0,
              'migrationComplete': true,
              'updatedAt': DateTime.now(),
            });

        // Delete the old taskStats collection
        await _firestore
            .collection('users')
            .doc(userDoc)
            .collection('taskStats')
            .doc('stats')
            .delete();

        debugPrint(
          'Successfully migrated taskStats to consolidated userStats structure',
        );
      }
    } catch (e) {
      debugPrint('Error during migration: $e');
    }
  }

  // ========== ACHIEVEMENTS MANAGEMENT ==========

  // Save achievement to Firebase
  Future<void> saveAchievement(Achievement achievement) async {
    try {
      await _ensureAuthenticated();

      final userDoc = effectiveUserId;
      if (userDoc == null) throw Exception('No user identifier available');

      await _firestore
          .collection('users')
          .doc(userDoc)
          .collection(achievementsCollection)
          .add({
            'emoji': achievement.emoji,
            'title': achievement.title,
            'description': achievement.description,
            'timestamp': achievement.timestamp.millisecondsSinceEpoch,
            'createdAt': DateTime.now(),
          });
    } catch (e) {
      debugPrint('Error saving achievement: $e');
      rethrow;
    }
  }

  Future<void> updateBadges(List<String> earnedBadges) async {
    try {
      await _ensureAuthenticated();

      final userDoc = effectiveUserId;
      if (userDoc == null) throw Exception('No user identifier available');

      await _firestore
          .collection('users')
          .doc(userDoc)
          .collection('userStats')
          .doc('stats')
          .update({
            'earnedBadges': earnedBadges,
            'totalBadges': earnedBadges.length,
            'updatedAt': DateTime.now(),
          });
    } catch (e) {
      // Try to create the document if it doesn't exist
      try {
        final userDoc = effectiveUserId;
        if (userDoc == null) throw Exception('No user identifier available');

        await _firestore
            .collection('users')
            .doc(userDoc)
            .collection('userStats')
            .doc('stats')
            .set({
              'earnedBadges': earnedBadges,
              'totalBadges': earnedBadges.length,
              'createdAt': DateTime.now(),
              'updatedAt': DateTime.now(),
            }, SetOptions(merge: true));
      } catch (createError) {
        debugPrint('Error creating userStats document: $createError');
        rethrow;
      }
    }
  }

  Future<void> updatePomodoroCount(
    int pomodoroCount,
    int totalFocusTime,
    int streakDays,
  ) async {
    try {
      await _ensureAuthenticated();

      final userDoc = effectiveUserId;
      if (userDoc == null) throw Exception('No user identifier available');

      await _firestore
          .collection('users')
          .doc(userDoc)
          .collection('userStats')
          .doc('stats')
          .update({
            'pomodorosCompleted': pomodoroCount,
            'totalFocusTimeMinutes': totalFocusTime,
            'streakDays': streakDays,
            'updatedAt': DateTime.now(),
          });
    } catch (e) {
      debugPrint('Error updating pomodoro stats: $e');
      rethrow;
    }
  }

  // Load achievements from Firebase
  Future<List<Achievement>> loadAchievements() async {
    try {
      await _ensureAuthenticated();

      final userDoc = effectiveUserId;
      if (userDoc == null) throw Exception('No user identifier available');

      final querySnapshot = await _firestore
          .collection('users')
          .doc(userDoc)
          .collection(achievementsCollection)
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      final achievements = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Achievement(
          emoji: data['emoji'] ?? '🏆',
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          timestamp: DateTime.fromMillisecondsSinceEpoch(
            data['timestamp'] ?? 0,
          ),
        );
      }).toList();

      return achievements;
    } catch (e) {
      debugPrint('Error loading achievements: $e');
      return [];
    }
  }

  // Get Firebase sync status
  Map<String, dynamic> getSyncStatus() {
    return {
      'isConnected': userId != null,
      'userId': userId,
      'userEmail': currentUserEmail,
      'lastSyncTime': DateTime.now().toIso8601String(),
      'collections': {
        'userStats': userStatsCollection,
        'achievements': achievementsCollection,
        'taskStats': 'taskStats',
        'tasks': tasksCollection,
      },
    };
  }

  Future<Map<String, dynamic>> testFirebaseIntegration() async {
    final results = <String, dynamic>{};

    try {
      await testFirestoreConnection();
      results['connectionTest'] = 'SUCCESS';

      final testStats = {
        'pomodorosCompleted': 999,
        'totalFocusTimeMinutes': 999,
        'streakDays': 999,
        'testTimestamp': DateTime.now().millisecondsSinceEpoch,
      };

      await _ensureAuthenticated();
      final userDoc = effectiveUserId;

      if (userDoc != null) {
        await _firestore
            .collection('users')
            .doc(userDoc)
            .collection('test')
            .doc('stats')
            .set(testStats);
        final loadedStats = await _firestore
            .collection('users')
            .doc(userDoc)
            .collection('test')
            .doc('stats')
            .get();

        results['statsTest'] = loadedStats.exists ? 'SUCCESS' : 'FAILED';
        results['testData'] = loadedStats.data();

        // Clean up test data
        await _firestore
            .collection('users')
            .doc(userDoc)
            .collection('test')
            .doc('stats')
            .delete();
      } else {
        results['statsTest'] = 'SKIPPED - No user identifier available';
      }
    } catch (e) {
      results['error'] = e.toString();
    }

    return results;
  }

  // ========== PROJECT MANAGEMENT ==========

  // Save project to Firebase
  Future<void> saveProject(Project project) async {
    try {
      await _ensureAuthenticated();

      final userDoc = effectiveUserId;
      if (userDoc == null) throw Exception('No user identifier available');

      // project model
      final projectData = project.toJson();

      await _firestore
          .collection('users')
          .doc(userDoc)
          .collection(projectsCollection)
          .doc(project.id)
          .set(projectData);
    } catch (e) {
      debugPrint('Error saving project: $e');
      rethrow;
    }
  }

  // Load projects from Firebase
  Future<List<Project>> loadProjects() async {
    try {
      await _ensureAuthenticated();

      final userDoc = effectiveUserId;
      if (userDoc == null) throw Exception('No user identifier available');

      final querySnapshot = await _firestore
          .collection('users')
          .doc(userDoc)
          .collection(projectsCollection)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();

        return Project.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('Error loading projects: $e');
      return [];
    }
  }

  // Load all data for users
  Future<Map<String, dynamic>> loadGmailUserData(String email) async {
    try {
      // Load user document
      final userDoc = await _firestore.collection('users').doc(email).get();

      Map<String, dynamic>? userData;
      if (userDoc.exists) {
        userData = userDoc.data();
      }

      // Load tasks
      final tasksSnapshot = await _firestore
          .collection('users')
          .doc(email)
          .collection(tasksCollection)
          .orderBy('createdAt', descending: false)
          .get();

      List<Map<String, dynamic>> tasks = tasksSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Load user stats
      final statsDoc = await _firestore
          .collection('users')
          .doc(email)
          .collection(userStatsCollection)
          .doc('stats')
          .get();

      Map<String, dynamic>? userStats;
      if (statsDoc.exists) {
        userStats = statsDoc.data();
      }

      // Load achievements
      final achievementsSnapshot = await _firestore
          .collection('users')
          .doc(email)
          .collection(achievementsCollection)
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      List<Map<String, dynamic>> achievements = achievementsSnapshot.docs.map((
        doc,
      ) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Load projects
      final projectsSnapshot = await _firestore
          .collection('users')
          .doc(email)
          .collection(projectsCollection)
          .get();

      List<Map<String, dynamic>> projects = projectsSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      return {
        'tasks': tasks,
        'userStats': userStats,
        'achievements': achievements,
        'projects': projects,
        'userData': userData,
        'email': email,
      };
    } catch (e) {
      debugPrint('Error loading Gmail user data: $e');
      rethrow;
    }
  }

  // Update user profile information
  Future<void> updateUserProfile(
    String email, {
    String? name,
    String? username,
    String? gender,
  }) async {
    try {
      final userDoc = _firestore.collection('users').doc(email);

      Map<String, dynamic> updateData = {
        'lastUpdatedAt': DateTime.now(),
      };

      if (name != null) updateData['name'] = name;
      if (username != null) updateData['username'] = username;
      if (gender != null) updateData['gender'] = gender;

      await userDoc.update(updateData);
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      rethrow;
    }
  }
}
