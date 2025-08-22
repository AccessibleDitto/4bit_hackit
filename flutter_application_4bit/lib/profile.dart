import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _editAnimationController;
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

  // Sample data
  String _currentFullName = 'Albert Einstein';
  String _currentUsername = 'alberteinstein';
  String _currentGender = 'Male';

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
    
    // Initialize form with current data
    _fullNameController.text = _currentFullName;
    _usernameController.text = _currentUsername;
    _selectedGender = _currentGender;

    // Animation setup
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _editAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _editModeAnimation = CurvedAnimation(
      parent: _editAnimationController,
      curve: Curves.easeInOut,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    // Start animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _editAnimationController.dispose();
    _fullNameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
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
                        children: [
                          const SizedBox(height: 20),
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: _buildProfileSection(),
                          ),
                          const SizedBox(height: 30),
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
                    ? const Color(0xFFFF8C42).withOpacity(0.1)
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
                              color: const Color(0xFFFF8C42).withOpacity(0.3),
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
                              color: const Color(0xFFFF8C42).withOpacity(0.4),
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
            color: const Color(0xFFFF8C42).withOpacity(0.1),
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
            onTap: () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(
                        Icons.share,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Profile shared!',
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(
                        Icons.qr_code,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'QR code generated!',
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

  Future<void> _saveChanges() async {
    setState(() {
      _isSaving = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 1500));

    // Update current data with form data
    _currentFullName = _fullNameController.text.trim();
    _currentUsername = _usernameController.text.trim();
    _currentGender = _selectedGender;

    setState(() {
      _isSaving = false;
    });

    // Show success message
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
                  const SizedBox(height: 20),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
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
                                ? const Color(0xFFFF8C42).withOpacity(0.2)
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
}