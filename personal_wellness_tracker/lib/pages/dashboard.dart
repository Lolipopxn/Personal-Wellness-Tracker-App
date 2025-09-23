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
        
        // ตรวจสอบข้อมูลที่จำเป็นและส่งไปหน้า profile หากข้อมูลไม่ครบ
        _checkAndRedirectToProfile();
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

  void _checkAndRedirectToProfile() {
    if (_userData == null) return;
    
    // ตรวจสอบข้อมูลที่จำเป็น
    final bool hasBasicInfo = _userData!['age'] != null && 
                             _userData!['weight'] != null && 
                             _userData!['height'] != null;
    
    // ตรวจสอบข้อมูลสุขภาพเพิ่มเติม
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
    
    final bool hasHealthInfo = bloodPressure != 'N/A' && heartRate != null;
    
    // หากข้อมูลไม่ครบ ให้ไปหน้า profile
    if (!hasBasicInfo || !hasHealthInfo) {
      _showIncompleteDataDialog();
    }
  }

  void _showIncompleteDataDialog() {
    showDialog(
      context: context,
      barrierDismissible: true, // เปลี่ยนให้สามารถปิด dialog ได้โดยการแตะข้างนอก
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange),
              SizedBox(width: 8),
              Text('ข้อมูลไม่ครบถ้วน'),
            ],
          ),
          content: const Text(
            'พบว่าข้อมูลส่วนตัวของคุณยังไม่ครบถ้วน กรุณากรอกข้อมูลให้ครบถ้วนเพื่อให้ระบบสามารถประเมินสุขภาพได้อย่างแม่นยำ\n\n'
            'ข้อมูลที่จำเป็น:\n'
            '• อายุ, น้ำหนัก, ส่วนสูง\n'
            '• ความดันโลหิต\n'
            '• อัตราเต้นหัวใจ',
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // ปิด dialog
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('ยกเลิก'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      Navigator.of(context).pop(); // ปิด dialog
                      
                      // นำทางไปหน้า profile และรอผลตอบกลับ
                      final result = await Navigator.pushNamed(context, '/profile');
                      
                      // ถ้ากลับมาแล้ว ให้ refresh ข้อมูล
                      if (result == true || result == null) {
                        await refreshAllData();
                      }
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF79D7BE),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('ไปกรอกข้อมูล'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
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
          ], // ปิด children ของ Column
        ), // ปิด Column (child ของ SingleChildScrollView)
      ), // ปิด SingleChildScrollView (child ของ RefreshIndicator)
    ), // ปิด RefreshIndicator (body ของ Scaffold)
    ); // ปิด Scaffold
  }
}