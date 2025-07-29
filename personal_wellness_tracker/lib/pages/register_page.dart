import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:personal_wellness_tracker/app/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Controllers for input fields
  final TextEditingController controllerEmail = TextEditingController();
  final TextEditingController controllerPassword = TextEditingController();
  final formKey = GlobalKey<FormState>();

  // State variables
  String errorMessage = '';
  bool _agreeToTerms = false;
  bool _isLoading = false;

  @override
  void dispose() {
    controllerEmail.dispose();
    controllerPassword.dispose();
    super.dispose();
  }

  // Register function
  void register() async {
    // Validate form fields
    final isValid = formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    // Check if terms are agreed
    if (!_agreeToTerms) {
      setState(() {
        errorMessage =
            'Please agree to the Terms of Services and Privacy Policy.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      errorMessage = '';
    });

    try {
      await authService.value.createAccount(
        email: controllerEmail.text.trim(),
        password: controllerPassword.text.trim(),
      );
      // Navigate to another page on success, e.g., back to login or to home
      if (context.mounted) {
        Navigator.of(
          context,
        ).pop(); // Go back to the previous screen (e.g., login)
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message ?? 'An unknown error occurred.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    final titleFontSize = (screenWidth * 0.08).clamp(26.0, 40.0);
    final bodyFontSize = (screenWidth * 0.045).clamp(14.0, 18.0);
    final paddingHorizontal = screenWidth * 0.06;
    final maxContentWidth = 500.0;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: paddingHorizontal,
              vertical: 32,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Center(
                      child: Text(
                        'Register',
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.04),

                    // Email
                    Text(
                      'Email *',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: bodyFontSize,
                      ),
                    ),
                    TextFormField(
                      controller: controllerEmail,
                      decoration: const InputDecoration(
                        hintText: 'Your email address',
                        hintStyle: TextStyle(color: Colors.grey),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Please enter your email';
                        if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value))
                          return 'Invalid email';
                        return null;
                      },
                    ),
                    SizedBox(height: screenHeight * 0.03),

                    // Password
                    Text(
                      'Password *',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: bodyFontSize,
                      ),
                    ),
                    TextFormField(
                      controller: controllerPassword,
                      decoration: const InputDecoration(
                        hintText: 'Your password',
                        hintStyle: TextStyle(color: Colors.grey),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                        ),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Please enter your password';
                        if (value.length < 6) return 'At least 6 characters';
                        return null;
                      },
                    ),
                    SizedBox(height: screenHeight * 0.03),

                    // Terms
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _agreeToTerms,
                            onChanged: (value) {
                              setState(() => _agreeToTerms = value ?? false);
                            },
                            activeColor: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: bodyFontSize,
                                color: Colors.black,
                              ),
                              children: [
                                const TextSpan(text: 'I agree to the '),
                                TextSpan(
                                  text: 'Terms of Services',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      // TODO
                                    },
                                ),
                                const TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      // TODO
                                    },
                                ),
                                const TextSpan(text: '.'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.03),

                    // Error Message
                    if (errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          errorMessage,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ),

                    // Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Confirm to create Account',
                                style: TextStyle(fontSize: bodyFontSize),
                              ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),

                    // Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Have an account? ',
                          style: TextStyle(fontSize: bodyFontSize),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Text(
                            'Login',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: bodyFontSize,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
