import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import '../app/firestore_service.dart';

class ActivitySection extends StatefulWidget {
  const ActivitySection({super.key});

  @override
  State<ActivitySection> createState() => _ActivitySectionState();
}

class _ActivitySectionState extends State<ActivitySection> {
  List<String> activities = [];
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _loadActivitiesFromFirestore();
  }

  Future<void> _loadActivitiesFromFirestore() async {
    final task = await _firestoreService.getDailyTask(DateTime.now());
    if (task != null && task['activities'] != null) {
      final List<dynamic> rawActivities = task['activities'];
      final List<String> loaded = rawActivities
          .map((item) => item['activity']?.toString() ?? '')
          .where((item) => item.isNotEmpty)
          .toList();

      setState(() {
        activities = loaded;
      });
    }
  }

  void showAddActivityDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("เพิ่มกิจกรรม"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: "ชื่อกิจกรรม",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("ยกเลิก"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                final newActivityText = controller.text.trim();

                final user = FirebaseAuth.instance.currentUser;
                if (user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('กรุณาล็อกอินก่อนบันทึกข้อมูล')),
                  );
                  return;
                }

                final newActivity = {
                  'activity': newActivityText,
                  'isTaskCompleted': true,
                };

                final exerciseData = {
                  'activities': FieldValue.arrayUnion([newActivity]),
                };

                try {
                  await _firestoreService.saveDailyTask(
                    exerciseData,
                    DateTime.now(),
                  );

                  setState(() {
                    activities.add(newActivityText);
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('บันทึกกิจกรรมเรียบร้อย')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
                }
              }

              Navigator.pop(context);
            },
            child: Text("ตกลง"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20),
        width: MediaQuery.of(context).size.width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: showAddActivityDialog,
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(Color(0xFF2E5077)),
                    foregroundColor: WidgetStateProperty.all(Colors.black),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.add, color: Colors.white),
                      SizedBox(width: 10),
                      Text(
                        'Add Activity',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: activities.length,
                itemBuilder: (context, index) {
                  final activity = activities[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Card.filled(
                      color: Colors.white,
                      shadowColor: Colors.black,
                      elevation: 6,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SizedBox(width: 15),
                              Icon(Icons.check, color: Colors.green, size: 18),
                              SizedBox(width: 8),
                              Text(activity, style: TextStyle(fontSize: 18)),
                            ],
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: 18,
                            ),
                            onPressed: () async {
                              final user = FirebaseAuth.instance.currentUser;
                              if (user == null) return;

                              final activityToRemove = {
                                'activity': activity,
                                'isTaskCompleted': true,
                              };

                              try {
                                await _firestoreService.saveDailyTask({
                                  'activities': FieldValue.arrayRemove([
                                    activityToRemove,
                                  ]),
                                }, DateTime.now());

                                setState(() {
                                  activities.removeAt(index);
                                });
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('ลบกิจกรรมไม่สำเร็จ: $e'),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
