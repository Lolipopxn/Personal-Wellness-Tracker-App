import 'package:flutter/material.dart';
import '../services/auth_service.dart'; // ✅ ใช้ AuthService ของ FastAPI

import 'package:personal_wellness_tracker/pages/dashboard.dart';
import 'package:personal_wellness_tracker/pages/daily_page.dart';
import 'package:personal_wellness_tracker/pages/food_save.dart';
import 'package:personal_wellness_tracker/pages/myProfile_page.dart';
import 'package:personal_wellness_tracker/pages/statistics_page.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int currentIndex = 0;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final result = await AuthService.getCurrentUser();
    if (mounted) {
      setState(() {
        if (result['success']) {
          _userData = result['user'];
        } else {
          _userData = {};
        }
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // ✅ ดึงชื่อจาก API (auth/me)
    String displayName = 'User';
    if (_userData != null && _userData!.isNotEmpty) {
      displayName = _userData!['username'] ?? _userData!['email'] ?? 'User';
    }

    final List<Widget> pages = [
      Dashboard(
        onNavigate: (int index) {
          setState(() {
            currentIndex = index;
          });
        },
      ),
      const DailyPage(),
      const FoodSavePage(),
      const StatisticsPage(),
      const UserProfilePage(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF79D7BE),
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.account_circle, size: 30),
              onPressed: () {},
            ),
            const SizedBox(width: 8),
            Text(
              displayName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: pages[currentIndex],
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        border: Border.all(
          color:
              Theme.of(context).bottomNavigationBarTheme.backgroundColor ??
              Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(50),
            spreadRadius: 2,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        child: SizedBox(
          height: 110,
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor:
                Theme.of(context).bottomNavigationBarTheme.backgroundColor ??
                Colors.white,
            selectedItemColor: const Color(0xFF79D7BE),
            unselectedItemColor:
                Theme.of(
                  context,
                ).bottomNavigationBarTheme.unselectedItemColor ??
                Colors.black,
            iconSize: 30,
            selectedFontSize: 16,
            unselectedFontSize: 14,
            currentIndex: currentIndex,
            onTap: _onItemTapped,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'หน้าแรก'),
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard),
                label: 'บันทึก',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.add_circle_outline),
                label: 'เพิ่มอาหาร',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart),
                label: 'สถิติ',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'โปรไฟล์',
              ),
            ],
            elevation: 0,
          ),
        ),
      ),
    );
  }
}
