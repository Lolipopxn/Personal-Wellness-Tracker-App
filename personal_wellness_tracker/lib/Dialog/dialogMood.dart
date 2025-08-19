import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import '../app/firestore_service.dart';

class MoodSelector extends StatefulWidget {
  final VoidCallback onConfirmed;

  const MoodSelector({super.key, required this.onConfirmed});

  @override
  _MoodSelectorState createState() => _MoodSelectorState();
}

class _MoodSelectorState extends State<MoodSelector> {
  final FirestoreService _firestoreService = FirestoreService();
  final taskData = FirestoreService().getDailyTask(DateTime.now());

  String? selectedMood;

  final List<String> moods = ["😃", "😊", "😐", "😢", "😠"];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreviousMood();
  }

  Future<void> _loadPreviousMood() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final taskData = await _firestoreService.getDailyTask(DateTime.now());
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
      backgroundColor: Colors.grey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Text(
            "อารมณ์วันนี้",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
          const SizedBox(width: 8),
          Text("💖", style: TextStyle(fontSize: 26)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: moods.map((emoji) {
              bool isSelected = selectedMood == emoji;
              return ChoiceChip(
                label: Text(emoji, style: TextStyle(fontSize: 28)),
                selected: isSelected,
                selectedColor: Colors.greenAccent.shade100,
                backgroundColor: Colors.white,
                shadowColor: Colors.grey.shade300,
                elevation: isSelected ? 4 : 2,
                pressElevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isSelected ? Colors.green : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
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
      actionsPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      actions: [
        TextButton(
          style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
          onPressed: () => Navigator.pop(context),
          child: Text("ยกเลิก", style: TextStyle(fontSize: 16)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
          ),
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
                await _firestoreService.saveDailyTask(moodData, DateTime.now());

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('บันทึกข้อมูลอารมณ์สำเร็จ')),
                );

                widget.onConfirmed();
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
          child: Text("ตกลง", style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }
}
