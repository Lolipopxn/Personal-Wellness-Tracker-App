import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';

import '../app/firestore_service.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePage();
}

class _UserProfilePage extends State<UserProfilePage> {
  final FirestoreService _firestoreService = FirestoreService();
  User? _user;
  Map<String, dynamic>? _firestoreUserData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllUserData();
  }

   Future<void> _loadAllUserData() async {
    setState(() {
      _isLoading = true;
    });

    _user = FirebaseAuth.instance.currentUser;
    if (_user != null) {
      await _user?.reload();
      _user = FirebaseAuth.instance.currentUser;
      _firestoreUserData = await _firestoreService.getUserData();
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Dummy data for user information
  final String userBio = 'ยินดีต้อนรับสู่โปรไฟล์ของคุณ!';

  final List<Map<String, dynamic>> achievements = const [
    {'title': 'ผู้ริเริ่ม', 'description': 'สำเร็จบันทึกครั้งเเรก', 'isAchieved': true,},
    {'title': 'นักวางแผน', 'description': 'บันทึกอาหารครบ 10 วัน', 'isAchieved': false,},
    {'title': 'นักพัฒนา', 'description': 'บันทึกกิจกรรมครบ 20 วัน', 'isAchieved': false,},
    {'title': 'ผู้เชี่ยวชาญ', 'description': 'บรรลุเป้าหมายสุขภาพ 3 เป้าหมาย', 'isAchieved': false,},
    {'title': 'นักวางแผนมื้ออาหาร', 'description': 'วางแผนมื้ออาหารครบ 5 มื้อ', 'isAchieved': false,},
    {'title': 'นักออกกำลังกาย', 'description': 'บันทึกการออกกำลังกายครบ 10 วัน', 'isAchieved': false,},
    {'title': 'ผู้เชี่ยวชาญด้านโภชนาการ', 'description': 'บรรลุเป้าหมายโภชนาการ 3 เป้าหมาย', 'isAchieved': false,},
    {'title': 'นักวางแผน', 'description': 'บันทึกอาหารครบ 20 วัน', 'isAchieved': false,},
    {'title': 'นักพัฒนา', 'description': 'บันทึกกิจกรรมครบ 40 วัน', 'isAchieved': false,},
    {'title': 'นักวางแผนมื้ออาหาร', 'description': 'วางแผนมื้ออาหารครบ 15 มื้อ', 'isAchieved': false,},
    {'title': 'นักออกกำลังกาย', 'description': 'บันทึกการออกกำลังกายครบ 30 วัน', 'isAchieved': false,},
  ];

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final String username =
        _firestoreUserData?['username'] ?? _user?.displayName ?? "ไม่ทราบชื่อ";
    final String? photoUrl =
        _firestoreUserData?['profileImageUrl'] ?? _user?.photoURL;
    
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            // Header Section: Avatar and Name
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30.0, horizontal: 20.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4DA1A9), Color(0xff2E5077)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30.0),
                  bottomRight: Radius.circular(30.0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(100),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: <Widget>[
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: photoUrl != null
                      ? NetworkImage(photoUrl)
                      : null,
                    backgroundColor: Colors.white,
                    child: photoUrl == null ? const Icon(Icons.person, size: 60, color: Color(0xff2E5077)) : null,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    username,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    userBio,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withAlpha(200),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // User Details Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'ข้อมูลส่วนตัว', // Personal Information heading
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const Divider(height: 20, thickness: 2, color: Colors.blueGrey),
                  Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          _buildDetailRow(Icons.account_circle, 'ชื่อ', _user?.displayName ?? "ไม่ทราบชื่อ",),
                          const SizedBox(height: 15),
                          _buildDetailRow(Icons.email, 'อีเมล', _user?.email ?? "ไม่ทราบอีเมล",),
                          const SizedBox(height: 15),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // Achievements Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'ความสำเร็จ', // Achievements heading
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const Divider(height: 20, thickness: 2, color: Colors.blueGrey),
                  ListView.builder(
                    physics: const NeverScrollableScrollPhysics(), // Disable scrolling for this list as parent is scrollable
                    shrinkWrap: true, // Wrap content height
                    itemCount: achievements.length,
                    itemBuilder: (context, index) {
                      final achievement = achievements[index];
                      final bool isAchieved = achievement['isAchieved'] as bool; // Get achievement status

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        elevation: isAchieved ? 3 : 1, // Lower elevation if not achieved
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        // Conditionally set color based on achievement status
                        color: isAchieved ? Theme.of(context).cardTheme.color : Colors.grey[200],
                        child: ListTile(
                          leading: CircleAvatar(

                            backgroundColor: isAchieved ? Colors.teal[100] : Colors.grey[300],
                            child: Icon(
                              Icons.star,
                              color: isAchieved ? Colors.teal[700] : Colors.grey[500],
                            ),
                          ),
                          title: Text(
                            achievement['title']!,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: isAchieved ? Colors.blueGrey : Colors.grey[600], // Darker grey for unachieved
                            ),
                          ),
                          subtitle: Text(
                            achievement['description']!,
                            style: TextStyle(
                              fontSize: 14,
                              color: isAchieved ? Colors.grey[600] : Colors.grey[500], // Lighter grey for unachieved
                            ),
                          ),
                          trailing: isAchieved
                              ? null
                              : const Icon(Icons.lock, size: 16, color: Colors.grey), // Show lock icon if not achieved
                          onTap: () {} // Disable onTap if not achieved
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30), // Bottom padding
          ],
        ),
      ),
    );
  }

  // Helper method to build a detail row with icon and text
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, color: Colors.blueGrey, size: 24),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}