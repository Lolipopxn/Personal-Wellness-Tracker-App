import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart'; // ThemeProvider
import '../services/auth_service.dart';
import '../app/notification_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadAllUserData();
    _loadNotificationSetting();
  }

  Future<void> _loadAllUserData() async {
    setState(() => _isLoading = true);

    final result = await AuthService.getCurrentUser();
    if (mounted) {
      setState(() {
        if (result['success']) {
          _userData = result['user'];
        } else {
          _userData = {};
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _updateUsername(String newUsername) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final result = await AuthService.updateProfile(username: newUsername);

    if (mounted) Navigator.pop(context); // close loading

    if (result['success']) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("อัปเดตชื่อผู้ใช้สำเร็จ")));
      _loadAllUserData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? "อัปเดตไม่สำเร็จ")),
      );
    }
  }

  Future<void> _saveDarkModePreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
  }

  Future<void> _loadNotificationSetting() async {
    final prefs = await SharedPreferences.getInstance();
    final savedValue = prefs.getBool('notificationsEnabled') ?? true;
    setState(() => notificationsEnabled = savedValue);
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

    final String username = _userData?['username'] ?? "ไม่ทราบชื่อ";
    final String email = _userData?['email'] ?? "ไม่ทราบอีเมล";

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
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(
                  username,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: Text(
                  email,
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
                            onPressed: () {
                              final newUsername = usernameController.text
                                  .trim();
                              if (newUsername.isNotEmpty) {
                                Navigator.pop(context); // close dialog
                                _updateUsername(newUsername);
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
                onChanged: (val) async {
                  setState(() => notificationsEnabled = val);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('notificationsEnabled', val);
                  await initNotificationService();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text("ออกจากระบบ"),
                onTap: () async {
                  await AuthService.logout();
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
