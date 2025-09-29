import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../app/daily_task_api.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key, required this.onNavigate});
  final void Function(int index) onNavigate;

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final ApiService _apiService = ApiService();
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

  @override
  void didUpdateWidget(Dashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh ข้อมูลเมื่อ widget ถูกอัปเดต (เช่น กลับมาจากหน้าอื่น)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        refreshAllData();
      }
    });
  }

  // Method สำหรับ refresh ข้อมูลทั้งหมด
  Future<void> refreshAllData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    await Future.wait([
      _fetchUserData(),
      loadData(),
      loadDailyTasks(),
    ]);
  }

  Future<void> _fetchUserData() async {
    try {
      // ตรวจสอบ token ก่อน
      final token = await _apiService.getToken();
      if (token == null) {
        throw Exception('No token found - need to login');
      }
      
      final data = await _apiService.getCurrentUser();
      print("DEBUG: User data received: $data"); // Debug line
      if (mounted) {
        setState(() {
          _userData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("DEBUG: Error fetching user data: $e"); // Debug line
      
      // ถ้าเป็น error "Not Found" หรือไม่มี token แสดงว่าต้อง login ใหม่
      if (e.toString().contains('Not Found') || 
          e.toString().contains('Unauthorized') ||
          e.toString().contains('No token found')) {
        if (mounted) {
          setState(() {
            _errorMessage = "กรุณาเข้าสู่ระบบใหม่";
            _isLoading = false;
          });
          
          // นำทางไปหน้า login
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/login');
            }
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = "เกิดข้อผิดพลาดในการดึงข้อมูล: $e";
            _isLoading = false;
          });
        }
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
    int count = await _apiService.getStreakCount();
    setState(() {
      savedDays = count;
      updateGoal(count);
    });
  }

  Future<void> loadDailyTasks() async {
    try {
      final today = DateTime.now();
      final dailyTask = await DailyTaskApi.getDailyTask(today);
      print("DEBUG: Daily task data received: $dailyTask");

      if (dailyTask != null && dailyTask['id'] != null) {
        final dailyTaskId = dailyTask['id'].toString();
        final tasks = await DailyTaskApi.getTasks(dailyTaskId);
        print("DEBUG: Tasks list received: $tasks");

        setState(() {
          
          // Parse tasks data
          _parseTasksData(tasks);
        });
      } else {
        // ไม่มีข้อมูล daily task
        setState(() {
          _setDefaultTaskData();
        });
      }
    } catch (e) {
      print("เกิดข้อผิดพลาดในการโหลดข้อมูล: $e");
      setState(() {
        _setDefaultTaskData();
      });
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

  double _calculateBMR(double? weight, double? height, int? age, String? gender) {
    if (weight == null || height == null || age == null || gender == null) {
      return 0;
    }
    
    // ใช้สูตร Mifflin-St Jeor
    if (gender.toLowerCase() == 'male') {
      return (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      return (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }
  }



  void _showTDEEDialog() {
    final int? age = _userData!['age'];
    final double? weight = _userData!['weight']?.toDouble();
    final double? height = _userData!['height']?.toDouble();
    final String? gender = _userData!['gender'];

    if (age == null || weight == null || height == null || gender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกข้อมูลส่วนตัวให้ครบถ้วนก่อนคำนวณ TDEE'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final double bmr = _calculateBMR(weight, height, age, gender);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _TDEECalculatorDialog(
          bmr: bmr,
          weight: weight,
          height: height,
          age: age,
          gender: gender,
          apiService: _apiService,
          onGoalSaved: () {
            // Refresh data after saving goal
            refreshAllData();
          },
        );
      },
    );
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

  void _parseTasksData(List<Map<String, dynamic>> tasks) {
    // หาข้อมูลแต่ละประเภท task
    Map<String, dynamic>? exerciseTask;
    Map<String, dynamic>? waterTask;
    Map<String, dynamic>? sleepTask;
    Map<String, dynamic>? moodTask;

    for (final task in tasks) {
      final taskType = task['task_type']?.toString();
      switch (taskType) {
        case 'exercise':
          exerciseTask = task;
          break;
        case 'water':
          waterTask = task;
          break;
        case 'sleep':
          sleepTask = task;
          break;
        case 'mood':
          moodTask = task;
          break;
      }
    }

    // อัปเดตข้อมูล exercise
    if (exerciseTask != null) {
      _exerciseData = {
        "type": exerciseTask['value_text'] ?? 'การออกกำลังกาย',
        "duration": exerciseTask['value_number'] != null 
            ? "${exerciseTask['value_number'].toInt()} นาที" 
            : '-',
        "calories": "-", // อาจจะคำนวณจาก duration หรือเก็บแยก
        "isTaskCompleted": exerciseTask['completed'] == true,
      };
    } else {
      _exerciseData = {
        "type": "-",
        "duration": "-",
        "calories": "-",
        "isTaskCompleted": false,
      };
    }

    // อัปเดตข้อมูล water
    if (waterTask != null) {
      _waterData = {
        "glasses": waterTask['value_number']?.toInt() ?? 0,
        "isTaskCompleted": waterTask['completed'] == true,
      };
    } else {
      _waterData = {
        "glasses": 0,
        "isTaskCompleted": false,
      };
    }

    // อัปเดตข้อมูล sleep
    if (sleepTask != null) {
      final startedAt = sleepTask['started_at'] != null 
          ? DateTime.tryParse(sleepTask['started_at']) 
          : null;
      final endedAt = sleepTask['ended_at'] != null 
          ? DateTime.tryParse(sleepTask['ended_at']) 
          : null;
      
      _sleepData = {
        "sleepTime": startedAt != null 
            ? "${startedAt.hour.toString().padLeft(2, '0')}:${startedAt.minute.toString().padLeft(2, '0')}" 
            : '-',
        "wakeTime": endedAt != null 
            ? "${endedAt.hour.toString().padLeft(2, '0')}:${endedAt.minute.toString().padLeft(2, '0')}" 
            : '-',
        "sleepQuality": sleepTask['task_quality'] ?? '-',
        "sleepHours": sleepTask['value_number']?.toStringAsFixed(1) ?? '-',
        "isTaskCompleted": sleepTask['completed'] == true,
      };
    } else {
      _sleepData = {
        "sleepTime": "-",
        "wakeTime": "-",
        "sleepQuality": "-",
        "sleepHours": "-",
        "isTaskCompleted": false,
      };
    }

    // อัปเดตข้อมูล mood
    if (moodTask != null) {
      mood = moodTask['value_text'] ?? 'N/A';
    } else {
      mood = 'N/A';
    }
  }

  void _setDefaultTaskData() {
    mood = 'N/A';
    _exerciseData = {
      "type": "-",
      "duration": "-",
      "calories": "-",
      "isTaskCompleted": false,
    };
    _sleepData = {
      "sleepTime": "-",
      "wakeTime": "-",
      "sleepQuality": "-",
      "sleepHours": "-",
      "isTaskCompleted": false,
    };
    _waterData = {
      "glasses": 0,
      "isTaskCompleted": false,
    };
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
              Icons.local_drink,
              "จำนวนแก้ว",
              "${_waterData?["glasses"] ?? 0} แก้ว",
            ),
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
              Icons.access_time,
              "ชั่วโมงการนอน",
              _sleepData?["sleepHours"] != null && _sleepData!["sleepHours"] != '-'
                  ? "${_sleepData!["sleepHours"]} ชั่วโมง"
                  : '-',
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
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[400],
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (_errorMessage!.contains('เข้าสู่ระบบ'))
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('เข้าสู่ระบบ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _errorMessage = null;
                    });
                    _fetchUserData();
                    loadData();
                    loadDailyTasks();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('ลองใหม่'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      );
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
                onPressed: () async {
                  // นำทางไปหน้า profile และรอผลตอบกลับ
                  final result = await Navigator.pushNamed(context, '/profile');
                  
                  // ถ้ากลับมาแล้ว ให้ refresh ข้อมูล
                  if (result == true || result == null) {
                    await refreshAllData();
                  }
                },
                child: const Text("ไปที่หน้าโปรไฟล์"),
              ),
            ],
          ),
        ),
      );
    }

    final String displayName =
        _userData!['username'] ??
        _userData!['email'] ??
        'User';
    final int? age = _userData!['age'];
    final double? weight = _userData!['weight']?.toDouble();
    final double? height = _userData!['height']?.toDouble();
    final String bmiResult = _calculateBmi(weight, height);

    // ปรับปรุงการเข้าถึงข้อมูลสุขภาพให้เข้ากับโครงสร้างใหม่ - รองรับทั้ง Firebase และ FastAPI structure
    String bloodPressure = 'N/A';
    int? heartRate;
    
    // ลองดึงข้อมูลจาก FastAPI structure ก่อน
    if (_userData!['blood_pressure'] != null) {
      bloodPressure = _userData!['blood_pressure'];
    }
    if (_userData!['heart_rate'] != null) {
      heartRate = _userData!['heart_rate'];
    }
    
    // ถ้าไม่มี ลองดึงจาก Firebase structure (สำหรับข้อมูลเก่า)
    if (bloodPressure == 'N/A' && _userData!['healthInfo'] != null) {
      final healthInfo = _userData!['healthInfo'];
      bloodPressure = healthInfo['bloodPressure'] ?? 'N/A';
      heartRate = healthInfo['heartRate'];
    }

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
      body: RefreshIndicator(
        onRefresh: refreshAllData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(), // เพื่อให้ pull-to-refresh ทำงานได้
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
                      widget.onNavigate(3);
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
                      _buildHealthMetricItem(label: "อารมณ์", value: mood),
                    ],
                  ),

                  const SizedBox(height: 20),
                  
                  // TDEE Calculator Button
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _showTDEEDialog,
                      icon: const Icon(Icons.calculate, size: 20),
                      label: const Text(
                        'คำนวณ TDEE และตั้งเป้าหมาย',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF79D7BE),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        shadowColor: const Color(0xFF79D7BE).withOpacity(0.4),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  _buildTaskInfo(),
                ],
              ),
            ),
          ], // ปิด children ของ Column
        ), // ปิด Column (child ของ SingleChildScrollView)
      ), // ปิด SingleChildScrollView (child ของ RefreshIndicator)
    ), // ปิด RefreshIndicator (body ของ Scaffold)
    ); // ปิด Scaffold
  }
}

class _TDEECalculatorDialog extends StatefulWidget {
  final double bmr;
  final double weight;
  final double height;
  final int age;
  final String gender;
  final ApiService apiService;
  final VoidCallback onGoalSaved;

  const _TDEECalculatorDialog({
    required this.bmr,
    required this.weight,
    required this.height,
    required this.age,
    required this.gender,
    required this.apiService,
    required this.onGoalSaved,
  });

  @override
  State<_TDEECalculatorDialog> createState() => _TDEECalculatorDialogState();
}

class _TDEECalculatorDialogState extends State<_TDEECalculatorDialog> {
  // Step management
  int currentStep = 0;
  
  // Goal data
  String? selectedActivityLevel;
  double? targetWeight;
  String? selectedTimeframe;
  String? selectedGoalType;
  int? targetWaterIntake = 8; // ตั้งค่าเริ่มต้น
  int? targetSleepHours = 8; // ตั้งค่าเริ่มต้น
  int? targetExerciseMinutesPerDay = 30; // นาทีต่อวันที่ user กรอก
  int? selectedExerciseFrequency; // จำนวนครั้งที่แน่นอนที่ user เลือก
  bool _isLoading = false;



  final List<String> timeframes = [
    '1 สัปดาห์',
    '2 สัปดาห์', 
    '1 เดือน',
    '2 เดือน',
    '3 เดือน',
    '6 เดือน',
  ];





  double get tdee {
    if (selectedExerciseFrequency == null) return 0;
    return widget.bmr * _getMultiplierForFrequency(selectedExerciseFrequency!);
  }

  double get targetCalories {
    if (targetWeight == null || selectedTimeframe == null) return tdee;
    
    double weightDifference = targetWeight! - widget.weight;
    int weeks = _getWeeksFromTimeframe(selectedTimeframe!);
    
    // Conservative approach: 1 kg weight change = ~7000 calories
    // (Accounts for both fat and lean mass changes)
    // Safe rate: 0.5-1 kg per week = ~500-1000 kcal/day deficit/surplus
    double weeklyCalorieAdjustment = (weightDifference * 7000) / weeks;
    double dailyCalorieAdjustment = weeklyCalorieAdjustment / 7;
    
    // Apply safety limits to prevent extreme calorie restrictions
    double maxDailyAdjustment = tdee * 0.25; // ไม่เกิน 25% ของ TDEE
    dailyCalorieAdjustment = dailyCalorieAdjustment.clamp(-maxDailyAdjustment, maxDailyAdjustment);
    
    return tdee + dailyCalorieAdjustment;
  }

  int _getWeeksFromTimeframe(String timeframe) {
    switch (timeframe) {
      case '1 สัปดาห์':
        return 1;
      case '2 สัปดาห์':
        return 2;
      case '1 เดือน':
        return 4;
      case '2 เดือน':
        return 8;
      case '3 เดือน':
        return 12;
      case '6 เดือน':
        return 24;
      default:
        return 4;
    }
  }

  String get goalDescription {
    if (targetWeight == null) return '';
    
    double weightDifference = targetWeight! - widget.weight;
    if (weightDifference == 0) {
      return 'รักษาน้ำหนัก';
    } else if (weightDifference > 0) {
      return 'เพิ่มน้ำหนัก ${weightDifference.toStringAsFixed(1)} กก.';
    } else {
      return 'ลดน้ำหนัก ${(-weightDifference).toStringAsFixed(1)} กก.';
    }
  }

  // ตรวจสอบความปลอดภัยของเป้าหมาย
  String get safetyWarning {
    if (targetWeight == null || selectedTimeframe == null) return '';
    
    double weightDifference = targetWeight! - widget.weight;
    int weeks = _getWeeksFromTimeframe(selectedTimeframe!);
    double weeklyRate = weightDifference.abs() / weeks;
    
    if (weeklyRate > 1.0) {
      return '⚠️ อัตราการเปลี่ยนแปลงน้ำหนักสูงเกินไป (>${weeklyRate.toStringAsFixed(1)} กก./สัปดาห์)';
    } else if (weeklyRate > 0.5 && weeklyRate <= 1.0) {
      return '✅ อัตราการเปลี่ยนแปลงน้ำหนักเหมาะสม (${weeklyRate.toStringAsFixed(1)} กก./สัปดาห์)';
    } else if (weeklyRate > 0) {
      return '👍 อัตราการเปลี่ยนแปลงน้ำหนักช้าและปลอดภัย (${weeklyRate.toStringAsFixed(1)} กก./สัปดาห์)';
    }
    return '';
  }



  double _getMultiplierForFrequency(int frequency) {
    // คำนวณตัวคูณ TDEE ตามความถี่การออกกำลังกาย
    if (frequency == 0) return 1.2; // ไม่ออกกำลังกาย
    if (frequency <= 3) return 1.375; // น้อย (1-3 ครั้ง)
    if (frequency <= 5) return 1.55; // ปานกลาง (4-5 ครั้ง)
    if (frequency <= 7) return 1.725; // มาก (6-7 ครั้ง)
    return 1.9; // มากที่สุด (8+ ครั้ง)
  }

  IconData _getFrequencyIcon(int frequency) {
    if (frequency == 0) return Icons.hotel; // ไม่ออกกำลังกาย
    if (frequency <= 2) return Icons.directions_walk; // น้อยมาก
    if (frequency <= 4) return Icons.directions_run; // น้อย-ปานกลาง
    if (frequency <= 6) return Icons.fitness_center; // ปานกลาง-มาก
    if (frequency == 7) return Icons.sports; // ทุกวัน
    return Icons.sports_gymnastics; // มากที่สุด (8+ ครั้ง)
  }

  String _getFrequencyLabel(int frequency) {
    // ลบส่วนแสดงตัวคูณออก
    if (frequency == 0) return 'ไม่ออกกำลังกาย';
    if (frequency <= 3) return 'การออกกำลังกายระดับน้อย';
    if (frequency <= 5) return 'การออกกำลังกายระดับปานกลาง';
    if (frequency <= 7) return 'การออกกำลังกายระดับมาก';
    return 'การออกกำลังกายระดับสูงมาก';
  }

  String _getFrequencyDescription(int frequency) {
    if (frequency == 0) return 'ไม่ออกกำลังกาย';
    if (frequency == 7) return 'ออกกำลังกายทุกวัน (7 ครั้ง)';
    if (frequency == 14) return 'ออกกำลังกายวันละ 2 ครั้ง (ทุกวัน)';
    if (frequency == 21) return 'ออกกำลังกายวันละ 3 ครั้ง (ทุกวัน)';
    return 'ออกกำลังกาย $frequency ครั้งต่อสัปดาห์';
  }

  void _nextStep() {
    if (currentStep < 4) { // ลดจาก 5 เป็น 4 เพราะลบ goal type step
      setState(() {
        currentStep++;
      });
    }
  }

  void _previousStep() {
    if (currentStep > 0) {
      setState(() {
        currentStep--;
      });
    }
  }

  bool _canProceedToNextStep() {
    switch (currentStep) {
      case 0:
        return targetWeight != null; // ขั้นที่ 1: น้ำหนักเป้าหมาย
      case 1:
        return selectedExerciseFrequency != null && targetExerciseMinutesPerDay != null; // ขั้นที่ 2: การออกกำลังกาย
      case 2:
        return selectedTimeframe != null; // ขั้นที่ 3: ระยะเวลา
      case 3:
        return targetWaterIntake != null && targetSleepHours != null; // ขั้นที่ 4: เป้าหมายรายวัน
      case 4:
        return true; // ขั้นที่ 5: สรุป
      default:
        return false;
    }
  }

  Future<void> _saveGoal() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Validate all required data
      if (targetWeight == null) throw Exception('กรุณากำหนดน้ำหนักเป้าหมาย');
      if (selectedExerciseFrequency == null) throw Exception('กรุณาเลือกจำนวนครั้งการออกกำลังกาย');
      if (targetExerciseMinutesPerDay == null) throw Exception('กรุณาเลือกเวลาออกกำลังกาย');
      if (selectedTimeframe == null) throw Exception('กรุณาเลือกระยะเวลาเป้าหมาย');
      if (targetWaterIntake == null) throw Exception('กรุณาตั้งเป้าหมายการดื่มน้ำ');
      if (targetSleepHours == null) throw Exception('กรุณาตั้งเป้าหมายการนอน');

      Map<String, dynamic> currentUser;
      try {
        currentUser = await widget.apiService.getCurrentUser();
        print('DEBUG: Current user data: $currentUser');
      } catch (e) {
        print('DEBUG: Failed to get current user: $e');
        throw Exception('ไม่สามารถตรวจสอบข้อมูลผู้ใช้ได้ กรุณาเข้าสู่ระบบใหม่');
      }
      
      final String userId = currentUser['uid']?.toString() ?? 
                           currentUser['id']?.toString() ?? 
                           currentUser['user_id']?.toString() ?? '';

      print('DEBUG: Extracted user ID: "$userId"');
      
      if (userId.isEmpty) {
        print('DEBUG: User data keys: ${currentUser.keys.toList()}');
        throw Exception('ไม่พบ ID ผู้ใช้ในข้อมูล กรุณาเข้าสู่ระบบใหม่');
      }

      // Calculate exercise values with debug
      final exerciseFreq = selectedExerciseFrequency ?? 0;
      final exerciseMinutesPerDay = targetExerciseMinutesPerDay ?? 30;
      
      print('DEBUG: =================');
      print('DEBUG: selectedExerciseFrequency = $selectedExerciseFrequency');
      print('DEBUG: selectedExerciseFrequency type = ${selectedExerciseFrequency.runtimeType}');
      print('DEBUG: exerciseFreq = $exerciseFreq');
      print('DEBUG: exerciseFreq type = ${exerciseFreq.runtimeType}');
      print('DEBUG: exerciseMinutesPerDay = $exerciseMinutesPerDay');
      print('DEBUG: tdeeMultiplier = ${_getMultiplierForFrequency(exerciseFreq)}');
      print('DEBUG: =================');

      // Create comprehensive goal data
      final goalData = {
        'goal_weight': targetWeight,
        'goal_exercise_frequency_week': exerciseFreq,
        'goal_exercise_minutes': exerciseMinutesPerDay,
        'goal_water_intake': targetWaterIntake ?? 8,
        'goal_calories': targetCalories.round(),
        'goal_sleep_hours': targetSleepHours ?? 8,
        'activity_level': _getFrequencyDescription(exerciseFreq),
        'goal_timeframe': selectedTimeframe,
      };

      print('DEBUG: =================');
      print('DEBUG: Sending goal data: $goalData');
      print('DEBUG: goal_exercise_frequency_week value: ${goalData['goal_exercise_frequency_week']}');
      print('DEBUG: goal_exercise_frequency_week type: ${goalData['goal_exercise_frequency_week'].runtimeType}');
      print('DEBUG: User ID: $userId');
      print('DEBUG: Goal calories: ${targetCalories.round()}');
      print('DEBUG: =================');

      // Save or update goals
      final result = await _saveOrUpdateGoals(userId, goalData);
      print('DEBUG: Final API response: $result');

      if (mounted) {
        Navigator.of(context).pop();
        
        // Use message from result or fallback to operation-based message
        final operation = result['_operation'] ?? 'create';
        final baseMessage = result['_message'] ?? 
            (operation == 'update' ? 'อัปเดตเป้าหมายสำเร็จ' : 'บันทึกเป้าหมายสำเร็จ');
        final successMessage = '$baseMessage! แคลอรี: ${targetCalories.round()} kcal/day';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
        widget.onGoalSaved();
      }
    } catch (e) {
      print('DEBUG: Error saving goals: $e');
      if (mounted) {
        String errorMessage = 'เกิดข้อผิดพลาด: ';
        if (e.toString().contains('Authentication expired') || 
            e.toString().contains('Could not validate credentials')) {
          errorMessage = 'กรุณาเข้าสู่ระบบใหม่';
        } else if (e.toString().contains('Network error')) {
          errorMessage = 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้';
        } else {
          errorMessage += e.toString().replaceAll('Exception: ', '');
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>> _saveOrUpdateGoals(String userId, Map<String, dynamic> goalData) async {
    try {
      // Always check if user already has goals first
      final existingGoals = await widget.apiService.getUserGoals(userId);
      print('DEBUG: Existing goals check: $existingGoals');
      
      if (existingGoals != null && existingGoals.isNotEmpty) {
        // User has existing goals - ALWAYS UPDATE (never create new)
        print('DEBUG: User has existing goals - updating...');
        print('DEBUG: Existing goal ID: ${existingGoals["id"] ?? "unknown"}');
        final result = await widget.apiService.updateUserGoals(
          userId: userId,
          goals: goalData,
        );
        print('DEBUG: Goals updated successfully: $result');
        result['_operation'] = 'update';
        result['_message'] = 'อัปเดตเป้าหมายสำเร็จ';
        return result;
      } else {
        // User doesn't have any goals - create first goal
        print('DEBUG: User has no existing goals - creating first goal...');
        final result = await widget.apiService.createUserGoals(
          userId: userId,
          goals: goalData,
        );
        print('DEBUG: First goal created successfully: $result');
        result['_operation'] = 'create';
        result['_message'] = 'สร้างเป้าหมายสำเร็จ';
        return result;
      }
    } catch (e) {
      print('DEBUG: Error in goal save/update process: $e');
      
      // Try to get more specific error information
      if (e.toString().contains('404') || e.toString().contains('not found')) {
        // Definitely no existing goals, create new
        print('DEBUG: Confirmed no existing goals - creating new...');
        try {
          final result = await widget.apiService.createUserGoals(
            userId: userId,
            goals: goalData,
          );
          print('DEBUG: New goal created after 404: $result');
          result['_operation'] = 'create';
          result['_message'] = 'สร้างเป้าหมายสำเร็จ';
          return result;
        } catch (createError) {
          print('DEBUG: Failed to create goal after 404: $createError');
          rethrow;
        }
      } else {
        // Other error, rethrow
        print('DEBUG: Unknown error in goal process: $e');
        rethrow;
      }
    }
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) { // ลดจาก 6 เป็น 5
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index <= currentStep
                ? const Color(0xFF79D7BE)
                : Colors.grey[300],
          ),
        );
      }),
    );
  }

  Widget _buildStepContent() {
    switch (currentStep) {
      case 0:
        return _buildTargetWeightStep(); // เริ่มต้นด้วยน้ำหนักเป้าหมาย
      case 1:
        return _buildActivityLevelStep();
      case 2:
        return _buildTimeframeStep();
      case 3:
        return _buildLifestyleStep();
      case 4:
        return _buildSummaryStep();
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.track_changes, color: Color(0xFF79D7BE)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'ตั้งเป้าหมายสุขภาพ',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              Text(
                'ขั้นที่ ${currentStep + 1}/5', // ลดจาก 6 เป็น 5
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStepIndicator(),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.65,
        child: _buildStepContent(),
      ),
      actions: _buildActionButtons(),
    );
  }

  List<Widget> _buildActionButtons() {
    return [
      if (currentStep > 0)
        TextButton(
          onPressed: _previousStep,
          child: const Text('ย้อนกลับ'),
        ),
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text(
          'ยกเลิก',
          style: TextStyle(color: Colors.grey),
        ),
      ),
      if (currentStep < 4) // ลดจาก 5 เป็น 4
        ElevatedButton(
          onPressed: _canProceedToNextStep() ? _nextStep : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF79D7BE),
            foregroundColor: Colors.white,
          ),
          child: const Text('ถัดไป'),
        )
      else
        ElevatedButton(
          onPressed: _isLoading ? null : _saveGoal,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF79D7BE),
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('บันทึกเป้าหมาย'),
        ),
    ];
  }





  Widget _buildActivityLevelStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'การออกกำลังกาย',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E5077),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'เลือกจำนวนครั้งและเวลาที่คุณจะออกกำลังกาย',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          
          // Exercise Minutes Selection
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.timer, color: Color(0xFF79D7BE)),
                    SizedBox(width: 8),
                    Text(
                      'เวลาออกกำลังกายต่อวัน',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E5077),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _showExerciseGoalDialog(),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF79D7BE).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF79D7BE)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.fitness_center,
                          color: Color(0xFF79D7BE),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${targetExerciseMinutesPerDay ?? 30} นาทีต่อวัน',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF79D7BE),
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Color(0xFF79D7BE),
                          size: 12,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Exercise Frequency Selection
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.fitness_center, color: Color(0xFF79D7BE)),
                    SizedBox(width: 8),
                    Text(
                      'จำนวนครั้งต่อสัปดาห์',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E5077),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'กรอกจำนวนครั้งที่ออกกำลังกายต่อสัปดาห์',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  keyboardType: TextInputType.number,
                  initialValue: selectedExerciseFrequency?.toString() ?? '',
                  decoration: InputDecoration(
                   
                    suffixText: 'ครั้ง/สัปดาห์',
                    prefixIcon: const Icon(Icons.repeat, color: Color(0xFF79D7BE)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF79D7BE), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      final frequency = int.tryParse(value);
                      print('DEBUG: Input value: "$value"');
                      print('DEBUG: Parsed frequency: $frequency');
                      
                      if (frequency != null && frequency >= 0 && frequency <= 21) {
                        selectedExerciseFrequency = frequency;
                        selectedActivityLevel = _getFrequencyLabel(frequency);
                        print('DEBUG: Set selectedExerciseFrequency to: $selectedExerciseFrequency');
                      } else if (value.isEmpty) {
                        selectedExerciseFrequency = null;
                        selectedActivityLevel = null;
                        print('DEBUG: Cleared selectedExerciseFrequency (empty input)');
                      } else {
                        print('DEBUG: Invalid frequency: $frequency (out of range 0-21)');
                      }
                    });
                  },
                ),
                if (selectedExerciseFrequency != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF79D7BE).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF79D7BE).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getFrequencyIcon(selectedExerciseFrequency!),
                          color: const Color(0xFF79D7BE),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getFrequencyDescription(selectedExerciseFrequency!),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF2E5077),
                                ),
                              ),

                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetWeightStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'กำหนดน้ำหนักเป้าหมาย',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E5077),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ระบบจะกำหนดเป้าหมายให้อัตโนมัติตามน้ำหนักที่คุณกรอก',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.scale, color: Color(0xFF79D7BE)),
                    const SizedBox(width: 8),
                    Text(
                      'น้ำหนักปัจจุบัน: ${widget.weight.toStringAsFixed(1)} กก.',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'น้ำหนักเป้าหมาย (กก.):',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: 'กรอกน้ำหนักเป้าหมาย',
                    suffixText: 'กก.',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      targetWeight = double.tryParse(value);
                      // อัตโนมัติกำหนดเป้าหมายตามน้ำหนัก
                      if (targetWeight != null) {
                        if (targetWeight! > widget.weight) {
                          selectedGoalType = 'เพิ่มน้ำหนัก';
                        } else if (targetWeight! < widget.weight) {
                          selectedGoalType = 'ลดน้ำหนัก';
                        } else {
                          selectedGoalType = 'รักษาน้ำหนัก';
                        }
                      }
                    });
                  },
                ),
                if (targetWeight != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _getWeightChangeColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getWeightChangeColor(),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              _getWeightChangeIcon(),
                              color: _getWeightChangeColor(),
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'เป้าหมายของคุณ:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    selectedGoalType ?? '',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: _getWeightChangeColor(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _getWeightChangeText(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getWeightChangeColor() {
    if (targetWeight == null) return Colors.grey;
    if (targetWeight! == widget.weight) return Colors.blue;
    return targetWeight! > widget.weight ? Colors.green : Colors.red;
  }

  IconData _getWeightChangeIcon() {
    if (targetWeight == null) return Icons.help;
    if (targetWeight! == widget.weight) return Icons.balance;
    return targetWeight! > widget.weight ? Icons.trending_up : Icons.trending_down;
  }

  String _getWeightChangeText() {
    if (targetWeight == null) return '';
    double difference = (targetWeight! - widget.weight).abs();
    if (targetWeight! == widget.weight) {
      return 'รักษาน้ำหนักปัจจุบัน';
    } else if (targetWeight! > widget.weight) {
      return 'เพิ่มน้ำหนัก ${difference.toStringAsFixed(1)} กก.';
    } else {
      return 'ลดน้ำหนัก ${difference.toStringAsFixed(1)} กก.';
    }
  }

  Widget _buildTimeframeStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ระยะเวลาเป้าหมาย',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E5077),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'คุณต้องการบรรลุเป้าหมายภายในเวลาเท่าไหร่?',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          ...timeframes.map((timeframe) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  setState(() {
                    selectedTimeframe = timeframe;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: selectedTimeframe == timeframe
                        ? const Color(0xFF79D7BE).withOpacity(0.2)
                        : Colors.white,
                    border: Border.all(
                      color: selectedTimeframe == timeframe
                          ? const Color(0xFF79D7BE)
                          : Colors.grey[300]!,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          timeframe,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: selectedTimeframe == timeframe
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (selectedTimeframe == timeframe)
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF79D7BE),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildLifestyleStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'เป้าหมายไลฟ์สไตล์',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E5077),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ตั้งเป้าหมายการดื่มน้ำและการนอนหลับ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          
          // Water intake
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.local_drink, color: Color(0xFF79D7BE)),
                    SizedBox(width: 8),
                    Text(
                      'เป้าหมายการดื่มน้ำ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _showWaterGoalDialog(),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF79D7BE).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF79D7BE)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'เลือกจำนวนแก้วต่อวัน',
                          style: TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            ...List.generate(
                              (targetWaterIntake ?? 8).clamp(0, 4),
                              (index) => const Icon(
                                Icons.water_drop,
                                color: Color(0xFF79D7BE),
                                size: 16,
                              ),
                            ),
                            if ((targetWaterIntake ?? 8) > 4)
                              Text(
                                ' +${(targetWaterIntake ?? 8) - 4}',
                                style: const TextStyle(
                                  color: Color(0xFF79D7BE),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            const Spacer(),
                            Text(
                              '${targetWaterIntake ?? 8} แก้ว',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF79D7BE),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Sleep hours
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.bedtime, color: Color(0xFF79D7BE)),
                    SizedBox(width: 8),
                    Text(
                      'เป้าหมายการนอน',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _showSleepGoalDialog(),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF79D7BE).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF79D7BE)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'เลือกเวลานอนต่อวัน',
                          style: TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            ...List.generate(
                              (targetSleepHours ?? 8).clamp(0, 4),
                              (index) => const Icon(
                                Icons.nights_stay,
                                color: Color(0xFF79D7BE),
                                size: 16,
                              ),
                            ),
                            if ((targetSleepHours ?? 8) > 4)
                              Text(
                                ' +${(targetSleepHours ?? 8) - 4}',
                                style: const TextStyle(
                                  color: Color(0xFF79D7BE),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            const Spacer(),
                            Text(
                              '${targetSleepHours ?? 8} ชม.',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF79D7BE),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          

        ],
      ),
    );
  }

  Widget _buildSummaryStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Simple Header
          const Text(
            'สรุปเป้าหมายของคุณ',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E5077),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ตรวจสอบความถูกต้องของข้อมูลก่อนบันทึก',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),

          // Goal Overview - Simple
          _buildSimpleCard(
            title: 'เป้าหมายหลัก',
            content: selectedGoalType ?? '',
            subtitle: '${widget.weight.toStringAsFixed(1)} กก. → ${targetWeight?.toStringAsFixed(1) ?? ''} กก. (${selectedTimeframe ?? ''})',
            icon: _getWeightChangeIcon(),
            color: _getWeightChangeColor(),
          ),
          
          // Safety Warning Card
          if (safetyWarning.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: safetyWarning.contains('⚠️') 
                    ? Colors.orange.withOpacity(0.1)
                    : safetyWarning.contains('✅')
                        ? Colors.green.withOpacity(0.1)
                        : Colors.blue.withOpacity(0.1),
                border: Border.all(
                  color: safetyWarning.contains('⚠️') 
                      ? Colors.orange
                      : safetyWarning.contains('✅')
                          ? Colors.green
                          : Colors.blue,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    safetyWarning.contains('⚠️') 
                        ? Icons.warning
                        : safetyWarning.contains('✅')
                            ? Icons.check_circle
                            : Icons.info,
                    color: safetyWarning.contains('⚠️') 
                        ? Colors.orange
                        : safetyWarning.contains('✅')
                            ? Colors.green
                            : Colors.blue,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      safetyWarning,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: safetyWarning.contains('⚠️') 
                            ? Colors.orange[800]
                            : safetyWarning.contains('✅')
                                ? Colors.green[800]
                                : Colors.blue[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Exercise Goals - Simple
          _buildSimpleCard(
            title: 'การออกกำลังกาย',
            content: selectedExerciseFrequency != null ? _getFrequencyDescription(selectedExerciseFrequency!) : 'ไม่ได้ตั้งค่า',
            subtitle: '${selectedExerciseFrequency ?? 0} ครั้ง/สัปดาห์ × ${targetExerciseMinutesPerDay ?? 30} นาที/ครั้ง',
            icon: Icons.fitness_center,
            color: const Color(0xFF79D7BE),
          ),

          // Water Goal - Simple
          _buildSimpleCard(
            title: 'เป้าหมายน้ำ',
            content: '${targetWaterIntake ?? 8} แก้วต่อวัน',
            subtitle: 'รวม ${(targetWaterIntake ?? 8) * 250} มล./วัน',
            icon: Icons.water_drop,
            color: Colors.blue,
          ),

          // Sleep Goal - Simple
          _buildSimpleCard(
            title: 'เป้าหมายการนอน',
            content: '${targetSleepHours ?? 8} ชั่วโมงต่อวัน',
            icon: Icons.bedtime,
            color: Colors.indigo,
          ),
          

          
          const SizedBox(height: 16),
          
          // Calories Results - Expanded Display
          if (selectedExerciseFrequency != null) ...[
            const SizedBox(height: 8),
            const Divider(thickness: 2, color: Color(0xFF79D7BE)),
            const SizedBox(height: 20),
            
            // Main Target Calories - Compact
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF79D7BE).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF79D7BE), width: 1),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        color: Color(0xFF79D7BE),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'เป้าหมายแคลอรีต่อวัน',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${targetCalories.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF79D7BE),
                      height: 1.0,
                    ),
                  ),
                  Text(
                    'แคลอรี่ต่อวัน',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (goalDescription.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      goalDescription,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),

            

          ],
        ],
      ),
    );
  }

  Widget _buildSimpleCard({
    required String title,
    required String content,
    String? subtitle,
    IconData? icon,
    Color? color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (color ?? const Color(0xFF79D7BE)).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color ?? const Color(0xFF79D7BE),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E5077),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }



  void _showWaterGoalDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        int selectedWater = targetWaterIntake ?? 8;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.water_drop, color: Color(0xFF79D7BE)),
                  SizedBox(width: 8),
                  Text('เลือกเป้าหมายดื่มน้ำ'),
                ],
              ),
              content: Container(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('แก้วต่อวัน (1 แก้ว = 250 มล.)'),
                    const SizedBox(height: 20),
                    GridView.builder(
                      shrinkWrap: true,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        childAspectRatio: 1,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: 12,
                      itemBuilder: (context, index) {
                        int glassCount = index + 4; // 4-15 glasses
                        bool isSelected = selectedWater == glassCount;
                        return InkWell(
                          onTap: () {
                            setDialogState(() {
                              selectedWater = glassCount;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF79D7BE) : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF79D7BE) : Colors.grey[300]!,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.water_drop,
                                  color: isSelected ? Colors.white : const Color(0xFF79D7BE),
                                  size: 20,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$glassCount',
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'รวม ${selectedWater * 250} มล. ต่อวัน',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF79D7BE),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('ยกเลิก'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      targetWaterIntake = selectedWater;
                    });
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF79D7BE),
                  ),
                  child: const Text('ยืนยัน', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSleepGoalDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        int selectedSleep = targetSleepHours ?? 8;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.nights_stay, color: Color(0xFF79D7BE)),
                  SizedBox(width: 8),
                  Text('เลือกเป้าหมายการนอน'),
                ],
              ),
              content: Container(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('ชั่วโมงต่อวัน'),
                    const SizedBox(height: 20),
                    GridView.builder(
                      shrinkWrap: true,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        childAspectRatio: 1,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: 8,
                      itemBuilder: (context, index) {
                        int sleepHours = index + 5; // 5-12 hours
                        bool isSelected = selectedSleep == sleepHours;
                        return InkWell(
                          onTap: () {
                            setDialogState(() {
                              selectedSleep = sleepHours;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF79D7BE) : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF79D7BE) : Colors.grey[300]!,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.nights_stay,
                                  color: isSelected ? Colors.white : const Color(0xFF79D7BE),
                                  size: 20,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${sleepHours}h',
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'การนอนหลับ $selectedSleep ชั่วโมงต่อวัน',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF79D7BE),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('ยกเลิก'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      targetSleepHours = selectedSleep;
                    });
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF79D7BE),
                  ),
                  child: const Text('ยืนยัน', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showExerciseGoalDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        int selectedExercise = targetExerciseMinutesPerDay ?? 30;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.fitness_center, color: Color(0xFF79D7BE)),
                  SizedBox(width: 8),
                  Text('เลือกเวลาออกกำลังกาย'),
                ],
              ),
              content: Container(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('เลือกเวลาออกกำลังกายต่อวัน (นาที)'),
                    const SizedBox(height: 20),
                    Container(
                      height: 200,
                      child: ListView.builder(
                        itemCount: 12,
                        itemBuilder: (context, index) {
                          int minutes = (index + 1) * 15; // 15, 30, 45, 60, 75, 90, 105, 120, 135, 150, 165, 180
                          bool isSelected = selectedExercise == minutes;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              onTap: () {
                                setDialogState(() {
                                  selectedExercise = minutes;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF79D7BE) : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFF79D7BE) : Colors.grey[300]!,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '$minutes นาที',
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : Colors.black,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'เลือก: $selectedExercise นาทีต่อวัน',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF79D7BE),
                      ),
                    ),
                    if (selectedExerciseFrequency != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'รวม ${selectedExercise * selectedExerciseFrequency!} นาที/สัปดาห์',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('ยกเลิก'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      targetExerciseMinutesPerDay = selectedExercise;
                    });
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF79D7BE),
                  ),
                  child: const Text('ยืนยัน', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}