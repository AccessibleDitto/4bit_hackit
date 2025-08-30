import 'package:flutter/material.dart';
import 'services/firebase_service.dart';
import 'register.dart';
// import 'calendar_page.dart';

// Firebase Authentication login page
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  String? _errorMessage;
  bool _isLoading = false;

  void _login() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter both email and password.';
        _isLoading = false;
      });
      return;
    }

    try {
      // Test Firestore connection and retrieve data
      await _firebaseService.testFirestoreConnection();
      
      // Get all users from Firestore
      List<Map<String, dynamic>> users = await _firebaseService.getAllUsers();
      debugPrint('Found ${users.length} users in Firestore');
      
      // Get all tasks from Firestore
      List<Map<String, dynamic>> tasks = await _firebaseService.getAllTasks();
      debugPrint('Found ${tasks.length} tasks in Firestore');
      
      // Check if user with this email exists and password matches
      Map<String, dynamic>? matchingUser;
      for (var user in users) {
        if (user['email'] == _emailController.text.trim()) {
          matchingUser = user;
          break;
        }
      }
      
      if (matchingUser != null) {
        // Check if password matches
        if (matchingUser['password'] == _passwordController.text.trim()) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Login successful! Welcome back.'),
                backgroundColor: Colors.green,
              ),
            );
            
            Navigator.pushReplacementNamed(context, '/home');
          }
        } else {
          setState(() {
            _errorMessage = 'Incorrect password. Please try again.';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'User not found. Please register first.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Firestore connection failed: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF181829),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2D223A),
          hintStyle: const TextStyle(color: Colors.white70),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
          titleLarge: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF8F5CF7),
            foregroundColor: Colors.white,
            shape: const StadiumBorder(),
            padding: EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: Color(0xFFFFA726)),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF8F5CF7),
        ).copyWith(secondary: Color(0xFFFFA726)),
      ),
      child: Scaffold(
        appBar: AppBar(
          leading: Navigator.canPop(context)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                )
              : null,
        ),
        body: Container(
          margin: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _header(context),
              _inputField(context),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              _signup(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Column(
      children: const [
        Text(
          "Welcome Back",
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8),
        Text(
          "Enter your credential to login",
          style: TextStyle(color: Colors.white70),
        ),
      ],
    );
  }

  Widget _inputField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _emailController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Email",
            prefixIcon: const Icon(Icons.email, color: Color(0xFF8F5CF7)),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _passwordController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Password",
            prefixIcon: const Icon(Icons.password, color: Color(0xFF8F5CF7)),
          ),
          obscureText: true,
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _isLoading ? null : _login,
          child: _isLoading 
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text("Login"),
        ),
      ],
    );
  }

  Widget _signup(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Don't have an account? ",
          style: TextStyle(color: Colors.white70),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SignupPage()),
            );
          },
          child: const Text(
            "Sign Up",
            style: TextStyle(color: Color(0xFFFFA726)),
          ),
        ),
      ],
    );
  }
}