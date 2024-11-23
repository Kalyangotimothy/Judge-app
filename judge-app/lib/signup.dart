import 'dart:async'; // Import this for Timer
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:judge_app_2/database.dart';
import 'package:judge_app_2/homescreen.dart';
import 'package:judge_app_2/signin.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _fs = FirestoreService();

  bool _passwordVisible = false;
  bool _isLoading = false; // State variable for loading
  String _loadingText = ''; // State variable for loading text
  Timer? _timer; // Timer to update loading text

  String getUsernameFromEmail(String email) {
    if (email.contains('@')) {
      return email.split('@').first;
    } else {
      throw const FormatException("Invalid email format");
    }
  }

  // Function to handle user registration
  Future<void> _registerUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Show loader
        _loadingText = 'Creating your account...'; // Initial loading text
      });

      // Start timer to update loading text every 5 seconds
      _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
        setState(() {
          _loadingText = 'Still creating your account...'; // Update text
        });
      });

      try {
        String username = getUsernameFromEmail(_emailController.text.trim());

        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Create categories in parallel
        List<String> categoryIds = await Future.wait([
          _fs.addCategory(userCredential.user!.uid, "Toto", 1),
          _fs.addCategory(userCredential.user!.uid, "Mini", 2),
          _fs.addCategory(userCredential.user!.uid, "Little", 3),
          _fs.addCategory(userCredential.user!.uid, "Teen", 4),
        ]);

        // Add students in parallel for each category
        List<Future<void>> addStudentFutures = [];
        for (var categoryId in categoryIds) {
          for (var i = 1; i < 101; i++) {
            addStudentFutures
                .add(_fs.addStudent(userCredential.user!.uid, categoryId, i));
          }
        }
        // Wait for all student addition futures to complete
        await Future.wait(addStudentFutures);

        // Stop the timer and reset loading state
        _timer?.cancel();
        setState(() {
          _isLoading = false; // Hide loader
          _loadingText = ''; // Clear loading text
        });

        print('User registered: ${userCredential.user!.email}');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => Homescreen(username: username)),
        );
      } catch (e) {
        _timer?.cancel(); // Stop the timer on error
        setState(() {
          _isLoading = false; // Hide loader
          _loadingText = ''; // Clear loading text
        });
        print('Error: $e');
        _showErrorDialog(e.toString());
      }
    }
  }

  // Error dialog function
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(children: [
        // Background Design
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.amber.withOpacity(0.1),
                Colors.amberAccent.withOpacity(0.2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        // Circular Decorations
        Positioned(
          top: -50,
          left: -50,
          child: CircleAvatar(
            radius: 100,
            backgroundColor: Colors.amber.withOpacity(0.3),
          ),
        ),
        Positioned(
          bottom: -60,
          right: -40,
          child: CircleAvatar(
            radius: 150,
            backgroundColor: Colors.amberAccent.withOpacity(0.2),
          ),
        ),
        // Form Content
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "SIGN UP",
                  style: GoogleFonts.poppins(
                    fontSize: 40.0,
                    fontWeight: FontWeight.w800,
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(height: 40.0),

                // Email Field
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  isPassword: false,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$')
                        .hasMatch(value)) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20.0),

                // Password Field with Eye Icon
                _buildTextField(
                  controller: _passwordController,
                  label: 'Password',
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    } else if (value.length < 6) {
                      return 'Password must be at least 6 characters long';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20.0),

                // Confirm Password Field
                _buildTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    } else if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30.0),

                // Sign-Up Button
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : _registerUser, // Disable button when loading
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50.0, vertical: 15.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    shadowColor: Colors.black38,
                    elevation: 5,
                  ),
                  child: Text(
                    _isLoading
                        ? 'Loading...'
                        : 'SIGN UP', // Change button text when loading
                    style: GoogleFonts.poppins(
                      fontSize: 20.0,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20.0),

                // Show loading text if loading
                if (_isLoading)
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text(
                      _loadingText,
                      style: GoogleFonts.poppins(
                        fontSize: 16.0,
                        color: Colors.amber,
                      ),
                    ),
                  ),

                // Link to Sign-In
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignInScreen(),
                      ),
                    );
                  },
                  child: Text(
                    "Have an account? Sign in here.",
                    style: GoogleFonts.poppins(
                      fontSize: 16.0,
                      color: Colors.amber,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  // Reusable TextField Widget with Eye Icon
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required bool isPassword,
    required String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: TextFormField(
        controller: controller,
        validator: validator,
        obscureText: isPassword ? !_passwordVisible : false,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.amber),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.amber),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.amber),
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _passwordVisible ? Icons.visibility : Icons.visibility_off,
                    color: Colors.amber,
                  ),
                  onPressed: () {
                    setState(() {
                      _passwordVisible = !_passwordVisible;
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _timer?.cancel(); // Cancel the timer when disposing
    super.dispose();
  }
}
