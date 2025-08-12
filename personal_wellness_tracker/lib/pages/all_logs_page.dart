import 'package:flutter/material.dart';
import '../app/firestore_service.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('บันทึกทั้งหมด'),
        backgroundColor: Color(0xFF79D7BE),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _firestoreService.fetchAllLogs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'เกิดข้อผิดพลาด: ${snapshot.error}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.redAccent,
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(
              child: Text('ไม่มีข้อมูลบันทึก', style: TextStyle(fontSize: 16)),
            );
          }

          final foodLogs =
              snapshot.data!['foodLogs'] as Map<String, List<dynamic>>;
          // debugPrint('Food Logs: $foodLogs'); // Debugging line
          final taskLogs = snapshot.data!['taskLogs'] as Map<String, dynamic>;
          // debugPrint('Food Logs: $taskLogs');

          String normalizeDateString(String dateStr) {
            final dt = DateTime.parse(dateStr);
            final year = dt.year.toString();
            final month = dt.month.toString().padLeft(2, '0');
            final day = dt.day.toString().padLeft(2, '0');
            return '$year-$month-$day';
          }

          Set<String> normalizedDates = {};

          for (var key in foodLogs.keys) {
            final mealsList = foodLogs[key];
            if (mealsList != null) {
              for (var meal in mealsList) {
                if (meal is Map<String, dynamic> &&
                    meal.containsKey('lastModified')) {
                  final lastModifiedStr = meal['lastModified'] as String;
                  final normalizedDate = normalizeDateString(lastModifiedStr);
                  normalizedDates.add(normalizedDate);
                }
              }
            }
          }

          for (var key in taskLogs.keys) {
            normalizedDates.add(normalizeDateString(key));
          }

          final allDates = normalizedDates.toList();
          allDates.sort((a, b) => b.compareTo(a));

          if (allDates.isEmpty) {
            return const Center(
              child: Text('ไม่มีข้อมูลบันทึก', style: TextStyle(fontSize: 16)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: allDates.length,
            itemBuilder: (context, index) {
              final date = allDates[index];
              final foodList = foodLogs[date] ?? [];
              final taskData = taskLogs[date];

              return Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: ExpansionTile(
                  enableFeedback: false,
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  collapsedShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  backgroundColor: Colors.white,
                  collapsedBackgroundColor: Colors.grey[50],
                  leading: const Icon(
                    Icons.calendar_today,
                    color: Color(0xFF79D7BE),
                  ), // เพิ่ม icon นำหน้า
                  title: Text(
                    date,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF79D7BE),
                    ),
                  ),
                  childrenPadding: const EdgeInsets.all(20),
                  children: [
                    _buildSectionTitle(
                      'บันทึกประจำวัน',
                      Icons.assignment,
                      Colors.blue,
                    ),
                    const SizedBox(height: 8),
                    _buildLogDetailCard(
                      taskData != null
                          ? formatTaskData(taskData)
                          : 'ไม่มีบันทึก',
                    ),
                    const Divider(height: 30),
                    _buildSectionTitle(
                      'บันทึกอาหาร',
                      Icons.fastfood,
                      Colors.orange,
                    ),
                    const SizedBox(height: 8),
                    if (foodList.isNotEmpty)
                      ...foodList.map((meal) {
                        if (meal is Map<String, dynamic>) {
                          return _buildFoodItemCard(meal);
                        } else {
                          return _buildLogDetailCard('ข้อมูลอาหารไม่ถูกต้อง');
                        }
                      }).toList(),
                    if (foodList.isEmpty)
                      _buildLogDetailCard('ไม่มีบันทึกอาหาร'),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildLogDetailCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 14,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildFoodItemCard(Map<String, dynamic> meal) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(10),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.restaurant,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal['name'] ?? 'ไม่มีชื่อเมนู',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatMealDetails(meal),
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String formatTaskData(Map<String, dynamic> taskData) {
    List<String> lines = [];

    if (taskData.containsKey('activitiy')) {
      lines.add('กิจกรรม: ${taskData['activities']}');
    }

    if (taskData.containsKey('exerciseId')) {
      final exercise = taskData['exerciseId'];
      if (exercise is Map<String, dynamic>) {
        lines.add('การออกกำลังกาย:');
        if (exercise.containsKey('calories')) {
          lines.add('- แคลอรี่: ${exercise['calories']}');
        }
        if (exercise.containsKey('duration')) {
          lines.add('- ระยะเวลา: ${exercise['duration']}');
        }
        if (exercise.containsKey('type')) {
          lines.add('- ประเภท: ${exercise['type']}');
        }
      }
    }

    if (taskData.containsKey('waterTaskId')) {
      final exercise = taskData['waterTaskId'];
      if (exercise is Map<String, dynamic>) {
        lines.add('การดื่มน้ำ:');
        if (exercise.containsKey('total_drink')) {
          lines.add('- ปริมาณการดื่มน้ำ: ${exercise['total_drink']} แก้ว');
        }
      }
    }

    if (taskData.containsKey('sleepTaskId')) {
      final sleep = taskData['sleepTaskId'];
      if (sleep is Map<String, dynamic>) {
        lines.add('การนอน:');
        if (sleep.containsKey('sleepTime')) {
          lines.add('- เวลาเข้านอน: ${sleep['sleepTime']}');
        }
        if (sleep.containsKey('wakeTime')) {
          lines.add('- เวลาตื่นนอน: ${sleep['wakeTime']}');
        }
        if (sleep.containsKey('sleepQuality')) {
          lines.add('- คุณภาพการนอน: ${sleep['sleepQuality']}');
        }
      }
    }

    if (taskData.containsKey('MoodId')) {
      final mood = taskData['MoodId'];
      if (mood is Map<String, dynamic>) {
        lines.add('อารมณ์:');
        if (mood.containsKey('mood')) {
          lines.add('- อารมณ์: ${mood['mood']}');
        }
      }
    }

    if (taskData.containsKey('activities')) {
      final activitiesList = taskData['activities'] as List<dynamic>;
      if (activitiesList.isNotEmpty) {
        lines.add('กิจกรรม:');
        for (var activityMap in activitiesList) {
          if (activityMap is Map<String, dynamic>) {
            final activityName = activityMap['activity'] ?? 'ไม่มีชื่อกิจกรรม';
            lines.add('- $activityName');
          }
        }
      } else {
        lines.add('ไม่มีกิจกรรมในวันนี้');
      }
    }

    return lines.isNotEmpty ? lines.join('\n') : 'ไม่มีข้อมูลรายละเอียด';
  }

  String formatMealDetails(Map<String, dynamic> meal) {
    List<String> details = [];

    if (meal.containsKey('name')) {
      details.add('ชื่ออาหาร: ${meal['name']}');
    }
    if (meal.containsKey('cal')) {
      // เพิ่ม calories เข้ามา
      details.add('แคลอรี่: ${meal['calories']} kcal');
    }
    if (meal.containsKey('desc')) {
      details.add('คำอธิบาย: ${meal['desc']}');
    }

    // ใช้ '\n' เพื่อให้แต่ละรายละเอียดขึ้นบรรทัดใหม่
    return details.isNotEmpty ? details.join('\n') : 'ไม่มีรายละเอียดเพิ่มเติม';
  }
}
