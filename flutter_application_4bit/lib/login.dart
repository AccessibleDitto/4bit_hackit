import 'package:flutter/material.dart'; // Import Flutter Material widgets and themes
import 'package:cloud_firestore/cloud_firestore.dart';
// Initialize Firestore instance

final db = FirebaseFirestore.instance; // Initialize Firestore instance

// Define a stateful widget for the login page
class LoginPage extends StatefulWidget {
  const LoginPage({super.key}); // Constructor with optional key for widget identity

  @override
  State<LoginPage> createState() => _LoginPageState(); // Link the widget to its state
}

// State class that holds data and logic for the LoginPage widget
class _LoginPageState extends State<LoginPage> {
  // Global key to uniquely identify the Form widget and allow form validation/saving
  final _formKey = GlobalKey<FormState>();

  // Variables to store user input
  String _email = '';
  String _password = '';

  // Controls whether the password is hidden or visible
  bool _obscureText = true;

  // Function to handle login button press
  void _login() {
    // Validate the form fields
    if (_formKey.currentState!.validate()) {
      // Save the form fields (triggers onSaved for each field)
      _formKey.currentState!.save();
      db.collection('users').doc(_email).set({// Save email and password to Firestore
        'password': _password,
      }).then(
        (value) =>       showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Login Info'),
          content: Text('Email: $_email\nPassword: $_password'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Close the dialog
              child: const Text('OK'),
            ),
          ],
        ),
      ), // Print success message on successful addition
      ).catchError(
        (error) => print("Failed to add user: $error"));
      // Show a dialog displaying the entered email and password

    }
  }
  void _forgetPassword() {
    // Logic to handle password reset or forget password functionality
    db.collection('users').doc(_email).get().then((doc) {
      if (doc.exists) {
        // If the user exists, show a dialog with the email
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Forgot Password'),
            content: Text(doc.data()?["password"] ?? 'No password set for this user.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), // Close the dialog
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        // If the user does not exist, show an error message
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: const Text('User does not exist. Please sign up first.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), // Close the dialog
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')), // App bar with title
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0), // Add padding around the form
          child: Form(
            key: _formKey, // Connect form with the global key for validation
            child: Column(
              mainAxisSize: MainAxisSize.max, // Column takes only as much space as needed
              children: [
                // Add a text box above the text fields
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Join xxx Today \u{1F464}',
                    style: TextStyle(
                      fontSize: 20, // Font size for the text
                      color: Colors.blue, // Text color
                      fontWeight: FontWeight.bold, // Make the text bold
                      ),
                    textAlign: TextAlign.left,
                  ),
                ),
                const SizedBox(height: 24), // Space between text and fields

                // Email input field
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Email', // Label above the field
                    border: OutlineInputBorder(), // Outline border
                  ),
                  keyboardType: TextInputType.emailAddress, // Email-specific keyboard
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Enter your email' : null, // Validation
                  onSaved: (value) => _email = value ?? '', // Save input to _email
                ),
                const SizedBox(height: 16), // Space between fields

                // Password input field
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Password', // Label above the field
                    border: const OutlineInputBorder(),
                    // Add an eye icon to toggle visibility
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          // Toggle password visibility and update UI
                          _obscureText = !_obscureText;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscureText, // Hide text when true
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Enter your password' : null, // Validation
                  onSaved: (value) => _password = value ?? '', // Save input to _password
                ),
                const SizedBox(height: 24), // Space before button

                // Full-width login button
                SizedBox(
                  width: double.infinity, // Button stretches full width
                  child: ElevatedButton(
                    onPressed: _login, // Call _login function when pressed
                    child: const Text('Login'), // Button label
                  ),
                ),
                const SizedBox(height: 16), // Space before forget password button
                // Full-width forget password button
                SizedBox(
                  width: double.infinity, // Button stretches full width
                  child: ElevatedButton(
                    onPressed: _forgetPassword, // Call _forgetPassword function when pressed
                    child: const Text('Forget Password'), // Button label
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
