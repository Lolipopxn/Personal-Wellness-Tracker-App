import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _start();
  }

  Future<void> _start() async {
    // รอแอนิเมชัน/สปแลช
    await Future.delayed(const Duration(milliseconds: 3000));

    // เช็คว่าผ่าน Onboarding แล้วหรือยัง
    final sp = await SharedPreferences.getInstance();
    final seen = sp.getBool('onboarding_done') ?? false;

    if (!mounted) return;
    if (seen) {
      Navigator.of(context).pushReplacementNamed('/login');
    } else {
      Navigator.of(context).pushReplacementNamed('/onboarding');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF120A3A);
    const diamond = Color(0xFFBFE3D6);

    return Scaffold(
      backgroundColor: background,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.rotate(
                angle: 0.785398,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: diamond,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Transform.rotate(
                    angle: -0.785398,
                    child: Center(
                      child: Image.asset(
                        "assets/images/heart-beat.png",
                        width: 80,
                        height: 96,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 50),
              const Text(
                'Life Tracker',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
