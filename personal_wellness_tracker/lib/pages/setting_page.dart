import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../main.dart'; // สมมติว่า ThemeProvider อยู่ใน main.dart
import '../services/offline_data_service.dart'; // แก้ไข path ไปยังไฟล์ service ของคุณ

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with AutomaticKeepAliveClientMixin {
  final OfflineDataService _offlineDataService = OfflineDataService();
  final _auth = FirebaseAuth.instance;

  User? _user;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadAllUserData();
  }

  Future<void> _loadAllUserData() async {
    if (!mounted) return;
    if (_isLoading == false) setState(() => _isLoading = true);

    try {
      _user = _auth.currentUser;
      if (_user != null) {
        _userData = await _offlineDataService.getUserProfile();
      }
      if (mounted) setState(() => _isLoading = false);
      await _backgroundRefreshFromFirebase();
    } catch (e) {
      debugPrint('Error loading user data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _backgroundRefreshFromFirebase() async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none ||
        _auth.currentUser == null) {
      return;
    }

    try {
      final success = await _offlineDataService.forceSyncFromFirestore();
      if (success && mounted) {
        _user = _auth.currentUser;
        _userData = await _offlineDataService.getUserProfile();
        setState(() {});
      }
    } catch (e) {
      debugPrint("Background refresh failed: $e");
    }
  }

  Future<void> _handleUpdateUsername(String newUsername) async {
    if (newUsername.isEmpty) return;
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (_) => const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      await _offlineDataService.updateUserProfile({'username': newUsername});
      await _loadAllUserData();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("บันทึกชื่อผู้ใช้เรียบร้อย"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("เกิดข้อผิดพลาด: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEditUsernameDialog() {
    final usernameController = TextEditingController(
      text: _userData?['username'] ?? _user?.displayName,
    );
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("แก้ไขชื่อผู้ใช้"),
        content: TextField(
          controller: usernameController,
          decoration: const InputDecoration(labelText: "ชื่อผู้ใช้ใหม่"),
          autofocus: true,
        ),
        actions: [
          TextButton(
            child: const Text("ยกเลิก"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("บันทึก"),
            onPressed: () =>
                _handleUpdateUsername(usernameController.text.trim()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("จัดการบัญชีผู้ใช้")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final themeProvider = Provider.of<ThemeProvider>(context);
    final String username =
        _userData?['username'] ?? _user?.displayName ?? "User";
    final String? photoUrl = _userData?['profileImageUrl'] ?? _user?.photoURL;

    return Scaffold(
      appBar: AppBar(title: const Text("จัดการบัญชีผู้ใช้")),
      body: RefreshIndicator(
        onRefresh: _loadAllUserData,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          children: [
            ListTile(
              leading: CircleAvatar(
                radius: 30,
                backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                    ? NetworkImage(photoUrl)
                    : null,
                child: (photoUrl == null || photoUrl.isEmpty)
                    ? const Icon(Icons.person, size: 30)
                    : null,
              ),
              title: Text(
                username,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              subtitle: Text(_user?.email ?? "ไม่ทราบอีเมล"),
              trailing: IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: _showEditUsernameDialog,
              ),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text("โหมดมืด"),
              secondary: const Icon(Icons.brightness_6_outlined),
              value: themeProvider.themeMode == ThemeMode.dark,
              onChanged: (val) {
                themeProvider.setThemeMode(
                  val ? ThemeMode.dark : ThemeMode.light,
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.health_and_safety_outlined),
              title: const Text("ตั้งค่าโปรไฟล์สุขภาพ"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pushNamed(context, '/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text("เปลี่ยนรหัสผ่าน"),
              onTap: () {
                final currentPasswordController = TextEditingController();
                final newPasswordController = TextEditingController();

                String? currentPasswordError;
                String? newPasswordError;

                showDialog(
                  context: context,
                  builder: (_) {
                    return StatefulBuilder(
                      builder: (context, setState) {
                        return AlertDialog(
                          title: const Text("เปลี่ยนรหัสผ่าน"),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: currentPasswordController,
                                decoration: InputDecoration(
                                  labelText: "รหัสผ่านปัจจุบัน",
                                  errorText: currentPasswordError,
                                ),
                                obscureText: true,
                              ),
                              TextField(
                                controller: newPasswordController,
                                decoration: InputDecoration(
                                  labelText: "รหัสผ่านใหม่",
                                  errorText: newPasswordError,
                                ),
                                obscureText: true,
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("ยกเลิก"),
                            ),
                            TextButton(
                              onPressed: () async {
                                final currentPassword =
                                    currentPasswordController.text;
                                final newPassword = newPasswordController.text;

                                setState(() {
                                  currentPasswordError = null;
                                  newPasswordError = null;
                                });

                                if (currentPassword.isEmpty ||
                                    newPassword.isEmpty) {
                                  setState(() {
                                    if (currentPassword.isEmpty) {
                                      currentPasswordError =
                                          "กรุณากรอกรหัสผ่านปัจจุบัน";
                                    }
                                    if (newPassword.isEmpty) {
                                      newPasswordError =
                                          "กรุณากรอกรหัสผ่านใหม่";
                                    }
                                  });
                                  return;
                                }

                                try {
                                  final user =
                                      FirebaseAuth.instance.currentUser;
                                  final cred = EmailAuthProvider.credential(
                                    email: user!.email!,
                                    password: currentPassword,
                                  );
                                  await user.reauthenticateWithCredential(cred);

                                  await user.updatePassword(newPassword);

                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("เปลี่ยนรหัสผ่านสำเร็จ"),
                                    ),
                                  );

                                  await FirebaseAuth.instance.signOut();

                                  if (!mounted) return;
                                  Navigator.of(context).pushNamedAndRemoveUntil(
                                    '/login',
                                    (route) => false,
                                  );
                                } on FirebaseAuthException catch (e) {
                                  setState(() {
                                    if (e.code == 'wrong-password' ||
                                        e.code == 'user-mismatch' ||
                                        e.code == 'invalid-credential') {
                                      currentPasswordError =
                                          "รหัสผ่านปัจจุบันไม่ถูกต้อง";
                                    } else if (e.code == 'weak-password') {
                                      newPasswordError =
                                          "รหัสผ่านใหม่ต้องมีอย่างน้อย 6 ตัวอักษร";
                                    }
                                  });
                                }
                              },
                              child: const Text("บันทึก"),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("ออกจากระบบ"),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (!mounted) return;
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/login', (route) => false);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                "ออกจากระบบ",
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                await _auth.signOut();
                if (!mounted) return;
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/auth', (route) => false);
              },
            ),
          ],
        ),
      ),
    );
  }
}
