import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app/firestore_service.dart';
import '../services/sync_service.dart';

import 'package:personal_wellness_tracker/pages/dashboard.dart';
import 'package:personal_wellness_tracker/pages/daily_page.dart';
import 'package:personal_wellness_tracker/pages/setting_page.dart';
import 'package:personal_wellness_tracker/pages/food_save.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int currentIndex = 0;

  final FirestoreService _firestoreService = FirestoreService();
  final SyncService _syncService = SyncService();
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _performBackgroundSync(); // เพิ่มการ sync daily tasks
  }

  Future<void> _fetchUserData() async {
    try {
      final data = await _firestoreService.getUserData();
      if (mounted) {
        setState(() {
          _userData = data;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userData = {};
        });
      }
    }
  }

  // ทำการ sync ข้อมูล daily tasks เพื่อให้ข้อมูลเป็นปัจจุบัน
  Future<void> _performBackgroundSync() async {
    try {
      print('🔄 Starting background sync for daily tasks in MainScaffold...');
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _syncService.forceSyncFromFirestore();
        print('✅ Background sync completed in MainScaffold');
      }
    } catch (e) {
      print('⚠️ Background sync failed in MainScaffold: $e');
      // ไม่แสดง error ให้ user เพราะเป็น background sync
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    String displayName = "";
    if (_userData != null) {
      displayName =
          _userData!['username'] ?? user?.displayName ?? user?.email ?? 'User';
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
      const SettingsPage(),
      const SettingsPage(),
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
            icon: const Icon(Icons.notifications, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: pages[currentIndex],
      bottomNavigationBar: Container(
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
            child: Theme(
              data: Theme.of(context).copyWith(
                splashColor: Colors.transparent,
                // highlightColor: Colors.transparent,
              ),
              child: BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                backgroundColor:
                    Theme.of(
                      context,
                    ).bottomNavigationBarTheme.backgroundColor ??
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
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: 'หน้าแรก',
                  ),
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
                useLegacyColorScheme: false,
                enableFeedback: false,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
