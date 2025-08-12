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

  Widget _buildDailyTaskItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isTablet,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFF79D7BE),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey, width: 1.5)
            ),
            child: Icon(icon, size: isTablet ? 50 : 40, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: isTablet ? 16 : 14),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthMetricItem({
    required String label,
    required String value,
    Color labelColor = Colors.grey,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: TextStyle(fontSize: 14, color: labelColor)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
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
            Text('บันทึกมาแล้ว ($savedDays วัน) 🔥', style: const TextStyle(fontSize: 14)),
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
                    onTap: () { widget.onNavigate(1); },
                    isTablet: isTablet,
                  ),
                  _buildDailyTaskItem(
                    icon: Icons.fastfood,
                    label: 'บันทึกอาหาร',
                    onTap: () {widget.onNavigate(2);},
                    isTablet: isTablet,
                  ),
                  _buildDailyTaskItem(
                    icon: Icons.bar_chart,
                    label: 'ผลความก้าวหน้า',
                    onTap: () {Navigator.pushNamed(context, '/all_logs');},
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
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
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
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "ผลการประเมิน: ",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Icon(Icons.check_circle, color: Colors.green, size: 24),
                      SizedBox(width: 8),
                      Text(
                        "สุขภาพดี",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
