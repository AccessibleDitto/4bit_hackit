import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AmbientMusicController extends StatefulWidget {
  final bool isAmbientMusic;
  final String selectedAmbientMusic;
  final ValueChanged<bool> onAmbientMusicChanged;
  final ValueChanged<String> onAmbientMusicOptionChanged;

  const AmbientMusicController({
    super.key,
    required this.isAmbientMusic,
    required this.selectedAmbientMusic,
    required this.onAmbientMusicChanged,
    required this.onAmbientMusicOptionChanged,
  });

  @override
  State<AmbientMusicController> createState() => _AmbientMusicControllerState();
}

class _AmbientMusicControllerState extends State<AmbientMusicController> {
  late AudioPlayer _audioPlayer;
  late String _selectedAmbientMusic;

  @override
  void initState() {
    super.initState();
  _audioPlayer = AudioPlayer();
  _selectedAmbientMusic = widget.selectedAmbientMusic;
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _showAmbientMusicModal() {
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
              const Text('Ambient Music Selection', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text('Choose ambient music to help you focus.'),
              const SizedBox(height: 24),
              ...[
                'None',
                'Amberlight',
                'Celestia',
                'Daydream',
                'Spring',
                'Moonlight',
                // Add more sounds as needed
              ].map((sound) => ListTile(
                title: Text(sound),
                trailing: _selectedAmbientMusic == sound
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () async {
                  setState(() {
                    _selectedAmbientMusic = sound;
                  });
                  widget.onAmbientMusicOptionChanged(sound);
                  widget.onAmbientMusicChanged(sound != 'Daydream');
                  if (sound == 'Amberlight') {
                    await _audioPlayer.setAsset('assets/Amberlight.mp3');
                    _audioPlayer.setLoopMode(LoopMode.one);
                    _audioPlayer.play();
                  } else if (sound == 'Celestia') {
                    await _audioPlayer.setAsset('assets/Celestia.mp3');
                    _audioPlayer.setLoopMode(LoopMode.one);
                    _audioPlayer.play();
                  } else if (sound == 'Daydream') {
                    await _audioPlayer.setAsset('assets/Daydreams.mp3');
                    _audioPlayer.setLoopMode(LoopMode.one);
                    _audioPlayer.play();
                  } else if (sound == 'Spring') {
                    await _audioPlayer.setAsset('assets/Memories-of-Spring.mp3');
                    _audioPlayer.setLoopMode(LoopMode.one);
                    _audioPlayer.play();
                  } else if (sound == 'Moonlight') {
                    await _audioPlayer.setAsset('assets/Moonlight.mp3');
                    _audioPlayer.setLoopMode(LoopMode.one);
                    _audioPlayer.play();
                  } else {
                    _audioPlayer.stop();
                  }
                  Navigator.pop(context);
                },
              )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ModeOption(
      icon: Icons.music_note,
      label: 'Ambient Music',
      isSelected: widget.isAmbientMusic,
      color: const Color(0xFF3B82F6),
      onTap: _showAmbientMusicModal,
    );
  }
}

class StrictModeController extends StatefulWidget {
  final Widget child;
  final bool isStrictMode;
  final ValueChanged<bool> onStrictModeChanged;
  final String strictModeDesc;

  const StrictModeController({
    super.key,
    required this.child,
    required this.isStrictMode,
    required this.onStrictModeChanged,
    required this.strictModeDesc,
  });

  @override
  State<StrictModeController> createState() => _StrictModeControllerState();
}

class _StrictModeControllerState extends State<StrictModeController> {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => !widget.isStrictMode,
      child: widget.child,
    );
  }
}

class ModeSelectionBar extends StatelessWidget {
  final bool isStrictMode;
  final bool isTimerMode;
  final bool isCountdownMode;
  final int focusSeconds;
  final bool isAmbientMusic;
  final String selectedAmbientMusic;
  final VoidCallback onStrictModePressed;
  final VoidCallback onTimerModePressed;
  final ValueChanged<bool> onCountdownModeChanged;
  final ValueChanged<bool> onAmbientMusicChanged;
  final ValueChanged<String> onAmbientMusicOptionChanged;

  const ModeSelectionBar({
    super.key,
    required this.isStrictMode,
    required this.isTimerMode,
    required this.isCountdownMode,
    required this.focusSeconds,
    required this.isAmbientMusic,
    required this.selectedAmbientMusic,
    required this.onStrictModePressed,
    required this.onTimerModePressed,
    required this.onCountdownModeChanged,
    required this.onAmbientMusicChanged,
    required this.onAmbientMusicOptionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
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
          ModeOption(
            icon: Icons.block,
            label: 'Strict Mode',
            isSelected: isStrictMode,
            color: const Color(0xFFEF4444),
            onTap: onStrictModePressed,
          ),
          ModeOption(
            icon: Icons.timer,
            label: 'Timer Mode',
            isSelected: isTimerMode,
            color: const Color(0xFF10B981),
            onTap: () => _showTimerModeModal(context),
          ),
            AmbientMusicController(
              isAmbientMusic: isAmbientMusic,
              selectedAmbientMusic: selectedAmbientMusic,
              onAmbientMusicChanged: onAmbientMusicChanged,
              onAmbientMusicOptionChanged: onAmbientMusicOptionChanged,
            ),
        ],
      ),
    );
  }

  void _showTimerModeModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => TimerModeModal(
        isCountdownMode: isCountdownMode,
        focusSeconds: focusSeconds,
        onModeChanged: (bool isCountdown) {
          onCountdownModeChanged(isCountdown);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class TimerModeModal extends StatefulWidget {
  final bool isCountdownMode;
  final int focusSeconds;
  final ValueChanged<bool> onModeChanged;

  const TimerModeModal({
    super.key,
    required this.isCountdownMode,
    required this.focusSeconds,
    required this.onModeChanged,
  });

  @override
  State<TimerModeModal> createState() => _TimerModeModalState();
}

class _TimerModeModalState extends State<TimerModeModal> {
  late bool _selectedIsCountdown;

  @override
  void initState() {
    super.initState();
    _selectedIsCountdown = widget.isCountdownMode;
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    return '${minutes.toString().padLeft(2, '0')}:00';
  }

  @override
  Widget build(BuildContext context) {
    final focusTime = _formatTime(widget.focusSeconds);
    
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Timer Mode Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text('Choose your timer type:'),
          const SizedBox(height: 24),
          ListTile(
            title: Text('$focusTime → 00:00'),
            subtitle: Text('Countdown from $focusTime until time runs out.'),
            trailing: _selectedIsCountdown
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: () {
              setState(() {
                _selectedIsCountdown = true;
              });
              widget.onModeChanged(true);
            },
          ),
          const SizedBox(height: 8),
          ListTile(
            title: const Row(
              children: [
                Text('00:00 → '),
                Icon(Icons.all_inclusive, size: 18),
              ],
            ),
            subtitle: const Text('Start counting from 0 until stopped manually.'),
            trailing: !_selectedIsCountdown
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: () {
              setState(() {
                _selectedIsCountdown = false;
              });
              widget.onModeChanged(false);
            },
          ),
        ],
      ),
    );
  }
}

class ModeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const ModeOption({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTap();
        HapticFeedback.selectionClick();
      },
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
}