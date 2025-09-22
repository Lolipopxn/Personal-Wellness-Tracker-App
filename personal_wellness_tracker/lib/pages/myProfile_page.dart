import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final result = await AuthService.getCurrentUser();

    if (!mounted) return;

    if (result['success']) {
      setState(() {
        _userData = result['user'];
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = result['message'] ?? 'Failed to load user data';
        _isLoading = false;
      });
    }
  }

  // Dummy data for user achievements
  final List<Map<String, dynamic>> achievements = const [
    {
      'title': 'ผู้ริเริ่ม',
      'description': 'สำเร็จบันทึกครั้งเเรก',
      'isAchieved': true,
    },
    {
      'title': 'นักวางแผน',
      'description': 'บันทึกอาหารครบ 10 วัน',
      'isAchieved': false,
    },
    {
      'title': 'นักพัฒนา',
      'description': 'บันทึกกิจกรรมครบ 20 วัน',
      'isAchieved': false,
    },
    {
      'title': 'ผู้เชี่ยวชาญ',
      'description': 'บรรลุเป้าหมายสุขภาพ 3 เป้าหมาย',
      'isAchieved': false,
    },
    {
      'title': 'นักวางแผนมื้ออาหาร',
      'description': 'วางแผนมื้ออาหารครบ 5 มื้อ',
      'isAchieved': false,
    },
    {
      'title': 'นักออกกำลังกาย',
      'description': 'บันทึกการออกกำลังกายครบ 10 วัน',
      'isAchieved': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Profile")),
        body: Center(
          child: Text(_errorMessage, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    final String username = _userData?['username'] ?? "ไม่ทราบชื่อ";
    final String email = _userData?['email'] ?? "ไม่ทราบอีเมล";

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: 30.0,
                horizontal: 20.0,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
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
                  const CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 60,
                      color: Color(0xff2E5077),
                    ),
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
                    'ยินดีต้อนรับสู่โปรไฟล์ของคุณ!',
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
                    'ข้อมูลส่วนตัว',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const Divider(
                    height: 20,
                    thickness: 2,
                    color: Colors.blueGrey,
                  ),
                  Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            Icons.account_circle,
                            'ชื่อผู้ใช้',
                            username,
                          ),
                          const SizedBox(height: 15),
                          _buildDetailRow(Icons.email, 'อีเมล', email),
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
                    'ความสำเร็จ',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const Divider(
                    height: 20,
                    thickness: 2,
                    color: Colors.blueGrey,
                  ),
                  ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: achievements.length,
                    itemBuilder: (context, index) {
                      final achievement = achievements[index];
                      final bool isAchieved = achievement['isAchieved'] as bool;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        elevation: isAchieved ? 3 : 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        color: isAchieved
                            ? Theme.of(context).cardTheme.color
                            : Colors.grey[200],
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isAchieved
                                ? Colors.teal[100]
                                : Colors.grey[300],
                            child: Icon(
                              Icons.star,
                              color: isAchieved
                                  ? Colors.teal[700]
                                  : Colors.grey[500],
                            ),
                          ),
                          title: Text(
                            achievement['title']!,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: isAchieved
                                  ? Colors.blueGrey
                                  : Colors.grey[600],
                            ),
                          ),
                          subtitle: Text(
                            achievement['description']!,
                            style: TextStyle(
                              fontSize: 14,
                              color: isAchieved
                                  ? Colors.grey[600]
                                  : Colors.grey[500],
                            ),
                          ),
                          trailing: isAchieved
                              ? null
                              : const Icon(
                                  Icons.lock,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Helper widget
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
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
