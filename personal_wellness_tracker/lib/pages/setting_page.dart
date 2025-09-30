import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart'; // ThemeProvider
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../providers/user_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
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
      if (result['success']) {
        Provider.of<UserProvider>(
          context,
          listen: false,
        ).setUserData(result['user']);
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateUsername(String newUsername) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final result = await AuthService.updateProfile(username: newUsername);

    if (mounted) Navigator.pop(context);

    if (result['success']) {
      Provider.of<UserProvider>(
        context,
        listen: false,
      ).updateUsername(newUsername);

      _showResultPopup("อัปเดตชื่อผู้ใช้สำเร็จ", true);
      _loadAllUserData();
    } else {
      _showResultPopup(result['message'] ?? "อัปเดตไม่สำเร็จ", false);
    }
  }

  Future<void> _saveDarkModePreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
  }

  Future<void> _loadNotificationSetting() async {
    final savedValue = await NotificationService().isEnabled();
    if (!mounted) return;
    setState(() => notificationsEnabled = savedValue);
  }

  void _showResultPopup(String message, bool success) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: success ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(success ? "สำเร็จ" : "ล้มเหลว"),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text("ตกลง"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _changePasswordDialog() {
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
                    setState(() {
                      currentPasswordError = null;
                      newPasswordError = null;
                    });

                    final currentPassword = currentPasswordController.text;
                    final newPassword = newPasswordController.text;

                    if (currentPassword.isEmpty || newPassword.isEmpty) {
                      setState(() {
                        if (currentPassword.isEmpty) {
                          currentPasswordError = "กรุณากรอกรหัสผ่านปัจจุบัน";
                        }
                        if (newPassword.isEmpty) {
                          newPasswordError = "กรุณากรอกรหัสผ่านใหม่";
                        }
                      });
                      return;
                    }

                    if (newPassword.length < 6) {
                      setState(() {
                        newPasswordError =
                            "รหัสผ่านใหม่ต้องมีอย่างน้อย 6 ตัวอักษร";
                      });
                      return;
                    }

                    Navigator.pop(context);

                    try {
                      final success = await AuthService().changePassword(
                        currentPassword: currentPassword,
                        newPassword: newPassword,
                      );

                      if (success) {
                        _showResultPopup("เปลี่ยนรหัสผ่านสำเร็จ", true);
                      } else {
                        _showResultPopup("รหัสผ่านปัจจุบันไม่ถูกต้อง", false);
                      }
                    } catch (e) {
                      _showResultPopup("เปลี่ยนรหัสผ่านล้มเหลว: $e", false);
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
    final userProvider = Provider.of<UserProvider>(context);
    final userData = userProvider.userData;

    final Color? appBarBackgroundColor = Theme.of(
      context,
    ).appBarTheme.backgroundColor;

    final String username = userData?['username'] ?? "ไม่ทราบชื่อ";
    final String email = userData?['email'] ?? "ไม่ทราบอีเมล";

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
                                Navigator.pop(context);
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
                  await NotificationService().setEnabled(val);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.health_and_safety),
                title: const Text("ตั้งค่าสุขภาพ"),
                onTap: () async {
                  await Navigator.pushNamed(context, '/profile');
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.lock),
                title: const Text("เปลี่ยนรหัสผ่าน"),
                onTap: _changePasswordDialog,
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
