import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart'; // Import your main.dart to access ThemeProvider
import '../services/offline_data_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final OfflineDataService _offlineDataService = OfflineDataService();
  User? _user;
  Map<String, dynamic>? _firestoreUserData;
  bool _isLoading = true;
  bool notificationsEnabled = true;

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
      _firestoreUserData = await _offlineDataService.getUserProfile();
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveDarkModePreference(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("จัดการบัญชีผู้ใช้")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final themeProvider = Provider.of<ThemeProvider>(context);
    final Color? appBarBackgroundColor = Theme.of(
      context,
    ).appBarTheme.backgroundColor;

    final String username =
        _firestoreUserData?['username'] ?? _user?.displayName ?? "ไม่ทราบชื่อ";
    final String? photoUrl =
        _firestoreUserData?['profileImageUrl'] ?? _user?.photoURL;

    return Scaffold(
      appBar: AppBar(
        title: const Text("จัดการบัญชีผู้ใช้"),
        backgroundColor: appBarBackgroundColor ?? const Color(0xFF79D7BE),
      ),
      body: Container(
        padding: const EdgeInsets.all(20.0),
        child: RefreshIndicator(
          onRefresh: _loadAllUserData,
          child: ListView(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundImage: photoUrl != null
                      ? NetworkImage(photoUrl)
                      : null,
                  child: photoUrl == null ? const Icon(Icons.person) : null,
                ),
                title: Text(
                  username,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: Text(
                  _user?.email ?? "ไม่ทราบอีเมล",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    final usernameController = TextEditingController(
                      text: username,
                    );
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("แก้ไขชื่อผู้ใช้"),
                        content: TextField(
                          controller: usernameController,
                          decoration: const InputDecoration(
                            labelText: "ชื่อผู้ใช้ใหม่",
                          ),
                          autofocus: true,
                        ),
                        actions: [
                          TextButton(
                            child: const Text("ยกเลิก"),
                            onPressed: () => Navigator.pop(context),
                          ),
                          TextButton(
                            child: const Text("บันทึก"),
                            onPressed: () async {
                              final newUsername = usernameController.text
                                  .trim();
                              if (newUsername.isNotEmpty) {
                                Navigator.pop(context);
                                showDialog(
                                  context: context,
                                  builder: (_) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                  barrierDismissible: false,
                                );
                                try {
                                  await _user?.updateDisplayName(newUsername);
                                  await _offlineDataService.updateUserProfile({
                                    'username': newUsername,
                                  });
                                  await _loadAllUserData();
                                  if (mounted) Navigator.pop(context);
                                } catch (e) {
                                  if (mounted) Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("เกิดข้อผิดพลาด: $e"),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Divider(),
              SwitchListTile(
                title: const Text("โหมดมืด (Dark Mode)"),
                activeColor: const Color(0xFF4DA1A9),
                value: themeProvider.themeMode == ThemeMode.dark,
                onChanged: (val) async {
                  themeProvider.setThemeMode(
                    val ? ThemeMode.dark : ThemeMode.light,
                  );
                  await _saveDarkModePreference(val);
                },
              ),
              SwitchListTile(
                title: const Text("เปิดการแจ้งเตือน"),
                activeColor: const Color(0xFF4DA1A9),
                value: notificationsEnabled,
                onChanged: (val) {
                  setState(() => notificationsEnabled = val);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.health_and_safety),
                title: const Text("ตั้งค่าสุขภาพ"),
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
            ],
          ),
        ),
      ),
    );
  }
}
