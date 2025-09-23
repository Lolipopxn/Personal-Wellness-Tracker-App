import 'package:flutter/material.dart';
import '../app/daily_task_api.dart';
import '../services/auth_service.dart';

Future<void> showSleepTrackingDialog(
  BuildContext context, {
  required void Function() onConfirmed,
}) async {
  // ---------- Prefill จาก API ----------
  String initialSleepTime = '';
  String initialWakeTime = '';
  String initialSleepQuality = 'ดี';

  TimeOfDay? sleepTod;
  TimeOfDay? wakeTod;

  try {
    final existingTask = await DailyTaskApi.getTaskForDate(
      taskType: 'sleep',
      date: DateTime.now(),
    );

    if (existingTask != null) {
      // backend ส่ง ISO8601 -> parse เป็น DateTime
      if (existingTask['started_at'] != null) {
        final dt = DateTime.parse(existingTask['started_at']).toLocal();
        sleepTod = TimeOfDay(hour: dt.hour, minute: dt.minute);
        initialSleepTime = sleepTod.format(context);
      }

      if (existingTask['ended_at'] != null) {
        final dt = DateTime.parse(existingTask['ended_at']).toLocal();
        wakeTod = TimeOfDay(hour: dt.hour, minute: dt.minute);
        initialWakeTime = wakeTod.format(context);
      }

      if (existingTask['task_quality'] != null) {
        initialSleepQuality = existingTask['task_quality'];
      }
    }
  } catch (e) {
    debugPrint("โหลดข้อมูลนอนเก่าไม่สำเร็จ: $e");
  }

  // ---------- Controllers ----------
  final sleepTimeController = TextEditingController(text: initialSleepTime);
  final wakeTimeController = TextEditingController(text: initialWakeTime);
  String sleepQuality = initialSleepQuality;

  await showDialog(
    context: context,
    builder: (context) {

      return StatefulBuilder(
        builder: (context, setState) {
          Future<void> pickTime(
            TextEditingController controller,
            void Function(TimeOfDay) onPicked,
          ) async {
            final TimeOfDay? picked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
              builder: (BuildContext context, Widget? child) {
                return Theme(
                  data: ThemeData(
                    colorScheme: const ColorScheme.light(
                      primary: Color(0xff79D7BE),
                      onPrimary: Colors.white,
                      onSurface: Colors.black,
                    ),
                    textButtonTheme: TextButtonThemeData(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              // แสดงในช่องเป็นข้อความอ่านง่าย
              controller.text = picked.format(context);
              // เก็บ TimeOfDay จริงไว้คำนวณ
              onPicked(picked);
            }
          }

          DateTime _combine(DateTime base, TimeOfDay tod) =>
              DateTime(base.year, base.month, base.day, tod.hour, tod.minute);

          return AlertDialog(
            // ... (title / content เดิม)
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => pickTime(
                    sleepTimeController,
                    (t) => setState(() => sleepTod = t),
                  ),
                  child: AbsorbPointer(
                    child: TextField(
                      controller: sleepTimeController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
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
                  onTap: () => pickTime(
                    wakeTimeController,
                    (t) => setState(() => wakeTod = t),
                  ),
                  child: AbsorbPointer(
                    child: TextField(
                      controller: wakeTimeController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.wb_sunny,
                          color: Colors.orange,
                        ),
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
                    prefixIcon: const Icon(Icons.star, color: Colors.green),
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
                  final sleepText = sleepTimeController.text.trim();
                  final wakeText = wakeTimeController.text.trim();

                  if (sleepText.isEmpty ||
                      wakeText.isEmpty ||
                      sleepTod == null ||
                      wakeTod == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('กรุณากรอกและเลือกเวลาเข้านอน/ตื่นนอน'),
                      ),
                    );
                    return;
                  }

                  final loggedIn = await AuthService.isLoggedIn();
                  if (!loggedIn) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('กรุณาล็อกอินก่อนบันทึกข้อมูล'),
                      ),
                    );
                    return;
                  }

                  final baseDate = DateTime.now();

                  DateTime startedAt = _combine(baseDate, sleepTod!);
                  DateTime endedAt = _combine(baseDate, wakeTod!);


                  try {
                    await DailyTaskApi.addOrUpdateTaskForDate(
                      taskType: 'sleep',
                      value: {
                        'task_quality': sleepQuality,
                        'started_at': startedAt.add(Duration(hours: 7)).toUtc().toIso8601String(),
                        'ended_at': endedAt.add(Duration(hours: 7)).toUtc().toIso8601String(),
                        'completed': true,
                      },
                      date: baseDate,
                    );

                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('บันทึกข้อมูลการนอนสำเร็จ')),
                    );
                    onConfirmed();
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
                    );
                  }

                  if (context.mounted) Navigator.pop(context);
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
