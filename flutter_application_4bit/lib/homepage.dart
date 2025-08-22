import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

class TimerModePage extends StatefulWidget {

  const TimerModePage({super.key});

  @override
  State<TimerModePage> createState() => _TimerModePageState();
}

enum TimerState { idle, focusRunning, focusPaused, breakIdle, breakRunning, completed }

class _TimerModePageState extends State<TimerModePage> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  
  late ConfettiController _confettiController;
  late AnimationController _progressAnimationController;
  late Animation<double> _progressAnimation;
  
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
  }

  @override
  void dispose() {
    _timer?.cancel();
    _confettiController.dispose();
    _progressAnimationController.dispose();
    super.dispose();
  }

  Timer? _timer;
  int _focusSeconds = 25 * 60; // 25 minutes
  int _breakSeconds = 5 * 60; // 5 minutes
  int _currentSeconds = 25 * 60;
  TimerState _timerState = TimerState.idle;
  int _currentSession = 0;
  int _totalSessions = 4;
  bool _isBreakTime = false;
  bool _isStrictMode = false;
  bool _isTimerMode = true;
  bool _isWhiteNoise = false;
  String _selectedTask = 'Select Task';

  final List<Map<String, dynamic>> _tasks = [
    {
      'title': 'Design User Experience (UX)',
      'sessions': 7,
      'color': Color(0xFF9333EA),
    },
    {
      'title': 'Design User Interface (UI)',
      'sessions': 6,
      'color': Color(0xFF10B981),
    },
    {
      'title': 'Create a Design Wireframe',
      'sessions': 4,
      'color': Color(0xFF3B82F6),
    },
    {
      'title': 'Write Documentation',
      'sessions': 3,
      'color': Color(0xFFEF4444),
    },
    {
      'title': 'Code Review Session',
      'sessions': 2,
      'color': Color(0xFFF59E0B),
    },
  ];

  void _showTaskSelectionModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Color(0xFF18181B),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF71717A),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Select Task',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // Add new task functionality
                        HapticFeedback.lightImpact();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9333EA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF27272A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF9333EA).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        color: const Color(0xFF9333EA),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Search tasks...',
                          style: GoogleFonts.inter(
                            color: const Color(0xFFA1A1AA),
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Today Tasks section
              Padding(
                padding: const EdgeInsets.all(24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Available Tasks',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFA1A1AA),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              // Task list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  physics: BouncingScrollPhysics(),
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
        HapticFeedback.selectionClick();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF27272A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: task['color'].withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: task['color'].withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            // Task color indicator
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: task['color'],
                shape: BoxShape.circle,
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
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: task['color'],
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${task['sessions']} sessions planned',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFA1A1AA),
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Pomodoro',
                        style: GoogleFonts.inter(
                          color: task['color'],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Select button
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: task['color'],
                borderRadius: BorderRadius.circular(12),
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

  void _startFocusTimer() {
    setState(() {
      _timerState = TimerState.focusRunning;
      _isBreakTime = false;
      _currentSession = _currentSession == 0 ? 1 : _currentSession;
      _currentSeconds = _focusSeconds;
    });
    _updateProgressAnimation();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_currentSeconds > 0) {
          _currentSeconds--;
          _updateProgressAnimation();
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
          if (_currentSeconds > 0) {
            _currentSeconds--;
            _updateProgressAnimation();
          } else {
            _completeFocusSession();
          }
        });
      });
    }
  }

  void _completeFocusSession() {
    _confettiController.play();
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
    _progressAnimationController.reset();
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

  Color _getProgressColor() {
    if (_isBreakTime) return const Color(0xFF10B981);
    return const Color(0xFF9333EA);
  }

  @override
  Widget build(BuildContext context) {
    if (_timerState == TimerState.completed) {
      return _buildCongratulationsScreen();
    }

    return Scaffold(
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
                  _buildAppBar(),
                  // Task Selection Dropdown (only show when idle)
                  if (_timerState == TimerState.idle) _buildTaskSelector(),
                  // Main Timer Section
                  Expanded(
                    child: _buildTimerSection(),
                  ),
                  // Mode Selection
                  _buildModeSelection(),
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
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildCongratulationsScreen() {
    // Trigger confetti animation when this screen is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confettiController.play();
    });
    
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFF0F0F0F),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0F0F0F),
                  Color(0xFF1A1A1A),
                  Color(0xFF0A0A0A),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Trophy with glow effect
                  Container(
                    width: 200,
                    height: 200,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Glow effect
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF9333EA).withOpacity(0.4),
                                blurRadius: 60,
                                spreadRadius: 20,
                              ),
                            ],
                          ),
                        ),
                        // Trophy
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF9333EA),
                                Color(0xFFC084FC),
                                Color(0xFF8B5CF6),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF9333EA).withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.emoji_events,
                            size: 80,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Congratulations text
                  Text(
                    'Congratulations!',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    'You\'ve completed all focus sessions for\n\'$_selectedTask\'',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: const Color(0xFFA1A1AA),
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Stats
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF18181B).withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF9333EA).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat('Sessions', '$_totalSessions'),
                        _buildStat('Focus Time', '${(_totalSessions * 25)} min'),
                        _buildStat('Breaks', '${_totalSessions - 1}'),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              // View Report functionality
                              HapticFeedback.lightImpact();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF9333EA),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              'View Report',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton(
                            onPressed: _resetToHome,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFF9333EA), width: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              'Start New Session',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            HapticFeedback.lightImpact();
                          },
                          child: Text(
                            'Back to Home',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF9333EA),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
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
        ),
        // Enhanced confetti animation overlay
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
            numberOfParticles: 30,
            maxBlastForce: 25,
            minBlastForce: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            color: const Color(0xFF9333EA),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            color: const Color(0xFFA1A1AA),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    bool shouldShowTaskPill = _timerState != TimerState.idle && 
                              _timerState != TimerState.completed;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF9333EA), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              HapticFeedback.lightImpact();
            },
            child: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 24,
            ),
          ),
          Expanded(
            child: shouldShowTaskPill ? Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF18181B).withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedTask,
                      style: GoogleFonts.inter(
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
            ) : Center(
              child: Text(
                'Timer Mode',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              // Settings functionality
              HapticFeedback.lightImpact();
            },
            child: const Icon(
              Icons.settings_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskSelector() {
    return GestureDetector(
      onTap: _showTaskSelectionModal,
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF9333EA).withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.task_alt,
              color: _selectedTask == 'Select Task' ? const Color(0xFFA1A1AA) : const Color(0xFF9333EA),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedTask,
                style: GoogleFonts.inter(
                  color: _selectedTask == 'Select Task' ? const Color(0xFFA1A1AA) : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: const Color(0xFF9333EA),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerSection() {
    // Get screen dimensions
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Calculate responsive circle size
    // Use 70% of screen width or 300px, whichever is smaller
    // Also ensure it doesn't exceed available height minus padding
    final maxCircleSize = screenWidth * 0.7;
    final availableHeight = screenHeight * 0.4; // 40% of screen height for circle
    final circleSize = [maxCircleSize, availableHeight, 300.0].reduce((a, b) => a < b ? a : b);
    
    // Calculate stroke width relative to circle size
    final strokeWidth = circleSize * 0.025; // 2.5% of circle size
    final minStrokeWidth = 4.0;
    final maxStrokeWidth = 12.0;
    final responsiveStrokeWidth = strokeWidth.clamp(minStrokeWidth, maxStrokeWidth);
    
    // Calculate font sizes relative to circle size
    final timerFontSize = circleSize * 0.16; // 16% of circle size
    final subtextFontSize = circleSize * 0.053; // 5.3% of circle size
    
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Session indicator
          if (_timerState != TimerState.idle)
            Container(
              margin: EdgeInsets.only(bottom: circleSize * 0.133), // Responsive margin
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_totalSessions, (index) {
                  final dotSize = circleSize * 0.04; // 4% of circle size
                  final activeDotSize = circleSize * 0.048; // 4.8% of circle size
                  
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: circleSize * 0.013),
                    width: index < _currentSession ? activeDotSize : dotSize,
                    height: index < _currentSession ? activeDotSize : dotSize,
                    decoration: BoxDecoration(
                      color: index < _currentSession 
                        ? const Color(0xFF9333EA)
                        : const Color(0xFF9333EA).withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
            ),
          
          // Timer Circle
          SizedBox(
            width: 300,
            height: 300,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer Circle
                SizedBox(
                  width: 300,
                  height: 300,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF27272A),
                        width: 8,
                      ),
                    ),
                  ),
                ),
                // Progress Circle (same size)
                SizedBox(
                  width: 300,
                  height: 300,
                  child: AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return CircularProgressIndicator(
                        value: _progressAnimation.value,
                        strokeWidth: 16, // match the total width of the outer border (8+8)
                        backgroundColor: const Color(0xFF27272A), // match the outer circle border color
                        valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor()),
                        strokeCap: StrokeCap.round,
                      );
                    },
                  ),
                ),
                
                // Timer Content - Now properly centered
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(_currentSeconds),
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: timerFontSize,
                        fontWeight: FontWeight.w300,
                        letterSpacing: -1,
                      ),
                    ),
                    SizedBox(height: circleSize * 0.027), // Responsive spacing
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: circleSize * 0.1),
                      child: Text(
                        _getTimerSubtext(),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: const Color(0xFFA1A1AA),
                          fontSize: subtextFontSize,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Responsive spacing before action buttons
          SizedBox(height: circleSize * 0.133),
          
          // Action Buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  String _getTimerSubtext() {
    switch (_timerState) {
      case TimerState.idle:
        return _currentSession > 0 ? 'Session $_currentSession of $_totalSessions' : 'Ready to focus';
      case TimerState.focusRunning:
      case TimerState.focusPaused:
        return 'Focus Time - Session $_currentSession of $_totalSessions';
      case TimerState.breakIdle:
      case TimerState.breakRunning:
        return 'Break Time - Take a rest';
      case TimerState.completed:
        return 'All sessions completed!';
    }
  }

  Widget _buildActionButtons() {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonWidth = (screenWidth * 0.6).clamp(200.0, 280.0);
    final smallButtonWidth = (screenWidth * 0.35).clamp(120.0, 180.0);
    final buttonHeight = 56.0;
    final fontSize = (screenWidth * 0.04).clamp(14.0, 18.0);
    
    switch (_timerState) {
      case TimerState.idle:
        return SizedBox(
          width: buttonWidth,
          height: buttonHeight,
          child: ElevatedButton(
            onPressed: _selectedTask != 'Select Task' ? _startFocusTimer : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedTask != 'Select Task' 
                ? const Color(0xFF9333EA) 
                : const Color(0xFF27272A),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              disabledBackgroundColor: const Color(0xFF27272A),
              disabledForegroundColor: const Color(0xFF71717A),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_arrow, size: fontSize + 4),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Start Focus Session',
                    style: GoogleFonts.inter(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
        
      case TimerState.focusRunning:
        return SizedBox(
          width: buttonWidth,
          height: buttonHeight,
          child: ElevatedButton(
            onPressed: _pauseTimer,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: const Color(0xFF9333EA),
              elevation: 0,
              side: const BorderSide(color: Color(0xFF9333EA), width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.pause, size: fontSize + 4),
                SizedBox(width: 8),
                Text(
                  'Pause',
                  style: GoogleFonts.inter(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
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
            SizedBox(
              width: smallButtonWidth,
              height: buttonHeight,
              child: OutlinedButton(
                onPressed: _resetToHome,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: const Color(0xFFEF4444),
                  side: const BorderSide(color: Color(0xFFEF4444), width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Stop',
                  style: GoogleFonts.inter(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: smallButtonWidth,
              height: buttonHeight,
              child: ElevatedButton(
                onPressed: _continueTimer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9333EA),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Continue',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1, 
                  style: GoogleFonts.inter(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
        
      case TimerState.breakIdle:
        return SizedBox(
          width: buttonWidth,
          height: buttonHeight,
          child: ElevatedButton(
            onPressed: _startBreakTimer,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.coffee, size: fontSize + 4),
                SizedBox(width: 8),
                Text(
                  'Start Break',
                  style: GoogleFonts.inter(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
        
      case TimerState.breakRunning:
        return SizedBox(
          width: buttonWidth,
          height: buttonHeight,
          child: OutlinedButton(
            onPressed: _skipBreak,
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: const Color(0xFF10B981),
              side: const BorderSide(color: Color(0xFF10B981), width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Skip Break',
              style: GoogleFonts.inter(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
        
      case TimerState.completed:
        return const SizedBox.shrink();
    }
  }

  Widget _buildModeSelection() {
    return Container(
      margin: const EdgeInsets.all(20),
      // padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B).withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF9333EA).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildModeOption(
            icon: Icons.block,
            label: 'Strict Mode',
            isSelected: _isStrictMode,
            color: const Color(0xFFEF4444),
            onTap: () {
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
                      const Text('Strict Mode Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      const Text('Here you can configure strict mode options.'),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          setState(() => _isStrictMode = !_isStrictMode);
                          Navigator.pop(context);
                        },
                        child: Text(_isStrictMode ? 'Disable Strict Mode' : 'Enable Strict Mode'),
                      ),
                    ],
                  ),
                ),
              );
              HapticFeedback.selectionClick();
            },
          ),
          _buildModeOption(
            icon: Icons.timer,
            label: 'Timer Mode',
            isSelected: _isTimerMode,
            color: const Color(0xFF10B981),
            onTap: () {
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
                      const Text('Timer Mode Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      const Text('Here you can configure timer mode options.'),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          setState(() => _isTimerMode = !_isTimerMode);
                          Navigator.pop(context);
                        },
                        child: Text(_isTimerMode ? 'Disable Timer Mode' : 'Enable Timer Mode'),
                      ),
                    ],
                  ),
                ),
              );
              HapticFeedback.selectionClick();
            },
          ),
          _buildModeOption(
            icon: Icons.music_note,
            label: 'White Noise',
            isSelected: _isWhiteNoise,
            color: const Color(0xFF3B82F6),
            onTap: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) => SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('White Noise Selection', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        const Text('Choose a background sound to help you focus.'),
                        const SizedBox(height: 24),
                        ListTile(
                          title: const Text('None'),
                          onTap: () {
                            setState(() { /* your state update here */ });
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          title: const Text('Cafe Ambiance'),
                          onTap: () {
                            setState(() { /* your state update here */ });
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          title: const Text('Rainforest Sound'),
                          onTap: () {
                            setState(() { /* your state update here */ });
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          title: const Text('Beach Waves'),
                          onTap: () {
                            setState(() { /* your state update here */ });
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          title: const Text('Forest'),
                          onTap: () {
                            setState(() { /* your state update here */ });
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
              HapticFeedback.selectionClick();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModeOption({
    required IconData icon,
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color,
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Place the navigation bar code at the end of the class
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFF9333EA) : const Color(0xFFA1A1AA),
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: isSelected ? const Color(0xFF9333EA) : const Color(0xFFA1A1AA),
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
}