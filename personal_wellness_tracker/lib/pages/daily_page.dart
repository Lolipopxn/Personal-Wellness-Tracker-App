import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:personal_wellness_tracker/Dialog/dialogMood.dart';
import 'package:personal_wellness_tracker/Dialog/sleepDialog.dart';
import 'package:personal_wellness_tracker/Dialog/activityDialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/daily_task_api.dart';

class DailyPage extends StatefulWidget {
  const DailyPage({super.key});

  @override
  State<DailyPage> createState() => _Daily();
}

class _Daily extends State<DailyPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool isTask1 = false;
  bool isTask2 = false;
  bool isTask3 = false;
  bool isTask4 = false;

  late Timer _timer;
  late DateTime _now;

  Widget _buildDurationPicker(
    int selectedHour,
    int selectedMinute,
    Function(int, int) onConfirm,
  ) {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Padding(
          padding: const EdgeInsets.only(
            bottom: 200.0,
            top: 30,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Center all elements
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment
                .stretch, // Stretch children for better alignment
            children: [
              // Title for the picker
              Text(
                "เลือกระยะเวลา",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50), // A deep, calming blue
                ),
              ),
              const SizedBox(
                height: 40,
              ), // More vertical space for a cleaner look
              // Time selection row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Hour Dropdown
                  _buildDropdown(
                    value: selectedHour,
                    items: List.generate(
                      24,
                      (i) => DropdownMenuItem(
                        value: i,
                        child: Text(
                          "$i ชม.",
                          style: TextStyle(
                            fontSize: 24,
                            color: Color(0xFF34495E),
                          ),
                        ),
                      ),
                    ),
                    onChanged: (v) => setModalState(() => selectedHour = v!),
                  ),
                  const SizedBox(width: 20),
                  // Minute Dropdown
                  _buildDropdown(
                    value: selectedMinute,
                    items: List.generate(
                      60,
                      (i) => DropdownMenuItem(
                        value: i,
                        child: Text(
                          "$i นาที",
                          style: TextStyle(
                            fontSize: 24,
                            color: Color(0xFF34495E),
                          ),
                        ),
                      ),
                    ),
                    onChanged: (v) => setModalState(() => selectedMinute = v!),
                  ),
                ],
              ),
              const SizedBox(height: 50), // Increased spacing between rows
              // Action buttons row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Cancel button
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "ยกเลิก",
                        style: TextStyle(
                          fontSize: 20,
                          color: Color(
                            0xFF95A5A6,
                          ), // A muted gray for a softer feel
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Confirm button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => onConfirm(selectedHour, selectedMinute),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(
                          0xFF2ECC71,
                        ), // A fresh, vibrant green
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            10,
                          ), // Rounded corners
                        ),
                      ),
                      child: Text("ตกลง", style: TextStyle(fontSize: 20)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // A helper function to apply consistent styling to the DropdownButton
  Widget _buildDropdown({
    required int value,
    required List<DropdownMenuItem<int>> items,
    required Function(int?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Color(0xFFECF0F1), // A light, neutral background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFBDC3C7)), // Subtle border
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          items: items,
          onChanged: onChanged,
          style: TextStyle(fontSize: 24, color: Color(0xFF34495E)),
          dropdownColor: Colors.white,
        ),
      ),
    );
  }

  Map<String, dynamic>? taskData;

  Future<bool> _isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token') != null;
  }

  Future<void> loadDailyTasks() async {
    try {
      final hasLogin = await _isLoggedIn();
      if (!hasLogin) return;

      final dailyTask = await DailyTaskApi.getDailyTask(DateTime.now());
      if (!mounted) return;

      if (dailyTask != null) {
        // ดึง tasks ทั้งหมดของ dailyTask นี้
        final tasks = await DailyTaskApi.getTasks(dailyTask['id']);

        bool task1 = false;
        bool task2 = false;
        bool task3 = false;
        bool task4 = false;

        for (final t in tasks) {
          if (t['task_type'] == 'exercise' && t['completed'] == true) {
            task1 = true;
          }
          if (t['task_type'] == 'water' && t['completed'] == true) {
            task2 = true;
          }
          if (t['task_type'] == 'sleep' && t['completed'] == true) {
            task3 = true;
          }
          if (t['task_type'] == 'mood' && t['completed'] == true) {
            task4 = true;
          }
        }

        setState(() {
          isTask1 = task1;
          isTask2 = task2;
          isTask3 = task3;
          isTask4 = task4;
        });
      }
    } catch (e) {
      print("เกิดข้อผิดพลาดในการโหลดข้อมูล: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    loadDailyTasks();
    _now = DateTime.now();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose(); //clear data
    _focusNode.dispose(); //clear focus
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String currentDate = DateFormat(
      'dd MMMM yyyy ( HH:mm:ss )',
      'th',
    ).format(_now);
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 30),
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 30,
              children: [
                Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).cardTheme.color ?? Color(0xFFF6F4F0),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(20),
                        blurRadius: 5,
                        offset: Offset(0, 2), // changes position of shadow
                      ),
                    ],
                  ),
                  child: Text(
                    'วันนี้: $currentDate',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color:
                          Theme.of(context).appBarTheme.foregroundColor ??
                          Color(0xFF2E5077),
                    ),
                  ),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: 10,
                  children: [
                    Icon(Icons.assignment, color: Color(0xFF2E5077), size: 30),
                    Text(
                      "Daily Habit Tracking",
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1FAB89).withAlpha(255),
                        shadows: [
                          Shadow(
                            color: Colors.black.withAlpha(50),
                            offset: Offset(5, 3),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey, thickness: 2)),
                  ],
                ),

                Card.outlined(
                  color: Theme.of(context).cardTheme.color ?? Colors.white,
                  shadowColor: Colors.black,
                  elevation: 10,
                  child: Container(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      spacing: 10,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isTask1
                                ? Colors.green
                                : Colors.red,
                            radius: 20,
                            child: const Icon(
                              Icons.fitness_center,
                              color: Colors.white,
                              size: 25,
                            ),
                          ),
                          title: Text(
                            "การออกกำลังกาย",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isTask1 ? Colors.green : Colors.red,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey,
                          ),
                          onTap: () async {
                            final daily =
                                await DailyTaskApi.getDailyTask(
                                  DateTime.now(),
                                ) ??
                                await DailyTaskApi.ensureDailyTaskForToday();

                            final dailyTaskId = daily['id']?.toString();
                            if (dailyTaskId == null || dailyTaskId.isEmpty)
                              return;

                            final tasks = await DailyTaskApi.getTasks(
                              dailyTaskId,
                            );

                            Map<String, dynamic>? exerciseTask;
                            for (final t in tasks) {
                              if (t['task_type'] == 'exercise') {
                                exerciseTask = t;
                                break;
                              }
                            }

                            final String? valueText =
                                (exerciseTask?['value_text'] as String?);
                            final String? valueNumberStr =
                                (exerciseTask?['value_number']?.toString());

                            String initialName = '';
                            String initialTime = '';
                            if (valueText != null &&
                                valueText.contains(' - ')) {
                              final parts = valueText.split(' - ');
                              initialName = parts.isNotEmpty ? parts[0] : '';
                              initialTime = parts.length > 1 ? parts[1] : '';
                            } else if (valueText != null) {
                              initialName = valueText;
                            }

                            showDialog(
                              context: context,
                              builder: (context) {
                                final nameController = TextEditingController(
                                  text: initialName,
                                );
                                final timeController = TextEditingController(
                                  text: initialTime,
                                );
                                final caloriesController =
                                    TextEditingController(
                                      text: valueNumberStr ?? '',
                                    );
                                int hour = 0, minute = 0;

                                return StatefulBuilder(
                                  builder: (context, setStateDialog) {
                                    return AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      backgroundColor: Colors.white,
                                      title: Row(
                                        children: const [
                                          Icon(
                                            Icons.fitness_center,
                                            color: Colors.green,
                                            size: 26,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            "การออกกำลังกายในวันนี้",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                            ),
                                          ),
                                        ],
                                      ),
                                      content: SingleChildScrollView(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            TextField(
                                              controller: nameController,
                                              decoration: InputDecoration(
                                                labelText: "ประเภท",
                                                prefixIcon: const Icon(
                                                  Icons.directions_run,
                                                ),
                                                filled: true,
                                                fillColor: Colors.grey[100],
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  borderSide: BorderSide.none,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 15),
                                            TextField(
                                              controller: caloriesController,
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: InputDecoration(
                                                labelText: "แคลอรี่ที่เผาผลาญ",
                                                prefixIcon: const Icon(
                                                  Icons.local_fire_department,
                                                ),
                                                filled: true,
                                                fillColor: Colors.grey[100],
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  borderSide: BorderSide.none,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 15),
                                            GestureDetector(
                                              onTap: () async {
                                                int tempHour = hour;
                                                int tempMinute = minute;

                                                await showModalBottomSheet(
                                                  shape: const RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.vertical(
                                                          top: Radius.circular(
                                                            20,
                                                          ),
                                                        ),
                                                  ),
                                                  context: context,
                                                  builder: (context) =>
                                                      _buildDurationPicker(
                                                        tempHour,
                                                        tempMinute,
                                                        (h, m) {
                                                          setStateDialog(() {
                                                            hour = h;
                                                            minute = m;
                                                            timeController
                                                                    .text =
                                                                "$h ชั่วโมง $m นาที";
                                                          });
                                                          Navigator.pop(
                                                            context,
                                                          );
                                                        },
                                                      ),
                                                );
                                              },
                                              child: AbsorbPointer(
                                                child: TextField(
                                                  controller: timeController,
                                                  decoration: InputDecoration(
                                                    labelText: "ระยะเวลา",
                                                    prefixIcon: const Icon(
                                                      Icons.timer,
                                                    ),
                                                    filled: true,
                                                    fillColor: Colors.grey[100],
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      borderSide:
                                                          BorderSide.none,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      actionsPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 10,
                                          ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text(
                                            "ยกเลิก",
                                            style: TextStyle(
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 12,
                                            ),
                                          ),
                                          onPressed: () async {
                                            if (nameController.text
                                                    .trim()
                                                    .isEmpty ||
                                                caloriesController.text
                                                    .trim()
                                                    .isEmpty ||
                                                timeController.text
                                                    .trim()
                                                    .isEmpty) {
                                              return;
                                            }

                                            setState(() => isTask1 = true);

                                            final exerciseData = {
                                              'exercise': {
                                                'task_type': 'exercise',
                                                'value_text':
                                                    '${nameController.text.trim()} - ${timeController.text.trim()}',
                                                'value_number':
                                                    double.tryParse(
                                                      caloriesController.text
                                                          .trim(),
                                                    ) ??
                                                    0.0,
                                                'completed': true,
                                              },
                                            };

                                            try {
                                              await DailyTaskApi.saveDailyTask(
                                                exerciseData,
                                                DateTime.now(),
                                              );
                                              await loadDailyTasks();
                                              if (!mounted) return;
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'บันทึกข้อมูลการออกกำลังกายสำเร็จ',
                                                  ),
                                                ),
                                              );
                                            } catch (e) {
                                              if (!mounted) return;
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'เกิดข้อผิดพลาด: $e',
                                                  ),
                                                ),
                                              );
                                            }

                                            if (mounted) Navigator.pop(context);
                                          },
                                          child: const Text(
                                            "บันทึก",
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                        Divider(color: Colors.grey[300]),

                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isTask2
                                ? Colors.green
                                : Colors.red,
                            radius: 20,
                            child: const Icon(
                              Icons.local_drink,
                              color: Colors.white,
                              size: 25,
                            ),
                          ),
                          title: Text(
                            "บันทึกการดื่มน้ำ",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isTask2 ? Colors.green : Colors.red,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey,
                          ),
                          onTap: () async {
                            final daily =
                                await DailyTaskApi.getDailyTask(
                                  DateTime.now(),
                                ) ??
                                await DailyTaskApi.ensureDailyTaskForToday();

                            final dailyTaskId = daily['id']?.toString();
                            if (dailyTaskId == null || dailyTaskId.isEmpty)
                              return;

                            final tasks = await DailyTaskApi.getTasks(
                              dailyTaskId,
                            );

                            Map<String, dynamic>? exerciseTask;
                            for (final t in tasks) {
                              if (t['task_type'] == 'exercise') {
                                exerciseTask = t;
                                break;
                              }
                            }

                            final String? valueNumberStr =
                                (exerciseTask?['value_number']?.toString());

                            final nameController = TextEditingController(
                              text: valueNumberStr ?? '',
                            );

                            showDialog(
                              context: context,
                              builder: (context) {
                                return StatefulBuilder(
                                  builder: (context, setStateDialog) {
                                    return AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      backgroundColor: Colors.white,
                                      title: Row(
                                        children: [
                                          Icon(
                                            Icons.local_drink,
                                            color: Colors.blue,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            "การดื่มน้ำในวันนี้",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text("💧"),
                                        ],
                                      ),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextField(
                                            controller: nameController,
                                            decoration: InputDecoration(
                                              labelText:
                                                  "ดื่มกี่แก้ว/ลิตร ต่อวัน",
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            keyboardType: TextInputType.number,
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text("ยกเลิก"),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          onPressed: () async {
                                            if (nameController.text
                                                .trim()
                                                .isNotEmpty) {
                                              setState(() {
                                                isTask2 = true;
                                              });

                                              final waterData = {
                                                'water': {
                                                  'task_type': 'water',
                                                  'value_number':
                                                      double.tryParse(
                                                        nameController.text
                                                            .trim(),
                                                      ) ??
                                                      0.0,
                                                  'completed': true,
                                                },
                                              };

                                              try {
                                                await DailyTaskApi.saveDailyTask(
                                                  waterData,
                                                  DateTime.now(),
                                                );
                                                await loadDailyTasks();
                                                if (!mounted) return;
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'บันทึกข้อมูลการดื่มน้ำสำเร็จ',
                                                    ),
                                                  ),
                                                );
                                              } catch (e) {
                                                if (!mounted) return;
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'เกิดข้อผิดพลาด: $e',
                                                    ),
                                                  ),
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
                          },
                        ),
                        Divider(color: Colors.grey[300]),

                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isTask3
                                ? Colors.green
                                : Colors.red,
                            radius: 20,
                            child: const Icon(
                              Icons.bedtime,
                              color: Colors.white,
                              size: 25,
                            ),
                          ),
                          title: Text(
                            "ติดตามการนอน",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isTask3 ? Colors.green : Colors.red,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey,
                          ),
                          onTap: () {
                            showSleepTrackingDialog(
                              context,
                              onConfirmed: () async {
                                if (mounted) {
                                  setState(() => isTask3 = true);

                                  try {
                                    await loadDailyTasks();
                                  } catch (e) {
                                    print('Error saving sleep data: $e');
                                  }
                                }
                              },
                            );
                          },
                        ),
                        Divider(color: Colors.grey[300]),

                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isTask4
                                ? Colors.green
                                : Colors.red,
                            child: const Icon(Icons.mood, color: Colors.white),
                          ),
                          title: Text(
                            "บันทึกอารมณ์วันนี้",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isTask4 ? Colors.green : Colors.red,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey,
                          ),
                          onTap: () {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) {
                                return MoodSelector(
                                  onConfirmed: () async {
                                    if (mounted) {
                                      setState(() => isTask4 = true);
                                      
                                      try {
                                        await loadDailyTasks();
                                      } catch (e) {
                                        print('Error saving mood data: $e');
                                      }
                                    }
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                Divider(
                  color: Colors.grey,
                  thickness: 2,
                  indent: 1,
                  endIndent: 1,
                ),

                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      spacing: 10,
                      children: [
                        Icon(
                          Icons.tag_faces,
                          size: 25,
                          color: Color(0xFF2E5077),
                        ),
                        Text(
                          "กิจกรรมอื่น ๆ",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1FAB89).withAlpha(255),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [Expanded(child: ActivitySection())],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
