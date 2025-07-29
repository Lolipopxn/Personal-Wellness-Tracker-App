import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:personal_wellness_tracker/Dialog/dialogMood.dart';
import 'package:personal_wellness_tracker/Dialog/sleepDialog.dart';
import 'package:personal_wellness_tracker/Dialog/activityDialog.dart';

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
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 109, 234, 103),
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            IconButton(
              icon: const Icon(
                Icons.account_circle,
                size: 30,
                color: Colors.black54,
              ),
              onPressed: () {},
            ),
            const SizedBox(width: 8),
            const Text(
              '6510110165',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.black54),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black54),
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 30,
          children: [
            Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(50),
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 10,
              children: [
                Text(
                  "Daily Habit Tracking",
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    color: Colors.green.withAlpha(255),
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
              color: Colors.white,
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
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            final nameController = TextEditingController();
                            final categoryController = TextEditingController();
                            final timeController = TextEditingController();
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
                                      onPressed: () => Navigator.pop(context),
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
                                      onPressed: () {
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
                                        }
                                        print("ประเภท: ${nameController.text}");
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
                              color: isTask1 ? Colors.green : Colors.black,
                              size: 20,
                            ),
                            Text(
                              "บันทึกการออกกำลังกาย",
                              style: TextStyle(
                                color: isTask1 ? Colors.green : Colors.black,
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
                        final nameController = TextEditingController();

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
                                          labelText: "ดื่มกี่แก้ว/ลิตร ต่อวัน",
                                          border: OutlineInputBorder(),
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
                                      onPressed: () {
                                        if (nameController.text
                                            .trim()
                                            .isNotEmpty) {
                                          setState(() {
                                            isTask2 = true;
                                          });
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
                              color: isTask2 ? Colors.green : Colors.black,
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Text(
                              "บันทึกการดื่มน้ำ",
                              style: TextStyle(
                                color: isTask2 ? Colors.green : Colors.black,
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
                          onConfirmed: (saved) {
                            if (saved) {
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
                              color: isTask3 ? Colors.green : Colors.black,
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Text(
                              "ติดตามการนอน",
                              style: TextStyle(
                                color: isTask3 ? Colors.green : Colors.black,
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
                            return MoodSelector(
                              onConfirm: (mood) {
                                if (mood != null) {
                                  setState(() {
                                    isTask4 = true;
                                  });
                                  print("เลือกอารมณ์: $mood");
                                }
                              },
                            );
                          },
                        );
                      },
                      child: Row(
                        children: [
                          Icon(
                            isTask4
                                ? Icons.check_box
                                : Icons.check_box_outline_blank,
                            color: isTask4 ? Colors.green : Colors.black,
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Text(
                            "บันทึกอารมณ์วันนี้",
                            style: TextStyle(
                              color: isTask4 ? Colors.green : Colors.black,
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

            Divider(color: Colors.grey, thickness: 2, indent: 1, endIndent: 1),

            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "กิจกรรมอื่น ๆ",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
    );
  }
}
