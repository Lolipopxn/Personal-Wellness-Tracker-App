import 'package:flutter/material.dart';
import '../app/daily_task_api.dart';
import '../services/auth_service.dart';

class ActivitySection extends StatefulWidget {
  const ActivitySection({super.key});

  @override
  State<ActivitySection> createState() => _ActivitySectionState();
}

class _ActivitySectionState extends State<ActivitySection> {
  final List<_ActivityItem> activities = [];

  @override
  void initState() {
    super.initState();
    _loadActivitiesFromApi();
  }

  Future<void> _loadActivitiesFromApi() async {
    activities.clear();

    final loggedIn = await AuthService.isLoggedIn();
    if (!loggedIn) {
      if (mounted) setState(() {});
      return;
    }

    final daily = await DailyTaskApi.getDailyTask(DateTime.now());
    if (daily == null) {
      if (mounted) setState(() {});
      return;
    }

    final dailyTaskId = daily['id']?.toString();
    if (dailyTaskId == null || dailyTaskId.isEmpty) {
      if (mounted) setState(() {});
      return;
    }

    final tasks = await DailyTaskApi.getTasks(dailyTaskId);

    for (final t in tasks) {
      final id   = (t['id'] ?? '').toString();           // ⬅️ ดึงไอดีจริง
      final type = (t['task_type'] ?? '').toString();
      final text = (t['value_text'] ?? '').toString();
      final done = t['completed'] == true;

      final isActivity = type == 'activity' || type.startsWith('activity:');
      if (id.isNotEmpty && isActivity && done && text.isNotEmpty) {
        activities.add(_ActivityItem(taskId: id, taskType: type, text: text));
      }
    }

    if (mounted) setState(() {});
  }

  void showAddActivityDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("เพิ่มกิจกรรม"),
        backgroundColor: Colors.white,
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: "ชื่อกิจกรรม",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ยกเลิก"),
          ),
          ElevatedButton(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(Colors.green),
              foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
            ),
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isEmpty) {
                Navigator.pop(context);
                return;
              }

              try {
                await DailyTaskApi.ensureDailyTaskForToday();

                // ใช้ task_type ยูนีคเพื่อเก็บหลายกิจกรรมในวันเดียว
                final key = 'activity:${DateTime.now().millisecondsSinceEpoch}';

                await DailyTaskApi.addOrUpdateTaskForDate(
                  taskType: key,
                  value: {
                    'value_text': text,
                    'completed': true,
                  },
                  date: DateTime.now(),
                );

                // ⬇️ รีโหลดจาก API เพื่อให้ได้ taskId จริง
                await _loadActivitiesFromApi();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('บันทึกกิจกรรมเรียบร้อย')),
                  );
                }
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
                );
              }

              if (mounted) Navigator.pop(context);
            },
            child: const Text("ตกลง"),
          ),
        ],
      ),
    );
  }

  Future<void> _removeActivityAt(int index) async {
    final item = activities[index];

    try {
      // ⬅️ ลบด้วยไอดีจริงจากฐานข้อมูล
      await DailyTaskApi.deleteTaskById(item.taskId);

      if (!mounted) return;
      setState(() {
        activities.removeAt(index);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ลบกิจกรรมไม่สำเร็จ: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        width: MediaQuery.of(context).size.width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ElevatedButton(
                onPressed: showAddActivityDialog,
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(const Color(0xFF2E5077)),
                  foregroundColor: MaterialStateProperty.all<Color>(Colors.black),
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add, color: Colors.white),
                    SizedBox(width: 10),
                    Text('Add Activity', style: TextStyle(fontSize: 16, color: Colors.white)),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: activities.length,
                itemBuilder: (context, index) {
                  final activity = activities[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Card(
                      color: Colors.white,
                      shadowColor: Colors.black,
                      elevation: 6,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(children: [
                              const SizedBox(width: 7),
                              const Icon(Icons.check, color: Colors.green, size: 18),
                              const SizedBox(width: 8),
                              Text(activity.text, style: const TextStyle(fontSize: 18)),
                            ]),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                              onPressed: () => _removeActivityAt(index),
                            ),
                          ],
                        ),
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

class _ActivityItem {
  final String taskId;
  final String taskType;
  final String text;
  const _ActivityItem({
    required this.taskId,
    required this.taskType,
    required this.text,
  });
}
