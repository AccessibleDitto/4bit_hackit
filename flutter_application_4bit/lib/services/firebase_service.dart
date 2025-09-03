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

  Future<void> clearAuthState() async {
    try {
      // Sign out from Firebase Auth if there's an active session
      if (_auth.currentUser != null) {
        await _auth.signOut();
        debugPrint('Cleared Firebase Auth state');
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
      
      debugPrint('Retrieved ${users.length} users from Firestore');
      return users;
      
    } catch (e) {
      debugPrint('Error retrieving users: $e');
      rethrow;
    }
  }

  Future<UserCredential?> signUpWithEmailPassword(String email, String password) async {
    try {
      debugPrint('Attempting to create user with email: $email');
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      ).timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw FirebaseAuthException(
            code: 'timeout',
            message: 'Request timed out. Please try again.',
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
      final currentUserId = userId;
      final userEmail = currentUserEmail;
      
      if (currentUserId == null && userEmail == null) {
        throw Exception('No authenticated user found. Please sign in again.');
      }
      // For Firebase Auth users
      if (currentUserId != null) {
        debugPrint('Deleting Firebase Auth user data for UID: $currentUserId');
        await _deleteUserData(currentUserId);
        // Delete the Firebase Auth user account
        await _auth.currentUser?.delete();
      } 
      // Fallback 
      else if (userEmail != null) {
        debugPrint('Deleting user data for email: $userEmail');
        await _deleteUserData(userEmail);
      }
      
    } catch (e) {
      debugPrint('Error deleting account: $e');
      rethrow;
    }
  }

  Future<void> deleteGmailBasedAccount(String email) async {
    try {
      debugPrint('Deleting Gmail-based account for email: $email');
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
      batch.delete(_firestore.collection('users').doc(documentId).collection(userStatsCollection).doc('stats'));
      
      // Delete tasks
      QuerySnapshot tasksSnapshot = await _firestore.collection('users').doc(documentId).collection(tasksCollection).get();
      for (DocumentSnapshot doc in tasksSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete achievements
      QuerySnapshot achievementsSnapshot = await _firestore.collection('users').doc(documentId).collection(achievementsCollection).get();
      for (DocumentSnapshot doc in achievementsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete projects
      QuerySnapshot projectsSnapshot = await _firestore.collection('users').doc(documentId).collection(projectsCollection).get();
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

  
  // Load all data for users
  Future<Map<String, dynamic>> loadGmailUserData(String email) async {
    try {
      // Load user document
      final userDoc = await _firestore
          .collection('users')
          .doc(email)
          .get();

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

      List<Map<String, dynamic>> achievements = achievementsSnapshot.docs.map((doc) {
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

      debugPrint('Successfully loaded data for Gmail user: $email');
      debugPrint('- Tasks: ${tasks.length}');
      debugPrint('- Achievements: ${achievements.length}');
      debugPrint('- Projects: ${projects.length}');
      debugPrint('- User Stats: ${userStats != null ? "Found" : "Not found"}');
      debugPrint('- User Data: ${userData != null ? "Found" : "Not found"}');

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
  Future<void> updateUserProfile(String email, {
    String? name,
    String? username,
    String? gender,
  }) async {
    try {
      debugPrint('Updating user profile for: $email');
      
      final userDoc = _firestore.collection('users').doc(email);
      
      // Build update data map
      Map<String, dynamic> updateData = {
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      };
      
      if (name != null) {
        updateData['name'] = name;
      }
      
      if (username != null) {
        updateData['username'] = username;
      }
      
      if (gender != null) {
        updateData['gender'] = gender;
      }
      
      // Update the user document
      await userDoc.update(updateData);
      
      debugPrint('Successfully updated user profile for: $email');
      debugPrint('Updated fields: ${updateData.keys.join(', ')}');
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      rethrow;
    }
  }
}