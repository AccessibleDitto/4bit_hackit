import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'profile.dart';
// app theme 
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
                            _buildSectionTitle('Account'),
                            _buildAccountSection(),
                            const SizedBox(height: 30),
                            _buildSectionTitle('Preferences'),
                            _buildPreferencesSection(),
                            const SizedBox(height: 30),
                            _buildSectionTitle('System'),
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
            tag: 'settings_back_button',
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
                    color: _colors.onSurface,
                    size: 20,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: _colors.surface,
                    padding: const EdgeInsets.all(12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: _colors.border),
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
              color: _colors.onBackground,
            ),
            child: const Text('Settings'),
          ),
          const Spacer(),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _colors.border),
              boxShadow: _isDarkMode ? null : [
                BoxShadow(
                  color: _colors.shadow,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.settings,
              color: _colors.primary,
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
          color: _colors.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
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
          onTap: () => _handleSettingsTap('Pomodoro Preferences'),
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
                        ? _colors.error.withOpacity(0.1)
                        : _colors.primary.withOpacity(0.1),
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
                color: _colors.primary.withOpacity(0.1),
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
                activeColor: _colors.primary,
                activeTrackColor: _colors.primary.withOpacity(0.3),
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
                color: _colors.onSurfaceVariant.withOpacity(0.3),
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
              ? _colors.primary.withOpacity(0.1)
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

  void _handleSettingsTap(String setting) {
    _showSuccessSnackBar('$setting opened');
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
              onPressed: () {
                Navigator.pop(context);
                _showSuccessSnackBar('Logged out successfully');
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