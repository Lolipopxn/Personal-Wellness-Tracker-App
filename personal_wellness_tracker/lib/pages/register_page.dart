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
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Register Title
                const Text(
                  'Register',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),

                // 2. Email Field
                const Text(
                  'Email *',
                  style: TextStyle(fontWeight: FontWeight.bold),
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
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // 3. Password Field
                const Text(
                  'Password *',
                  style: TextStyle(fontWeight: FontWeight.bold),
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
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters long';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // 4. Terms of Service Checkbox
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: _agreeToTerms,
                        onChanged: (bool? value) {
                          setState(() {
                            _agreeToTerms = value ?? false;
                          });
                        },
                        activeColor: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 14,
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
                                  // TODO: Show Terms of Services
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
                                  // TODO: Show Privacy Policy
                                },
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Error Message Display
                if (errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // 5. Create Account Button
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
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Confirm to create Account',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // 6. Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Have an Account? "),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'Login',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
