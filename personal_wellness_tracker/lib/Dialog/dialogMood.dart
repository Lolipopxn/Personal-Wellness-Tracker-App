import 'package:flutter/material.dart';
import '../app/daily_task_api.dart';
import '../services/auth_service.dart';

class MoodSelector extends StatefulWidget {
  final VoidCallback onConfirmed;

  const MoodSelector({super.key, required this.onConfirmed});

  @override
  _MoodSelectorState createState() => _MoodSelectorState();
}

class _MoodSelectorState extends State<MoodSelector> {
  String? selectedMood;
  bool isLoading = true;

  final List<String> moods = ["😃", "😊", "😐", "😢", "😠"];

  @override
  void initState() {
    super.initState();
    _loadPreviousMood();
  }

  Future<void> _loadPreviousMood() async {
    try {
      final loggedIn = await AuthService.isLoggedIn();
      if (!loggedIn) {
        if (mounted) setState(() => isLoading = false);
        return;
      }

      final daily = await DailyTaskApi.getDailyTask(DateTime.now());
      if (daily == null) {
        if (mounted) setState(() => isLoading = false);
        return;
      }

      final dailyTaskId = daily['id']?.toString();
      if (dailyTaskId == null || dailyTaskId.isEmpty) {
        if (mounted) setState(() => isLoading = false);
        return;
      }

      final tasks = await DailyTaskApi.getTasks(dailyTaskId);

      String? moodText;
      for (final t in tasks) {
        if (t['task_type'] == 'mood') {
          moodText = t['value_text'] as String?;
          break;
        }
      }

      if (mounted) {
        setState(() {
          selectedMood = moodText;
          isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _saveMood() async {
    if (selectedMood == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("กรุณาเลือกอารมณ์")));
      return;
    }

    try {
      await DailyTaskApi.addOrUpdateTaskForDate(
        taskType: 'mood',
        value: {
          'value_text': selectedMood,
          'completed': true,
        },
        date: DateTime.now(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('บันทึกข้อมูลอารมณ์สำเร็จ')));
      widget.onConfirmed();
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: const [
          Text("อารมณ์วันนี้", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
          SizedBox(width: 8),
          Text("💖", style: TextStyle(fontSize: 26)),
        ],
      ),
      content: isLoading
          ? const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: moods.map((emoji) {
                    final isSelected = selectedMood == emoji;
                    return ChoiceChip(
                      label: Text(emoji, style: const TextStyle(fontSize: 28)),
                      selected: isSelected,
                      selectedColor: Colors.greenAccent.shade100,
                      backgroundColor: Colors.white,
                      shadowColor: Colors.grey.shade300,
                      elevation: isSelected ? 4 : 2,
                      pressElevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isSelected ? Colors.green : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      onSelected: (_) {
                        setState(() => selectedMood = emoji);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      actions: [
        TextButton(
          style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
          onPressed: () => Navigator.pop(context),
          child: const Text("ยกเลิก", style: TextStyle(fontSize: 16)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
          ),
          onPressed: isLoading ? null : _saveMood,
          child: const Text("ตกลง", style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }
}