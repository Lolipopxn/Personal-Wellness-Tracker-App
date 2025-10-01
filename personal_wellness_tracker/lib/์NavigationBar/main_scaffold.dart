import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../providers/user_provider.dart';

import 'package:personal_wellness_tracker/pages/dashboard.dart';
import 'package:personal_wellness_tracker/pages/daily_page.dart';
import 'package:personal_wellness_tracker/pages/food_save.dart';
import 'package:personal_wellness_tracker/pages/myProfile_page.dart';
import 'package:personal_wellness_tracker/pages/progress_page.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int currentIndex = 0;

  // NEW: keep pages alive across tab switches
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _fetchUserData();

    // NEW: instantiate pages once
    _pages = [
      Dashboard(
        onNavigate: (int index) {
          setState(() {
            currentIndex = index;
          });
        },
      ),
      const DailyPage(),
      const FoodSavePage(),
      const ProgressScreen(),
      const UserProfilePage(),
    ];
  }

  Future<void> _fetchUserData() async {
    final result = await AuthService.getCurrentUser();
    if (!mounted) return;

    if (result['success']) {
      Provider.of<UserProvider>(
        context,
        listen: false,
      ).setUserData(result['user']);
    } else {
      Provider.of<UserProvider>(context, listen: false).setUserData({});
    }
  }

  void _onItemTapped(int index) {
    // ถ้าเป็นการเปลี่ยนจากหน้า Profile (index 4) ไปหน้า Dashboard (index 0)
    // ให้ refresh ข้อมูลใน dashboard
    if (currentIndex == 4 && index == 0) {
      // จะ refresh ใน Dashboard widget เอง
    }

    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final userData = userProvider.userData;

    String displayName = 'User';
    if (userData != null && userData.isNotEmpty) {
      displayName = userData['username'] ?? userData['email'] ?? 'User';
    }

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
      // CHANGED: keep all pages alive; timers in DailyPage keep running
      body: IndexedStack(
        index: currentIndex,
        children: _pages,
      ),
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
