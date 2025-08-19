import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import '../app/firestore_service.dart';

Future<void> showSleepTrackingDialog(
  BuildContext context, {
  required void Function() onConfirmed,
}) async {
  final FirestoreService _firestoreService = FirestoreService();
  final taskData = await _firestoreService.getDailyTask(DateTime.now());

  final sleepTimeController = TextEditingController(
    text: taskData?['sleepTaskId']?['sleepTime'] ?? '',
  );
  final wakeTimeController = TextEditingController(
    text: taskData?['sleepTaskId']?['wakeTime'] ?? '',
  );
  String sleepQuality = taskData?['sleepTaskId']?['sleepQuality'] ?? 'ดี';

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          Future<void> pickTime(TextEditingController controller) async {
            final TimeOfDay? picked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
              builder: (BuildContext context, Widget? child) {
                return Theme(
                  data: ThemeData(
                    colorScheme: ColorScheme.light(
                      primary: Color(0xff79D7BE),
                      onPrimary: Colors.white,
                      onSurface: Colors.black,
                    ),
                    textButtonTheme: TextButtonThemeData(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black, //Cancel
                      ),
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              controller.text = picked.format(context);
            }
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Colors.white,
            title: Row(
              children: [
                Icon(Icons.bedtime, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Text(
                  "ติดตามการนอน",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 4),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => pickTime(sleepTimeController),
                  child: AbsorbPointer(
                    child: TextField(
                      controller: sleepTimeController,
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.nightlight_round,
                          color: Colors.deepPurple,
                        ),
                        labelText: "เวลาเข้านอน",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => pickTime(wakeTimeController),
                  child: AbsorbPointer(
                    child: TextField(
                      controller: wakeTimeController,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.wb_sunny, color: Colors.orange),
                        labelText: "เวลาตื่นนอน",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.star, color: Colors.green),
                    labelText: "คุณภาพการนอน",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: sleepQuality,
                      items: ['ดี', 'ปานกลาง', 'แย่']
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          sleepQuality = value!;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("ยกเลิก"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  if (sleepTimeController.text.isNotEmpty &&
                      wakeTimeController.text.isNotEmpty) {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('กรุณาล็อกอินก่อนบันทึกข้อมูล'),
                        ),
                      );
                      return;
                    }

                    final sleepData = {
                      'sleepTaskId': {
                        'sleepTime': sleepTimeController.text.trim(),
                        'wakeTime': wakeTimeController.text.trim(),
                        'sleepQuality': sleepQuality,
                        'isTaskCompleted': true,
                      },
                    };

                    try {
                      await _firestoreService.saveDailyTask(
                        sleepData,
                        DateTime.now(),
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('บันทึกข้อมูลการนอนสำเร็จ'),
                        ),
                      );

                      onConfirmed();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
                      );
                    }
                  }

                  Navigator.pop(context);
                },
                child: const Text("ตกลง"),
              ),
            ],
          );
        },
      );
    },
  );
}
