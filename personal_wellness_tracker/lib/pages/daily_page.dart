import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:personal_wellness_tracker/Dialog/dialogMood.dart';
import 'package:personal_wellness_tracker/Dialog/sleepDialog.dart';
import 'package:personal_wellness_tracker/Dialog/activityDialog.dart';

import 'package:firebase_auth/firebase_auth.dart';
import '../app/firestore_service.dart';

class DailyPage extends StatefulWidget {
  const DailyPage({super.key});

  @override
  State<DailyPage> createState() => _Daily();
}

class _Daily extends State<DailyPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final FirestoreService _firestoreService = FirestoreService();

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

  Future<void> loadDailyTasks() async {
    try {
      final taskData = await _firestoreService.getDailyTask(DateTime.now());

      if (taskData != null) {
        setState(() {
          isTask1 =
              taskData.containsKey('exerciseId') &&
              taskData['exerciseId']['isTaskCompleted'] == true;

          isTask2 =
              taskData.containsKey('waterTaskId') &&
              taskData['waterTaskId']['isTaskCompleted'] == true;

          isTask3 =
              taskData.containsKey('sleepTaskId') &&
              taskData['sleepTaskId']['isTaskCompleted'] == true;

          isTask4 =
              taskData.containsKey('MoodId') &&
              taskData['MoodId']['isTaskCompleted'] == true;
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
                            final taskData = await _firestoreService
                                .getDailyTask(DateTime.now());

                            showDialog(
                              context: context,
                              builder: (context) {
                                final exercise = taskData?['exerciseId'];
                                final nameController = TextEditingController(
                                  text: exercise != null
                                      ? exercise['type']
                                      : '',
                                );
                                final categoryController =
                                    TextEditingController(
                                      text: exercise != null
                                          ? exercise['calories']
                                          : '',
                                    );
                                final timeController = TextEditingController(
                                  text: exercise != null
                                      ? exercise['duration']
                                      : '',
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
                                        children: [
                                          Icon(
                                            Icons.fitness_center,
                                            color: Colors.green,
                                            size: 26,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            "การออกกำลังกายในวันนี้",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                      content: SingleChildScrollView(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            /// Exercise Type
                                            TextField(
                                              controller: nameController,
                                              decoration: InputDecoration(
                                                labelText: "ประเภท",
                                                prefixIcon: Icon(
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

                                            /// Calories Burned
                                            TextField(
                                              controller: categoryController,
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: InputDecoration(
                                                labelText: "แคลอรี่ที่เผาผลาญ",
                                                prefixIcon: Icon(
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

                                            /// Duration Picker
                                            GestureDetector(
                                              onTap: () async {
                                                int tempHour = hour;
                                                int tempMinute = minute;

                                                await showModalBottomSheet(
                                                  shape: RoundedRectangleBorder(
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
                                                    prefixIcon: Icon(
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
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.grey[600],
                                          ),
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: Text(
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
                                                    .isNotEmpty &&
                                                categoryController.text
                                                    .trim()
                                                    .isNotEmpty &&
                                                timeController.text
                                                    .trim()
                                                    .isNotEmpty) {
                                              setState(() {
                                                isTask1 = true;
                                              });

                                              final user = FirebaseAuth
                                                  .instance
                                                  .currentUser;
                                              if (user == null) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'กรุณาล็อกอินก่อนบันทึกข้อมูล',
                                                    ),
                                                  ),
                                                );
                                                return;
                                              }

                                              final exerciseData = {
                                                'exerciseId': {
                                                  'type': nameController.text
                                                      .trim(),
                                                  'calories': categoryController
                                                      .text
                                                      .trim(),
                                                  'duration':
                                                      '$hour ชั่วโมง $minute นาที',
                                                  'isTaskCompleted': true,
                                                },
                                              };

                                              try {
                                                await _firestoreService
                                                    .saveDailyTask(
                                                      exerciseData,
                                                      DateTime.now(),
                                                    );

                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'บันทึกข้อมูลการออกกำลังกายสำเร็จ',
                                                    ),
                                                  ),
                                                );
                                              } catch (e) {
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
                                          child: Text(
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
                            final taskData = await _firestoreService
                                .getDailyTask(DateTime.now());
                            final nameController = TextEditingController(
                              text:
                                  taskData?['waterTaskId']?['total_drink'] ??
                                  '',
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
                                              final user = FirebaseAuth
                                                  .instance
                                                  .currentUser;
                                              if (user == null) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'กรุณาล็อกอินก่อนบันทึกข้อมูล',
                                                    ),
                                                  ),
                                                );
                                                return;
                                              }

                                              final waterData = {
                                                'waterTaskId': {
                                                  'total_drink': nameController
                                                      .text
                                                      .trim(),
                                                  'isTaskCompleted': true,
                                                },
                                              };

                                              try {
                                                await _firestoreService
                                                    .saveDailyTask(
                                                      waterData,
                                                      DateTime.now(),
                                                    );

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
                              onConfirmed: () {
                                if (mounted) {
                                  setState(() {
                                    isTask3 = true;
                                  });
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
                                  onConfirmed: () {
                                    if (mounted) {
                                      setState(() {
                                        isTask4 = true;
                                      });
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
