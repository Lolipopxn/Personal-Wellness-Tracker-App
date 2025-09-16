import 'dart:async';
import 'package:flutter/material.dart';

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

    Timer(const Duration(milliseconds: 3000), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    const background = Color(0xFF120A3A); 
    const diamond     = Color(0xFFBFE3D6);

    return Scaffold(
      backgroundColor: background,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // สี่เหลี่ยมข้าวหลามตัด + โลโก้
              Transform.rotate(
                angle: 0.785398, // 45 องศา
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: diamond,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Transform.rotate(
                    angle: -0.785398, // หมุนกลับให้ไอคอนตรง
                    child: Center(
                      child: Image.asset("assets/images/heart-beat.png", width: 80, height: 96, color: Colors.white),
                      // child: Icon(
                      //   Icons.health_and_safety_rounded,
                      //   color: Colors.white,
                      //   size: 96,
                      // ),
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