import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    return const RegistrationScreen();
  }
}

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final ApiService _apiService = ApiService();

  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _goalWeightController = TextEditingController();
  final TextEditingController _goalExerciseController = TextEditingController();
  final TextEditingController _goalWaterController = TextEditingController();
  final TextEditingController _goalExerciseMinutesController =
      TextEditingController();
  final TextEditingController _bpController = TextEditingController();
  final TextEditingController _hrController = TextEditingController();
  TextEditingController? _otherProblemController;

  String? _selectedGender;
  int _currentStepIndex = 0;
  final int _totalSteps = 3;
  List<bool>? _healthProblemsChecked;
  bool _otherChecked = false;
  String? _stepErrorMessage;

  final List<GlobalKey<FormState>> _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final currentUser = await _apiService.getCurrentUser();
      print("DEBUG: Loading user data: $currentUser"); // Debug line
      if (mounted) {
        setState(() {
          // โหลดข้อมูลพื้นฐาน
          _ageController.text = currentUser['age']?.toString() ?? '';
          _selectedGender = currentUser['gender'];
          _weightController.text = currentUser['weight']?.toString() ?? '';
          _heightController.text = currentUser['height']?.toString() ?? '';
          
          // โหลดข้อมูลเป้าหมาย (ถ้ามี)
          if (currentUser['goals'] != null) {
            final goals = currentUser['goals'];
            _goalWeightController.text = goals['goal_weight']?.toString() ?? goals['weight']?.toString() ?? '';
            _goalExerciseController.text = goals['goal_exercise_frequency']?.toString() ?? goals['exerciseFrequency']?.toString() ?? '';
            _goalExerciseMinutesController.text = goals['goal_exercise_minutes']?.toString() ?? goals['exerciseMinutes']?.toString() ?? '';
            _goalWaterController.text = goals['goal_water_intake']?.toString() ?? goals['waterIntake']?.toString() ?? '';
          }
          
          // โหลดข้อมูลสุขภาพ (ถ้ามี)
          if (currentUser['preferences'] != null) {
            final prefs = currentUser['preferences'];
            _bpController.text = prefs['bloodPressure'] ?? '';
            _hrController.text = prefs['heartRate']?.toString() ?? '';
          }
          
          // รองรับข้อมูลจาก FastAPI structure
          if (currentUser['blood_pressure'] != null) {
            _bpController.text = currentUser['blood_pressure'];
          }
          if (currentUser['heart_rate'] != null) {
            _hrController.text = currentUser['heart_rate'].toString();
          }
          
          // โหลดปัญหาสุขภาพ
          _loadHealthProblems(currentUser);
        });
      }
    } catch (e) {
      print("Error loading user data: $e");
    }
  }

  void _loadHealthProblems(Map<String, dynamic> currentUser) {
    final List<String> problemsOptions = [
      'โรคเบาหวาน',
      'โรคความดันโลหิตสูง',
      'โรคหัวใจ',
      'โรคไขมันในเลือดสูง',
      'โรคภูมิแพ้',
    ];
    
    // Initialize checklist if not already done
    if (_healthProblemsChecked == null) {
      _healthProblemsChecked = List.generate(problemsOptions.length, (index) => false);
      _otherProblemController = TextEditingController();
      _otherChecked = false;
    }
    
    // Load existing health problems
    List<String>? existingProblems;
    
    // Try to get from direct field first (FastAPI structure)
    if (currentUser['health_problems'] is String && currentUser['health_problems'].isNotEmpty) {
      // Split string by comma and clean up
      existingProblems = currentUser['health_problems'].split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    } else if (currentUser['health_problems'] is List) {
      existingProblems = currentUser['health_problems'].cast<String>();
    }
    // Try from preferences (alternative structure)
    else if (currentUser['preferences'] != null) {
      if (currentUser['preferences']['healthProblems'] is String && currentUser['preferences']['healthProblems'].isNotEmpty) {
        existingProblems = currentUser['preferences']['healthProblems'].split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      } else if (currentUser['preferences']['healthProblems'] is List) {
        existingProblems = currentUser['preferences']['healthProblems'].cast<String>();
      }
    }
    
    if (existingProblems != null && existingProblems.isNotEmpty) {
      for (String problem in existingProblems) {
        // Check if it's one of the predefined problems
        int index = problemsOptions.indexOf(problem);
        if (index != -1) {
          _healthProblemsChecked![index] = true;
        } else {
          // It's a custom problem
          _otherChecked = true;
          _otherProblemController?.text = problem;
        }
      }
    }
  }

  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _goalWeightController.dispose();
    _goalExerciseController.dispose();
    _goalWaterController.dispose();
    _goalExerciseMinutesController.dispose();
    _bpController.dispose();
    _hrController.dispose();
    _otherProblemController?.dispose();
    super.dispose();
  }

  Future<void> _saveRegistrationData() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final currentUser = await _apiService.getCurrentUser();
      print("DEBUG: Current user data: $currentUser"); // Debug line
      
      final List<String> problemsList = [];
      final List<String> problemsOptions = [
        'โรคเบาหวาน',
        'โรคความดันโลหิตสูง',
        'โรคหัวใจ',
        'โรคไขมันในเลือดสูง',
        'โรคภูมิแพ้',
      ];
      if (_healthProblemsChecked != null) {
        for (int i = 0; i < _healthProblemsChecked!.length; i++) {
          if (_healthProblemsChecked![i]) {
            problemsList.add(problemsOptions[i]);
          }
        }
      }
      if (_otherChecked && _otherProblemController!.text.isNotEmpty) {
        problemsList.add(_otherProblemController!.text.trim());
      }

      final String userId = currentUser['uid']?.toString() ?? currentUser['id']?.toString() ?? '';
      print("DEBUG: Using userId: $userId"); // Debug line
      print("DEBUG: Health problems list: $problemsList"); // Debug line

      // Update user profile (ข้อมูลพื้นฐานเท่านั้น - ไปที่ users table)
      final userProfileData = {
        'email': currentUser['email'],
        'age': int.tryParse(_ageController.text),
        'gender': _selectedGender?.toLowerCase(), // แปลงเป็น lowercase
        'weight': double.tryParse(_weightController.text),
        'height': double.tryParse(_heightController.text),
        'blood_pressure': _bpController.text.trim(),
        'heart_rate': int.tryParse(_hrController.text),
        'health_problems': problemsList, // ส่งเป็น array สำหรับ PostgreSQL
        'profile_completed': true,
      };
      
      print("DEBUG: User profile data to send: $userProfileData"); // Debug line

      // Update user goals (ข้อมูลเป้าหมาย - ไปที่ user_goals table แยกต่างหาก)
      final userGoalsData = {
        'goal_weight': double.tryParse(_goalWeightController.text),
        'goal_exercise_frequency': int.tryParse(_goalExerciseController.text),
        'goal_exercise_minutes': int.tryParse(_goalExerciseMinutesController.text),
        'goal_water_intake': int.tryParse(_goalWaterController.text),
      };
      
      print("DEBUG: User goals data to send: $userGoalsData"); // Debug line

      // Update health info
      final healthInfoData = {
        'healthProblems': problemsList,
        'bloodPressure': _bpController.text.trim(),
        'heartRate': int.tryParse(_hrController.text),
      };
      
      print("DEBUG: Health info data to send: $healthInfoData"); // Debug line

      // ส่งข้อมูลไป 3 ที่แยกกัน:
      // 1. อัปเดตข้อมูลพื้นฐานใน users table
      try {
        await _apiService.updateUserProfile(
          userId: userId,
          profileData: userProfileData,
        );
        print("DEBUG: User profile updated successfully");
      } catch (e) {
        print("DEBUG: Failed to update user profile: $e");
        throw e; // Re-throw เพื่อให้ทำงานต่อไปยัง catch block ด้านนอก
      }
      
      // 2. อัปเดตข้อมูลเป้าหมายใน user_goals table
      try {
        await _apiService.createUserGoals(
          userId: userId,
          goals: userGoalsData,
        );
        print("DEBUG: User goals created successfully");
      } catch (e) {
        // ถ้า create ไม่ได้ อาจเป็นเพราะมีอยู่แล้ว ลอง update
        print("DEBUG: Goals create failed, trying update: $e");
        try {
          await _apiService.updateUserGoals(
            userId: userId,
            goals: userGoalsData,
          );
          print("DEBUG: User goals updated successfully");
        } catch (updateError) {
          print("DEBUG: Failed to update user goals: $updateError");
          // ไม่ throw error เพราะไม่ใช่ข้อมูลสำคัญมาก
        }
      }
      
      // 3. อัปเดตข้อมูลสุขภาพใน user_preferences table
      try {
        await _apiService.createUserPreferences(
          userId: userId,
          healthInfo: healthInfoData,
        );
        print("DEBUG: User preferences created successfully");
      } catch (e) {
        // ถ้า create ไม่ได้ อาจเป็นเพราะมีอยู่แล้ว ลอง update
        print("DEBUG: Preferences create failed, trying update: $e");
        try {
          await _apiService.updateUserPreferences(
            userId: userId,
            healthInfo: healthInfoData,
          );
          print("DEBUG: User preferences updated successfully");
        } catch (updateError) {
          print("DEBUG: Failed to update user preferences: $updateError");
          // ไม่ throw error เพราะไม่ใช่ข้อมูลสำคัญมาก
        }
      }

      if (mounted) Navigator.of(context).pop();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.check_circle, color: Colors.green, size: 60),
              SizedBox(height: 18),
              Text(
                'อัปเดตข้อมูลสำเร็จ',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.of(context).pop(); // ปิด dialog สำเร็จ
                  Navigator.of(context).pop(true); // กลับไปหน้าก่อนหน้าพร้อมส่งค่า true เพื่อ refresh
                },
                child: const Text('ตกลง'),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาดในการอัปเดต: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('แก้ไขข้อมูลส่วนตัว'),
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 60,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop(true); // ส่งค่า true เพื่อ refresh dashboard
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 20.0,
                horizontal: 16.0,
              ),
              child: _buildStepProgressBar(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: _buildStepContent(),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(51, 158, 158, 158),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  if (_stepErrorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _stepErrorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (_currentStepIndex == 0) {
                              // ถ้าอยู่ stage 1 (index 0) ให้กลับไปหน้าก่อนหน้า
                              Navigator.of(context).pop(true); // ส่งค่า true เพื่อ refresh
                            } else if (_currentStepIndex > 0) {
                              setState(() {
                                _stepErrorMessage = null;
                                _currentStepIndex--;
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'ย้อนกลับ',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            bool valid = false;
                            setState(() {
                              _stepErrorMessage = null;
                            });
                            switch (_currentStepIndex) {
                              case 0:
                                valid = _validateStep1();
                                break;
                              case 1:
                                valid = _validateStep2();
                                break;
                              case 2:
                                valid = _validateStep3();
                                break;
                            }
                            if (!valid) return;
                            if (_currentStepIndex < _totalSteps - 1) {
                              setState(() {
                                _currentStepIndex++;
                              });
                            } else {
                              _saveRegistrationData();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _currentStepIndex < _totalSteps - 1
                                ? Colors.green
                                : Colors.blue,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            _currentStepIndex < _totalSteps - 1
                                ? 'ถัดไป'
                                : 'อัปเดตข้อมูล',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
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

  Widget _buildStepProgressBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_totalSteps * 2 - 1, (index) {
        if (index.isEven) {
          int step = index ~/ 2;
          bool isActiveStep = step <= _currentStepIndex;
          return Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActiveStep ? Colors.green : Colors.white,
                  border: Border.all(
                    color: isActiveStep ? Colors.green : Colors.grey[400]!,
                    width: 2,
                  ),
                  boxShadow: isActiveStep
                      ? [
                          BoxShadow(
                            color: const Color.fromARGB(51, 76, 175, 80),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActiveStep ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _getStepLabel(step),
                style: TextStyle(
                  color: isActiveStep ? Colors.green : Colors.black54,
                  fontSize: 13,
                  fontWeight: isActiveStep
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ],
          );
        } else {
          int leftStep = (index - 1) ~/ 2;
          bool isLineActive = (leftStep + 1) <= _currentStepIndex;
          return Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              color: isLineActive ? Colors.green : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }
      }),
    );
  }

  String _getStepLabel(int index) {
    switch (index) {
      case 0:
        return 'ข้อมูลพื้นฐาน';
      case 1:
        return 'เป้าหมาย';
      case 2:
        return 'ประเมินสุขภาพ';
      default:
        return '';
    }
  }

  Widget _buildStepContent() {
    switch (_currentStepIndex) {
      case 0:
        return Form(
          key: _formKeys[0],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'กรอกข้อมูลพื้นฐาน',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 22,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(
                        'อายุ (ปี)',
                        _ageController,
                        TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'กรุณากรอกอายุ';
                          if (int.tryParse(v) == null || int.parse(v) <= 0)
                            return 'อายุไม่ถูกต้อง';
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          'เพศ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _genderSelectButton('male', Icons.male),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _genderSelectButton('female', Icons.female),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _genderSelectButton(
                              'other',
                              Icons.transgender,
                            ),
                          ),
                        ],
                      ),
                      if (_stepErrorMessage != null && _selectedGender == null)
                        const Padding(
                          padding: EdgeInsets.only(top: 4, left: 8),
                          child: Text(
                            'กรุณาเลือกเพศ',
                            style: TextStyle(color: Colors.red, fontSize: 13),
                          ),
                        ),
                      const SizedBox(height: 15),
                      _buildTextField(
                        'น้ำหนัก (กิโลกรัม)',
                        _weightController,
                        TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'กรุณากรอกน้ำหนัก';
                          if (double.tryParse(v) == null ||
                              double.parse(v) <= 0)
                            return 'น้ำหนักไม่ถูกต้อง';
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      _buildTextField(
                        'ส่วนสูง (เซนติเมตร)',
                        _heightController,
                        TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'กรุณากรอกส่วนสูง';
                          if (double.tryParse(v) == null ||
                              double.parse(v) <= 0)
                            return 'ส่วนสูงไม่ถูกต้อง';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      case 1:
        return Form(
          key: _formKeys[1],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'กรอกเป้าหมายของคุณ',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 18),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 22,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.monitor_weight, color: Colors.green),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildTextField(
                              'เป้าหมายน้ำหนัก (กิโลกรัม)',
                              _goalWeightController,
                              TextInputType.number,
                              validator: (v) {
                                if (v == null || v.isEmpty)
                                  return 'กรุณากรอกเป้าหมายน้ำหนัก';
                                if (double.tryParse(v) == null ||
                                    double.parse(v) <= 0)
                                  return 'น้ำหนักไม่ถูกต้อง';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          const Icon(Icons.fitness_center, color: Colors.green),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildTextField(
                              'การออกกำลังกาย (ครั้ง/สัปดาห์)',
                              _goalExerciseController,
                              TextInputType.number,
                              validator: (v) {
                                if (v == null || v.isEmpty)
                                  return 'กรุณากรอกจำนวนครั้ง';
                                if (int.tryParse(v) == null ||
                                    int.parse(v) <= 0)
                                  return 'จำนวนครั้งไม่ถูกต้อง';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          const Icon(Icons.timer, color: Colors.green),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                int initial =
                                    int.tryParse(
                                      _goalExerciseMinutesController.text,
                                    ) ??
                                    30;
                                final selected =
                                    await _showCupertinoMinutesPicker(initial);
                                if (selected != null) {
                                  setState(() {
                                    _goalExerciseMinutesController.text =
                                        selected.toString();
                                  });
                                }
                              },
                              child: AbsorbPointer(
                                child: _buildTextField(
                                  'การออกกำลังกาย (นาที/วัน)',
                                  _goalExerciseMinutesController,
                                  TextInputType.number,
                                  validator: (v) {
                                    if (v == null || v.isEmpty)
                                      return 'กรุณากรอกนาที';
                                    if (int.tryParse(v) == null ||
                                        int.parse(v) <= 0)
                                      return 'นาทีไม่ถูกต้อง';
                                    return null;
                                  },
                                  enabled: false,
                                  hintText:
                                      _goalExerciseMinutesController
                                          .text
                                          .isNotEmpty
                                      ? null
                                      : 'แตะเพื่อเลือก',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.local_drink, color: Colors.green),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final selected = await _showWaterCupPicker();
                                if (selected != null) {
                                  setState(() {
                                    _goalWaterController.text = selected
                                        .toString();
                                  });
                                }
                              },
                              child: AbsorbPointer(
                                child: _buildTextField(
                                  'เป้าหมายการดื่มน้ำ (แก้ว/วัน)',
                                  _goalWaterController,
                                  TextInputType.number,
                                  validator: (v) {
                                    if (v == null || v.isEmpty)
                                      return 'กรุณากรอกจำนวนแก้ว';
                                    if (int.tryParse(v) == null ||
                                        int.parse(v) <= 0)
                                      return 'จำนวนแก้วไม่ถูกต้อง';
                                    return null;
                                  },
                                  enabled: false,
                                  hintText: _goalWaterController.text.isNotEmpty
                                      ? null
                                      : 'แตะเพื่อเลือก',
                                ),
                              ),
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
        );
      case 2:
        return Form(
          key: _formKeys[2],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'ประเมินสุขภาพเบื้องต้น',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 18),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 22,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.bloodtype, color: Colors.green),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildTextField(
                              'ความดันโลหิต (mmHg)',
                              _bpController,
                              TextInputType.text,
                              validator: (v) {
                                if (v == null || v.isEmpty)
                                  return 'กรุณากรอกความดันโลหิต';
                                final regex = RegExp(r'^\d{2,3}/\d{2,3}$');
                                if (!regex.hasMatch(v))
                                  return 'กรุณากรอกในรูปแบบ 120/80';
                                return null;
                              },
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9/]'),
                                ),
                                LengthLimitingTextInputFormatter(7),
                              ],
                              hintText: 'เช่น 120/80',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          const Icon(Icons.favorite, color: Colors.green),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildTextField(
                              'อัตราการเต้นหัวใจ (bpm)',
                              _hrController,
                              TextInputType.number,
                              validator: (v) {
                                if (v == null || v.isEmpty)
                                  return 'กรุณากรอกอัตราการเต้นหัวใจ';
                                if (int.tryParse(v) == null ||
                                    int.parse(v) <= 0)
                                  return 'ค่าต้องเป็นตัวเลข';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'ปัญหาสุขภาพที่พบ (เลือกได้มากกว่า 1 ข้อ)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildHealthProblemsChecklist(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  bool _validateStep1() {
    final form = _formKeys[0].currentState;
    bool valid = form?.validate() ?? false;
    if (!valid) {
      setState(() {
        _stepErrorMessage = 'กรุณากรอกข้อมูลให้ครบถ้วน';
      });
      return false;
    }
    if (_selectedGender == null) {
      setState(() {
        _stepErrorMessage = 'กรุณาเลือกเพศ';
      });
      return false;
    }
    return true;
  }

  bool _validateStep2() {
    final form = _formKeys[1].currentState;
    bool valid = form?.validate() ?? false;
    if (!valid) {
      setState(() {
        _stepErrorMessage = 'กรุณากรอกข้อมูลเป้าหมายให้ครบถ้วน';
      });
      return false;
    }
    return true;
  }

  bool _validateStep3() {
    final form = _formKeys[2].currentState;
    bool valid = form?.validate() ?? false;
    if (!valid) {
      setState(() {
        _stepErrorMessage = 'กรุณากรอกข้อมูลสุขภาพให้ครบถ้วน';
      });
      return false;
    }
    return true;
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    TextInputType keyboardType, {
    String? Function(String?)? validator,
    bool enabled = true,
    List<TextInputFormatter>? inputFormatters,
    String? hintText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: enabled,
      validator: validator,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 15,
          horizontal: 15,
        ),
      ),
    );
  }

  Widget _genderSelectButton(String gender, IconData icon) {
    final bool isSelected = _selectedGender == gender;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = gender;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green[100] : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.08),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.green : Colors.grey[600],
              size: 32,
            ),
            const SizedBox(height: 4),
            Text(
              gender == 'male'
                  ? 'ชาย'
                  : gender == 'female'
                  ? 'หญิง'
                  : 'อื่นๆ',
              style: TextStyle(
                color: isSelected ? Colors.green[900] : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthProblemsChecklist() {
    final List<String> problems = [
      'โรคเบาหวาน',
      'โรคความดันโลหิตสูง',
      'โรคหัวใจ',
      'โรคไขมันในเลือดสูง',
      'โรคภูมิแพ้',
    ];
    if (_healthProblemsChecked == null) {
      _healthProblemsChecked = List.generate(problems.length, (index) => false);
      _otherProblemController = TextEditingController();
      _otherChecked = false;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 0,
          children: List.generate(problems.length, (index) {
            return FilterChip(
              label: Text(problems[index]),
              selected: _healthProblemsChecked![index],
              selectedColor: Colors.green[200],
              checkmarkColor: Colors.green[900],
              onSelected: (val) {
                setState(() {
                  _healthProblemsChecked![index] = val;
                });
              },
            );
          }),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Checkbox(
              value: _otherChecked,
              onChanged: (val) {
                setState(() {
                  _otherChecked = val ?? false;
                  if (!_otherChecked) _otherProblemController?.clear();
                });
              },
            ),
            const Text('อื่น ๆ'),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _otherProblemController,
                enabled: _otherChecked,
                decoration: InputDecoration(
                  hintText: 'โปรดระบุ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<int?> _showCupertinoMinutesPicker(int initialValue) {
    int tempValue = initialValue;
    return showDialog<int>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 200,
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(
                    initialItem: (initialValue ~/ 5).clamp(0, 59) - 1,
                  ),
                  itemExtent: 36,
                  magnification: 1.1,
                  onSelectedItemChanged: (index) {
                    tempValue = (index + 1) * 5;
                  },
                  children: List.generate(
                    60,
                    (index) => Center(child: Text('${(index + 1) * 5} นาที')),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(tempValue),
                  child: const Text("ตกลง"), // "Confirm"
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<int?> _showWaterCupPicker() {
    return showDialog<int>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'เลือกจำนวนแก้วน้ำ',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: List.generate(12, (i) {
                    final cupNum = i + 1;
                    return GestureDetector(
                      onTap: () => Navigator.of(context).pop(cupNum),
                      child: CircleAvatar(radius: 24, child: Text('$cupNum')),
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
