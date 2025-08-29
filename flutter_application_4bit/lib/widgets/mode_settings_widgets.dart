import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class WhiteNoiseController extends StatefulWidget {
  final bool isWhiteNoise;
  final String selectedWhiteNoise;
  final ValueChanged<bool> onWhiteNoiseChanged;
  final ValueChanged<String> onWhiteNoiseOptionChanged;

  const WhiteNoiseController({
    super.key,
    required this.isWhiteNoise,
    required this.selectedWhiteNoise,
    required this.onWhiteNoiseChanged,
    required this.onWhiteNoiseOptionChanged,
  });

  @override
  State<WhiteNoiseController> createState() => _WhiteNoiseControllerState();
}

class _WhiteNoiseControllerState extends State<WhiteNoiseController> {
  late AudioPlayer _audioPlayer;
  late String _selectedWhiteNoise;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _selectedWhiteNoise = widget.selectedWhiteNoise;
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _showWhiteNoiseModal() {
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
              ...[
                'None',
                'White Noise',
                // Add more sounds as needed
              ].map((sound) => ListTile(
                title: Text(sound),
                trailing: _selectedWhiteNoise == sound
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () async {
                  setState(() {
                    _selectedWhiteNoise = sound;
                  });
                  widget.onWhiteNoiseOptionChanged(sound);
                  widget.onWhiteNoiseChanged(sound != 'None');
                  if (sound == 'White Noise') {
                    await _audioPlayer.setAsset('assets/white_noise.mp3');
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
      label: 'White Noise',
      isSelected: widget.isWhiteNoise,
      color: const Color(0xFF3B82F6),
      onTap: _showWhiteNoiseModal,
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
  final bool isWhiteNoise;
  final String selectedWhiteNoise;
  final VoidCallback onStrictModePressed;
  final VoidCallback onTimerModePressed;
  final ValueChanged<bool> onWhiteNoiseChanged;
  final ValueChanged<String> onWhiteNoiseOptionChanged;

  const ModeSelectionBar({
    super.key,
    required this.isStrictMode,
    required this.isTimerMode,
    required this.isWhiteNoise,
    required this.selectedWhiteNoise,
    required this.onStrictModePressed,
    required this.onTimerModePressed,
    required this.onWhiteNoiseChanged,
    required this.onWhiteNoiseOptionChanged,
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
            onTap: onTimerModePressed,
          ),
            WhiteNoiseController(
              isWhiteNoise: isWhiteNoise,
              selectedWhiteNoise: selectedWhiteNoise,
              onWhiteNoiseChanged: onWhiteNoiseChanged,
              onWhiteNoiseOptionChanged: onWhiteNoiseOptionChanged,
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