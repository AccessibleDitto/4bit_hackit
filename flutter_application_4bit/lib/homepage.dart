import 'package:just_audio/just_audio.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

// Import the modular files
import 'models/timer_models.dart';
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
  OverlayEntry? _topNotificationEntry;
  late VoidCallback _settingsListener;

  Timer? _timer;
  int get _focusSeconds => PomodoroSettings.instance.pomodoroLength * 60;
  int get _breakSeconds => PomodoroSettings.instance.shortBreakLength * 60;
  // for testing, set focusSecond and breakSecond to 5sec
  // int _focusSeconds = 5;
  // int _breakSeconds = 5;
  int _currentSeconds = PomodoroSettings.instance.pomodoroLength * 60;
  TimerState _timerState = TimerState.idle;
  int _currentSession = 0;
  int _totalSessions = 2;
  bool _isBreakTime = false;
  bool _isStrictMode = false;
  bool _isTimerMode = true;
  bool _isCountdownMode = true;
  String _timerModeValue = '${PomodoroSettings.instance.pomodoroLength.toString().padLeft(2, '0')}:00 → 00:00';
  bool _isAmbientMusic = false;
  String _selectedAmbientMusic = 'None';
  String _selectedTask = 'Select Task';

  late ConfettiController _confettiController;
  late AnimationController _progressAnimationController;
  late Animation<double> _progressAnimation;
  int _selectedIndex = 0;

  final UserStats _userStats = UserStats();

  final List<Task> _tasks = TimerUtils.getDefaultTasks();

  void _showTaskSelectionModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return TaskSelectionModal(
          tasks: _tasks,
          onTaskSelected: (task) {
            setState(() {
              _selectedTask = task.title;
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

  void _startFocusTimer() {
    setState(() {
      _timerState = TimerState.focusRunning;
      _isBreakTime = false;
      _currentSession = _currentSession == 0 ? 1 : _currentSession;
      _currentSeconds = _isCountdownMode ? _focusSeconds : 0;
    });
    _updateProgressAnimation();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_isCountdownMode) {
          // Countdown mode: decrease from focusSeconds to 0
          if (_currentSeconds > 0) {
            _currentSeconds--;
            _updateProgressAnimation();
          } else {
            _completeFocusSession();
          }
        } else {
          // Count-up mode: increase from 0 indefinitely
          _currentSeconds++;
          _updateProgressAnimation();
        }
      });
    });
  }

  void _startBreakTimer() {
    // If Disable Break is enabled, skip break entirely
    if (PomodoroSettings.instance.disableBreak == true) {
      _skipBreak();
      return;
    }
    setState(() {
      _timerState = TimerState.breakRunning;
      _isBreakTime = true;
      _currentSeconds = _breakSeconds;
    });
    _updateProgressAnimation();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_currentSeconds > 0) {
          _currentSeconds--;
          _updateProgressAnimation();
        } else {
          _completeBreakSession();
        }
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      if (_timerState == TimerState.focusRunning) {
        _timerState = TimerState.focusPaused;
      }
    });
  }

  void _continueTimer() {
    if (_timerState == TimerState.focusPaused) {
      setState(() {
        _timerState = TimerState.focusRunning;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_isCountdownMode) {
            // Countdown mode: decrease from current to 0
            if (_currentSeconds > 0) {
              _currentSeconds--;
              _updateProgressAnimation();
            } else {
              _completeFocusSession();
            }
          } else {
            // Count-up mode: increase from current indefinitely
            _currentSeconds++;
            _updateProgressAnimation();
          }
        });
      });
    }
  }

  void _completeFocusSession() {
    _confettiController.play();
    _timer?.cancel();
    // Track the completed pomodoro
    _userStats.completedPomodoro(durationMinutes: _focusSeconds ~/ 60);

    if (_currentSession >= _totalSessions) {
      // All sessions completed
      debugPrint('All Pomodoro sessions completed!');
      setState(() {
        _timerState = TimerState.completed;
      });
    } else {
      // Handle break logic based on settings
      if (PomodoroSettings.instance.disableBreak == true) {
        // If break is disabled, skip break and go to next pomodoro or idle
        _skipBreak();
      } else if (PomodoroSettings.instance.autoStartBreak == true) {
        // Auto start break
        _startBreakTimer();
      } else {
        // Wait for user to start break
        setState(() {
          _timerState = TimerState.breakIdle;
          _isBreakTime = true;
          _currentSeconds = _breakSeconds;
        });
      }
    }
  }

  void _completeBreakSession() {
    _timer?.cancel();
    _currentSession++;

    if (PomodoroSettings.instance.autoStartNextPomodoro == true && _currentSession <= _totalSessions) {
      // Auto start next pomodoro
      _startFocusTimer();
    } else {
      setState(() {
        _timerState = TimerState.idle;
        _isBreakTime = false;
        _currentSeconds = _focusSeconds;
      });
    }
  }

  void _skipBreak() {
    _timer?.cancel();
    _currentSession++;
    
    if (_currentSession > _totalSessions) {
      setState(() {
        _timerState = TimerState.completed;
      });
    } else {
      setState(() {
        _timerState = TimerState.idle;
        _isBreakTime = false;
        _currentSeconds = _focusSeconds;
      });
    }
  }

  void _resetToHome() {
    _timer?.cancel();
    setState(() {
      _timerState = TimerState.idle;
      _currentSession = 0;
      _currentSeconds = _isCountdownMode ? _focusSeconds : 0;
      _isBreakTime = false;
      _selectedTask = 'Select Task';
    });
    _progressAnimationController.reset();
  }

  double _getProgress() {
    if (_timerState == TimerState.idle || _timerState == TimerState.completed) return 0.0;
    
    if (_isBreakTime) {
      return (_breakSeconds - _currentSeconds) / _breakSeconds;
    } else {
      if (_isCountdownMode) {
        return (_focusSeconds - _currentSeconds) / _focusSeconds;
      } else {
        // For count-up mode, show a circular progress that does not complete
        return (_currentSeconds % 60) / 60.0;
      }
    }
  }

  void _updateProgressAnimation() {
    double targetProgress = _getProgress();
    _progressAnimation = Tween<double>(
      begin: _progressAnimation.value,
      end: targetProgress,
    ).animate(CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.linear,
    ));
    _progressAnimationController.reset();
    _progressAnimationController.forward();
  }

  void _showModeModal(String title, String description, bool currentValue, Function(bool) onChanged) {
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

  Future<void> _loadTimerModeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    int pomodoroLength = prefs.getInt('pomodoroLength') ?? PomodoroSettings.instance.pomodoroLength;
    String defaultMode = '${pomodoroLength.toString().padLeft(2, '0')}:00 → 00:00';
    String savedMode = prefs.getString('timerMode') ?? defaultMode;
    setState(() {
      _timerModeValue = savedMode;
      _isCountdownMode = (savedMode == defaultMode);
    });
  }

  void _onTimerModeChanged(bool isCountdown) {
    setState(() {
      _isCountdownMode = isCountdown;
      _timerModeValue = isCountdown
          ? '${PomodoroSettings.instance.pomodoroLength.toString().padLeft(2, '0')}:00 → 00:00'
          : '00:00 → ∞';
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('timerMode', _timerModeValue);
      });
      // Reset timer when mode changes
      if (_timerState == TimerState.focusRunning || _timerState == TimerState.focusPaused) {
        _timer?.cancel();
        _currentSeconds = isCountdown ? _focusSeconds : 0;
        _timerState = TimerState.idle;
        _progressAnimationController.reset();
      }
    });
  }

  void _showTopNotification(String message, {Color backgroundColor = Colors.black87}) {
    _topNotificationEntry?.remove();
    _topNotificationEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 56,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_topNotificationEntry!);
    Future.delayed(const Duration(seconds: 5), () {
      _topNotificationEntry?.remove();
      _topNotificationEntry = null;
    });
  }

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.linear,
    ));

  _audioPlayer = AudioPlayer();

    _settingsListener = () {
      setState(() {});
    };
    PomodoroSettings.instance.addListener(_settingsListener);
    _loadTimerModeFromPrefs();
  }

  @override
  void dispose() {
    PomodoroSettings.instance.removeListener(_settingsListener);
    _timer?.cancel();
    _confettiController.dispose();
    _progressAnimationController.dispose();
  _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_timerState == TimerState.completed) {
      return CongratulationsScreen(
        selectedTask: _selectedTask,
        totalSessions: _totalSessions,
        confettiController: _confettiController,
        onViewReport: () {
          // View Report functionality
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
                      selectedTask: _selectedTask,
                      timerState: _timerState,
                      onBackPressed: () {
                        if (!_isStrictMode) {
                          Navigator.pop(context);
                        }
                      },
                      onResetToHome: _resetToHome,
                      onSettingsPressed: () {
                        // Settings functionality
                      },
                    ),
                    // Task Selection Dropdown (only show when idle)
                    if (_timerState == TimerState.idle)
                      TaskSelector(
                        selectedTask: _selectedTask,
                        onTap: _showTaskSelectionModal,
                      ),
                    // Main Timer Section
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Always show session indicator when a task is selected
                          if (_selectedTask != 'Select Task')
                            SessionIndicator(
                              currentSession: _currentSession,
                              totalSessions: _totalSessions,
                            ),
                          // Timer Circle
                          TimerCircle(
                            currentSeconds: _currentSeconds,
                            timerState: _timerState,
                            isBreakTime: _isBreakTime,
                            focusSeconds: _focusSeconds,
                            breakSeconds: _breakSeconds,
                            progressAnimation: _progressAnimation,
                          ),
                          const SizedBox(height: 40),
                          // Action Buttons
                          TimerActionButtons(
                            timerState: _timerState,
                            selectedTask: _selectedTask,
                            onStartFocus: _startFocusTimer,
                            onPause: _pauseTimer,
                            onContinue: _continueTimer,
                            onStartBreak: _startBreakTimer,
                            onSkipBreak: _skipBreak,
                            onReset: _resetToHome,
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