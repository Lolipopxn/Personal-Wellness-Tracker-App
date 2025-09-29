import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../services/auth_service.dart';
import '../services/achievement_service.dart';
import '../models/achievement.dart';
import '../providers/user_provider.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  List<Achievement> _achievements = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadAchievements();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final result = await AuthService.getCurrentUser();

    if (!mounted) return;

    if (result['success']) {
      Provider.of<UserProvider>(
        context,
        listen: false,
      ).setUserData(result['user']);
      setState(() => _isLoading = false);
    } else {
      setState(() {
        _errorMessage = result['message'] ?? 'Failed to load user data';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAchievements() async {
    await AchievementService.initializeUserAchievements();

    final result = await AchievementService.getUserAchievements();

    if (!mounted) return;

    if (result['success']) {
      setState(() {
        _achievements = result['achievements'] ?? [];
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = result['message'] ?? 'Failed to load achievements';
        _isLoading = false;
      });
    }
  }

  /// ฟังก์ชันแชร์ achievement card
  Future<void> _shareAchievementCard(
    Achievement achievement,
    GlobalKey cardKey,
  ) async {
    try {
      // สร้าง ScreenshotController สำหรับ card นี้
      final controller = ScreenshotController();

      // จับภาพ card achievement
      final Uint8List? image = await controller.captureFromWidget(
        Material(
          child: Container(
            width: 350,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _buildShareableAchievementCard(achievement),
          ),
        ),
      );

      if (image != null) {
        // สร้างไฟล์ชั่วคราว
        final directory = await getTemporaryDirectory();
        final imagePath = '${directory.path}/achievement_${achievement.id}.png';
        final imageFile = File(imagePath);
        await imageFile.writeAsBytes(image);

        // แชร์รูปภาพพร้อมข้อความ
        final shareText =
            '🏆 ฉันได้รับความสำเร็จ "${achievement.name}" แล้ว!\n\n${achievement.description}\n\n#PersonalWellnessTracker #Achievement #Wellness';

        await Share.shareXFiles([XFile(imagePath)], text: shareText);
      }
    } catch (e) {
      debugPrint('Error sharing achievement card: $e');
      // แสดง error message ให้ผู้ใช้
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ไม่สามารถแชร์ได้ในขณะนี้ กรุณาลองใหม่อีกครั้ง'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// สร้าง achievement card สำหรับแชร์
  Widget _buildShareableAchievementCard(Achievement achievement) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4DA1A9), Color(0xff2E5077)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(Icons.star, color: Colors.yellow[300], size: 40),
              const SizedBox(height: 8),
              const Text(
                'ความสำเร็จ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Achievement details
        Text(
          achievement.name,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xff2E5077),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          achievement.description,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        // Achievement status
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.teal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.teal, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.teal[600], size: 16),
              const SizedBox(width: 4),
              Text(
                'สำเร็จแล้ว!',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.teal[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // App branding
        Text(
          'Personal Wellness Tracker',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final userData = userProvider.userData;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Profile")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  _loadUserData();
                  _loadAchievements();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final String username = userData?['username'] ?? "ไม่ทราบชื่อ";
    final String email = userData?['email'] ?? "ไม่ทราบอีเมล";

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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ความสำเร็จ',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                      IconButton(
                        onPressed: _loadAchievements,
                        icon: const Icon(Icons.refresh),
                        tooltip: 'รีเฟรชความสำเร็จ',
                      ),
                    ],
                  ),
                  const Divider(
                    height: 20,
                    thickness: 2,
                    color: Colors.blueGrey,
                  ),
                  _achievements.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text(
                              'ไม่มีข้อมูลความสำเร็จ',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: _achievements.length,
                          itemBuilder: (context, index) {
                            final achievement = _achievements[index];
                            final bool isAchieved = achievement.achieved;
                            final double progress = achievement.target > 0
                                ? (achievement.current / achievement.target)
                                      .clamp(0.0, 1.0)
                                : 0.0;

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
                                    isAchieved ? Icons.star : Icons.star_border,
                                    color: isAchieved
                                        ? Colors.teal[700]
                                        : Colors.grey[500],
                                  ),
                                ),
                                title: Text(
                                  achievement.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: isAchieved
                                        ? Colors.blueGrey
                                        : Colors.grey[600],
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      achievement.description,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isAchieved
                                            ? Colors.grey[600]
                                            : Colors.grey[500],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    if (!isAchieved) ...[
                                      Text(
                                        'ความคืบหน้า: ${achievement.current}/${achievement.target}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      LinearProgressIndicator(
                                        value: progress,
                                        backgroundColor: Colors.grey[300],
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.teal[400]!,
                                            ),
                                      ),
                                    ] else ...[
                                      Text(
                                        'สำเร็จแล้ว',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.teal[600],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // ปุ่มแชร์ - enable เมื่อ achievement สำเร็จแล้ว
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        color: isAchieved
                                            ? Colors.teal
                                            : Colors.grey.shade300,
                                      ),
                                      child: IconButton(
                                        onPressed: isAchieved
                                            ? () => _shareAchievementCard(
                                                achievement,
                                                GlobalKey(),
                                              )
                                            : null,
                                        icon: Icon(
                                          Icons.share,
                                          color: isAchieved
                                              ? Colors.white
                                              : Colors.grey.shade500,
                                          size: 20,
                                        ),
                                        tooltip: isAchieved
                                            ? 'แชร์ความสำเร็จ'
                                            : 'ยังไม่สำเร็จ ไม่สามารถแชร์ได้',
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // ไอคอนสถานะ
                                    isAchieved
                                        ? Icon(
                                            Icons.check_circle,
                                            color: Colors.teal[600],
                                          )
                                        : const Icon(
                                            Icons.lock,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                  ],
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
