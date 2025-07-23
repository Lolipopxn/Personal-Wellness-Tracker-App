import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:personal_wellness_tracker/app/auth_service.dart';
import 'package:personal_wellness_tracker/pages/profile_widget.dart';
import 'package:personal_wellness_tracker/pages/register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController controllerEmail = TextEditingController();
  TextEditingController controllerPassword = TextEditingController();
  final formKey = GlobalKey<FormState>();
  String errorMessage = '';

  @override
  void dispose() {
    controllerEmail.dispose();
    controllerPassword.dispose();
    super.dispose();
  }

  void signIn() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await authService.value.signIn(
        email: controllerEmail.text.trim(),
        password: controllerPassword.text.trim(),
      );

      // ถ้า login สำเร็จ -> ไปหน้า Profile
      if (context.mounted) {
        // ซ่อน loading indicator ก่อนเปลี่ยนหน้า
        Navigator.of(context).pop();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProfileWidget()),
        );
      }
    } on FirebaseAuthException catch (e) {
      // ซ่อน loading indicator
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      setState(() {
        errorMessage = e.message ?? 'An unknown error occurred.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Image Placeholder
                  Center(
                    child: Icon(
                      Icons.image_search, // ไอคอน Placeholder
                      size: 100,
                      color: Colors.grey.shade300,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 3. Login Title
                  const Center(
                    child: Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // 4. Email Field
                  const Text(
                    'Email',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: controllerEmail,
                    decoration: const InputDecoration(
                      hintText: 'Your email address',
                      hintStyle: TextStyle(color: Colors.grey),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 10.0,
                        horizontal: 10.0,
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
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // 5. Password Field
                  const Text(
                    'Password',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: controllerPassword,
                    decoration: const InputDecoration(
                      hintText: 'Your password',
                      hintStyle: TextStyle(color: Colors.grey),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 10.0,
                        horizontal: 10.0,
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
                  const SizedBox(height: 24),

                  // Error Message
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

                  // 6. Sign In Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState?.validate() ?? false) {
                          signIn();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_forward),
                          SizedBox(width: 10),
                          Text('Sign In', style: TextStyle(fontSize: 18)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Have an Account? "),
                      GestureDetector(
                        onTap: () {
                          // เมื่อกดที่นี่
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterPage(),
                            ),
                          );
                        },
                        child: const Text(
                          'Register',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 8. "OR" Divider
                  const Row(
                    children: [
                      Expanded(child: Divider(thickness: 1)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('OR', style: TextStyle(color: Colors.grey)),
                      ),
                      Expanded(child: Divider(thickness: 1)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 9. Social Login Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.email_outlined, size: 28),
                        onPressed: () {
                          /* TODO: Handle 1st social login */
                        },
                        style: IconButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade400),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        icon: const Icon(Icons.email_outlined, size: 28),
                        onPressed: () {
                          /* TODO: Handle 2nd social login */
                        },
                        style: IconButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade400),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
