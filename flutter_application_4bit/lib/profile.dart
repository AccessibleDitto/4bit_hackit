import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/user_stats_service.dart';
import 'services/firebase_service.dart';
import 'theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _editAnimationController;
  late TabController _tabController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _editModeAnimation;
  late Animation<double> _scaleAnimation;

  // Form controllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  
  String _selectedGender = 'Prefer not to say';
  String _selectedAvatar = '👤';
  bool _isEditing = false;
  bool _isSaving = false;

  // User stats instance
  final UserStats _userStats = UserStats();
  final FirebaseService _firebaseService = FirebaseService();

  String _currentFullName = 'User';
  String _currentUsername = 'user';
  String _currentGender = 'Prefer not to say';
  String _joinedDate = 'Recently';
  String? _currentUserEmail;

  final List<String> _genderOptions = [
    'Male',
    'Female',
    'Non-binary',
    'Prefer not to say'
  ];

  final List<String> _avatarOptions = [
    '👤', '👨', '👩', '🧑', '👨‍💼', '👩‍💼', '👨‍🎓', '👩‍🎓',
    '👨‍💻', '👩‍💻', '🧑‍💻', '👨‍🔬', '👩‍🔬', '👨‍🎨', '👩‍🎨', '🧑‍🎨'
  ];

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _editAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400), 
      vsync: this,
    );

    _tabController = TabController(length: 2, vsync: this);

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

    _editModeAnimation = CurvedAnimation(
      parent: _editAnimationController,
      curve: Curves.easeInOut,
    );

    _fullNameController.text = _currentFullName;
    _usernameController.text = _currentUsername;
    _selectedGender = _currentGender;

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _loadUserData();
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _editAnimationController.dispose();
    _tabController.dispose();
    _fullNameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            ScaleTransition(
              scale: _scaleAnimation,
              child: _buildProfileSection(),
            ),
            const SizedBox(height: 20),
            _buildTabBar(),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPersonalDetailsTab(),
                      _buildAchievementsTab(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Hero(
            tag: 'back_button',
            child: Material(
              color: Colors.transparent,
              child: IconButton(
                onPressed: () {
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
          ),
          const Spacer(),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: _isEditing ? const Color(0xFFFF8C42) : Colors.white,
            ),
            child: const Text('Profile'),
          ),
          const Spacer(),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            child: IconButton(
              onPressed: _isSaving ? null : _toggleEditMode,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF8C42)),
                      ),
                    )
                  : AnimatedRotation(
                      turns: _isEditing ? 0.125 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        _isEditing ? Icons.check : Icons.edit,
                        color: _isEditing ? const Color(0xFFFF8C42) : Colors.white,
                        size: 20,
                      ),
                    ),
              style: IconButton.styleFrom(
                backgroundColor: _isEditing 
                    ? const Color(0xFFFF8C42).withValues(alpha:0.1)
                    : const Color(0xFF1E1E1E),
                padding: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: _isEditing ? _showAvatarSelector : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            child: Stack(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isEditing 
                          ? const Color(0xFFFF8C42) 
                          : const Color(0xFF333333),
                      width: _isEditing ? 2 : 1,
                    ),
                    boxShadow: _isEditing
                        ? [
                            BoxShadow(
                              color: const Color(0xFFFF8C42).withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      _selectedAvatar,
                      style: const TextStyle(fontSize: 50),
                    ),
                  ),
                ),
                if (_isEditing)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: AnimatedScale(
                      scale: _isEditing ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.elasticOut,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF8C42),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF121212),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF8C42).withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _isEditing
              ? Column(
                  key: const ValueKey('editing'),
                  children: [
                    Text(
                      'Edit your profile',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: const Color(0xFF888888),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                )
              : Column(
                  key: const ValueKey('display'),
                  children: [
                    Text(
                      _currentFullName,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@$_currentUsername',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: const Color(0xFFFF8C42),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF333333),
                        ),
                      ),
                      child: Text(
                        _currentGender,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF888888),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildEditableFields() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF333333),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF8C42).withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.edit_outlined,
                color: const Color(0xFFFF8C42),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Edit Profile',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          _buildTextFormField(
            controller: _fullNameController,
            label: 'Full Name',
            icon: Icons.person_outline,
          ),
          
          const SizedBox(height: 16),
          
          _buildTextFormField(
            controller: _usernameController,
            label: 'Username',
            icon: Icons.alternate_email,
          ),
          
          const SizedBox(height: 16),
          
          _buildGenderSelector(),
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? prefix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF888888),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF333333),
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: controller,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white,
            ),
            onTap: () => HapticFeedback.lightImpact(),
            decoration: InputDecoration(
              prefixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 16),
                  Icon(
                    icon,
                    color: const Color(0xFFFF8C42),
                    size: 20,
                  ),
                  if (prefix != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      prefix,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: const Color(0xFF888888),
                      ),
                    ),
                  ],
                  const SizedBox(width: 12),
                ],
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF888888),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF333333),
              width: 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedGender,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Color(0xFFFF8C42),
              ),
              dropdownColor: const Color(0xFF2A2A2A),
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.white,
              ),
              items: _genderOptions.map((String gender) {
                return DropdownMenuItem<String>(
                  value: gender,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        color: Color(0xFFFF8C42),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(gender),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _selectedGender = newValue;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF333333),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildQuickActionButton(
            icon: Icons.share_outlined,
            label: 'Share Profile',
            onTap: () async {
              HapticFeedback.lightImpact();
              final String shareText = 'Check out my Khronofy profile!\n\nName: $_currentFullName\nUsername: $_currentUsername\nGender: $_currentGender';
              await Share.share(shareText);
            },
          ),
          Container(
            width: 1,
            height: 40,
            color: const Color(0xFF333333),
          ),
          _buildQuickActionButton(
            icon: Icons.qr_code,
            label: 'QR Code',
            onTap: () {
              HapticFeedback.lightImpact();
              showDialog(
                context: context,
                builder: (context) {
                  final String qrData = 'Name: $_currentFullName\nUsername: $_currentUsername\nGender: $_currentGender';
                  return AlertDialog(
                    backgroundColor: const Color(0xFF181829),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: const Text('Profile QR Code', style: TextStyle(color: Colors.white)),
                    content: SizedBox(
                      width: 250,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          QrImageView(
                            data: qrData,
                            version: QrVersions.auto,
                            size: 200.0,
                            backgroundColor: Colors.white,
                          ),
                          const SizedBox(height: 16),
                          SelectableText(qrData, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: const Color(0xFFFF8C42),
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF888888),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggleEditMode() async {
    HapticFeedback.mediumImpact();
    
    if (_isEditing) {
      // Save changes
      await _saveChanges();
    } else {
      // Enter edit mode
      _editAnimationController.forward();
    }
    
    setState(() {
      _isEditing = !_isEditing;
    });

    if (!_isEditing) {
      _editAnimationController.reverse();
    }
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentUserEmail = prefs.getString('current_user_email');
      
      if (_currentUserEmail == null) {
        debugPrint('Profile: No user email found, using defaults');
        _setDefaultUserData();
        return;
      }
      debugPrint('Profile: Loading user data for: $_currentUserEmail');
      final userData = await _firebaseService.loadGmailUserData(_currentUserEmail!);
      
      if (mounted) {
        _processUserData(userData);
      }
      
    } catch (error) {
      debugPrint('Profile: Error loading user data: $error');
      if (mounted) {
        _setDefaultUserData();
        _showErrorMessage('Failed to load profile data');
      }
    }
  }

  void _processUserData(Map<String, dynamic> userData) {
    final userInfo = userData['userData'] as Map<String, dynamic>?;
    
    setState(() {
      if (userInfo != null) {
        // update profile
        _currentFullName = userInfo['name'] ?? _extractNameFromEmail(_currentUserEmail!);
        _currentUsername = userInfo['username'] ?? _extractUsernameFromEmail(_currentUserEmail!);
        final loadedGender = userInfo['gender'] ?? 'Prefer not to say';
        _currentGender = loadedGender;
        _selectedGender = loadedGender;
        
        _processJoinDate(userInfo['createdAt']);
        
        // update form controllers
        _fullNameController.text = _currentFullName;
        _usernameController.text = _currentUsername;
        
        debugPrint('Profile: Successfully loaded user data for $_currentFullName');
      } else {
        _setDefaultUserData();
      }
      _loadUserStatsData();
    });
  }

  // firebase integration 
  Future<void> _loadUserStatsData() async {
    try {
      await _userStats.initializeFromFirebase();
      debugPrint('Profile: User stats loaded from Firebase successfully');
    } catch (error) {
      debugPrint('Profile: Error loading stats data: $error');
      // _userStats.initializeSampleData(); 
    }
  }

  // set default user data for fallback
  void _setDefaultUserData() {
    setState(() {
      _currentFullName = _extractNameFromEmail(_currentUserEmail ?? 'User');
      _currentUsername = _extractUsernameFromEmail(_currentUserEmail ?? 'user');
      _currentGender = 'Prefer not to say';
      _selectedGender = _currentGender;
      _fullNameController.text = _currentFullName;
      _usernameController.text = _currentUsername;
    });
  }

  void _processJoinDate(dynamic timestamp) {
    try {
      DateTime? dateTime;
      
      if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else if (timestamp is Map) {
        if (timestamp.containsKey('_seconds')) {
          final seconds = timestamp['_seconds'] as int;
          dateTime = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
        } else if (timestamp.containsKey('seconds')) {
          final seconds = timestamp['seconds'] as int;
          dateTime = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
        }
      } else if (timestamp is int) {
        dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      }
      
      if (dateTime != null) {
        _joinedDate = _formatJoinDate(dateTime);
        debugPrint('Profile: Parsed join date: $_joinedDate');
      }
    } catch (e) {
      debugPrint('Profile: Error parsing join date: $e');
      _joinedDate = 'Recently'; // fallback
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _extractNameFromEmail(String email) {
    final namePart = email.split('@')[0];
    return namePart.split('.').map((part) => 
      part.isEmpty ? '' : part[0].toUpperCase() + part.substring(1).toLowerCase()
    ).join(' ');
  }

  String _extractUsernameFromEmail(String email) {
    return email.split('@')[0].replaceAll('.', '');
  }

  String _formatJoinDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Validate form data
      if (_fullNameController.text.trim().isEmpty) {
        throw Exception('Full name cannot be empty');
      }
      
      if (_usernameController.text.trim().isEmpty) {
        throw Exception('Username cannot be empty');
      }

      // Check if we have the user email
      if (_currentUserEmail == null) {
        throw Exception('User email not found');
      }

      // Save to Firebase
      await _firebaseService.updateUserProfile(
        _currentUserEmail!,
        name: _fullNameController.text.trim(),
        username: _usernameController.text.trim(),
        gender: _selectedGender,
      );

      // Update local state after successful Firebase update
      _currentFullName = _fullNameController.text.trim();
      _currentUsername = _usernameController.text.trim();
      _currentGender = _selectedGender;

      setState(() {
        _isSaving = false;
      });

      // Show success message
      if (mounted) {
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
                  'Profile updated successfully!',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFFF8C42),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.error,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Failed to update profile: ${e.toString().replaceAll('Exception: ', '')}',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _showAvatarSelector() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF666666),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'Choose Avatar',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                    ),
                    itemCount: _avatarOptions.length,
                    itemBuilder: (context, index) {
                      final avatar = _avatarOptions[index];
                      final isSelected = avatar == _selectedAvatar;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _selectedAvatar = avatar;
                          });
                          Navigator.pop(context);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? const Color(0xFFFF8C42).withValues(alpha: 0.2)
                                : const Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected 
                                  ? const Color(0xFFFF8C42)
                                  : const Color(0xFF333333),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              avatar,
                              style: const TextStyle(fontSize: 30),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF404040), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: const Color(0xFFFF8C42),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF8C42).withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF999999),
        labelStyle: GoogleFonts.inter(
          fontSize: isSmallScreen ? 10 : 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: isSmallScreen ? 10 : 13,
          fontWeight: FontWeight.w500,
        ),
        tabs: [
          Tab(
            height: 42,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_outline, size: isSmallScreen ? 14 : 18),
                SizedBox(width: isSmallScreen ? 3 : 6),
                Flexible(
                  child: Text(
                    'Personal',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Tab(
            height: 42,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emoji_events_outlined, size: isSmallScreen ? 14 : 18),
                SizedBox(width: isSmallScreen ? 3 : 6),
                Flexible(
                  child: Text(
                    'Achievements',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalDetailsTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _editModeAnimation,
              builder: (context, child) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  height: _isEditing ? null : 0,
                  child: AnimatedOpacity(
                    opacity: _isEditing ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 400),
                    child: _buildEditableFields(),
                  ),
                );
              },
            ),
            if (_isEditing) const SizedBox(height: 30),
            _buildQuickActions(),
            const SizedBox(height: 20),
            _buildPersonalInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsTab() {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 3 : 20),
        child: Column(
          children: [
            _buildStatsGrid(),
            SizedBox(height: isSmallScreen ? 3 : 30),
            _buildBadgesSection(),
            SizedBox(height: isSmallScreen ? 3 : 30),
            _buildRecentAchievements(),
            SizedBox(height: isSmallScreen ? 1 : 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Information',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          _buildInfoRow('Full Name', _currentFullName, Icons.person),
          const SizedBox(height: 16),
          _buildInfoRow('Username', '@$_currentUsername', Icons.alternate_email),
          const SizedBox(height: 16),
          _buildInfoRow('Gender', _currentGender, Icons.wc),
          const SizedBox(height: 16),
          _buildInfoRow('Joined', _joinedDate, Icons.calendar_today),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFF8C42).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFFFF8C42),
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF888888),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: isSmallScreen ? 8 : 20,
      crossAxisSpacing: isSmallScreen ? 8 : 20,
      childAspectRatio: isSmallScreen ? 1.1 : 1.0,
      children: [
        _buildStatCard('Pomodoros\nCompleted', '${_userStats.pomodorosCompleted}', Icons.timer, const Color(0xFFFF8C42)),
        _buildStatCard('Total Focus\nTime', _userStats.totalFocusTime, Icons.access_time, const Color(0xFF10B981)),
        _buildStatCard('Streak\nDays', '${_userStats.streakDays}', Icons.local_fire_department, const Color(0xFFF59E0B)),
        _buildStatCard('Tasks\nCompleted', '${_userStats.tasksCompleted}', Icons.check_circle, const Color(0xFF8B5CF6)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 8 : 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 20),
        border: Border.all(color: const Color(0xFF333333)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: isSmallScreen ? 4 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 6 : 16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 16),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: isSmallScreen ? 40: 46,
            ),
          ),
          SizedBox(height: isSmallScreen ? 6 : 16),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: isSmallScreen ? 14 : 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          SizedBox(height: isSmallScreen ? 3 : 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: isSmallScreen ? 12 : 14,
              color: const Color(0xFF888888),
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesSection() {
    final allBadges = _userStats.allAvailableBadges;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF333333)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8C42).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: Color(0xFFFF8C42),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Badges Earned',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8C42).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_userStats.earnedBadges.length}/${allBadges.length}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFF8C42),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: constraints.maxWidth > 400 ? 1.6 : 1.3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: allBadges.length,
                itemBuilder: (context, index) {
                  final badgeId = allBadges[index];
                  final isEarned = _userStats.earnedBadges.contains(badgeId);
                  final badge = _userStats.getBadgeInfo(badgeId);
                  return _buildEnhancedBadge(badge.emoji, badge.title, badge.description, isEarned);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedBadge(String emoji, String title, String description, bool isEarned) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isEarned 
          ? const Color(0xFF2A2A2A)
          : const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEarned 
            ? const Color(0xFFFF8C42).withValues(alpha: 0.5)
            : const Color(0xFF333333),
          width: isEarned ? 2 : 1,
        ),
        boxShadow: isEarned ? [
          BoxShadow(
            color: const Color(0xFFFF8C42).withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isEarned 
                    ? const Color(0xFFFF8C42).withValues(alpha: 0.1)
                    : const Color(0xFF333333).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    emoji,
                    style: TextStyle(
                      fontSize: 12,
                      color: isEarned ? Colors.white : Colors.grey.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
              if (isEarned)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 17,
                    height: 17,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 9,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isEarned ? Colors.white : const Color(0xFF666666),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              description,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 8.5,
                color: isEarned ? const Color(0xFF999999) : const Color(0xFF555555),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAchievements() {
    final achievements = _userStats.recentAchievements;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 6 : 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF333333)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 2 : 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.history,
                  color: const Color(0xFF10B981),
                  size: isSmallScreen ? 12 : 20,
                ),
              ),
              SizedBox(width: isSmallScreen ? 4 : 12),
              Text(
                'Recent Achievements',
                style: GoogleFonts.inter(
                  fontSize: isSmallScreen ? 10 : 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 3 : 10),
          if (achievements.isEmpty)
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 6 : 20),
              child: Column(
                children: [
                  Icon(
                    Icons.star_outline,
                    size: isSmallScreen ? 20 : 48,
                    color: Colors.grey.withValues(alpha: 0.5),
                  ),
                  SizedBox(height: isSmallScreen ? 3 : 12),
                  Text(
                    'No achievements yet',
                    style: GoogleFonts.inter(
                      fontSize: isSmallScreen ? 10 : 16,
                      color: const Color(0xFF888888),
                    ),
                  ),
                  Text(
                    'Complete tasks and pomodoros to unlock achievements!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: isSmallScreen ? 10 : 16,
                      color: const Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            )
          else
            ...achievements.take(3).map((achievement) {
              final timeAgo = _getTimeAgo(achievement.timestamp);
              return Padding(
                padding: EdgeInsets.only(bottom: isSmallScreen ? 1 : 12),
                child: _buildAchievementItem(
                  achievement.emoji,
                  achievement.title,
                  achievement.description,
                  timeAgo,
                ),
              );
            }),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildAchievementItem(String emoji, String title, String description, String time) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    
    return Row(
      children: [
        Container(
          width: isSmallScreen ? 20 : 40,
          height: isSmallScreen ? 20 : 40,
          decoration: BoxDecoration(
            color: const Color(0xFFFF8C42).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Center(
            child: Text(
              emoji,
              style: TextStyle(fontSize: isSmallScreen ? 10 : 20),
            ),
          ),
        ),
        SizedBox(width: isSmallScreen ? 3 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: isSmallScreen ? 9 : 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: isSmallScreen ? 7 : 12,
                  color: const Color(0xFF888888),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
        Text(
          time,
          style: GoogleFonts.inter(
            fontSize: isSmallScreen ? 6 : 11,
            color: const Color(0xFF666666),
          ),
        ),
      ],
    );
  }
}