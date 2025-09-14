import 'dart:async';
import '../pomodoro_preferences.dart';
import '../tasks_updated.dart';
enum GlobalTimerState { idle, running, paused, completed }

class GlobalTimerService {
  // Helper to get current focus minutes from PomodoroSettings
  int get _focusMinutes => PomodoroSettings.instance.pomodoroLength;

  // Call this to refresh session info if pomodoro length changes
  void refreshSessionInfo({double? estimatedHours, double? timeSpentHours}) {
    final estHours = estimatedHours ?? 0.0;
    final spentHours = timeSpentHours ?? 0.0;
    _totalSessions = (estHours * 60 / _focusMinutes).ceil();
    int completedSessions = (spentHours * 60 / _focusMinutes).floor();
    _currentSession = completedSessions + 1;
    if (_currentSession > _totalSessions) {
      _currentSession = _totalSessions;
    }
  }
  static final GlobalTimerService _instance = GlobalTimerService._internal();
  factory GlobalTimerService() => _instance;
  GlobalTimerService._internal();

  Timer? _timer;
  int _currentSeconds = 0;
  int _targetSeconds = 0;
  GlobalTimerState _state = GlobalTimerState.idle;
  bool _isCountdown = true;
  Function()? onTick;
  Function()? onComplete;
  // Session tracking
  int _currentSession = 0;
  int _totalSessions = 0;
  String _selectedTask = 'Select Task';
  int _pausedSeconds = 0; // Track paused time for resume functionality

  int get currentSeconds => _currentSeconds;
  int get targetSeconds => _targetSeconds;
  GlobalTimerState get state => _state;
  bool get isCountdown => _isCountdown;
  int get currentSession => _currentSession;
  int get totalSessions => _totalSessions;
  String get selectedTask => _selectedTask;

  void setState(GlobalTimerState newState) {
    _state = newState;
  }

  void setTaskInfo(String taskName, double estimatedHours, double timeSpentHours) {
    _selectedTask = taskName;
    refreshSessionInfo(estimatedHours: estimatedHours, timeSpentHours: timeSpentHours);
  }

  void updateTaskTimeSpent(double newTimeSpentHours, double estimatedHours) {
    refreshSessionInfo(estimatedHours: estimatedHours, timeSpentHours: newTimeSpentHours);
  }

  void nextSession() {
    if (_currentSession < _totalSessions) {
      _currentSession++;
    }
  }

  void resetSession() {
    _currentSession = 1;
  }

  void start({required int targetSeconds, bool isCountdown = true}) {
    _targetSeconds = targetSeconds;
    _isCountdown = isCountdown;
    _currentSeconds = isCountdown ? targetSeconds : 0;
    _state = GlobalTimerState.running;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_state != GlobalTimerState.running) return;
      if (_isCountdown) {
        if (_currentSeconds > 0) {
          _currentSeconds--;
          onTick?.call();
        } else {
          _state = GlobalTimerState.completed;
          _timer?.cancel();
          onComplete?.call();
        }
      } else {
        _currentSeconds++;
        onTick?.call();
        if (_currentSeconds >= _targetSeconds) {
          _state = GlobalTimerState.completed;
          _timer?.cancel();
          onComplete?.call();
        }
      }
    });
  }

  void pause() {
    if (_state == GlobalTimerState.running) {
      _state = GlobalTimerState.paused;
      _pausedSeconds = _currentSeconds; // Store current time for resume

      _timer?.cancel();
      onTick?.call(); // Trigger UI update
    }
  }

  void resume() {
    if (_state == GlobalTimerState.paused) {
      _state = GlobalTimerState.running;
      _currentSeconds = _pausedSeconds; // Restore paused time
      start(targetSeconds: _isCountdown ? _currentSeconds : _targetSeconds, isCountdown: _isCountdown);
    }
  }

  void stop() {
    _state = GlobalTimerState.idle;
    _timer?.cancel();
    _currentSeconds = 0;
    _pausedSeconds = 0;
    _currentSession = 0;
    _totalSessions = 0;
    _selectedTask = 'Select Task';
  }
}
