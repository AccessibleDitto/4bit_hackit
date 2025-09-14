import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppBarType {
  home,      // home page
  standard,  // main nav pages (tasks, report, calendar)
  settings,  // settings and profile pages with back button
}

class StandardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final AppBarType type;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;
  final Widget? leading;
  final bool showBackButton;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;
  final Widget? flexibleSpace;
  
  const StandardAppBar({
    super.key,
    required this.title,
    this.type = AppBarType.standard,
    this.actions,
    this.onBackPressed,
    this.leading,
    this.showBackButton = false,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 0,
    this.flexibleSpace,
  });

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case AppBarType.home:
        return _buildHomeAppBar(context);
      case AppBarType.standard:
        return _buildStandardAppBar(context);
      case AppBarType.settings:
        return _buildSettingsAppBar(context);
    }
  }

  Widget _buildHomeAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF9333EA), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            const Icon(
              Icons.timer,
              color: Colors.white,
              size: 24,
            ),
            Expanded(
              child: Center(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            if (actions != null) ...actions!,
          ],
        ),
      ),
    );
  }

  Widget _buildStandardAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor ?? const Color(0xFF0F0F0F),
      foregroundColor: foregroundColor ?? Colors.white,
      elevation: elevation,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF9333EA), Color(0xFF7C3AED)],
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(_getIconForTitle(title), color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      actions: actions ?? [
        const Icon(Icons.more_vert, color: Colors.white),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildSettingsAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SafeArea(
        child: Row(
          children: [
            if (showBackButton || onBackPressed != null)
              Hero(
                tag: '${title.toLowerCase()}_back_button',
                child: Material(
                  color: Colors.transparent,
                  child: IconButton(
                    onPressed: onBackPressed ?? () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 20,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF1E1E1E),
                      padding: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              )
            else if (leading != null)
              leading!
            else
              Hero(
                tag: '${title.toLowerCase()}_icon',
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getIconForTitle(title),
                      color: Colors.white,
                      size: 24,
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
                color: Colors.white,
              ),
              child: Text(title),
            ),
            const Spacer(),
            if (actions != null) ...actions! else const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  IconData _getIconForTitle(String title) {
    switch (title.toLowerCase()) {
      case 'settings':
        return Icons.settings;
      case 'profile':
        return Icons.person;
      case 'preferences':
        return Icons.tune;
      case 'report':
        return Icons.analytics;
      case 'tasks':
        return Icons.task_alt;
      // case 'calendar':
      //   return Icons.calendar_month;
      // case 'projects':
      //   return Icons.folder;
      default:
        return Icons.dashboard;
    }
  }

  @override
  Size get preferredSize {
    switch (type) {
      case AppBarType.home:
      case AppBarType.settings:
        return const Size.fromHeight(80);
      case AppBarType.standard:
        return const Size.fromHeight(56);
    }
  }
}