import 'package:flutter/material.dart';
import 'dart:async';

void main() {
  runApp(const ChronofyApp());
}

class ChronofyApp extends StatelessWidget {
  const ChronofyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chronofy',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        fontFamily: 'SF Pro Display',
      ),
      home: const ChronofyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

enum TimerState { idle, focusRunning, focusPaused, breakIdle, breakRunning, completed }

class ChronofyHomePage extends StatefulWidget {
  const ChronofyHomePage({super.key});

  @override
  State<ChronofyHomePage> createState() => _ChronofyHomePageState();
}

class _ChronofyHomePageState extends State<ChronofyHomePage> {
  Timer? _timer;
  int _focusSeconds = 25 * 60; // 25 minutes
  int _breakSeconds = 5 * 60; // 5 minutes
  int _currentSeconds = 25 * 60;
  TimerState _timerState = TimerState.idle;
  int _currentSession = 0;
  int _totalSessions = 4;
  bool _isBreakTime = false;
  
  void _showTaskSelectionModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Color(0xFF2A2D3A),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Select Task',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // Add new task functionality
                      },
                      child: const Icon(
                        Icons.add,
                        color: Color(0xFFFF6B47),
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3C4043),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.search,
                        color: Color(0xFF9AA0A6),
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Search task...',
                          style: TextStyle(
                            color: Color(0xFF9AA0A6),
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Today Tasks section
              const Padding(
                padding: EdgeInsets.all(20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Today Tasks',
                    style: TextStyle(
                      color: Color(0xFF9AA0A6),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              // Task list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _tasks.length,
                  itemBuilder: (context, index) {
                    final task = _tasks[index];
                    return _buildTaskItem(task, index);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaskItem(Map<String, dynamic> task, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTask = task['title'];
        });
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF3C4043),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: task['color'],
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // Play button
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: task['color'],
                  width: 2,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Task info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task['title'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: task['color'],
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${task['sessions']}',
                        style: TextStyle(
                          color: task['color'],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.wb_sunny_outlined,
                        color: Color(0xFF9AA0A6),
                        size: 16,
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.flag_outlined,
                        color: Color(0xFF9AA0A6),
                        size: 16,
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.fastfood_outlined,
                        color: Color(0xFF9AA0A6),
                        size: 16,
                      ),
                      const Spacer(),
                      const Text(
                        'Pomodoro App',
                        style: TextStyle(
                          color: Color(0xFF9AA0A6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Play button (right)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: task['color'],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _selectedIndex = 0;
  bool _isStrictMode = false;
  bool _isTimerMode = true;
  bool _isWhiteNoise = false;
  String _selectedTask = 'Select Task';

  final List<Map<String, dynamic>> _tasks = [
    {
      'title': 'Design User Experience (UX)',
      'sessions': 7,
      'color': Color(0xFFFF6B47),
    },
    {
      'title': 'Design User Interface (UI)',
      'sessions': 6,
      'color': Color(0xFF4CAF50),
    },
    {
      'title': 'Create a Design Wireframe',
      'sessions': 4,
      'color': Color(0xFF2196F3),
    },
  ];

  void _startFocusTimer() {
    setState(() {
      _timerState = TimerState.focusRunning;
      _isBreakTime = false;
      _currentSession = _currentSession == 0 ? 1 : _currentSession;
      _currentSeconds = _focusSeconds;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_currentSeconds > 0) {
          _currentSeconds--;
        } else {
          _completeFocusSession();
        }
      });
    });
  }

  void _startBreakTimer() {
    setState(() {
      _timerState = TimerState.breakRunning;
      _isBreakTime = true;
      _currentSeconds = _breakSeconds;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_currentSeconds > 0) {
          _currentSeconds--;
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
          if (_currentSeconds > 0) {
            _currentSeconds--;
          } else {
            _completeFocusSession();
          }
        });
      });
    }
  }

  void _completeFocusSession() {
    _timer?.cancel();
    
    if (_currentSession >= _totalSessions) {
      // All sessions completed
      setState(() {
        _timerState = TimerState.completed;
      });
    } else {
      // Start break
      setState(() {
        _timerState = TimerState.breakIdle;
        _isBreakTime = true;
        _currentSeconds = _breakSeconds;
      });
    }
  }

  void _completeBreakSession() {
    _timer?.cancel();
    _currentSession++;
    
    setState(() {
      _timerState = TimerState.idle;
      _isBreakTime = false;
      _currentSeconds = _focusSeconds;
    });
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
      _currentSeconds = _focusSeconds;
      _isBreakTime = false;
      _selectedTask = 'Select Task';
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  double _getProgress() {
    if (_timerState == TimerState.idle || _timerState == TimerState.completed) return 0.0;
    
    if (_isBreakTime) {
      return (_breakSeconds - _currentSeconds) / _breakSeconds;
    } else {
      return (_focusSeconds - _currentSeconds) / _focusSeconds;
    }
  }

  Color _getProgressColor() {
    if (_isBreakTime) return const Color(0xFFFF6B47);
    return const Color(0xFFFF6B47);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_timerState == TimerState.completed) {
      return _buildCongratulationsScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF2A2D3A),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            _buildAppBar(),
            
            // Task Selection Dropdown (only show when idle)
            if (_timerState == TimerState.idle) _buildTaskSelector(),
            
            // Main Timer Section
            Expanded(
              child: _buildTimerSection(),
            ),
            
            // Mode Selection
            _buildModeSelection(),
            
            // Bottom Navigation
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildCongratulationsScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1D29),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1D29), Color(0xFF2A2D3A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Confetti and Trophy
              Container(
                width: 200,
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Trophy
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.emoji_events,
                        size: 80,
                        color: Color(0xFFFFA000),
                      ),
                    ),
                    
                    // Confetti particles
                    ...List.generate(15, (index) {
                      final double angle = (index * 24) * 3.14159 / 180;
                      final double radius = 80 + (index % 3) * 20;
                      return Positioned(
                        left: 100 + radius * 0.8 * (index % 2 == 0 ? 1 : -1),
                        top: 100 + radius * 0.6 * (index % 3 == 0 ? 1 : -1),
                        child: Transform.rotate(
                          angle: angle,
                          child: Container(
                            width: 6,
                            height: 15,
                            decoration: BoxDecoration(
                              color: [
                                const Color(0xFFFF6B47),
                                const Color(0xFF4CAF50),
                                const Color(0xFF2196F3),
                                const Color(0xFFFFD700),
                                const Color(0xFFE91E63),
                              ][index % 5],
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Congratulations text
              const Text(
                'Congratulations!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'You\'ve completed the task\n\'$_selectedTask\'',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: 60),
              
              // Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _resetToHome,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            side: const BorderSide(color: Colors.white, width: 1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: const Text(
                            'Back to Home',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            // View Report functionality - placeholder
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6B47),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: const Text(
                            'View Report',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    bool shouldShowTaskPill = _timerState != TimerState.idle && 
                              _timerState != TimerState.completed;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF6B47), Color(0xFFFF8A65)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.menu,
            color: Colors.white,
            size: 24,
          ),
          Expanded(
            child: shouldShowTaskPill ? Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2D3A),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2196F3),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedTask,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: _resetToHome,
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ) : const Center(
              child: Text(
                'Chronofy',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const Icon(
            Icons.notifications_outlined,
            color: Colors.white,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildTaskSelector() {
    return GestureDetector(
      onTap: _showTaskSelectionModal,
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF3C4043),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _selectedTask,
                style: TextStyle(
                  color: _selectedTask == 'Select Task' ? const Color(0xFF9AA0A6) : Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Color(0xFF9AA0A6),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerSection() {
    return Container(
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF2A2D3A),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(40),
            topRight: Radius.circular(40),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            
            // Timer Circle
            Container(
              width: 280,
              height: 280,
              child: Stack(
                children: [
                  // Outer Circle
                  Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF3C4043),
                        width: 8,
                      ),
                    ),
                  ),
                  
                  // Progress Circle
                  Container(
                    width: 280,
                    height: 280,
                    child: CircularProgressIndicator(
                      value: _getProgress(),
                      strokeWidth: 8,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor()),
                    ),
                  ),
                  
                  // Timer Content
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _formatTime(_currentSeconds),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getTimerSubtext(),
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 60),
            
            // Action Buttons
            _buildActionButtons(),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _getTimerSubtext() {
    switch (_timerState) {
      case TimerState.idle:
        return _currentSession > 0 ? '$_currentSession of $_totalSessions sessions' : 'No sessions';
      case TimerState.focusRunning:
      case TimerState.focusPaused:
        return '$_currentSession of $_totalSessions sessions';
      case TimerState.breakIdle:
      case TimerState.breakRunning:
        return 'Short Break';
      case TimerState.completed:
        return 'All sessions completed!';
    }
  }

  Widget _buildActionButtons() {
    switch (_timerState) {
      case TimerState.idle:
        return Container(
          width: 200,
          height: 56,
          child: ElevatedButton(
            onPressed: _startFocusTimer,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B47),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_arrow, size: 24),
                SizedBox(width: 8),
                Text(
                  'Start to Focus',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
        
      case TimerState.focusRunning:
        return Container(
          width: 200,
          height: 56,
          child: ElevatedButton(
            onPressed: _pauseTimer,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: const Color(0xFFFF6B47),
              elevation: 0,
              side: const BorderSide(color: Color(0xFFFF6B47), width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pause, size: 24),
                SizedBox(width: 8),
                Text(
                  'Pause',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
        
      case TimerState.focusPaused:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  // Stop functionality - placeholder for now
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A4A4A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text(
                  'Stop',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Container(
              width: 120,
              height: 56,
              child: ElevatedButton(
                onPressed: _continueTimer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B47),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        );
        
      case TimerState.breakIdle:
        return Container(
          width: 200,
          height: 56,
          child: ElevatedButton(
            onPressed: _startBreakTimer,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B47),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_arrow, size: 24),
                SizedBox(width: 8),
                Text(
                  'Start Break Time',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
        
      case TimerState.breakRunning:
        return Container(
          width: 200,
          height: 56,
          child: ElevatedButton(
            onPressed: _skipBreak,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: const Color(0xFFFF6B47),
              elevation: 0,
              side: const BorderSide(color: Color(0xFFFF6B47), width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: const Text(
              'Skip Break',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
        
      case TimerState.completed:
        return const SizedBox.shrink();
    }
  }

  Widget _buildModeSelection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildModeOption(
            icon: Icons.block,
            label: 'Strict Mode',
            isSelected: _isStrictMode,
            onTap: () => setState(() => _isStrictMode = !_isStrictMode),
          ),
          _buildModeOption(
            icon: Icons.hourglass_empty,
            label: 'Timer Mode',
            isSelected: _isTimerMode,
            onTap: () => setState(() => _isTimerMode = !_isTimerMode),
          ),
          _buildModeOption(
            icon: Icons.music_note,
            label: 'White Noise',
            isSelected: _isWhiteNoise,
            onTap: () => setState(() => _isWhiteNoise = !_isWhiteNoise),
          ),
        ],
      ),
    );
  }

  Widget _buildModeOption({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFF6B47) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[400],
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFFFF6B47) : Colors.grey[400],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            icon: Icons.timer,
            label: 'Pomodoro',
            isSelected: _selectedIndex == 0,
            onTap: () => setState(() => _selectedIndex = 0),
          ),
          _buildNavItem(
            icon: Icons.apps,
            label: 'Manage',
            isSelected: _selectedIndex == 1,
            onTap: () => setState(() => _selectedIndex = 1),
          ),
          _buildNavItem(
            icon: Icons.calendar_today,
            label: 'Calendar',
            isSelected: _selectedIndex == 2,
            onTap: () => setState(() => _selectedIndex = 2),
          ),
          _buildNavItem(
            icon: Icons.trending_up,
            label: 'Report',
            isSelected: _selectedIndex == 3,
            onTap: () => setState(() => _selectedIndex = 3),
          ),
          _buildNavItem(
            icon: Icons.settings,
            label: 'Settings',
            isSelected: _selectedIndex == 4,
            onTap: () => setState(() => _selectedIndex = 4),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFFFF6B47) : Colors.grey[600],
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFFFF6B47) : Colors.grey[600],
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}