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
  String sleepQuality = taskData != null && taskData['sleepQuality'] != null
      ? taskData['sleepQuality']
      : 'ดี';

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          Future<void> pickTime(TextEditingController controller) async {
            final TimeOfDay? picked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
            );
            if (picked != null) {
              controller.text = picked.format(context);
            }
          }

          return AlertDialog(
            title: Text("ติดตามการนอน"),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
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
                        labelText: "เวลาเข้านอน",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                GestureDetector(
                  onTap: () => pickTime(wakeTimeController),
                  child: AbsorbPointer(
                    child: TextField(
                      controller: wakeTimeController,
                      decoration: InputDecoration(
                        labelText: "เวลาตื่นนอน",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: "คุณภาพการนอน",
                    border: OutlineInputBorder(),
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
                child: Text("ยกเลิก"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (sleepTimeController.text.isNotEmpty &&
                      wakeTimeController.text.isNotEmpty) {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('กรุณาล็อกอินก่อนบันทึกข้อมูล')),
                      );
                      return;
                    }

                    final exerciseData = {
                      'sleepTaskId': {
                        'sleepTime': sleepTimeController.text.trim(),
                        'wakeTime': wakeTimeController.text.trim(),
                        'sleepQuality': sleepQuality,
                        'isTaskCompleted': true,
                      },
                    };

                    try {
                      await _firestoreService.saveDailyTask(
                        exerciseData,
                        DateTime.now(),
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('บันทึกข้อมูลการนอนสำเร็จ')),
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
                child: Text("ตกลง"),
              ),
            ],
          );
        },
      );
    },
  );
}
