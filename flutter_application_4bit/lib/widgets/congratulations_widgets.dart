import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_4bit/pomodoro_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'timer_display_widgets.dart';

class CongratulationsScreen extends StatelessWidget {
  final String selectedTask;
  final int totalSessions;
  final ConfettiController confettiController;
  final VoidCallback onViewReport;
  final VoidCallback onStartNewSession;
  final VoidCallback onBackToHome;

  const CongratulationsScreen({
    super.key,
    required this.selectedTask,
    required this.totalSessions,
    required this.confettiController,
    required this.onViewReport,
    required this.onStartNewSession,
    required this.onBackToHome,
  });

  @override
  Widget build(BuildContext context) {
    // Trigger confetti animation when this screen is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      confettiController.play();
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
                  const TrophyIcon(),
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
                    'You\'ve completed all focus sessions for\n\'$selectedTask\'',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: const Color(0xFFA1A1AA),
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Stats
                  StatsContainer(totalSessions: totalSessions),
                  const SizedBox(height: 40),
                  // Buttons
                  CompletionButtons(
                    onViewReport: onViewReport,
                    onStartNewSession: onStartNewSession,
                    onBackToHome: onBackToHome,
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
            confettiController: confettiController,
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
}

class TrophyIcon extends StatelessWidget {
  const TrophyIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
    );
  }
}

class StatsContainer extends StatelessWidget {
  final int totalSessions;

  const StatsContainer({
    super.key,
    required this.totalSessions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          SessionStat(label: 'Sessions', value: '$totalSessions'),
          SessionStat(label: 'Focus Time', value: '${totalSessions * PomodoroSettings.instance.pomodoroLength} min'),
          SessionStat(label: 'Breaks', value: '${totalSessions - 1}'),
        ],
      ),
    );
  }
}

class CompletionButtons extends StatelessWidget {
  final VoidCallback onViewReport;
  final VoidCallback onStartNewSession;
  final VoidCallback onBackToHome;

  const CompletionButtons({
    super.key,
    required this.onViewReport,
    required this.onStartNewSession,
    required this.onBackToHome,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                onViewReport();
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
              onPressed: onStartNewSession,
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFF9333EA), width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Back to Home',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}