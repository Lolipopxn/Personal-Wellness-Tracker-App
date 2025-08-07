import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import '../app/firestore_service.dart';

class MoodSelector extends StatefulWidget {
  const MoodSelector({super.key});

  @override
  _MoodSelectorState createState() => _MoodSelectorState();
}

class _MoodSelectorState extends State<MoodSelector> {
  final FirestoreService _firestoreService = FirestoreService();
  String? selectedMood;

  final List<String> moods = ["😃", "😊", "😐", "😢", "😠"];

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

              final exerciseData = {
                'MoodId': {'mood': selectedMood, 'isTaskCompleted': true},
              };

              try {
                await _firestoreService.saveDailyTask(
                  exerciseData,
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
