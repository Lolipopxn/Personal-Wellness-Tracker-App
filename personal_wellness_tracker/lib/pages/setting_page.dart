import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isDarkMode = false;
  bool notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("จัดการบัญชีผู้ใช้")),
      body: ListView(
        children: [
          // Section: User Info
          ListTile(
            leading: const CircleAvatar(
              backgroundImage: AssetImage('assets/user_avatar.png'),
            ),
            title: const Text("ชื่อผู้ใช้"),
            subtitle: const Text("example@email.com"),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // ไปหน้าแก้ไขโปรไฟล์
              },
            ),
          ),
          const Divider(),

          // Section: Settings
          SwitchListTile(
            title: const Text("โหมดมืด (Dark Mode)"),
            value: isDarkMode,
            onChanged: (val) {
              setState(() => isDarkMode = val);
              // TODO: save to shared_preferences
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
            leading: const Icon(Icons.language),
            title: const Text("ภาษา"),
            onTap: () {
              // TODO: เลือกภาษา
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
    );
  }
}
