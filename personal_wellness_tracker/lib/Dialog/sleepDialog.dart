import 'package:flutter/material.dart';

Future<void> showSleepTrackingDialog(
  BuildContext context, {
  required void Function(bool isSaved) onConfirmed,
}) async {

  final sleepTimeController = TextEditingController();
  final wakeTimeController = TextEditingController();
  String sleepQuality = 'ดี';

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
                          .map((value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ))
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
                onPressed: () {
                  if (sleepTimeController.text.isNotEmpty &&
                      wakeTimeController.text.isNotEmpty) {
                    onConfirmed(true); 
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
