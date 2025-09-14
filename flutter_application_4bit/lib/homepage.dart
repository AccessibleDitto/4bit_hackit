import 'package:flutter_application_4bit/tasks_updated.dart';
import 'package:just_audio/just_audio.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

//imports for NFC and App Limiter
import 'dart:async';
import 'dart:developer';
import 'package:app_limiter/app_limiter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';


// Import the modular files
import 'models/timer_models.dart';
import 'tasks_updated.dart' as TaskData show getTasksList, updateTaskTimeSpent, startTask, completeTask;
import 'models/task_models.dart' show TaskStatus;
import 'services/global_timer_service.dart';
import 'services/user_stats_service.dart';
import 'utils/timer_utils.dart';
import 'widgets/app_bar_widgets.dart';
import 'widgets/task_widgets.dart';
import 'widgets/timer_display_widgets.dart';
import 'widgets/timer_control_widgets.dart';
import 'widgets/mode_settings_widgets.dart';
import 'widgets/navigation_widgets.dart';
import 'widgets/congratulations_widgets.dart';
import 'pomodoro_preferences.dart';

class TimerModePage extends StatefulWidget {
  const TimerModePage({super.key});

  @override
  State<TimerModePage> createState() => _TimerModePageState();
}

class _TimerModePageState extends State<TimerModePage> with TickerProviderStateMixin {
  late AudioPlayer _audioPlayer;
  late VoidCallback _settingsListener;
  late VoidCallback _timerModeListener;
  String _platformVersion = 'Unknown';
  final _appLimiterPlugin = AppLimiter();
  String _nfcStatus = 'NFC Status: Unknown';
  String _readData = 'No data read yet';
  bool _isReading = false;
  bool _isNFCAvailable = false;
  bool _isLocked = false;

  final GlobalTimerService _globalTimer = GlobalTimerService();

  int get _focusSeconds => PomodoroSettings.instance.pomodoroLength * 60;
  int get _breakSeconds => PomodoroSettings.instance.shortBreakLength * 60;
  bool _isBreakTime = false;
  bool _isStrictMode = false;
  final bool _isTimerMode = true;
  bool _isCountdownMode = true;  // Will be initialized from settings
  String _timerModeValue = '';
  bool _isAmbientMusic = false;
  String _selectedAmbientMusic = 'None';

  late ConfettiController _confettiController;
  late AnimationController _progressAnimationController;
  final ValueNotifier<double> _progressNotifier = ValueNotifier<double>(0.0);
  final int _selectedIndex = 0;

  dynamic _currentFullTask; // Track the currently selected full task with timeSpent

  final TextEditingController _writeController = TextEditingController();
  Future<void> _checkCurrentState() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isLocked = prefs.getBool('locked');
    setState(() {
      _isLocked = isLocked ?? false;
    });
  }
  // App blocker
  Future<void> initPlatformState() async {
    String platformVersion;
    try {
      platformVersion =
          await _appLimiterPlugin.getPlatformVersion() ??
          'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }
  Future<bool> checkAndroidPermission() async {
    try {
      final result = await _appLimiterPlugin.isAndroidPermissionAllowed();
      log(result.toString(), name: 'Permission Status');
      return result;
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }
  Future<void> requestAndroidPermission() async {
    try {
      await _appLimiterPlugin.requestAndroidPermission();
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }

  Future<void> blockAndroidApps() async {
    try {
      if (_isLocked) {
        debugPrint("Apps are already blocked");
        return;
      }
      await _appLimiterPlugin.blocAndroidApp();
      setState(() {
        _isLocked = true;
      });
    
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }

  Future<void> unBlockAndroidApps() async {
    try {
      if (!_isLocked) {
        debugPrint("Apps are already unblocked");
        return;
      }
      await _appLimiterPlugin.unblocAndroidApp();
      setState(() {
        _isLocked = false;
      });
    
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }

  //nfc
  Future<void> _checkNFCAvailability() async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    
    setState(() {
      _isNFCAvailable = isAvailable;
      _nfcStatus = isAvailable ? 'NFC Status: Available' : 'NFC Status: Not Available';
    });
  }
  Future<void> _startReading(context) async {

    if (!_isNFCAvailable) {
      debugPrint("NFC is not available on this device");
      return;
    }

    setState(() {
      _isReading = true;
      _readData = 'Waiting for NFC tag...';
    });

    try {
      NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
        try {
          // Try to read NDEF data
          var ndef = Ndef.from(tag);
          if (ndef == null) {
            if (mounted) {
              setState(() {
                _readData = 'Tag is not NDEF formatted or not readable';
                _isReading = false;
              });
            }
            return;
          }

          NdefMessage? ndefMessage = await ndef.read();

          String data = '';
          for (NdefRecord record in ndefMessage.records) {
            if (record.typeNameFormat == NdefTypeNameFormat.nfcWellknown) {
              if (record.type.length == 1 && record.type[0] == 0x54) {
                // Text Record
                List<int> payload = record.payload;
                if (payload.isNotEmpty) {
                  int languageLength = payload[0] & 0x3F;
                  String text = String.fromCharCodes(payload.sublist(1 + languageLength));
                  data += text;
                }
              } else if (record.type.length == 1 && record.type[0] == 0x55) {
                // URI Record
                List<int> payload = record.payload;
                if (payload.isNotEmpty) {
                  String uri = String.fromCharCodes(payload.sublist(1));
                  data += uri;
                }
              }
            }
          }

          if (mounted) {
            setState(() {
              _readData = data.isNotEmpty ? data : 'No readable text data found';
              _isReading = false;
            });
          }

          NfcManager.instance.stopSession();

          // Check if the NFC tag contains "lock" command
          debugPrint("Read data: $_readData");
          if (data == "lock") {
            debugPrint("Locking/Unlocking apps");
            if (!_isLocked) {
              await blockAndroidApps();
              Navigator.pop(context); // Close the modal
            } else {
              await unBlockAndroidApps();
              Navigator.pop(context); // Close the modal
            }
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _readData = 'Error reading tag: $e';
              _isReading = false;
            });
          }
          NfcManager.instance.stopSession(errorMessage: 'Error reading tag');
        }
      });
    } catch (e) {
      setState(() {
        _readData = 'Error starting NFC session: $e';
        _isReading = false;
      });
    }
  }


  void _showTaskSelectionModal() {
    // Filter out completed tasks
    final fullTasks = TaskData.getTasksList();
    const colorOrder = [
      Color(0xFF9333EA),
      Color(0xFF10B981),
      Color(0xFF3B82F6),
      Color(0xFFEF4444),
      Color(0xFFF59E0B),
    ];

    // Map fullTasks to TimerModels.Task for dropdown - only show incomplete tasks
    final pomodoroLength = PomodoroSettings.instance.pomodoroLength;
    final incompleteTasks = fullTasks
      .where((t) => t.status != TaskStatus.completed && t.status != TaskStatus.cancelled)
      .toList();
    final dropdownTasks = incompleteTasks.asMap().map((index, t) => MapEntry(index, Task(
      title: t.title,
      color: colorOrder[index % colorOrder.length],
      estimatedTime: t.estimatedTime,
      timeSpent: t.timeSpent,
      focusMinutes: pomodoroLength,
    ))).values.toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return TaskSelectionModal(
          tasks: dropdownTasks,
          onTaskSelected: (task) {
            // Find the corresponding full task from fullTasks
            final fullTask = fullTasks.firstWhere(
              (t) => t.title == task.title,
              orElse: () => fullTasks.first, // Fallback to first task if not found
            );
            setState(() {
              _currentFullTask = fullTask;
              // Start the task if it's not started yet
              if (fullTask.status == TaskStatus.notStarted) {
                TaskData.startTask(fullTask.id);
              }
              // Set global timer task info for session tracking with time spent
              _globalTimer.setTaskInfo(task.title, task.estimatedTime, fullTask.timeSpent);
              // Initialize timer based on task's previously spent time
              _initializeTimerForTask(fullTask);
            });
          },
          onAddNewTask: () {
            // Add new task functionality
            HapticFeedback.lightImpact();
          },
        );
      },
    );
  }

  // Initialize timer based on task's timeSpent
  void _initializeTimerForTask(dynamic task) {
    int pomodoroLength = PomodoroSettings.instance.pomodoroLength;
    int focusSeconds = pomodoroLength * 60;
    int timeSpentSeconds = (task.timeSpent * 3600).round(); // Convert hours to seconds
    int estimatedTimeSeconds = (task.estimatedTime * 3600).round(); // Convert hours to seconds
    int remainingTimeSeconds = (estimatedTimeSeconds - timeSpentSeconds).clamp(0, estimatedTimeSeconds);

    setState(() {
      if (_isCountdownMode) {
        // Each session limited to focus time duration
        int sessionDuration = remainingTimeSeconds.clamp(0, focusSeconds);
        _globalTimer.start(targetSeconds: sessionDuration, isCountdown: true);
      } else {
        // In count-up mode, start from 0 and limit to focus time duration
        _globalTimer.start(targetSeconds: focusSeconds, isCountdown: false);
      }
    });
  }

  void _startFocusTimer() {
    int pomodoroLength = PomodoroSettings.instance.pomodoroLength;
    int focusSeconds = pomodoroLength * 60;
    if (_currentFullTask != null) {
      // Use task-based timing with remaining time
      int timeSpentSeconds = (_currentFullTask.timeSpent * 3600).round();
      int estimatedTimeSeconds = (_currentFullTask.estimatedTime * 3600).round();
      int remainingTimeSeconds = (estimatedTimeSeconds - timeSpentSeconds).clamp(0, estimatedTimeSeconds);
      // Each session should not exceed focus time duration
      int timerDuration = _isCountdownMode ? 
        remainingTimeSeconds.clamp(0, focusSeconds) : 
        focusSeconds;
      _globalTimer.start(targetSeconds: timerDuration, isCountdown: _isCountdownMode);
    } else {
      // Default focus timer
      _globalTimer.start(targetSeconds: focusSeconds, isCountdown: true);
    }
    _updateProgressAnimation();
  }

  void _startBreakTimer() {
    // If Disable Break is enabled, skip break entirely
    if (PomodoroSettings.instance.disableBreak == true) {
      _skipBreak();
      return;
    }
    setState(() {
      _isBreakTime = true;
      _globalTimer.start(targetSeconds: _breakSeconds, isCountdown: true);
    });
    _updateProgressAnimation();
  }

  void _skipBreak() {
    int pomodoroLength = PomodoroSettings.instance.pomodoroLength;
    int focusSeconds = pomodoroLength * 60;
    setState(() {
      _isBreakTime = false;
      _globalTimer.start(targetSeconds: focusSeconds, isCountdown: true);
    });
  }

  void _resetToHome() {
    // Save the current session's progress if we have a task selected and timer was running or paused
    if (_currentFullTask != null && (_globalTimer.state == GlobalTimerState.running || _globalTimer.state == GlobalTimerState.paused)) {
      double additionalTimeSpentHours = 0.0;
      if (_isCountdownMode) {
        // In countdown mode, calculate time spent in current session
        int sessionStartSeconds = _globalTimer.targetSeconds;
        additionalTimeSpentHours = (sessionStartSeconds - _globalTimer.currentSeconds) / 3600.0;
      } else {
        // In count-up mode, use the current seconds as time spent
        additionalTimeSpentHours = _globalTimer.currentSeconds / 3600.0;
      }
      if (additionalTimeSpentHours > 0) {
  TaskData.updateTaskTimeSpent(_currentFullTask.id, additionalTimeSpentHours);
      }
    }
    // Reset session tracking
    _currentFullTask = null;
    _globalTimer.stop();
    setState(() {
      _isBreakTime = false;
    });
  }

  void _checkAndShowBadgePopup() {
    final userStats = UserStats();
    final recentAchievements = userStats.recentAchievements;
    
    if (recentAchievements.isNotEmpty) {
      final latestAchievement = recentAchievements.first;
      
      final now = DateTime.now();
      final achievementTime = latestAchievement.timestamp;
      final timeDifference = now.difference(achievementTime).inSeconds;
      
      if (timeDifference <= 5) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _showBadgeEarnedDialog(latestAchievement);
          }
        });
      }
    }
  }

  void _showBadgeEarnedDialog(Achievement achievement) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BadgeEarnedDialog(
        achievement: achievement,
        onDismiss: () {
          Navigator.of(context).pop();
        },
        onViewProfile: () {
          Navigator.of(context).pop();
          Navigator.pushNamed(context, '/profile');
        },
      ),
    );
  }

  double _getProgress() {
    if (_globalTimer.state == GlobalTimerState.idle || _globalTimer.state == GlobalTimerState.completed) return 0.0;
    
    if (_isBreakTime) {
      if (_breakSeconds == 0) return 0.0;
      return (_breakSeconds - _globalTimer.currentSeconds) / _breakSeconds;
    } else {
      if (_isCountdownMode) {
        // Show progress based on how much time has elapsed from the original focus time
        if (_globalTimer.targetSeconds == 0) return 0.0;
        double elapsed = (_focusSeconds - _globalTimer.currentSeconds).toDouble();
        return elapsed / _focusSeconds;
      } else {
        // For count-up mode, show progress based on current seconds vs focus time
        if (_focusSeconds == 0) return 0.0;
        return _globalTimer.currentSeconds / _focusSeconds;
      }
    }
  }

  void _updateProgressAnimation() {
    double currentProgress = _getProgress();
    _progressNotifier.value = currentProgress;
  }

  void _showModeModal(String title, String description, bool currentValue, Function(bool) onChanged) {
    if (title  == 'Strict Mode Settings') {
      if(checkAndroidPermission() == false){
        showModalBottomSheet(context: context, builder: (context) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text("Permissions not Granted", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text("Enable Usage Stats and Overlay Access to use Strict Mode."),
            const SizedBox(height: 24),
            ],
          ),
        ));
      }
      else{
        _startReading(context);
        var mode = _isLocked ? "Disable" : "Enable";
        showModalBottomSheet(context: context, builder: (context) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text("$mode Strict Mode", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text("Scan your NFC tag to $mode strict mode."),
            const SizedBox(height: 24),
            ],
          ),
        ));
      }


    }
    else{
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text(description),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                onChanged(!currentValue);
                Navigator.pop(context);
              },
              child: Text(currentValue ? 'Disable $title' : 'Enable $title'),
            ),
          ],
        ),
      ),
    );
    }
  }

  Future<void> _loadTimerModeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    // Try to load timer mode as a boolean first
    bool? savedCountdownMode = prefs.getBool('isCountdownMode');
    if (savedCountdownMode != null) {
      setState(() {
        _isCountdownMode = savedCountdownMode;
        _timerModeValue = _isCountdownMode ?
            '${PomodoroSettings.instance.pomodoroLength.toString().padLeft(2, '0')}:00 → 00:00' :
            '00:00 → ∞';
      });
    } else {
      // Fallback to string comparison for legacy support
      String defaultMode = '${PomodoroSettings.instance.pomodoroLength.toString().padLeft(2, '0')}:00 → 00:00';
      String savedMode = prefs.getString('timerMode') ?? defaultMode;
      setState(() {
        _isCountdownMode = savedMode == defaultMode;
        _timerModeValue = _isCountdownMode ?
            '${PomodoroSettings.instance.pomodoroLength.toString().padLeft(2, '0')}:00 → 00:00' :
            '00:00 → ∞';
      });
    }
  }

  void _onTimerModeChanged(bool isCountdown) {
    setState(() {
      // Save the current progress before switching modes
      double additionalTimeSpentHours = 0.0;
      if (_currentFullTask != null && _globalTimer.state != GlobalTimerState.idle) {
        if (_isCountdownMode) {
          // In countdown mode, calculate time spent from when timer started
          int originalTargetSeconds = _globalTimer.targetSeconds;
          int timeElapsedSeconds = originalTargetSeconds - _globalTimer.currentSeconds;
          additionalTimeSpentHours = timeElapsedSeconds / 3600.0;
        } else {
          // In count-up mode, use the current seconds as time spent
          additionalTimeSpentHours = _globalTimer.currentSeconds / 3600.0;
        }
        
        // Update the task's timeSpent before switching modes
        if (additionalTimeSpentHours > 0) {
          TaskData.updateTaskTimeSpent(_currentFullTask.id, additionalTimeSpentHours);
          // Update the local task object as well
          _currentFullTask.timeSpent += additionalTimeSpentHours;
          // Update the global timer's session information with new timeSpent
          _globalTimer.updateTaskTimeSpent(_currentFullTask.timeSpent, _currentFullTask.estimatedTime);
        }
      }

      _isCountdownMode = isCountdown;
      _timerModeValue = isCountdown
          ? '${PomodoroSettings.instance.pomodoroLength.toString().padLeft(2, '0')}:00 → 00:00'
          : '00:00 → ∞';
      // Save to both SharedPreferences and PomodoroSettings
      PomodoroSettings.instance.isCountdownMode = isCountdown;
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('timerMode', _timerModeValue);
        prefs.setBool('isCountdownMode', isCountdown);
      });

      // Handle timer state changes
      if (_globalTimer.state == GlobalTimerState.running) {
        int pomodoroLength = PomodoroSettings.instance.pomodoroLength;
        int focusSeconds = pomodoroLength * 1;
        _globalTimer.stop();
        if (_currentFullTask != null) {
          if (isCountdown) {
            // Switching to countdown mode - calculate remaining time and limit to focus time duration
            int timeSpentSeconds = (_currentFullTask.timeSpent * 3600).round();
            int estimatedTimeSeconds = (_currentFullTask.estimatedTime * 3600).round();
            int remainingTimeSeconds = (estimatedTimeSeconds - timeSpentSeconds).clamp(0, estimatedTimeSeconds);
            int sessionDuration = remainingTimeSeconds.clamp(0, focusSeconds);
            _globalTimer.start(targetSeconds: sessionDuration, isCountdown: true);
          } else {
            // Switching to countup mode - start from 0 and limit to focus time duration
            _globalTimer.start(targetSeconds: focusSeconds, isCountdown: false);
          }
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _checkNFCAvailability();
    initPlatformState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 950),
      vsync: this,
    );
    _checkCurrentState();

  _audioPlayer = AudioPlayer();

    _settingsListener = () {
      setState(() {});
    };
    _timerModeListener = () {
      setState(() {
        _isCountdownMode = PomodoroSettings.instance.isCountdownMode;
        _timerModeValue = _isCountdownMode
            ? '${PomodoroSettings.instance.pomodoroLength.toString().padLeft(2, '0')}:00 → 00:00'
            : '00:00 → ∞';
      });
    };
    PomodoroSettings.instance.addListener(_settingsListener);
    PomodoroSettings.instance.addListener(_timerModeListener);
    _loadTimerModeFromPrefs();

    _globalTimer.onTick = () {
      setState(() {
        _updateProgressAnimation();
      });
    };
    _globalTimer.onComplete = () {
      setState(() {
        if (!_isBreakTime && _currentFullTask != null) {
          // Check if this was the last session before advancing
          bool isLastSession = _globalTimer.currentSession >= _globalTimer.totalSessions;
          
          // Check if this is the last session for the task
          if (_globalTimer.currentSession >= _globalTimer.totalSessions) {
            // Task completed - mark as completed
            TaskData.completeTask(_currentFullTask.id);
          } else {
            // Focus session completed, advance to next session
            _globalTimer.nextSession();
          
          // Check if all sessions are completed
          if (isLastSession) {
            // All sessions completed - mark task as complete and show congratulations
            // Mark the task as completed (sets timeSpent = estimatedTime and status = completed)
            TaskData.completeTask(_currentFullTask.id);
            _currentFullTask.timeSpent = _currentFullTask.estimatedTime;
            // Call completedTask() for task-related badges when full task is done
            UserStats().completedTask();
            // Check for new task badges after task completion
            Future.delayed(const Duration(milliseconds: 500), () {
              _checkAndShowBadgePopup();
            });
            _globalTimer.setState(GlobalTimerState.completed);
          } else {
            // More sessions remain - reset state to idle for next session
            _globalTimer.setState(GlobalTimerState.idle);
          }
          }
        }
      }); // Update UI when session completes
      
      // Track pomodoro completion for achievements
      if (!_isBreakTime) {
        final pomodoroLength = PomodoroSettings.instance.pomodoroLength.toInt();
        UserStats().completedPomodoro(durationMinutes: pomodoroLength);
        _checkAndShowBadgePopup();
      }
    };
  }

  @override
  void dispose() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setBool('locked', _isLocked);
  PomodoroSettings.instance.removeListener(_settingsListener);
  PomodoroSettings.instance.removeListener(_timerModeListener);
  _confettiController.dispose();
  _writeController.dispose();
  _progressAnimationController.dispose();
  _progressNotifier.dispose();
  _audioPlayer.dispose();
  _globalTimer.onTick = null;
  _globalTimer.onComplete = null;
  super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_globalTimer.state == GlobalTimerState.completed) {
      return CongratulationsScreen(
        selectedTask: _globalTimer.selectedTask,
        totalSessions: _globalTimer.totalSessions,
        confettiController: _confettiController,
        onViewReport: () {
          Navigator.pushNamed(context, '/report');
          HapticFeedback.lightImpact();
        },
        onStartNewSession: _resetToHome,
        onBackToHome: () {
          Navigator.pop(context);
          HapticFeedback.lightImpact();
        },
      );
    }

    return StrictModeController(
      isStrictMode: _isStrictMode,
      onStrictModeChanged: (value) {
        setState(() => _isStrictMode = value);
      },
      strictModeDesc: 'Strict Mode prevents you from navigating away or exiting this page until you disable it. Enable this to avoid distractions during focus sessions.',
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F0F),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F0F0F),
                Color(0xFF1A1A1A),
                Color(0xFF0A0A0A),
              ],
            ),
          ),
          child: Stack(
            children: [
              SafeArea(
                child: Column(
                  children: [
                    // Top App Bar
                    TimerAppBar(
                      selectedTask: _globalTimer.selectedTask,
                      timerState: _isBreakTime ? TimerState.breakRunning :
                                 (_globalTimer.state == GlobalTimerState.running ? TimerState.focusRunning : 
                                 (_globalTimer.state == GlobalTimerState.paused ? TimerState.focusPaused : TimerState.idle)),
                      onBackPressed: () {},
                      onResetToHome: _resetToHome,
                    ),
                    // Task Selection Dropdown (only show when idle)
                    if (_globalTimer.state == GlobalTimerState.idle)
                      TaskSelector(
                        selectedTask: _globalTimer.selectedTask,
                        onTap: _showTaskSelectionModal,
                      ),
                    // Main Timer Section
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Show session indicator only in countdown mode and when a task is selected
                          if (_globalTimer.selectedTask != 'Select Task' && _isCountdownMode)
                            SessionIndicator(
                              currentSession: _globalTimer.currentSession,
                              totalSessions: _globalTimer.totalSessions,
                            ),
                          // Timer Circle - only show in countdown mode
                          if (_isCountdownMode)
                            ValueListenableBuilder<double>(
                              valueListenable: _progressNotifier,
                              builder: (context, progressValue, child) {
                                return TimerCircle(
                                  currentSeconds: _globalTimer.currentSeconds,
                                  timerState: _isBreakTime ? TimerState.breakRunning :
                                             (_globalTimer.state == GlobalTimerState.running ? TimerState.focusRunning : 
                                             (_globalTimer.state == GlobalTimerState.paused ? TimerState.focusPaused : TimerState.idle)),
                                  isBreakTime: _isBreakTime,
                                  focusSeconds: _focusSeconds,
                                  breakSeconds: _breakSeconds,
                                  progressValue: progressValue,
                                  currentSession: _globalTimer.currentSession,
                                  totalSessions: _globalTimer.totalSessions,
                                );
                              },
                            )
                          else
                            // In count-up mode, show timer display without progress circle
                            Container(
                              width: 300,
                              height: 300,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF0F0F0F),
                                border: Border.all(
                                  color: const Color(0xFF27272A),
                                  width: 8,
                                ),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      TimerUtils.formatTime(_globalTimer.currentSeconds),
                                      style: const TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _isBreakTime ? 'Break Time' : 'Count Up Mode',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 40),
                          // Action Buttons
                          TimerActionButtons(
                            timerState: _isBreakTime ? TimerState.breakRunning :
                                       (_globalTimer.state == GlobalTimerState.running ? TimerState.focusRunning : 
                                       (_globalTimer.state == GlobalTimerState.paused ? TimerState.focusPaused : TimerState.idle)),
                            selectedTask: _globalTimer.selectedTask,
                            onStartFocus: _startFocusTimer,
                            onPause: _globalTimer.pause,
                            onContinue: _globalTimer.resume,
                            onReset: _resetToHome,
                            onStartBreak: _startBreakTimer,
                          ),
                        ],
                      ),
                    ),
                    // Mode Selection
                    ModeSelectionBar(
                      isStrictMode: _isStrictMode,
                      isTimerMode: _isTimerMode,
                      isCountdownMode: _isCountdownMode,
                      focusSeconds: _focusSeconds,
                      isAmbientMusic: _isAmbientMusic,
                      selectedAmbientMusic: _selectedAmbientMusic,
                      onStrictModePressed: () => _showModeModal(
                        'Strict Mode Settings',
                        'Strict Mode prevents you from navigating away or exiting this page until you disable it. Enable this to avoid distractions during focus sessions.',
                        _isStrictMode,
                        (value) {
                          setState(() => _isStrictMode = value);
                        },  
                      ),
                      onTimerModePressed: () {
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (context) => TimerModeModal(
                            isCountdownMode: _isCountdownMode,
                            focusSeconds: _focusSeconds,
                            onModeChanged: (bool isCountdown) {
                              _onTimerModeChanged(isCountdown);
                              Navigator.pop(context);
                            },
                          ),
                        );
                      },
                      onCountdownModeChanged: _onTimerModeChanged,
                      onAmbientMusicChanged: (enabled) {
                        setState(() => _isAmbientMusic = enabled);
                      },
                      onAmbientMusicOptionChanged: (sound) {
                        setState(() => _selectedAmbientMusic = sound);
                      },
                    ),
                  ],
                ),
              ),
              // Confetti animation overlay
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  colors: const [
                    Color(0xFF9333EA),
                    Color(0xFF10B981),
                    Color(0xFF3B82F6),
                    Color(0xFFEF4444),
                    Color(0xFFF59E0B),
                  ],
                  emissionFrequency: 0.05,
                  numberOfParticles: 20,
                  maxBlastForce: 20,
                  minBlastForce: 8,
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigation(
          selectedIndex: _selectedIndex,
          isStrictMode: _isStrictMode,
        ),
      ),
    );
  }
}

class BadgeEarnedDialog extends StatefulWidget {
  final Achievement achievement;
  final VoidCallback onDismiss;
  final VoidCallback onViewProfile;

  const BadgeEarnedDialog({
    super.key,
    required this.achievement,
    required this.onDismiss,
    required this.onViewProfile,
  });

  @override
  State<BadgeEarnedDialog> createState() => _BadgeEarnedDialogState();
}

class _BadgeEarnedDialogState extends State<BadgeEarnedDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF9333EA).withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF9333EA).withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Achievement Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF9333EA).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF9333EA).withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          widget.achievement.emoji,
                          style: const TextStyle(fontSize: 40),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // earned text
                    Text(
                      'Achievement Earned!',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF9333EA),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // title
                    Text(
                      widget.achievement.title,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    
                    // acheivement desc
                    Text(
                      widget.achievement.description,
                      style: GoogleFonts.inter(
                        color: const Color(0xFFA1A1AA),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: widget.onDismiss,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFF9333EA)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              'Continue',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: widget.onViewProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF9333EA),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              'View Profile',
                              style: GoogleFonts.inter(
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
          ),
        );
      },
    );
  }
}