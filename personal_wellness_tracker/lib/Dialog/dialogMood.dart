import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import '../services/offline_data_service.dart';

class MoodSelector extends StatefulWidget {
  const MoodSelector({super.key});

  @override
  _MoodSelectorState createState() => _MoodSelectorState();
}

class _MoodSelectorState extends State<MoodSelector> {
  final OfflineDataService _offlineDataService = OfflineDataService();

  String? selectedMood;

  final List<String> moods = ["😃", "😊", "😐", "😢", "😠"];

  bool isLoading = true; // เพิ่มตัวแปรไว้รอโหลดข้อมูล

  @override
  void initState() {
    super.initState();
    _loadPreviousMood();
  }

  Future<void> _loadPreviousMood() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final taskData = await _offlineDataService.getDailyTask(DateTime.now());
    final moodData = taskData?['MoodId'] ?? {};

    if (mounted) {
      setState(() {
        selectedMood = moodData['mood'];
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("เลือกอารมณ์ของวันนี้"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 10,
            children: moods.map((emoji) {
              return ChoiceChip(
                label: Text(emoji, style: TextStyle(fontSize: 24)),
                selected: selectedMood == emoji,
                selectedColor: Colors.blue.shade100,
                backgroundColor: Colors.grey.shade200,
                onSelected: (_) {
                  setState(() {
                    selectedMood = emoji;
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text("ยกเลิก"),
        ),
        ElevatedButton(
          onPressed: () async {
            if (selectedMood != null) {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('กรุณาล็อกอินก่อนบันทึกข้อมูล')),
                );
                return;
              }

              final moodData = {
                'MoodId': {'mood': selectedMood, 'isTaskCompleted': true},
              };

              try {
                await _offlineDataService.saveDailyTask(
                  moodData,
                  DateTime.now(),
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('บันทึกข้อมูลอารมณ์สำเร็จ')),
                );
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
              }
            } else {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text("กรุณาเลือกอารมณ์")));
              return;
            }

            Navigator.pop(context);
          },
          child: Text("ตกลง"),
        ),
      ],
    );
  }
}