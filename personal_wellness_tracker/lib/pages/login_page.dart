import 'package:flutter/material.dart';
import 'package:personal_wellness_tracker/์NavigationBar/main_scaffold.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'profile.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final controllerEmail = TextEditingController();
  final controllerPassword = TextEditingController();
  final formKey = GlobalKey<FormState>();
  String errorMessage = '';
  bool _isLoading = false;

  @override
  void dispose() {
    controllerEmail.dispose();
    controllerPassword.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      errorMessage = '';
    });

    try {
      final result = await AuthService.login(
        email: controllerEmail.text.trim(),
        password: controllerPassword.text.trim(),
      );

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        if (context.mounted) {
          // เช็คสถานะการกรอกข้อมูลโปรไฟล์
          await _checkProfileCompletion();
        }
      } else {
        setState(() {
          errorMessage = result['message'] ?? 'Login failed';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        errorMessage = 'An error occurred: $e';
      });
    }
  }

  Future<void> _checkProfileCompletion() async {
    try {
      final apiService = ApiService();
      final userData = await apiService.getCurrentUser();
      
      print("DEBUG: User data from login: $userData"); // Debug line
      
      // เช็คว่า profile_completed เป็น true หรือไม่
      bool isProfileComplete = userData['profile_completed'] ?? false;
      
      if (context.mounted) {
        if (isProfileComplete) {
          // โปรไฟล์ครบถ้วนแล้ว ไปหน้าหลัก
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainScaffold()),
            (route) => false,
          );
        } else {
          // โปรไฟล์ยังไม่ครบถ้วน ไปหน้ากรอกข้อมูล
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const Profile(isFromLogin: true)),
            (route) => false,
          );
        }
      }
    } catch (e) {
      print("Error checking profile completion: $e");
      // ถ้าเกิดข้อผิดพลาด ให้ไปหน้าหลักตามปกติ
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainScaffold()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    final titleFontSize = (screenWidth * 0.08).clamp(26.0, 40.0);
    final bodyFontSize = (screenWidth * 0.04).clamp(14.0, 18.0);
    final iconSize = (screenWidth * 0.25).clamp(80.0, 140.0);
    final horizontalPadding = screenWidth * 0.06;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: screenHeight * 0.03),
                        Center(
                          child: Image.asset(
                            'assets/images/heart-beat.png',
                            width: iconSize,
                            height: iconSize,
                            fit: BoxFit.contain,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.03),
                        Center(
                          child: Text(
                            'Login',
                            style: TextStyle(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.05),

                        // Email
                        Text(
                          'Email',
                          style: TextStyle(
                            fontSize: bodyFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: controllerEmail,
                          decoration: const InputDecoration(
                            hintText: 'Your email address',
                            hintStyle: TextStyle(color: Colors.grey),
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 10,
                            ),
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
                            if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            ).hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: screenHeight * 0.03),

                        // Password
                        Text(
                          'Password',
                          style: TextStyle(
                            fontSize: bodyFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: controllerPassword,
                          decoration: const InputDecoration(
                            hintText: 'Your password',
                            hintStyle: TextStyle(color: Colors.grey),
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 10,
                            ),
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
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        if (errorMessage.isNotEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Text(
                                errorMessage,
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        SizedBox(height: screenHeight * 0.01),
                        // Sign in button
                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton(
                                onPressed: _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.arrow_forward),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Sign In',
                                      style: TextStyle(fontSize: bodyFontSize),
                                    ),
                                  ],
                                ),
                              ),
                        SizedBox(height: screenHeight * 0.03),

                        // Register link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Don't have an account? "),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(context, '/register');
                              },
                              child: const Text(
                                'Register',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.03),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
