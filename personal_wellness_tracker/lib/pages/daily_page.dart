import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:personal_wellness_tracker/Dialog/dialogMood.dart';
import 'package:personal_wellness_tracker/Dialog/sleepDialog.dart';
import 'package:personal_wellness_tracker/Dialog/activityDialog.dart';

import 'package:firebase_auth/firebase_auth.dart';
import '../services/offline_data_service.dart';
import '../services/sync_service.dart';

class DailyPage extends StatefulWidget {
  const DailyPage({super.key});

  @override
  State<DailyPage> createState() => _Daily();
}

class _Daily extends State<DailyPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final OfflineDataService _offlineDataService = OfflineDataService();
  final SyncService _syncService = SyncService();

  bool isTask1 = false;
  bool isTask2 = false;
  bool isTask3 = false;
  bool isTask4 = false;

  Widget _buildDurationPicker(
    int selectedHour,
    int selectedMinute,
    Function(int, int) onConfirm,
  ) {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Padding(
          padding: EdgeInsets.only(bottom: 200.0, top: 30, left: 20, right: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            spacing: 50,
            children: [
              Text("เลือกระยะเวลา", style: TextStyle(fontSize: 24)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DropdownButton<int>(
                    value: selectedHour,
                    items: List.generate(
                      24,
                      (i) => DropdownMenuItem(
                        value: i,
                        child: Text("$i ชม", style: TextStyle(fontSize: 24)),
                      ),
                    ),
                    onChanged: (v) => setModalState(() => selectedHour = v!),
                  ),
                  SizedBox(width: 20),
                  DropdownButton<int>(
                    value: selectedMinute,
                    items: List.generate(
                      60,
                      (i) => DropdownMenuItem(
                        value: i,
                        child: Text("$i นาที", style: TextStyle(fontSize: 24)),
                      ),
                    ),
                    onChanged: (v) => setModalState(() => selectedMinute = v!),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                spacing: 10,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    onPressed: () => Navigator.pop(context),
                    child: Text("ยกเลิก", style: TextStyle(fontSize: 20)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => onConfirm(selectedHour, selectedMinute),
                    child: Text("ตกลง", style: TextStyle(fontSize: 20)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Map<String, dynamic>? taskData;

  Future<void> loadDailyTasks() async {
    try {
      final currentDate = DateTime.now();
      final dateString = '${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}';
      
      print('📋 Loading daily tasks for date: $dateString (${currentDate.toString()})');
      
      final taskData = await _offlineDataService.getDailyTask(DateTime.now());
      
      print('📋 Raw task data from database: $taskData');

      if (taskData != null) {
        print('📋 Task data found! Parsing individual tasks...');
        
        // Check Exercise Task
        bool exerciseCompleted = taskData.containsKey('exerciseId') && 
                                taskData['exerciseId']['isTaskCompleted'] == true;
        print('🏃 Exercise Task: ${taskData.containsKey('exerciseId') ? "Found" : "Not found"}');
        if (taskData.containsKey('exerciseId')) {
          print('   - Exercise data: ${taskData['exerciseId']}');
          print('   - Is completed: $exerciseCompleted');
        }
        
        // Check Water Task  
        bool waterCompleted = taskData.containsKey('waterTaskId') && 
                             taskData['waterTaskId']['isTaskCompleted'] == true;
        print('💧 Water Task: ${taskData.containsKey('waterTaskId') ? "Found" : "Not found"}');
        if (taskData.containsKey('waterTaskId')) {
          print('   - Water data: ${taskData['waterTaskId']}');
          print('   - Is completed: $waterCompleted');
        }
        
        // Check Sleep Task
        bool sleepCompleted = taskData.containsKey('sleepTaskId') && 
                             taskData['sleepTaskId']['isTaskCompleted'] == true;
        print('😴 Sleep Task: ${taskData.containsKey('sleepTaskId') ? "Found" : "Not found"}');
        if (taskData.containsKey('sleepTaskId')) {
          print('   - Sleep data: ${taskData['sleepTaskId']}');
          print('   - Is completed: $sleepCompleted');
        }
        
        // Check Mood Task
        bool moodCompleted = taskData.containsKey('MoodId') && 
                            taskData['MoodId']['isTaskCompleted'] == true;
        print('😊 Mood Task: ${taskData.containsKey('MoodId') ? "Found" : "Not found"}');
        if (taskData.containsKey('MoodId')) {
          print('   - Mood data: ${taskData['MoodId']}');
          print('   - Is completed: $moodCompleted');
        }
        
        setState(() {
          isTask1 = exerciseCompleted;
          isTask2 = waterCompleted;
          isTask3 = sleepCompleted;
          isTask4 = moodCompleted;
        });
        
        print('📋 Final task states: Exercise=$isTask1, Water=$isTask2, Sleep=$isTask3, Mood=$isTask4');
      } else {
        print('📋 No task data found for today');
        setState(() {
          isTask1 = false;
          isTask2 = false;
          isTask3 = false;
          isTask4 = false;
        });
      }
    } catch (e) {
      print("❌ Error loading daily tasks: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    loadDailyTasks();
    // เพิ่มการ sync ข้อมูลเมื่อเปิดหน้า
    _syncDataFromFirebase();
  }

  Future<void> _syncDataFromFirebase() async {
    try {
      // ใช้ SyncService เพื่อ sync ข้อมูลจาก Firebase
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('🔄 Starting sync from Firebase...');
        await _syncService.forceSyncFromFirestore();
        print('✅ Sync completed, reloading data...');
        // รอสักครู่แล้ว reload ข้อมูล
        Future.delayed(Duration(seconds: 1), () {
          loadDailyTasks();
        });
      }
    } catch (e) {
      print('❌ Sync error: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose(); //clear data
    _focusNode.dispose(); //clear focus
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String currentDate = DateFormat(
      'dd MMMM yyyy',
      'th',
    ).format(DateTime.now());
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
                        GestureDetector(
                          onTap: () async {
                            final taskData = await _offlineDataService.getDailyTask(DateTime.now());

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
                                      insetPadding: EdgeInsets.all(20),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      title: Text("การออกกำลังกายในวันนี้"),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        spacing: 20,
                                        children: [
                                          TextField(
                                            controller: nameController,
                                            decoration: InputDecoration(
                                              labelText: "ประเภท",
                                              border: OutlineInputBorder(),
                                            ),
                                          ),
                                          TextField(
                                            controller: categoryController,
                                            decoration: InputDecoration(
                                              labelText: "เเคลอรี่ที่เผาผลาญ",
                                              border: OutlineInputBorder(),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () async {
                                              int tempHour = hour;
                                              int tempMinute = minute;

                                              await showModalBottomSheet(
                                                context: context,
                                                builder: (context) =>
                                                    _buildDurationPicker(
                                                      tempHour,
                                                      tempMinute,
                                                      (h, m) {
                                                        setStateDialog(() {
                                                          hour = h;
                                                          minute = m;
                                                          timeController.text =
                                                              "$h ชั่วโมง $m นาที";
                                                        });
                                                        Navigator.pop(context);
                                                      },
                                                    ),
                                              );
                                            },
                                            child: AbsorbPointer(
                                              child: TextField(
                                                controller: timeController,
                                                decoration: InputDecoration(
                                                  labelText: "ระยะเวลา",
                                                  border: OutlineInputBorder(),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: Text("ยกเลิก"),
                                        ),
                                        ElevatedButton(
                                          style: ButtonStyle(
                                            backgroundColor:
                                                WidgetStateProperty.all(
                                                  Colors.green,
                                                ),
                                            foregroundColor:
                                                WidgetStateProperty.all(
                                                  Colors.white,
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
                                                await _offlineDataService
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

                                            print(
                                              "ประเภท: ${nameController.text}",
                                            );
                                            print(
                                              "ประเภท: ${categoryController.text}",
                                            );
                                            print(
                                              "ระยะเวลา: ${timeController.text}",
                                            );
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
                          },
                          child: Container(
                            padding: EdgeInsets.all(0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              spacing: 10,
                              children: [
                                Icon(
                                  isTask1
                                      ? Icons.check_box
                                      : Icons.check_box_outline_blank,
                                  color: isTask1 ? Colors.green : Colors.red,
                                  size: 20,
                                ),
                                Text(
                                  "บันทึกการออกกำลังกาย",
                                  style: TextStyle(
                                    color: isTask1 ? Colors.green : Colors.red,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        GestureDetector(
                          onTap: () async{
                            final taskData = await _offlineDataService.getDailyTask(DateTime.now());
                            final nameController = TextEditingController(text: taskData?['waterTaskId']?['total_drink'] ?? '');

                            showDialog(
                              context: context,
                              builder: (context) {
                                return StatefulBuilder(
                                  builder: (context, setStateDialog) {
                                    return AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      title: Text("การดื่มน้ำในวันนี้"),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextField(
                                            controller: nameController,
                                            decoration: InputDecoration(
                                              labelText:
                                                  "ดื่มกี่แก้ว/ลิตร ต่อวัน",
                                              border: OutlineInputBorder(),
                                            ),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: Text("ยกเลิก"),
                                        ),
                                        ElevatedButton(
                                          style: ButtonStyle(
                                            backgroundColor:
                                                WidgetStateProperty.all(
                                                  Colors.green,
                                                ),
                                            foregroundColor:
                                                WidgetStateProperty.all(
                                                  Colors.white,
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
                                                  SnackBar(
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
                                                await _offlineDataService
                                                    .saveDailyTask(
                                                      waterData,
                                                      DateTime.now(),
                                                    );

                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
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
                                          child: Text("ตกลง"),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.all(0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Icon(
                                  isTask2
                                      ? Icons.check_box
                                      : Icons.check_box_outline_blank,
                                  color: isTask2 ? Colors.green : Colors.red,
                                  size: 20,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  "บันทึกการดื่มน้ำ",
                                  style: TextStyle(
                                    color: isTask2 ? Colors.green : Colors.red,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        GestureDetector(
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
                          child: Container(
                            padding: EdgeInsets.all(0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Icon(
                                  isTask3
                                      ? Icons.check_box
                                      : Icons.check_box_outline_blank,
                                  color: isTask3 ? Colors.green : Colors.red,
                                  size: 20,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  "ติดตามการนอน",
                                  style: TextStyle(
                                    color: isTask3 ? Colors.green : Colors.red,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) {
                                return MoodSelector();
                              },
                            );
                          },
                          child: Row(
                            children: [
                              Icon(
                                isTask4
                                    ? Icons.check_box
                                    : Icons.check_box_outline_blank,
                                color: isTask4 ? Colors.green : Colors.red,
                                size: 20,
                              ),
                              SizedBox(width: 10),
                              Text(
                                "บันทึกอารมณ์วันนี้",
                                style: TextStyle(
                                  color: isTask4 ? Colors.green : Colors.red,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
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
