import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/firebase_service.dart';
import 'profile.dart';
import 'pomodoro_preferences.dart';
import 'login.dart';
import 'homepage.dart';
import 'widgets/navigation_widgets.dart';
import 'package:flutter_application_4bit/widgets/standard_app_bar.dart';

// theme mode
enum AppThemeMode { light, dark, system }

// standard colours
class AppColors {
  final Color primary;
  final Color background;
  final Color surface;
  final Color onBackground;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color border;
  final Color error;
  final Color shadow;

  const AppColors({
    required this.primary,
    required this.background,
    required this.surface,
    required this.onBackground,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.border,
    required this.error,
    required this.shadow,
  });

  factory AppColors.light() {
    return const AppColors(
      primary: Color(0xFFFF8C42),
      background: Color(0xFFF8F9FA),
      surface: Colors.white,
      onBackground: Color(0xFF1A1A1A),
      onSurface: Color(0xFF1A1A1A),
      onSurfaceVariant: Color(0xFF666666),
      border: Color(0xFFE0E0E0),
      error: Color(0xFFEF4444),
      shadow: Color(0x1A000000),
    );
  }

  factory AppColors.dark() {
    return const AppColors(
      primary: Color(0xFFFF8C42),
      background: Color(0xFF121212),
      surface: Color(0xFF1E1E1E),
      onBackground: Colors.white,
      onSurface: Colors.white,
      onSurfaceVariant: Color(0xFF888888),
      border: Color(0xFF333333),
      error: Color(0xFFEF4444),
      shadow: Color(0x00000000),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final FirebaseService _firebaseService = FirebaseService();

  // Settings states
  bool _notificationsEnabled = true;
  AppThemeMode _selectedThemeMode = AppThemeMode.dark;
  
  // Theme helpers
  bool get _isDarkMode {
    switch (_selectedThemeMode) {
      case AppThemeMode.dark:
        return true;
      case AppThemeMode.light:
        return false;
      case AppThemeMode.system:
        return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
  }
  
  AppColors get _colors => _isDarkMode ? AppColors.dark() : AppColors.light();
  
  @override
  void initState() {
    super.initState();
    
    // Animation setup
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

    // delay animation
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Scaffold(
        backgroundColor: _colors.background,
        appBar: const StandardAppBar(
          title: 'Settings',
          type: AppBarType.standard,
        ),

        body: SafeArea(
          child: Column(
            children: [
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
                            _buildSectionTitle('Account'),
                            _buildAccountSection(),
                            const SizedBox(height: 30),
                            _buildSectionTitle('Preferences'),
                            _buildPreferencesSection(),
                            const SizedBox(height: 30),
                            _buildSectionTitle('System',
                            ),
                            _buildSystemSection(),
                            const SizedBox(height: 30),
                            _buildSectionTitle('Support'),
                            _buildSupportSection(),
                            const SizedBox(height: 30),
                            _buildSectionTitle('Session'),
                            _buildSessionSection(),
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
        bottomNavigationBar: const BottomNavigation(
          selectedIndex: 4,
          isStrictMode: false,
        ),
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
          color: _colors.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: AlertDialog(
          backgroundColor: _colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Delete Account',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _colors.error,
            ),
          ),
          content: Text(
            'Are you sure you want to permanently delete your account? This action cannot be undone.\n\nThis will delete:\n• All your tasks and projects\n• Your profile information\n• Your Pomodoro statistics\n• All achievements and progress',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: _colors.onSurfaceVariant,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  color: _colors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Call the delete function after closing the dialog
                _deleteFirebaseAccount();
              },
              child: Text(
                'Delete',
                style: GoogleFonts.inter(
                  color: _colors.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ), 
      ), 
    ); 
  }

  void _deleteFirebaseAccount() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Deleting account...'),
          ],
        ),
      ),
    );
    
    try {
      final currentUser = _firebaseService.currentUser;
      if (currentUser?.email != null) {
        // User is signed into Firebase Auth
        await _firebaseService.deleteAccount();
      } else {
        // User is using Gmail-based authentication without Firebase Auth
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
        }
        if (mounted) {
          _showEmailInputDialog();
        }
        return;
      }
      
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }
      
      if (mounted) {
        _showSuccessSnackBar('Account deleted successfully');
        
        // Navigate to login page immediately
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }
      
      if (mounted) {
        String errorMessage = 'Failed to delete account';
        
        switch (e.code) {
          case 'requires-recent-login':
            errorMessage = 'For security reasons, please sign out and sign back in, then try deleting your account again.';
            break;
          case 'network-request-failed':
            errorMessage = 'Network error. Please check your connection and try again';
            break;
          default:
            errorMessage = 'Error: ${e.message}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An unexpected error occurred'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEmailInputDialog() {
    final TextEditingController emailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Confirm Account Deletion',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _colors.error,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Please enter your email address to confirm account deletion:',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: _colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              emailController.dispose();
              Navigator.pop(context);
            },
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: _colors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              final email = emailController.text.trim();
              if (email.isEmpty || !email.contains('@')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid email address'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              Navigator.pop(context);
              emailController.dispose();
              
              // Call the delete function after closing the dialog
              _deleteGmailAccount(email);
            },
            child: Text(
              'Delete Account',
              style: GoogleFonts.inter(
                color: _colors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteGmailAccount(String email) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Deleting account...'),
          ],
        ),
      ),
    );
    
    try {
      // Delete Gmail-based account
      await _firebaseService.deleteGmailBasedAccount(email);
      
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }
      
      if (mounted) {
        _showSuccessSnackBar('Account deleted successfully');
        
        // Navigate to login page immediately
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildAccountSection() {
    return Column(
      children: [
        _buildSettingsItem(
          title: 'My Profile',
          subtitle: 'View and edit your profile information',
          icon: Icons.person_outline,
          onTap: () => _navigateToProfile(),
          showArrow: true,
        ),        
        const SizedBox(height: 12),
        _buildSettingsItem(
          title: 'Account & Security',
          subtitle: 'Password, privacy, and security settings',
          icon: Icons.security_outlined,
          onTap: () => _handleSettingsTap('Account & Security'),
          showArrow: true,
        ),
        const SizedBox(height: 12),
        _buildSettingsItem(
          title: 'Delete Account',
          subtitle: 'Permanently delete your account',
          icon: Icons.delete_forever,
          onTap: _showDeleteAccountDialog,
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildPreferencesSection() {
    return Column(
      children: [
        _buildSettingsItem(
          title: 'Pomodoro Preferences',
          subtitle: 'Customize your focus and break timers',
          icon: Icons.timer_outlined,
          onTap: () => _navigateToPomodoroPreferences(),
          showArrow: true,
        ),
        const SizedBox(height: 12),
        _buildSettingsItem(
          title: 'Date & Time',
          subtitle: 'Time zone and format preferences',
          icon: Icons.schedule_outlined,
          onTap: () => _handleSettingsTap('Date & Time'),
          showArrow: true,
        ),
        const SizedBox(height: 12),
        _buildToggleSettingsItem(
          title: 'Notifications',
          subtitle: 'Push notifications and alerts',
          icon: Icons.notifications_outlined,
          value: _notificationsEnabled,
          onChanged: (value) {
            HapticFeedback.lightImpact();
            setState(() {
              _notificationsEnabled = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSystemSection() {
    return Column(
      children: [
        _buildSettingsItem(
          title: 'App Appearance',
          subtitle: 'Theme, colors, and display settings',
          icon: Icons.palette_outlined,
          onTap: () => _showThemeSelector(),
          showArrow: true,
          trailing: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _colors.border),
              boxShadow: _isDarkMode ? null : [
                BoxShadow(
                  color: _colors.shadow,
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              _selectedThemeMode.name.replaceFirst(_selectedThemeMode.name[0], _selectedThemeMode.name[0].toUpperCase()),
              style: GoogleFonts.inter(
                fontSize: 12,
                color: _colors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSupportSection() {
    return Column(
      children: [
        _buildSettingsItem(
          title: 'Help & Support',
          subtitle: 'FAQs, tutorials, and contact support',
          icon: Icons.help_outline,
          onTap: () => _handleSettingsTap('Help & Support'),
          showArrow: true,
        ),
        const SizedBox(height: 12),
        _buildSettingsItem(
          title: 'About',
          subtitle: 'Version info and legal information',
          icon: Icons.info_outline,
          onTap: () => _handleSettingsTap('About'),
          showArrow: true,
        ),
      ],
    );
  }

  Widget _buildSessionSection() {
    return Column(
      children: [
        _buildSettingsItem(
          title: 'Log Out',
          subtitle: 'Sign out of your account',
          icon: Icons.logout,
          onTap: () => _showLogoutDialog(),
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildSettingsItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool showArrow = false,
    bool isDestructive = false,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _colors.border,
                width: 1,
              ),
              boxShadow: _isDarkMode ? null : [
                BoxShadow(
                  color: _colors.shadow,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDestructive
                        ? _colors.error.withValues(alpha: 0.1)
                        : _colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: isDestructive 
                        ? _colors.error 
                        : _colors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isDestructive ? _colors.error : _colors.onSurface,
                        ),
                        child: Text(title),
                      ),
                      const SizedBox(height: 2),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: _colors.onSurfaceVariant,
                        ),
                        child: Text(subtitle),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing,
                ],
                if (showArrow) ...[
                  const SizedBox(width: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: _colors.onSurfaceVariant,
                      size: 16,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleSettingsItem({
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
          color: _colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _colors.border,
            width: 1,
          ),
          boxShadow: _isDarkMode ? null : [
            BoxShadow(
              color: _colors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: _colors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _colors.onSurface,
                    ),
                    child: Text(title),
                  ),
                  const SizedBox(height: 2),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: _colors.onSurfaceVariant,
                    ),
                    child: Text(subtitle),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: _colors.primary,
                activeTrackColor: _colors.primary.withValues(alpha: 0.3),
                inactiveThumbColor: _isDarkMode ? const Color(0xFF666666) : const Color(0xFFBBBBBB),
                inactiveTrackColor: _isDarkMode ? const Color(0xFF333333) : const Color(0xFFE0E0E0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToProfile() {
    HapticFeedback.mediumImpact();
    // Navigate to profile screen
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
            const ProfileScreen(),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  void _showThemeSelector() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: _colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: _isDarkMode ? null : [
            BoxShadow(
              color: _colors.shadow,
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _colors.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose Theme',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildThemeOption('Dark', Icons.dark_mode, AppThemeMode.dark),
                  _buildThemeOption('Light', Icons.light_mode, AppThemeMode.light),
                  _buildThemeOption('System', Icons.settings_brightness, AppThemeMode.system),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(String theme, IconData icon, AppThemeMode themeMode) {
    final isSelected = _selectedThemeMode == themeMode;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _selectedThemeMode = themeMode;
        });
        Navigator.pop(context);
        _showSuccessSnackBar('Theme changed to $theme');
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? _colors.primary.withValues(alpha: 0.1)
              : (_isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? _colors.primary
                : _colors.border,
            width: 1,
          ),
          boxShadow: _isDarkMode ? null : [
            if (!isSelected) BoxShadow(
              color: _colors.shadow,
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected 
                  ? _colors.primary
                  : _colors.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              theme,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isSelected ? _colors.onSurface : _colors.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(
                Icons.check,
                color: _colors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  void _navigateToPomodoroPreferences() {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const PomodoroPreferencesScreen(),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  void _handleSettingsTap(String setting) {
    String title = setting;
    String content = '';
    Widget? customContent;
    switch (setting) {
      case 'Account & Security':
        content = 'Manage your password, privacy, and security settings here. (Feature coming soon)';
        break;
      case 'Date & Time':
        content = 'Set your time zone and date/time format preferences. (Feature coming soon)';
        break;
      case 'Help & Support':
        customContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Frequently Asked Questions',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: _colors.onSurface)),
            const SizedBox(height: 16),
            _buildFAQItem('How do I reset my password?',
                'On the login screen, tap "Forgot Password" and follow the instructions.'),
            _buildFAQItem('Is my data secure?',
                'Absolutely. We use industry-standard encryption to protect your data and never share it with third parties.'),
            _buildFAQItem('How do I delete my account?',
                'Go to Settings > Account > Delete Account. Note that this action is irreversible.'),
          ],
        );
        break;
      case 'About':
        content = '4bit Hackit\nVersion 1.0.0\n\nMade with ❤️.';
        break;
      default:
        content = '$setting opened.';
    }
    showDialog(
      context: context,
      builder: (context) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: AlertDialog(
          backgroundColor: _colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _colors.onSurface,
            ),
          ),
          content: customContent ?? Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: _colors.onSurfaceVariant,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: GoogleFonts.inter(
                  color: _colors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _colors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            answer,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: _colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: AlertDialog(
          backgroundColor: _colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Log Out',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _colors.onSurface,
            ),
          ),
          content: Text(
            'Are you sure you want to log out?',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: _colors.onSurfaceVariant,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  color: _colors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _firebaseService.signOut();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to sign out'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
              child: Text(
                'Log Out',
                style: GoogleFonts.inter(
                  color: _colors.error,
                  fontWeight: FontWeight.w500,
                ),
                // do the log out logic with firebase 
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              message,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: _colors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}