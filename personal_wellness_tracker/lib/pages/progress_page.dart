import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:personal_wellness_tracker/app/daily_task_api.dart';
import 'package:personal_wellness_tracker/services/api_service.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class Palette {
  static const navy = Color(0xFF2E5077); // ข้อความ/ไอคอนหลัก
  static const teal = Color(0xFF4DA1A9); // ปุ่มหลัก/แอ็กเซนต์
  static const mint = Color(0xFF79D7BE); // พื้นหลังชิป/แทร็ก
  static const paper = Color(0xFFF8F9FA); // พื้นหลังการ์ด
  static const cardShadow = Color(0xFF000000); // เงาการ์ด
}

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  int _doneCount = 0;
  final int _totalTasks = 5;

  Map<int, int> _weeklyWater = {};
  Map<int, int> _weeklyExercise = {};
  Map<int, double> _weeklySleep = {};
  Map<int, double> _weeklyCalories = {};

  int _currentDayOfWeek = 0;

  final ApiService _apiService = ApiService();
  final ScreenshotController _screenshotController = ScreenshotController();

  Map<String, dynamic>? _userGoals;

  DateTime _getMondayOfCurrentWeek() {
    final now = DateTime.now();
    final dayOfWeek = now.weekday;
    final daysToSubtract = dayOfWeek - 1;
    return DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: daysToSubtract));
  }

  int _getDayIndex(DateTime date) => date.weekday - 1;

  Future<Map<String, dynamic>> _getFoodDataForDate(DateTime date) async {
    try {
      final currentUser = await _apiService.getCurrentUser();
      final userId = currentUser['uid'] ?? currentUser['id'];

      final foodLog = await _apiService.getFoodLogByDate(userId, date);

      if (foodLog != null) {
        final meals = await _apiService.getMealsByFoodLog(foodLog['id']);

        int totalCalories = 0;
        Set<String> mealTypes = {};

        for (final meal in meals) {
          totalCalories += (meal['calories'] ?? 0) as int;
          final mealType = meal['meal_type'];
          if (mealType != null) {
            mealTypes.add(mealType);
          }
        }

        int mainMealsCount = 0;
        if (mealTypes.contains('breakfast')) mainMealsCount++;
        if (mealTypes.contains('lunch')) mainMealsCount++;
        if (mealTypes.contains('dinner')) mainMealsCount++;

        return {
          'calories': totalCalories.toDouble(),
          'mainMealsCount': mainMealsCount,
          'hasThreeMeals': mainMealsCount >= 3,
        };
      }
    } catch (e) {
      debugPrint('Error getting food data for date $date: $e');
    }

    return {'calories': 0.0, 'mainMealsCount': 0, 'hasThreeMeals': false};
  }

  Future<void> _loadUserGoals() async {
    try {
      final currentUser = await _apiService.getCurrentUser();
      final userId = currentUser['uid'] ?? currentUser['id'];

      final goals = await _apiService.getUserGoals(userId);
      if (goals != null) {
        setState(() {
          _userGoals = goals;
        });
      }
    } catch (e) {
      debugPrint('Error loading user goals: $e');
    }
  }

  Future<void> _loadWeeklyData() async {
    try {
      final monday = _getMondayOfCurrentWeek();
      final today = DateTime.now();

      _weeklyWater.clear();
      _weeklyExercise.clear();
      _weeklySleep.clear();
      _weeklyCalories.clear();

      _currentDayOfWeek = _getDayIndex(today);

      int todayDoneCount = 0;
      bool todayHasThreeMeals = false;

      for (int i = 0; i <= _currentDayOfWeek; i++) {
        final date = monday.add(Duration(days: i));
        final daily = await DailyTaskApi.getDailyTask(date);
        final foodData = await _getFoodDataForDate(date);

        if (daily != null) {
          final dailyTaskId = daily['id']?.toString();
          if (dailyTaskId != null) {
            final tasks = await DailyTaskApi.getTasks(dailyTaskId);

            int water = 0;
            int exercise = 0;
            double sleep = 0;
            bool doneMood = false;

            for (final task in tasks) {
              final type = (task['task_type'] ?? '').toString();
              switch (type) {
                case 'water':
                  water = ((task['value_number'] ?? 0) as num).toInt();
                  break;
                case 'exercise':
                  exercise = ((task['value_number'] ?? 0) as num).toInt();
                  break;
                case 'sleep':
                  if (task['started_at'] != null && task['ended_at'] != null) {
                    final start = DateTime.tryParse(
                      task['started_at'] ?? '',
                    )?.toLocal();
                    final end = DateTime.tryParse(
                      task['ended_at'] ?? '',
                    )?.toLocal();
                    if (start != null && end != null) {
                      sleep = end.difference(start).inMinutes / 60.0;
                    }
                  }
                  break;
                case 'mood':
                  if (task['value_text'] != null ||
                      task['value_number'] != null) {
                    doneMood = true;
                  }
                  break;
              }
            }

            if (water > 0) _weeklyWater[i] = water;
            if (exercise > 0) _weeklyExercise[i] = exercise;
            if (sleep > 0) _weeklySleep[i] = sleep;

            if (i == _currentDayOfWeek) {
              if (water >= (_userGoals?['goal_water_intake'] ?? 8))
                todayDoneCount++;
              if (exercise >= (_userGoals?['goal_exercise_minutes'] ?? 30))
                todayDoneCount++;
              if (sleep >= (_userGoals?['goal_sleep_hours'] ?? 6))
                todayDoneCount++;
              if (doneMood) todayDoneCount++;
              todayHasThreeMeals = foodData['hasThreeMeals'] as bool;
              if (todayHasThreeMeals) todayDoneCount++;
            }
          }
        } else {
          if (i == _currentDayOfWeek) {
            todayHasThreeMeals = foodData['hasThreeMeals'] as bool;
            if (todayHasThreeMeals) todayDoneCount++;
          }
        }

        final calories = foodData['calories'] as double;
        if (calories > 0) {
          _weeklyCalories[i] = calories;
        }
      }

      setState(() {
        _doneCount = todayDoneCount;
      });
    } catch (e) {
      debugPrint('Load weekly data error: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserGoals().then((_) => _loadWeeklyData());
  }

  Future<void> _shareGoalCard() async {
    try {
      final Uint8List? image = await _screenshotController.capture();
      if (image != null) {
        final directory = await getTemporaryDirectory();
        final imagePath = '${directory.path}/goal_progress.png';
        final imageFile = File(imagePath);
        await imageFile.writeAsBytes(image);

        final percentage = ((_doneCount / _totalTasks) * 100).round();
        final shareText =
            'เป้าหมายวันนี้ของฉัน: $_doneCount/$_totalTasks งาน ($percentage%) 🎯\n\n#PersonalWellnessTracker #HealthGoals #Wellness';

        await Share.shareXFiles([XFile(imagePath)], text: shareText);
      }
    } catch (e) {
      debugPrint('Error sharing goal card: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ไม่สามารถแชร์ได้ในขณะนี้ กรุณาลองใหม่อีกครั้ง'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 2,
        backgroundColor: Palette.teal,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        title: const Text(
          'ความก้าวหน้าของฉัน',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadWeeklyData,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // 🔹 การ์ดเป้าหมายวันนี้ + แชร์
            Screenshot(
              controller: _screenshotController,
              child: Card(
                color: Palette.paper,
                shadowColor: Palette.cardShadow.withOpacity(0.1),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: FutureBuilder<Map<String, dynamic>>(
                    future: _getTodayGoalsStatus(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final goals = snapshot.data!;
                        final now = DateTime.now();
                        final weekdayNames = [
                          'จันทร์',
                          'อังคาร',
                          'พุธ',
                          'พฤหัสบดี',
                          'ศุกร์',
                          'เสาร์',
                          'อาทิตย์',
                        ];
                        final currentDay = weekdayNames[now.weekday - 1];
                        final dateString =
                            "$currentDay ${now.day}/${now.month}/${now.year + 543}";

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'เป้าหมายวันนี้',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Palette.navy,
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: _doneCount >= _totalTasks
                                        ? Palette.teal
                                        : Colors.grey.shade300,
                                  ),
                                  child: IconButton(
                                    onPressed: _doneCount >= _totalTasks
                                        ? _shareGoalCard
                                        : null,
                                    icon: Icon(
                                      Icons.share,
                                      color: _doneCount >= _totalTasks
                                          ? Colors.white
                                          : Colors.grey.shade500,
                                      size: 20,
                                    ),
                                    tooltip: _doneCount >= _totalTasks
                                        ? 'แชร์ความสำเร็จ'
                                        : 'ทำเป้าหมายให้ครบก่อนแชร์',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dateString,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            // ✅ Progress bar
                            LinearProgressIndicator(
                              value: _doneCount / _totalTasks,
                              minHeight: 10,
                              backgroundColor: Palette.mint.withOpacity(0.3),
                              color: Palette.teal,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            const SizedBox(height: 16),
                            _buildGoalItem(
                              icon: Icons.local_drink,
                              title: 'ดื่มน้ำ',
                              isCompleted: goals['water'] as bool,
                              currentValue:
                                  '${goals['waterCount']}/${_userGoals?['goal_water_intake'] ?? 8} แก้ว',
                            ),
                            _buildGoalItem(
                              icon: Icons.fitness_center,
                              title: 'ออกกำลังกาย',
                              isCompleted: goals['exercise'] as bool,
                              currentValue:
                                  '${goals['exerciseMinutes']}/${_userGoals?['goal_exercise_minutes'] ?? 30} นาที',
                            ),
                            _buildGoalItem(
                              icon: Icons.bedtime,
                              title: 'นอนหลับ',
                              isCompleted: goals['sleep'] as bool,
                              currentValue:
                                  '${goals['sleepHours'].toStringAsFixed(1)}/${_userGoals?['goal_sleep_hours'] ?? 6} ชม.',
                            ),
                            _buildGoalItem(
                              icon: Icons.restaurant,
                              title: 'แคลอรี่',
                              isCompleted:
                                  (goals['calories'] as double) >=
                                  (_userGoals?['goal_calorie_intake'] ?? 2000),
                              currentValue:
                                  '${goals['calories']}/${_userGoals?['goal_calorie_intake'] ?? 2000} kcal',
                            ),
                          ],
                        );
                      }
                      return const Center(child: CircularProgressIndicator());
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
            _buildChartCard(
              title: 'การนอนหลับ (สัปดาห์นี้)',
              unit: 'ชม.',
              icon: Icons.bedtime,
              color: Palette.navy,
              chart: _buildLineChart(
                _weeklySleep,
                Palette.navy,
                (_userGoals?['goal_sleep_hours'] ?? 12).toDouble(),
              ),
            ),
            const SizedBox(height: 16),
            _buildChartCard(
              title: 'การออกกำลังกาย (สัปดาห์นี้)',
              unit: 'นาที',
              icon: Icons.fitness_center,
              color: Palette.teal,
              chart: _buildLineChart(
                _weeklyExercise.map((k, v) => MapEntry(k, v.toDouble())),
                Palette.teal,
                (_userGoals?['goal_exercise_minutes'] ?? 120).toDouble(),
              ),
            ),
            const SizedBox(height: 16),
            _buildChartCard(
              title: 'การดื่มน้ำ (สัปดาห์นี้)',
              unit: 'แก้ว',
              icon: Icons.local_drink,
              color: Palette.teal,
              chart: _buildBarChart(
                _weeklyWater,
                Palette.teal,
                (_userGoals?['goal_water_intake'] ?? 15).toDouble(),
              ),
            ),
            const SizedBox(height: 16),
            _buildChartCard(
              title: 'แคลอรี่ (สัปดาห์นี้)',
              unit: 'kcal',
              icon: Icons.restaurant,
              color: Palette.mint,
              chart: _buildLineChart(
                _weeklyCalories,
                Palette.mint,
                (_userGoals?['goal_calorie_intake'] ?? 3000).toDouble(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _getTodayGoalsStatus() async {
    try {
      final today = DateTime.now();
      final daily =
          await DailyTaskApi.getDailyTask(today) ??
          await DailyTaskApi.ensureDailyTaskForToday();

      int water = 0;
      int exercise = 0;
      double sleep = 0;
      bool mood = false;

      if (daily != null) {
        final dailyTaskId = daily['id']?.toString();
        if (dailyTaskId != null) {
          final tasks = await DailyTaskApi.getTasks(dailyTaskId);

          for (final task in tasks) {
            final type = (task['task_type'] ?? '').toString();
            switch (type) {
              case 'water':
                water = ((task['value_number'] ?? 0) as num).toInt();
                break;
              case 'exercise':
                exercise = ((task['value_number'] ?? 0) as num).toInt();
                break;
              case 'sleep':
                if (task['started_at'] != null && task['ended_at'] != null) {
                  final start = DateTime.tryParse(
                    task['started_at'] ?? '',
                  )?.toLocal();
                  final end = DateTime.tryParse(
                    task['ended_at'] ?? '',
                  )?.toLocal();
                  if (start != null && end != null) {
                    sleep = end.difference(start).inMinutes / 60.0;
                  }
                }
                break;
              case 'mood':
                if (task['value_text'] != null ||
                    task['value_number'] != null) {
                  mood = true;
                }
                break;
            }
          }
        }
      }

      final foodData = await _getFoodDataForDate(today);

      return {
        'water': water >= (_userGoals?['goal_water_intake'] ?? 8),
        'waterCount': water,
        'exercise': exercise >= (_userGoals?['goal_exercise_minutes'] ?? 30),
        'exerciseMinutes': exercise,
        'sleep': sleep >= (_userGoals?['goal_sleep_hours'] ?? 6),
        'sleepHours': sleep,
        'mood': mood,
        'threeMeals': foodData['hasThreeMeals'] as bool,
        'mealsCount': foodData['mainMealsCount'] as int,
        'calories': foodData['calories'],
      };
    } catch (e) {
      debugPrint('Error getting today goals status: $e');
      return {
        'water': false,
        'waterCount': 0,
        'exercise': false,
        'exerciseMinutes': 0,
        'sleep': false,
        'sleepHours': 0.0,
        'mood': false,
        'threeMeals': false,
        'mealsCount': 0,
        'calories': 0.0,
      };
    }
  }

  Widget _buildGoalItem({
    required IconData icon,
    required String title,
    required bool isCompleted,
    required String currentValue,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: isCompleted ? Palette.teal : Colors.grey, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: isCompleted ? Palette.navy : Colors.grey,
                fontWeight: isCompleted ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
          Text(
            currentValue,
            style: TextStyle(
              fontSize: 12,
              color: isCompleted ? Palette.teal : Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isCompleted ? Palette.teal : Colors.grey,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildDayTitles(double value, TitleMeta meta) {
    const days = ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'];
    final style = TextStyle(
      color: Palette.navy,
      fontSize: 12,
      fontWeight: value.toInt() == _currentDayOfWeek
          ? FontWeight.bold
          : FontWeight.normal,
    );
    String text = '';
    if (value.toInt() >= 0 && value.toInt() < days.length) {
      text = days[value.toInt()];
    }
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 4,
      child: Text(text, style: style),
    );
  }

  Widget _buildChartCard({
    required String title,
    required String unit,
    required Widget chart,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      color: Palette.paper,
      shadowColor: Palette.cardShadow.withOpacity(0.15),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Palette.navy,
                  ),
                ),
                const Spacer(),
                Text(
                  unit,
                  style: const TextStyle(fontSize: 14, color: Palette.navy),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(height: 200, child: chart),
          ],
        ),
      ),
    );
  }

  // ✅ Line Chart capped
  Widget _buildLineChart(Map<int, double> data, Color color, double maxY) {
    List<FlSpot> spots = [];
    data.forEach((dayIndex, value) {
      final cappedValue = value > maxY ? maxY : value;
      spots.add(FlSpot(dayIndex.toDouble(), cappedValue));
    });

    return LineChart(
      LineChartData(
        maxY: maxY,
        minY: 0,
        maxX: 6,
        minX: 0,
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: _buildDayTitles,
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: spots.isEmpty
            ? []
            : [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: color,
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: color.withOpacity(0.1),
                  ),
                ),
              ],
      ),
    );
  }

  // ✅ Bar Chart capped
  Widget _buildBarChart(Map<int, int> data, Color color, double maxY) {
    List<BarChartGroupData> barGroups = [];

    for (int i = 0; i < 7; i++) {
      final rawValue = data[i]?.toDouble() ?? 0.0;
      final cappedValue = rawValue > maxY ? maxY : rawValue;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: cappedValue,
              color: rawValue > 0 ? color : Colors.grey.withOpacity(0.3),
              width: 20,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        maxY: maxY,
        minY: 0,
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: _buildDayTitles,
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
        gridData: const FlGridData(show: false),
      ),
    );
  }
}
