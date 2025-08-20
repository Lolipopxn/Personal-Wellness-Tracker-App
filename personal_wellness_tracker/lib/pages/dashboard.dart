import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app/firestore_service.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key, required this.onNavigate});
  final void Function(int index) onNavigate;

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final FirestoreService _firestoreService = FirestoreService();
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _exerciseData;
  Map<String, dynamic>? _sleepData;
  Map<String, dynamic>? _waterData;
  bool _isLoading = true;
  String? _errorMessage;
  int savedDays = 0;
  int totalDays = 7;
  String mood = "N/A";

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    loadData();
    loadDailyTasks();
  }

  Future<void> _fetchUserData() async {
    try {
      final data = await _firestoreService.getUserData();
      if (mounted) {
        setState(() {
          _userData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "เกิดข้อผิดพลาดในการดึงข้อมูล: $e";
          _isLoading = false;
        });
      }
    }
  }

  void updateGoal(int days) {
    List<int> goals = [7, 14, 30, 60, 90, 180, 365];
    for (int g in goals) {
      if (days < g) {
        totalDays = g;
        return;
      }
    }
    totalDays = days + 30;
  }

  Future<void> loadData() async {
    int count = await _firestoreService.getStreakCount();
    setState(() {
      savedDays = count;
      updateGoal(count);
    });
  }

  Future<void> loadDailyTasks() async {
    try {
      final taskData = await _firestoreService.getDailyTask(DateTime.now());

      if (taskData != null) {
        setState(() {
          mood = taskData["MoodId"]["mood"] ?? 'N/A';
          _exerciseData = taskData["exerciseId"];
          _sleepData = taskData["sleepTaskId"];
          _waterData = taskData["waterTaskId"];
        });
      }
    } catch (e) {
      print("เกิดข้อผิดพลาดในการโหลดข้อมูล: $e");
    }
  }

  String _calculateBmi(double? weight, double? height) {
    if (weight == null || height == null || height == 0) {
      return "N/A";
    }
    final double heightInMeters = height / 100;
    final double bmi = weight / (heightInMeters * heightInMeters);

    String interpretation;
    if (bmi < 18.5) {
      interpretation = "น้ำหนักน้อย";
    } else if (bmi < 24.9) {
      interpretation = "ปกติ";
    } else if (bmi < 29.9) {
      interpretation = "น้ำหนักเกิน";
    } else {
      interpretation = "อ้วน";
    }
    return "${bmi.toStringAsFixed(1)} ($interpretation)";
  }

  String evaluateHealth({
    required double? weight,
    required double? height,
    required String bloodPressure,
    required int? heartRate,
    required String mood,
    bool exerciseCompleted = false,
    bool waterCompleted = false,
  }) {
    String bmiResult = _calculateBmi(weight, height);
    bool isNormalBmi = bmiResult.contains("ปกติ");

    bool isNormalBP = false;
    if (bloodPressure != "N/A") {
      try {
        final parts = bloodPressure.split("/");
        int systolic = int.parse(parts[0]);
        int diastolic = int.parse(parts[1]);
        isNormalBP =
            (systolic >= 90 && systolic <= 120) &&
            (diastolic >= 60 && diastolic <= 80);
      } catch (_) {}
    }

    bool isNormalHR = heartRate != null && heartRate >= 60 && heartRate <= 100;

    bool isGoodMood = mood != "N/A" && mood.toLowerCase().contains("happy");

    int score = 0;
    if (isNormalBmi) score++;
    if (isNormalBP) score++;
    if (isNormalHR) score++;
    if (isGoodMood) score++;
    if (exerciseCompleted) score++;
    if (waterCompleted) score++;
    if (score >= 4) {
      return "สุขภาพดี";
    } else if (score >= 2) {
      return "ปานกลาง";
    } else {
      return "ควรปรับปรุง";
    }
  }

  Widget _buildDailyTaskItem({
  required IconData icon,
  required String label,
  required VoidCallback onTap,
  required bool isTablet,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF79D7BE), // main color
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF79D7BE).withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, size: isTablet ? 52 : 42, color: Colors.white),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isTablet ? 16 : 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2E5077), // dark text
          ),
        ),
      ],
    ),
  );
}

  Widget _buildHealthMetricItem({
  required String label,
  required String value,
}) {
  return Container(
    width: 150,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 6,
          offset: const Offset(0, 3),
        )
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF2E5077))),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF79D7BE)),
        ),
      ],
    ),
  );
}

  Widget _buildTaskInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionCard(
          title: "ข้อมูลการออกกำลังกาย",
          children: [
            _buildInfoRow(
              Icons.fitness_center,
              "ประเภท",
              _exerciseData?["type"] ?? '-',
            ),
            _buildInfoRow(
              Icons.timer,
              "ระยะเวลา",
              _exerciseData?["duration"] ?? '-',
            ),
            _buildInfoRow(
              Icons.local_fire_department,
              "แคลอรี่",
              _exerciseData?["calories"] ?? '-',
            ),
            _buildInfoRow(
              _exerciseData?["isTaskCompleted"] == true
                  ? Icons.check_circle
                  : Icons.cancel,
              "เสร็จสิ้น",
              _exerciseData?["isTaskCompleted"] == true
                  ? "สำเร็จแล้ว"
                  : "ยังไม่เสร็จ",
              color: _exerciseData?["isTaskCompleted"] == true
                  ? Colors.green
                  : Colors.red,
            ),
          ],
        ),
        _buildSectionCard(
          title: "ข้อมูลการดื่มน้ำ",
          children: [
            _buildInfoRow(
              _waterData?["isTaskCompleted"] == true
                  ? Icons.check_circle
                  : Icons.cancel,
              "เสร็จสิ้น",
              _waterData?["isTaskCompleted"] == true
                  ? "สำเร็จแล้ว"
                  : "ยังไม่เสร็จ",
              color: _waterData?["isTaskCompleted"] == true
                  ? Colors.green
                  : Colors.red,
            ),
          ],
        ),
        _buildSectionCard(
          title: "ข้อมูลการนอน",
          children: [
            _buildInfoRow(
              Icons.bedtime,
              "เริ่มนอน",
              _sleepData?["sleepTime"] ?? '-',
            ),
            _buildInfoRow(
              Icons.wb_sunny,
              "ตื่นนอน",
              _sleepData?["wakeTime"] ?? '-',
            ),
            _buildInfoRow(
              Icons.star,
              "คุณภาพ",
              _sleepData?["sleepQuality"] ?? '-',
            ),
            _buildInfoRow(
              _sleepData?["isTaskCompleted"] == true
                  ? Icons.check_circle
                  : Icons.cancel,
              "เสร็จสิ้น",
              _sleepData?["isTaskCompleted"] == true
                  ? "สำเร็จแล้ว"
                  : "ยังไม่เสร็จ",
              color: _sleepData?["isTaskCompleted"] == true
                  ? Colors.green
                  : Colors.red,
            ),
          ],
        ),
      ],
    );
  }

  /// --- Helper Widgets ---
 Widget _buildSectionCard({
  required String title,
  required List<Widget> children,
}) {
  return Card(
    margin: const EdgeInsets.symmetric(vertical: 10),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    color: Colors.white, // เน้นความสะอาดตา
    elevation: 6,
    shadowColor: Colors.black26,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E5077), // สีหัวข้อเข้ม
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    ),
  );
}

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22, color: color ?? Colors.blueAccent),
          ),
          const SizedBox(width: 12),
          Text(
            "$label: ",
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: color ?? Colors.black87,
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      return Scaffold(body: Center(child: Text(_errorMessage!)));
    }

    if (_userData == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("ไม่พบข้อมูลผู้ใช้"),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/profile');
                },
                child: const Text("ไปที่หน้าโปรไฟล์"),
              ),
            ],
          ),
        ),
      );
    }

    final user = FirebaseAuth.instance.currentUser;
    final String displayName =
        _userData!['username'] ??
        user?.displayName ??
        _userData!['email'] ??
        'User';
    final int? age = _userData!['age'];
    final double? weight = _userData!['weight'];
    final double? height = _userData!['height'];
    final String bmiResult = _calculateBmi(weight, height);

    final Map<String, dynamic> healthInfo = _userData!['healthInfo'] ?? {};
    final String bloodPressure = healthInfo['bloodPressure'] ?? 'N/A';
    final int? heartRate = healthInfo['heartRate'];

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    final bool exerciseDone = _exerciseData?["isTaskCompleted"] == true;
    final bool waterDone = _waterData?["isTaskCompleted"] == true;

    final String evaluation = evaluateHealth(
      weight: weight,
      height: height,
      bloodPressure: bloodPressure,
      heartRate: heartRate,
      mood: mood,
      exerciseCompleted: exerciseDone,
      waterCompleted: waterDone,
    );

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              height: isTablet ? 200 : 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/Health.jpg',
                  width: double.infinity,
                  height: 150,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'บันทึกมาแล้ว ($savedDays วัน) 🔥',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: LinearProgressIndicator(
                    value: savedDays / totalDays,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.blue,
                    ),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 10),
                Text('$totalDays วัน', style: const TextStyle(fontSize: 14)),
              ],
            ),
            const SizedBox(height: 30),
            const Center(
              child: Text(
                'สิ่งที่ต้องทำประจำวัน',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 15),
            Center(
              child: Wrap(
                spacing: 30,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: <Widget>[
                  _buildDailyTaskItem(
                    icon: Icons.track_changes,
                    label: 'ติดตามประจำวัน',
                    onTap: () {
                      widget.onNavigate(1);
                    },
                    isTablet: isTablet,
                  ),
                  _buildDailyTaskItem(
                    icon: Icons.fastfood,
                    label: 'บันทึกอาหาร',
                    onTap: () {
                      widget.onNavigate(2);
                    },
                    isTablet: isTablet,
                  ),
                  _buildDailyTaskItem(
                    icon: Icons.bar_chart,
                    label: 'ผลความก้าวหน้า',
                    onTap: () {
                      Navigator.pushNamed(context, '/all_logs');
                    },
                    isTablet: isTablet,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Divider(thickness: 2, color: Colors.grey),
            const Center(
              child: Text(
                "สุขภาพประจำวัน",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "ผลการประเมิน: ",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Icon(
                        evaluation == "สุขภาพดี"
                            ? Icons.check_circle
                            : Icons.warning,
                        color: evaluation == "สุขภาพดี"
                            ? Colors.green
                            : Colors.orange,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        evaluation,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: evaluation == "สุขภาพดี"
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 20.0,
                    runSpacing: 15.0,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildHealthMetricItem(
                        label: "ชื่อผู้ใช้",
                        value: displayName,
                      ),
                      _buildHealthMetricItem(
                        label: "อายุ",
                        value: "${age ?? 'N/A'} ปี",
                      ),
                      _buildHealthMetricItem(
                        label: "น้ำหนัก",
                        value: "${weight ?? 'N/A'} kg",
                      ),
                      _buildHealthMetricItem(
                        label: "ส่วนสูง",
                        value: "${height ?? 'N/A'} cm",
                      ),
                      _buildHealthMetricItem(
                        label: "ค่า BMI",
                        value: bmiResult,
                      ),
                      _buildHealthMetricItem(
                        label: "ความดันโลหิต",
                        value: bloodPressure,
                      ),
                      _buildHealthMetricItem(
                        label: "อัตราเต้นหัวใจ",
                        value: "${heartRate ?? 'N/A'} bpm",
                      ),
                      _buildHealthMetricItem(
                        label: "อาหาร",
                        value: "2000 kcal",
                      ),
                      _buildHealthMetricItem(label: "อารมณ์", value: mood),
                    ],
                  ),

                  const SizedBox(height: 20),
                  _buildTaskInfo(),

                  
                  
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
