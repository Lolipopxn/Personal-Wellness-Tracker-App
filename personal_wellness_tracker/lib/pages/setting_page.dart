import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart'; // Add this import
import 'package:shared_preferences/shared_preferences.dart'; // Add this import
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
    final themeProvider = Provider.of<ThemeProvider>(context); // Access ThemeProvider

    return Scaffold(
      appBar: AppBar(
        title: const Text("จัดการบัญชีผู้ใช้"),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? Color(0xFF79D7BE), // Use theme color
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
              title: Text(user?.displayName ?? "ไม่ทราบชื่อ", style: Theme.of(context).textTheme.titleMedium), // Apply text style
              subtitle: Text(user?.email ?? "ไม่ทราบอีเมล", style: Theme.of(context).textTheme.bodyMedium), // Apply text style
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
              value: themeProvider.themeMode == ThemeMode.dark, // Use themeProvider's themeMode
              onChanged: (val) async {
                themeProvider.setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
                await _saveDarkModePreference(val); // Save the preference
              },
            ),
            SwitchListTile(
              title: const Text("เปิดการแจ้งเตือน"),
              value: notificationsEnabled,
              onChanged: (val) {
                setState(() => notificationsEnabled = val);
                // TODO: save setting
              },
            ),
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
                // TODO: ไปหน้าเปลี่ยนรหัสผ่าน
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("ออกจากระบบ"),
              onTap: () {
                // TODO: ออกจากระบบ
              },
            ),
          ],
        ),
      ),
    );
  }
}