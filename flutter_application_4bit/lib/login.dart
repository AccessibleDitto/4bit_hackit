import 'package:flutter/material.dart';
import 'register.dart';
// import 'calendar_page.dart';
import 'homepage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _errorMessage;

  // just sample user for demonstration
  final String _mockUsername = 'user';
  final String _mockPassword = '123';

  void _login() {
    setState(() {
      _errorMessage = null;
      if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
        _errorMessage = 'Please enter both username and password.';
      } else if (_usernameController.text != _mockUsername || _passwordController.text != _mockPassword) {
        _errorMessage = 'Invalid username or password.';
      } else {
        _errorMessage = null;
        // Will change this to navigate to home page after successful login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const TimerModePage(),
          ),
        );
        _usernameController.clear();
        _passwordController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
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
      home: Scaffold(
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

  _header(context) {
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

  _inputField(context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _usernameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Username",
            prefixIcon: const Icon(Icons.person, color: Color(0xFF8F5CF7)),
          ),
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
        ElevatedButton(onPressed: _login, child: const Text("Login")),
      ],
    );
  }

  _signup(context) {
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
