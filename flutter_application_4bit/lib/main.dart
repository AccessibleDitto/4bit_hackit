import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_4bit/register.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login.dart';
import 'dart:ui';
import 'tasks.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Khronofy App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        textTheme: GoogleFonts.interTextTheme(),
      ),
      home: const MyHomePage(title: 'Khronofy'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _cardController;
  late AnimationController _particleController;
  
  late Animation<double> _logoAnimation;
  late Animation<Offset> _logoSlideAnimation;
  late Animation<double> _cardAnimation;
  late Animation<Offset> _cardSlideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _particleController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    // Initialize animations
    _logoAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutBack,
    );
    
    _logoSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutQuart,
    ));

    _cardAnimation = CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOutBack,
    );
    
    _cardSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOutQuart,
    ));

    // Start animations
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _cardController.forward();
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _cardController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            // Animated background particles
            _buildAnimatedBackground(),
            
            // Main content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    
                    // Logo section
                    SlideTransition(
                      position: _logoSlideAnimation,
                      child: FadeTransition(
                        opacity: _logoAnimation,
                        child: ScaleTransition(
                          scale: _logoAnimation,
                          child: _buildLogoSection(),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 60),
                    
                    // Onboarding card
                    SlideTransition(
                      position: _cardSlideAnimation,
                      child: FadeTransition(
                        opacity: _cardAnimation,
                        child: ScaleTransition(
                          scale: _cardAnimation,
                          child: _buildOnboardingCard(),
                        ),
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Footer
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return Stack(
          children: List.generate(12, (index) {
            final progress = (_particleController.value + (index * 0.1)) % 1.0;
            final screenHeight = MediaQuery.of(context).size.height;
            final screenWidth = MediaQuery.of(context).size.width;
            
            return Positioned(
              left: (index * screenWidth / 12) % screenWidth,
              top: screenHeight - (progress * (screenHeight + 100)),
              child: Opacity(
                opacity: progress < 0.1 ? progress * 10 : 
                        progress > 0.9 ? (1 - progress) * 10 : 1.0,
                child: Container(
                  width: 4 + (index % 3) * 2,
                  height: 4 + (index % 3) * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF9333EA).withOpacity(0.8),
                        const Color(0xFF9333EA).withOpacity(0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        // App Icon
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9333EA).withOpacity(0.4),
                blurRadius: 40,
                spreadRadius: 10,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 56,
            backgroundColor: Colors.white.withOpacity(0.1),
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [
                  Color(0xFF9333EA),
                  Color(0xFFC084FC),
                  Color(0xFF8B5CF6),
                ],
              ).createShader(bounds),
              child: const Icon(
                Icons.access_time,
                size: 56,
                color: Colors.white,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Welcome text
        Text(
          'Welcome to',
          style: GoogleFonts.inter(
            fontSize: 20,
            color: const Color(0xFFA1A1AA),
            fontWeight: FontWeight.w400,
          ),
        ),
        
        const SizedBox(height: 8),
        
        // App name with shader
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFF9333EA),
              Color(0xFFC084FC),
              Color(0xFF8B5CF6),
            ],
          ).createShader(bounds),
          child: Text(
            'Khronofy',
            style: GoogleFonts.pacifico(
              fontSize: 48,
              fontWeight: FontWeight.w400,
              color: Colors.white,
              letterSpacing: -1,
              height: 1.0,
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Gradient underline
        Container(
          width: 80,
          height: 3,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: const LinearGradient(
              colors: [
                Colors.transparent,
                Color(0xFF9333EA),
                Colors.transparent,
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Tagline
        Text(
          'Your time, beautifully managed.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 16,
            color: const Color(0xFFA1A1AA),
            fontWeight: FontWeight.w300,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildOnboardingCard() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF18181B).withOpacity(0.9),
            const Color(0xFF18181B).withOpacity(0.7),
          ],
        ),
        border: Border.all(
          color: const Color(0xFF9333EA).withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.8),
            blurRadius: 50,
            offset: const Offset(0, 25),
          ),
          BoxShadow(
            color: const Color(0xFF9333EA).withOpacity(0.1),
            blurRadius: 100,
            spreadRadius: 10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Text(
                  'Get Started',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Sign Up Button
                _buildPrimaryButton(
                  'Sign Up',
                  onPressed: _handleSignUp,
                ),
                
                const SizedBox(height: 16),
                
                // Divider
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              const Color(0xFF9333EA).withOpacity(0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'or',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF71717A),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              const Color(0xFF9333EA).withOpacity(0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Login Button
                _buildSecondaryButton(
                  'Login',
                  onPressed: _handleLogin,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(String text, {required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF9333EA), Color(0xFF7C3AED)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9333EA).withOpacity(0.4),
                blurRadius: 25,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Container(
            alignment: Alignment.center,
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(String text, {required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFF27272A).withOpacity(0.8),
          foregroundColor: Colors.white,
          side: BorderSide(
            color: const Color(0xFF9333EA).withOpacity(0.3),
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: () => _showBottomSheet('Terms of Service'),
            child: Text(
              'Terms',
              style: GoogleFonts.inter(
                color: const Color(0xFF9333EA),
                fontSize: 14,
              ),
            ),
          ),
          Text(
            '•',
            style: GoogleFonts.inter(
              color: const Color(0xFF71717A),
              fontSize: 14,
            ),
          ),
          TextButton(
            onPressed: () => _showBottomSheet('Privacy Policy'),
            child: Text(
              'Privacy',
              style: GoogleFonts.inter(
                color: const Color(0xFF9333EA),
                fontSize: 14,
              ),
            ),
          ),
          Text(
            '•',
            style: GoogleFonts.inter(
              color: const Color(0xFF71717A),
              fontSize: 14,
            ),
          ),
          TextButton(
            onPressed: () => _showBottomSheet('Support'),
            child: Text(
              'Support',
              style: GoogleFonts.inter(
                color: const Color(0xFF9333EA),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSignUp() async {
    HapticFeedback.lightImpact();
    
    // Navigate to your existing SignupPage
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SignupPage()),
    );
  }

  void _handleLogin() async {
    HapticFeedback.lightImpact();
    
    // Navigate to your existing LoginPage
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  void _showBottomSheet(String title) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF18181B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF18181B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF71717A),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Title
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _getContentForTitle(title),
                ),
              ),
              
              // Close button
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9333EA),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Close',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
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

  Widget _getContentForTitle(String title) {
    switch (title) {
      case 'Terms of Service':
        return _buildTermsContent();
      case 'Privacy Policy':
        return _buildPrivacyContent();
      case 'Support':
        return _buildSupportContent();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTermsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Acceptance of Terms'),
        _buildSectionText(
          'By downloading, accessing, or using the Khronofy mobile application, you agree to be bound by these Terms of Service and all applicable laws and regulations.'
        ),
        
        _buildSectionTitle('Use License'),
        _buildSectionText(
          'Permission is granted to temporarily use Khronofy for personal, non-commercial transitory viewing only. This license shall automatically terminate if you violate any of these restrictions.'
        ),
        
        _buildSectionTitle('User Accounts'),
        _buildSectionText(
          'You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account. You must notify us immediately of any unauthorized use.'
        ),
        
        _buildSectionTitle('Privacy'),
        _buildSectionText(
          'Your privacy is important to us. Please review our Privacy Policy, which also governs your use of the Service, to understand our practices.'
        ),
        
        _buildSectionTitle('Prohibited Uses'),
        _buildSectionText(
          'You may not use Khronofy for any unlawful purpose or to solicit others to perform unlawful acts. You may not violate any international, federal, provincial, or state regulations, rules, or laws.'
        ),
        
        _buildSectionTitle('Modifications'),
        _buildSectionText(
          'Khronofy reserves the right to revise these terms of service at any time without notice. By using this app, you are agreeing to be bound by the current version of these terms.'
        ),
        
        const SizedBox(height: 24),
        
        Text(
          'Last updated: ${DateTime.now().toString().split(' ')[0]}',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF71717A),
            fontStyle: FontStyle.italic,
          ),
        ),
        
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildPrivacyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Information We Collect'),
        _buildSectionText(
          'We collect information you provide directly to us, such as when you create an account, use our time management features, or contact us for support.'
        ),
        
        _buildSectionTitle('How We Use Your Information'),
        _buildSectionText(
          'We use the information we collect to:\n\n• Provide, maintain, and improve our services\n• Process transactions and send related information\n• Send technical notices and support messages\n• Respond to your comments and questions'
        ),
        
        _buildSectionTitle('Information Sharing'),
        _buildSectionText(
          'We do not sell, trade, or otherwise transfer your personal information to third parties without your consent, except as described in this policy.'
        ),
        
        _buildSectionTitle('Data Security'),
        _buildSectionText(
          'We implement appropriate technical and organizational measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.'
        ),
        
        _buildSectionTitle('Data Retention'),
        _buildSectionText(
          'We retain your personal information only for as long as necessary to provide you with our services and as described in this Privacy Policy.'
        ),
        
        _buildSectionTitle('Your Rights'),
        _buildSectionText(
          'You have the right to access, update, or delete your personal information. You may also object to or restrict certain processing of your data.'
        ),
        
        _buildSectionTitle('Contact Us'),
        _buildSectionText(
          'If you have any questions about this Privacy Policy, please contact us at privacy@khronofy.com'
        ),
        
        const SizedBox(height: 24),
        
        Text(
          'Last updated: ${DateTime.now().toString().split(' ')[0]}',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF71717A),
            fontStyle: FontStyle.italic,
          ),
        ),
        
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSupportContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Frequently Asked Questions'),
        
        _buildFAQItem(
          'How do I reset my password?',
          'On the login screen, tap "Forgot Password" and follow the instructions.',
        ),
        
        _buildFAQItem(
          'Is my data secure?',
          'Absolutely. We use industry-standard encryption to protect your data and never share it with third parties.',
        ),
        
        _buildFAQItem(
          'How do I delete my account?',
          'Go to Settings > Account > Delete Account. Note that this action is irreversible.',
        ),
        
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSectionText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 14,
          color: const Color(0xFFA1A1AA),
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF27272A).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF9333EA).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFFA1A1AA),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String title, String subtitle, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF27272A).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF9333EA).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF9333EA).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF9333EA),
              size: 24,
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
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF9333EA),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF71717A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}