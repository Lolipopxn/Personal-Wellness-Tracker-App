import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart'; // Import your main.dart to access ThemeProvider

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notificationsEnabled = true;
  User? user;

  Future<void> refreshUser() async {
    await user?.reload();
    setState(() {
      user = FirebaseAuth.instance.currentUser;
    });
  }

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
  }

  // Function to save dark mode preference
  Future<void> _saveDarkModePreference(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final themeProvider = Provider.of<ThemeProvider>(
      context,
    ); // Access ThemeProvider

    final Color? appBarBackgroundColor = Theme.of(
      context,
    ).appBarTheme.backgroundColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text("จัดการบัญชีผู้ใช้"),
        backgroundColor:
            appBarBackgroundColor ?? Color(0xFF79D7BE), // Use theme color
      ),
      body: Container(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            // Section: User Info
            ListTile(
              leading: CircleAvatar(
                backgroundImage: user?.photoURL != null
                    ? NetworkImage(user!.photoURL!)
                    : null,
                child: user?.photoURL == null ? const Icon(Icons.person) : null,
              ),
              title: Text(
                user?.displayName ?? "ไม่ทราบชื่อ",
                style: Theme.of(context).textTheme.titleMedium,
              ), // Apply text style
              subtitle: Text(
                user?.email ?? "ไม่ทราบอีเมล",
                style: Theme.of(context).textTheme.bodyMedium,
              ), // Apply text style
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  final nameController = TextEditingController(
                    text: user?.displayName ?? "",
                  );
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("แก้ไขชื่อผู้ใช้"),
                      content: TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: "ชื่อใหม่",
                        ),
                      ),
                      actions: [
                        TextButton(
                          child: const Text("ยกเลิก"),
                          onPressed: () => Navigator.pop(context),
                        ),
                        TextButton(
                          child: const Text("บันทึก"),
                          onPressed: () async {
                            final newName = nameController.text.trim();
                            if (newName.isNotEmpty) {
                              await user?.updateDisplayName(newName);
                              await refreshUser();
                              Navigator.pop(context);
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

            // Section: Settings
            SwitchListTile(
              title: const Text("โหมดมืด (Dark Mode)"),
              activeColor: Color(0xFF4DA1A9),
              value:
                  themeProvider.themeMode ==
                  ThemeMode.dark, // Use themeProvider themeMode
              onChanged: (val) async {
                themeProvider.setThemeMode(
                  val ? ThemeMode.dark : ThemeMode.light,
                );
                await _saveDarkModePreference(val); // Save the preference
              },
            ),

            SwitchListTile(
              title: const Text("เปิดการแจ้งเตือน"),
              activeColor: Color(0xFF4DA1A9),
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
    );
  }
}
