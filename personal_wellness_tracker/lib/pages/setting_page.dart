import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart'; // Import your main.dart to access ThemeProvider
import '../app/firestore_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FirestoreService _firestoreService = FirestoreService();
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
      _firestoreUserData = await _firestoreService.getUserData();
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
                                  await _firestoreService.updateUserData({
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
                  // TODO
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
