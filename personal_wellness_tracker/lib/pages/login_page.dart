import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:personal_wellness_tracker/%E0%B9%8CNavigationBar/main_scaffold.dart';
import 'package:personal_wellness_tracker/app/auth_service.dart';
import 'package:personal_wellness_tracker/services/sync_service.dart';
// import 'package:personal_wellness_tracker/pages/profile_widget.dart';
import 'package:personal_wellness_tracker/pages/register_page.dart';
// import 'package:personal_wellness_tracker/pages/home.dart';

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
      // 1. ลงชื่อเข้าใช้ Firebase
      await authService.value.signIn(
        email: controllerEmail.text.trim(),
        password: controllerPassword.text.trim(),
      );

      if (context.mounted) {
        // อัปเดต loading dialog เป็น sync message
        Navigator.of(context).pop();
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('กำลังซิงค์ข้อมูลจาก Firebase...'),
              ],
            ),
          ),
        );

        // 2. ซิงค์ข้อมูลจาก Firebase ลง SQLite แบบสมบูรณ์
        print('🔄 Starting comprehensive sync after login...');
        final syncService = SyncService();
        
        try {
          // ใช้ forceSyncFromFirestore เพื่อให้แน่ใจว่าข้อมูลทั้งหมดรวมถึง daily tasks จะถูก sync
          await syncService.forceSyncFromFirestore();
          print('✅ Comprehensive login sync completed successfully');
          
          if (context.mounted) {
            // ปิด sync dialog
            Navigator.of(context).pop();
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('เข้าสู่ระบบและซิงค์ข้อมูลสำเร็จ'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } catch (syncError) {
          print('⚠️ Login sync failed: $syncError');
          
          if (context.mounted) {
            // ปิด sync dialog
            Navigator.of(context).pop();
            
            // แสดง warning แต่ยังคงเข้าสู่แอป
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('การซิงค์ข้อมูลไม่สำเร็จ: $syncError\nแต่คุณยังสามารถใช้งานแอปได้'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
        
        if (context.mounted) {
          // 3. นำทางไปหน้าหลัก
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainScaffold()),
            (route) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        setState(() {
          errorMessage = e.message ?? 'An unknown error occurred.';
        });
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        setState(() {
          errorMessage = 'เกิดข้อผิดพลาดในการเข้าสู่ระบบ: $e';
        });
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
                          child: Icon(
                            Icons.image_search,
                            size: iconSize,
                            color: Colors.grey.shade300,
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

                        // Sign in button
                        ElevatedButton(
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
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterPage(),
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
                        SizedBox(height: screenHeight * 0.03),

                        // Divider
                        const Row(
                          children: [
                            Expanded(child: Divider(thickness: 1)),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'OR',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                            Expanded(child: Divider(thickness: 1)),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.03),

                        // Social login
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.g_mobiledata, size: 28),
                              onPressed: () {
                                // TODO
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
                              icon: const Icon(Icons.apple, size: 28),
                              onPressed: () {
                                // TODO
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
                        SizedBox(height: screenHeight * 0.02),
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
