import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Singleton for accessing Pomodoro settings globally
class PomodoroSettings extends ChangeNotifier {
  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    // _pomodoroLength = prefs.getInt('pomodoroLength') ?? 25; // this was original time
    _pomodoroLength = prefs.getInt('pomodoroLength') ?? 1; 
    _isCountdownMode = prefs.getBool('isCountdownMode') ?? true;
    notifyListeners();
  }
  bool _isCountdownMode = true;
  bool get isCountdownMode => _isCountdownMode;
  set isCountdownMode(bool value) {
    _isCountdownMode = value;
    notifyListeners();
  }
  // Break logic toggles
  bool _disableBreak = false;
  bool _autoStartBreak = false;
  bool _autoStartNextPomodoro = false;

  bool get disableBreak => _disableBreak;
  bool get autoStartBreak => _autoStartBreak;
  bool get autoStartNextPomodoro => _autoStartNextPomodoro;

  void setDisableBreak(bool value) {
    _disableBreak = value;
    notifyListeners();
  }
  void setAutoStartBreak(bool value) {
    _autoStartBreak = value;
    notifyListeners();
  }
  void setAutoStartNextPomodoro(bool value) {
    _autoStartNextPomodoro = value;
    notifyListeners();
  }
  static final PomodoroSettings instance = PomodoroSettings._internal();
  PomodoroSettings._internal();

  // int _pomodoroLength = 25; // this was original time
  int _pomodoroLength = 1; 
  int _shortBreakLength = 5;
  int _longBreakLength = 15;
  int _longBreakAfter = 4;

  int get pomodoroLength => _pomodoroLength;
  int get shortBreakLength => _shortBreakLength;
  int get longBreakLength => _longBreakLength;
  int get longBreakAfter => _longBreakAfter;

  void setPomodoroLength(int value) {
    _pomodoroLength = value;
    notifyListeners();
  }

  void setShortBreakLength(int value) {
    _shortBreakLength = value;
    notifyListeners();
  }

  void setLongBreakLength(int value) {
    _longBreakLength = value;
    notifyListeners();
  }

  void setLongBreakAfter(int value) {
    _longBreakAfter = value;
    notifyListeners();
  }
}

class PomodoroPreferencesScreen extends StatefulWidget {
  const PomodoroPreferencesScreen({super.key});

  @override
  State<PomodoroPreferencesScreen> createState() => _PomodoroPreferencesScreenState();
}

class _PomodoroPreferencesScreenState extends State<PomodoroPreferencesScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // pomodoro settings
  bool _strictMode = false;
  int _pomodoroLength = 1; 
  int _shortBreakLength = 5; // minutes
  int _longBreakLength = 15; // minutes
  int _longBreakAfter = 4; // pomodoros
  late String _timerMode;
  List<String> get _timerModeOptions => [
    '${_pomodoroLength.toString().padLeft(2, '0')}:00 → 00:00',
    '00:00 → ∞',
  ];
  bool _whiteNoise = true;
  bool _disableBreak = false;
  bool _autoStartBreak = false;
  bool _autoStartNextPomodoro = false;
  String _reminderRingtone = 'Default';
  bool _reminderVibrate = true;
  String _completionSound = 'Bell';

  // Theme colors
  bool get n => true;
  Color get _primaryColor => const Color(0xFFFF8C42);
  Color get _backgroundColor => const Color(0xFF121212);
  Color get _surfaceColor => const Color(0xFF1E1E1E);
  Color get _onSurfaceColor => Colors.white;
  Color get _onSurfaceVariantColor => const Color(0xFF888888);
  Color get _borderColor => const Color(0xFF333333);

  @override
  void initState() {
    super.initState();
    _timerMode = '${_pomodoroLength.toString().padLeft(2, '0')}:00 → 00:00';
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _animationController.forward();
    });
    _loadPomodoroSettings();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _savePomodoroLength(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pomodoroLength', value);
  }

  Future<void> _saveTimerMode(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('timerMode', value);
  }

  Future<void> _loadPomodoroSettings() async {
    final prefs = await SharedPreferences.getInstance();
    // int loadedLength = prefs.getInt('pomodoroLength') ?? 25; // this was original time
    int loadedLength = prefs.getInt('pomodoroLength') ?? 1;
    String defaultMode = '${loadedLength.toString().padLeft(2, '0')}:00 → 00:00';
    List<String> options = [defaultMode, '00:00 → ∞'];
    String loadedTimerMode = prefs.getString('timerMode') ?? defaultMode;
    if (!options.contains(loadedTimerMode)) {
      loadedTimerMode = defaultMode;
    }
    bool loadedDisableBreak = prefs.getBool('disableBreak') ?? false;
    bool loadedAutoStartBreak = prefs.getBool('autoStartBreak') ?? false;
    bool loadedAutoStartNextPomodoro = prefs.getBool('autoStartNextPomodoro') ?? false;
    setState(() {
      _pomodoroLength = loadedLength;
      _timerMode = loadedTimerMode;
      _disableBreak = loadedDisableBreak;
      _autoStartBreak = loadedAutoStartBreak;
      _autoStartNextPomodoro = loadedAutoStartNextPomodoro;
    });
    PomodoroSettings.instance.setDisableBreak(loadedDisableBreak);
    PomodoroSettings.instance.setAutoStartBreak(loadedAutoStartBreak);
    PomodoroSettings.instance.setAutoStartNextPomodoro(loadedAutoStartNextPomodoro);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Scaffold(
        backgroundColor: _backgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            _buildSectionTitle('Timer Settings'),
                            _buildTimerSection(),
                            const SizedBox(height: 30),
                            _buildSectionTitle('Break Settings'),
                            _buildBreakSection(),
                            const SizedBox(height: 30),
                            _buildSectionTitle('Audio & Notifications'),
                            _buildAudioSection(),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Hero(
            tag: 'pomodoro_back_button',
            child: Material(
              color: Colors.transparent,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                child: IconButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                  },
                  icon: Icon(
                    Icons.arrow_back_ios,
                    color: _onSurfaceColor,
                    size: 20,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: _surfaceColor,
                    padding: const EdgeInsets.all(12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: _borderColor),
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: _onSurfaceColor,
            ),
            child: const Text('Pomodoro Preferences'),
          ),
          const Spacer(),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _borderColor),
            ),
            child: Icon(
              Icons.timer,
              color: _primaryColor,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: _primaryColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTimerSection() {
    return Column(
      children: [
        _buildToggleItem(
          title: 'Strict Mode',
          subtitle: 'Prevent app switching during pomodoro sessions',
          icon: Icons.lock_outline,
          value: _strictMode,
          onChanged: (value) => setState(() => _strictMode = value),
        ),
        const SizedBox(height: 12),
        _buildDropdownItem(
          title: 'Timer Mode',
          subtitle: 'Choose your preferred timer style',
          icon: Icons.timer_outlined,
          value: _timerModeOptions.contains(_timerMode) ? _timerMode : _timerModeOptions.first,
          options: _timerModeOptions,
          onChanged: (value) async {
            if (value == null) return;
            setState(() => _timerMode = value);
            await _saveTimerMode(value);
          },
        ),
        const SizedBox(height: 12),
        _buildSliderItem(
          title: 'Pomodoro Length',
          subtitle: '$_pomodoroLength minutes',
          icon: Icons.schedule,
          value: _pomodoroLength.toDouble(),
          min: 1, // this was 25
          max: 60, 
          divisions: 7, 
          onChanged: (value) async {
            int newValue = value.round();
            setState(() {
              _pomodoroLength = newValue;
              // Always sync timer mode value to the new options
              _timerMode = '${_pomodoroLength.toString().padLeft(2, '0')}:00 → 00:00';
            });
            PomodoroSettings.instance.setPomodoroLength(newValue);
            await _savePomodoroLength(newValue);
          },
        ),
      ],
    );
  }

  Widget _buildBreakSection() {
    return Column(
      children: [
        _buildSliderItem(
          title: 'Short Break Length',
          subtitle: '$_shortBreakLength minutes',
          icon: Icons.coffee_outlined,
          value: _shortBreakLength.toDouble(),
          min: 1,
          max: 15,
          divisions: 14,
          onChanged: (value) {
            int newValue = value.round();
            setState(() => _shortBreakLength = newValue);
            PomodoroSettings.instance.setShortBreakLength(newValue);
          },
        ),
        const SizedBox(height: 12),
        _buildSliderItem(
          title: 'Long Break Length',
          subtitle: '$_longBreakLength minutes',
          icon: Icons.weekend_outlined,
          value: _longBreakLength.toDouble(),
          min: 10,
          max: 45,
          divisions: 7,
          onChanged: (value) {
            int newValue = value.round();
            setState(() => _longBreakLength = newValue);
            PomodoroSettings.instance.setLongBreakLength(newValue);
          },
        ),
        const SizedBox(height: 12),
        _buildSliderItem(
          title: 'Long Break After',
          subtitle: '$_longBreakAfter pomodoros',
          icon: Icons.repeat,
          value: _longBreakAfter.toDouble(),
          min: 2,
          max: 8,
          divisions: 6,
          onChanged: (value) {
            int newValue = value.round();
            setState(() => _longBreakAfter = newValue);
            PomodoroSettings.instance.setLongBreakAfter(newValue);
          },
        ),
        const SizedBox(height: 12),
        _buildToggleItem(
          title: 'Disable Break',
          subtitle: 'Skip all break periods',
          icon: Icons.skip_next,
          value: _disableBreak,
          onChanged: (value) async {
            setState(() => _disableBreak = value);
            PomodoroSettings.instance.setDisableBreak(value);
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('disableBreak', value);
          },
        ),
        const SizedBox(height: 12),
        _buildToggleItem(
          title: 'Auto Start Break',
          subtitle: 'Automatically start break when pomodoro ends',
          icon: Icons.play_arrow,
          value: _autoStartBreak,
          onChanged: (value) async {
            setState(() => _autoStartBreak = value);
            PomodoroSettings.instance.setAutoStartBreak(value);
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('autoStartBreak', value);
          },
        ),
        const SizedBox(height: 12),
        _buildToggleItem(
          title: 'Auto Start Next Pomodoro',
          subtitle: 'Automatically start next pomodoro after break',
          icon: Icons.fast_forward,
          value: _autoStartNextPomodoro,
          onChanged: (value) async {
            setState(() => _autoStartNextPomodoro = value);
            PomodoroSettings.instance.setAutoStartNextPomodoro(value);
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('autoStartNextPomodoro', value);
          },
        ),
      ],
    );
  }

  Widget _buildAudioSection() {
    return Column(
      children: [
        _buildToggleItem(
          title: 'White Noise',
          subtitle: 'Play ambient sounds during focus sessions',
          icon: Icons.headphones,
          value: _whiteNoise,
          onChanged: (value) => setState(() => _whiteNoise = value),
        ),
        const SizedBox(height: 12),
        _buildDropdownItem(
          title: 'Reminder Ringtone',
          subtitle: 'Sound for session start/end reminders',
          icon: Icons.music_note,
          value: _reminderRingtone,
          options: ['Default', 'Bell', 'Chime', 'Piano', 'None'],
          onChanged: (value) => setState(() => _reminderRingtone = value!),
        ),
        const SizedBox(height: 12),
        _buildToggleItem(
          title: 'Reminder Vibrate',
          subtitle: 'Vibrate device for notifications',
          icon: Icons.vibration,
          value: _reminderVibrate,
          onChanged: (value) => setState(() => _reminderVibrate = value),
        ),
        const SizedBox(height: 12),
        _buildDropdownItem(
          title: 'Completion Sound',
          subtitle: 'Sound when session completes',
          icon: Icons.notifications_active,
          value: _completionSound,
          options: ['Bell', 'Chime', 'Success', 'Applause', 'None'],
          onChanged: (value) => setState(() => _completionSound = value!),
        ),
      ],
    );
  }

  Widget _buildToggleItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _borderColor,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: _primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _onSurfaceColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: _onSurfaceVariantColor,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: (newValue) {
                HapticFeedback.lightImpact();
                onChanged(newValue);
              },
              activeThumbColor: _primaryColor,
              activeTrackColor: _primaryColor.withValues(alpha: 0.3),
              inactiveThumbColor: const Color(0xFF666666),
              inactiveTrackColor: const Color(0xFF333333),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _borderColor,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: _primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _onSurfaceColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: _onSurfaceVariantColor,
                    ),
                  ),
                ],
              ),
            ),
            DropdownButton<String>(
              value: value,
              onChanged: onChanged,
              dropdownColor: _surfaceColor,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: _onSurfaceColor,
              ),
              underline: Container(),
              items: options.map((String option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required double value,
    required double min,
    required double max,
    required int? divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _borderColor,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: _primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: _onSurfaceColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: _onSurfaceVariantColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: _primaryColor,
                inactiveTrackColor: _borderColor,
                thumbColor: _primaryColor,
                overlayColor: _primaryColor.withValues(alpha: 0.2),
                trackHeight: 4,
              ),
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: divisions,
                onChanged: (newValue) {
                  HapticFeedback.lightImpact();
                  onChanged(newValue);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}