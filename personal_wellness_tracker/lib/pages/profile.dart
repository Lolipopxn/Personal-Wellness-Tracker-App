import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../์NavigationBar/main_scaffold.dart';

class Profile extends StatelessWidget {
  final bool isFromLogin;
  
  const Profile({super.key, this.isFromLogin = false});

  @override
  Widget build(BuildContext context) {
    return RegistrationScreen(isFromLogin: isFromLogin);
  }
}

class RegistrationScreen extends StatefulWidget {
  final bool isFromLogin;
  
  const RegistrationScreen({super.key, this.isFromLogin = false});

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
  final int _totalSteps = 4;
  List<bool>? _healthProblemsChecked;
  bool _otherChecked = false;
  String? _stepErrorMessage;

  final List<GlobalKey<FormState>> _formKeys = [
    GlobalKey<FormState>(),
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
      
      // โหลดข้อมูลเป้าหมายแยกต่างหาก
      Map<String, dynamic>? userGoals;
      Map<String, dynamic>? userPreferences;
      
      final String userId = currentUser['uid']?.toString() ?? currentUser['id']?.toString() ?? '';
      
      if (userId.isNotEmpty) {
        try {
          // ดึงข้อมูลเป้าหมายจาก user_goals table
          userGoals = await _apiService.getUserGoals(userId);
          print("DEBUG: Loading user goals: $userGoals");
        } catch (e) {
          print("DEBUG: Error loading user goals: $e");
        }
        
        try {
          // ดึงข้อมูล preferences จาก user_preferences table
          userPreferences = await _apiService.getUserPreferences(userId);
          print("DEBUG: Loading user preferences: $userPreferences");
        } catch (e) {
          print("DEBUG: Error loading user preferences: $e");
        }
      }
      
      if (mounted) {
        setState(() {
          // โหลดข้อมูลพื้นฐานจาก users table
          _ageController.text = currentUser['age']?.toString() ?? '';
          _selectedGender = currentUser['gender'];
          _weightController.text = currentUser['weight']?.toString() ?? '';
          _heightController.text = currentUser['height']?.toString() ?? '';
          
          // โหลดข้อมูลสุขภาพจาก users table (FastAPI structure)
          if (currentUser['blood_pressure'] != null) {
            _bpController.text = currentUser['blood_pressure'].toString();
          }
          if (currentUser['heart_rate'] != null) {
            _hrController.text = currentUser['heart_rate'].toString();
          }
          
          // โหลดข้อมูลเป้าหมายจาก user_goals table
          if (userGoals != null) {
            _goalWeightController.text = userGoals['goal_weight']?.toString() ?? '';
            _goalExerciseController.text = userGoals['goal_exercise_frequency']?.toString() ?? '';
            _goalExerciseMinutesController.text = userGoals['goal_exercise_minutes']?.toString() ?? '';
            _goalWaterController.text = userGoals['goal_water_intake']?.toString() ?? '';
            print("DEBUG: Loaded goals from user_goals table - Weight: ${_goalWeightController.text}, Exercise: ${_goalExerciseController.text}, Minutes: ${_goalExerciseMinutesController.text}, Water: ${_goalWaterController.text}");
          } 
          // Fallback: ถ้าไม่มีข้อมูลจาก user_goals table ให้ลองดึงจาก embedded goals ใน currentUser
          else if (currentUser['goals'] != null) {
            final goals = currentUser['goals'];
            _goalWeightController.text = goals['goal_weight']?.toString() ?? goals['weight']?.toString() ?? '';
            _goalExerciseController.text = goals['goal_exercise_frequency']?.toString() ?? goals['exerciseFrequency']?.toString() ?? '';
            _goalExerciseMinutesController.text = goals['goal_exercise_minutes']?.toString() ?? goals['exerciseMinutes']?.toString() ?? '';
            _goalWaterController.text = goals['goal_water_intake']?.toString() ?? goals['waterIntake']?.toString() ?? '';
            print("DEBUG: Loaded goals from embedded goals - Weight: ${_goalWeightController.text}, Exercise: ${_goalExerciseController.text}, Minutes: ${_goalExerciseMinutesController.text}, Water: ${_goalWaterController.text}");
          } else {
            print("DEBUG: No user goals found from any source");
          }
          
          // โหลดข้อมูลสุขภาพจาก user_preferences table (สำหรับข้อมูลเพิ่มเติม)
          if (userPreferences != null) {
            // ถ้า preferences มีข้อมูลสุขภาพที่ละเอียดกว่า ให้ใช้จาก preferences
            if (userPreferences['bloodPressure'] != null && userPreferences['bloodPressure'].toString().isNotEmpty) {
              _bpController.text = userPreferences['bloodPressure'].toString();
            }
            if (userPreferences['heartRate'] != null) {
              _hrController.text = userPreferences['heartRate'].toString();
            }
          }
          
          // โหลดปัญหาสุขภาพ
          _loadHealthProblems(currentUser, userPreferences);
        });
      }
    } catch (e) {
      print("Error loading user data: $e");
    }
  }

  void _loadHealthProblems(Map<String, dynamic> currentUser, [Map<String, dynamic>? userPreferences]) {
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
    // Try from userPreferences parameter (จาก user_preferences table)
    else if (userPreferences != null) {
      if (userPreferences['healthProblems'] is String && userPreferences['healthProblems'].isNotEmpty) {
        existingProblems = userPreferences['healthProblems'].split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      } else if (userPreferences['healthProblems'] is List) {
        existingProblems = userPreferences['healthProblems'].cast<String>();
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
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          elevation: 8,
          content: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success animation container
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF79D7BE).withOpacity(0.1),
                    border: Border.all(
                      color: Color(0xFF79D7BE),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Color(0xFF79D7BE),
                    size: 50,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Title text
                Text(
                  widget.isFromLogin ? 'ตั้งค่าข้อมูลเสร็จสิ้น!' : 'อัปเดตข้อมูลสำเร็จ!',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E5077),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                
                // Subtitle text
                Text(
                  widget.isFromLogin 
                    ? 'ยินดีต้อนรับสู่แอปติดตามสุขภาพ\nเริ่มต้นการใช้งานได้เลย!'
                    : 'ข้อมูลของคุณได้รับการอัปเดต\nเรียบร้อยแล้ว',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10, left: 20, right: 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF79D7BE),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    shadowColor: Color(0xFF79D7BE).withOpacity(0.3),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(); // ปิด dialog สำเร็จ
                    
                    // ถ้ามาจากการ login ให้ไปหน้าหลัก ถ้าไม่ใช่ให้กลับไปหน้าเดิม
                    if (widget.isFromLogin) {
                      // นำทางไปหน้าหลักของแอป เมื่อกรอกข้อมูลครบถ้วนแล้ว
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const MainScaffold()),
                        (route) => false,
                      );
                    } else {
                      // กลับไปหน้าก่อนหน้าพร้อมส่งค่า true เพื่อ refresh
                      Navigator.of(context).pop(true);
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        widget.isFromLogin ? 'เริ่มใช้งาน' : 'ตกลง',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
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
        title: Text(widget.isFromLogin ? 'ตั้งค่าข้อมูลส่วนตัว' : 'แก้ไขข้อมูลส่วนตัว'),
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 60,
        leading: widget.isFromLogin 
          ? null // ซ่อนปุ่มกลับถ้ามาจากการ login
          : IconButton(
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
                              case 3:
                                valid = _validateStep4();
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
                                ? Color(0xFF79D7BE)
                                : Color(0xFF4DA1A9),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(_totalSteps * 2 - 1, (index) {
          if (index.isEven) {
            int step = index ~/ 2;
            bool isActiveStep = step <= _currentStepIndex;
            return Expanded(
              child: Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isActiveStep 
                        ? LinearGradient(
                            colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                      color: isActiveStep ? null : Colors.white,
                      border: Border.all(
                        color: isActiveStep ? Color(0xFF2E7D32) : Colors.grey[400]!,
                        width: 2,
                      ),
                      boxShadow: isActiveStep ? [
                        BoxShadow(
                          color: Color(0xFF4CAF50).withOpacity(0.3),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ] : null,
                    ),
                    child: Center(
                      child: Text(
                        '${step + 1}',
                        style: TextStyle(
                          color: isActiveStep ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getStepLabel(step),
                    style: TextStyle(
                      color: isActiveStep ? Color(0xFF2E7D32) : Colors.black54,
                      fontSize: 11,
                      fontWeight: isActiveStep
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          } else {
            int leftStep = (index - 1) ~/ 2;
            bool isLineActive = (leftStep + 1) <= _currentStepIndex;
            return Expanded(
              flex: 1,
              child: Container(
                height: 3,
                margin: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
                decoration: BoxDecoration(
                  gradient: isLineActive 
                    ? LinearGradient(
                        colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      )
                    : null,
                  color: isLineActive ? null : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: isLineActive ? [
                    BoxShadow(
                      color: Color(0xFF4CAF50).withOpacity(0.2),
                      spreadRadius: 0,
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ] : null,
                ),
              ),
            );
          }
        }),
      ),
    );
  }

  String _getStepLabel(int index) {
    switch (index) {
      case 0:
        return 'ข้อมูล\nพื้นฐาน';
      case 1:
        return 'เป้า\nหมาย';
      case 2:
        return 'ประเมิน\nสุขภาพ';
      case 3:
        return 'สรุป\nข้อมูล';
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
                  color: Color(0xFF2E5077),
                ),
              ),
              const SizedBox(height: 20),
              
              Card(
                elevation: 2,
                color: Color(0xFFF6F4F0),
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
                  color: Color(0xFF2E5077),
                ),
              ),
              const SizedBox(height: 18),
              Card(
                elevation: 2,
                color: Color(0xFFF6F4F0),
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
                          const Icon(Icons.monitor_weight, color: Color(0xFF2E5077)),
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
                          const Icon(Icons.fitness_center, color: Color(0xFF2E5077)),
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
                          const Icon(Icons.timer, color: Color(0xFF2E5077)),
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
                        children: [
                          const Icon(Icons.local_drink, color: Color(0xFF2E5077)),
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
                  color: Color(0xFF2E5077),
                ),
              ),
              const SizedBox(height: 18),
              Card(
                elevation: 2,
                color: Color(0xFFF6F4F0),
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
                          const Icon(Icons.bloodtype, color: Color(0xFF2E5077)),
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
                          const Icon(Icons.favorite, color: Color(0xFF2E5077)),
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
      case 3:
        return Form(
          key: _formKeys[3],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'สรุปข้อมูลทั้งหมด',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E5077),
                ),
              ),
              const SizedBox(height: 20),
              
              // Card สรุปข้อมูลพื้นฐาน
              if (_ageController.text.isNotEmpty || 
                  _selectedGender != null || 
                  _weightController.text.isNotEmpty || 
                  _heightController.text.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF79D7BE).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xFF79D7BE).withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Color(0xFF2E5077), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'ข้อมูลพื้นฐาน',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Color(0xFF2E5077),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_ageController.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Icon(Icons.cake, size: 16, color: Color(0xFF4DA1A9)),
                              const SizedBox(width: 8),
                              Text('อายุ: ', style: TextStyle(
                                color: Color(0xFF2E5077),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              )),
                              Text('${_ageController.text} ปี', 
                                   style: const TextStyle(
                                     fontWeight: FontWeight.w700,
                                     fontSize: 15,
                                     color: Color(0xFF2E5077),
                                   )),
                            ],
                          ),
                        ),
                      if (_selectedGender != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Icon(_selectedGender == 'male' ? Icons.male : 
                                   _selectedGender == 'female' ? Icons.female : Icons.transgender, 
                                   size: 16, color: Color(0xFF4DA1A9)),
                              const SizedBox(width: 8),
                              Text('เพศ: ', style: TextStyle(
                                color: Color(0xFF2E5077),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              )),
                              Text(_selectedGender == 'male' ? 'ชาย' : 
                                   _selectedGender == 'female' ? 'หญิง' : 'อื่นๆ', 
                                   style: const TextStyle(
                                     fontWeight: FontWeight.w700,
                                     fontSize: 15,
                                     color: Color(0xFF2E5077),
                                   )),
                            ],
                          ),
                        ),
                      if (_weightController.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Icon(Icons.monitor_weight, size: 16, color: Color(0xFF4DA1A9)),
                              const SizedBox(width: 8),
                              Text('น้ำหนัก: ', style: TextStyle(
                                color: Color(0xFF2E5077),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              )),
                              Text('${_weightController.text} กก.', 
                                   style: const TextStyle(
                                     fontWeight: FontWeight.w700,
                                     fontSize: 15,
                                     color: Color(0xFF2E5077),
                                   )),
                            ],
                          ),
                        ),
                      if (_heightController.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Icon(Icons.height, size: 16, color: Color(0xFF4DA1A9)),
                              const SizedBox(width: 8),
                              Text('ส่วนสูง: ', style: TextStyle(
                                color: Color(0xFF2E5077),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              )),
                              Text('${_heightController.text} ซม.', 
                                   style: const TextStyle(
                                     fontWeight: FontWeight.w700,
                                     fontSize: 15,
                                     color: Color(0xFF2E5077),
                                   )),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              
              // Card สรุปเป้าหมาย
              if (_goalWeightController.text.isNotEmpty || 
                  _goalExerciseController.text.isNotEmpty || 
                  _goalExerciseMinutesController.text.isNotEmpty || 
                  _goalWaterController.text.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF79D7BE).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xFF79D7BE).withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.flag_outlined, color: Color(0xFF2E5077), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'เป้าหมายที่ตั้งไว้',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Color(0xFF2E5077),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_goalWeightController.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(Icons.monitor_weight, size: 16, color: Color(0xFF4DA1A9)),
                              const SizedBox(width: 8),
                              Text('น้ำหนักเป้าหมาย: ', style: TextStyle(
                                color: Color(0xFF2E5077),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              )),
                              Text('${_goalWeightController.text} กก.', 
                                   style: const TextStyle(
                                     fontWeight: FontWeight.w700,
                                     fontSize: 15,
                                     color: Color(0xFF2E5077),
                                   )),
                            ],
                          ),
                        ),
                      if (_goalExerciseController.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(Icons.fitness_center, size: 16, color: Color(0xFF4DA1A9)),
                              const SizedBox(width: 8),
                              Text('ออกกำลังกาย: ', style: TextStyle(
                                color: Color(0xFF2E5077),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              )),
                              Text('${_goalExerciseController.text} ครั้ง/สัปดาห์', 
                                   style: const TextStyle(
                                     fontWeight: FontWeight.w700,
                                     fontSize: 15,
                                     color: Color(0xFF2E5077),
                                   )),
                            ],
                          ),
                        ),
                      if (_goalExerciseMinutesController.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(Icons.timer, size: 16, color: Color(0xFF4DA1A9)),
                              const SizedBox(width: 8),
                              Text('ระยะเวลา: ', style: TextStyle(
                                color: Color(0xFF2E5077),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              )),
                              Text('${_goalExerciseMinutesController.text} นาที/วัน', 
                                   style: const TextStyle(
                                     fontWeight: FontWeight.w700,
                                     fontSize: 15,
                                     color: Color(0xFF2E5077),
                                   )),
                            ],
                          ),
                        ),
                      if (_goalWaterController.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 0),
                          child: Row(
                            children: [
                              Icon(Icons.local_drink, size: 16, color: Color(0xFF4DA1A9)),
                              const SizedBox(width: 8),
                              Text('ดื่มน้ำ: ', style: TextStyle(
                                color: Color(0xFF2E5077),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              )),
                              Text('${_goalWaterController.text} แก้ว/วัน', 
                                   style: const TextStyle(
                                     fontWeight: FontWeight.w700,
                                     fontSize: 15,
                                     color: Color(0xFF2E5077),
                                   )),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              
              // Card สรุปข้อมูลสุขภาพ
              if (_bpController.text.isNotEmpty || 
                  _hrController.text.isNotEmpty || 
                  (_healthProblemsChecked != null && _healthProblemsChecked!.any((checked) => checked)) ||
                  _otherChecked)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF79D7BE).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xFF79D7BE).withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.health_and_safety, color: Color(0xFF2E5077), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'ข้อมูลสุขภาพที่บันทึกไว้',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Color(0xFF2E5077),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_bpController.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(Icons.bloodtype, size: 16, color: Color(0xFF4DA1A9)),
                              const SizedBox(width: 8),
                              Text('ความดันโลหิต: ', style: TextStyle(
                                color: Color(0xFF2E5077),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              )),
                              Text('${_bpController.text} mmHg', 
                                   style: const TextStyle(
                                     fontWeight: FontWeight.w700,
                                     fontSize: 15,
                                     color: Color(0xFF2E5077),
                                   )),
                            ],
                          ),
                        ),
                      if (_hrController.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(Icons.favorite, size: 16, color: Color(0xFF4DA1A9)),
                              const SizedBox(width: 8),
                              Text('อัตราการเต้นหัวใจ: ', style: TextStyle(
                                color: Color(0xFF2E5077),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              )),
                              Text('${_hrController.text} ครั้ง/นาที', 
                                   style: const TextStyle(
                                     fontWeight: FontWeight.w700,
                                     fontSize: 15,
                                     color: Color(0xFF2E5077),
                                   )),
                            ],
                          ),
                        ),
                      if (_healthProblemsChecked != null && _healthProblemsChecked!.any((checked) => checked))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.local_hospital, size: 16, color: Color(0xFF4DA1A9)),
                                  const SizedBox(width: 8),
                                  Text('ปัญหาสุขภาพ: ', style: TextStyle(
                                    color: Color(0xFF2E5077),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  )),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  if (_healthProblemsChecked![0]) 
                                    Chip(
                                      label: Text('โรคเบาหวาน', 
                                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                                      backgroundColor: Color(0xFF4DA1A9),
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  if (_healthProblemsChecked![1]) 
                                    Chip(
                                      label: Text('โรคความดันโลหิตสูง', 
                                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                                      backgroundColor: Color(0xFF4DA1A9),
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  if (_healthProblemsChecked![2]) 
                                    Chip(
                                      label: Text('โรคหัวใจ', 
                                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                                      backgroundColor: Color(0xFF4DA1A9),
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  if (_healthProblemsChecked![3]) 
                                    Chip(
                                      label: Text('โรคไขมันในเลือดสูง', 
                                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                                      backgroundColor: Color(0xFF4DA1A9),
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  if (_healthProblemsChecked![4]) 
                                    Chip(
                                      label: Text('โรคภูมิแพ้', 
                                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                                      backgroundColor: Color(0xFF4DA1A9),
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  if (_otherChecked && _otherProblemController!.text.isNotEmpty)
                                    Chip(
                                      label: Text(_otherProblemController!.text, 
                                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                                      backgroundColor: Color(0xFF4DA1A9),
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              
              // ข้อความยืนยันการกรอกข้อมูล
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF79D7BE).withOpacity(0.1),
                      Color(0xFF4DA1A9).withOpacity(0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Color(0xFF79D7BE).withOpacity(0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF79D7BE).withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF79D7BE).withOpacity(0.2),
                        border: Border.all(
                          color: Color(0xFF79D7BE),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.fact_check_rounded, 
                        color: Color(0xFF2E5077), 
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ยืนยันข้อมูลที่กรอก',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Color(0xFF2E5077),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'กรุณาตรวจสอบข้อมูลทั้งหมดด้านบนให้ถูกต้อง\nหากต้องการแก้ไขสามารถกลับไปแก้ไขได้',
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF2E5077).withOpacity(0.8),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Color(0xFF79D7BE).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Color(0xFF2E5077),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'ข้อมูลจะถูกบันทึกอย่างปลอดภัย',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF2E5077),
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

  bool _validateStep4() {
    // Stage สรุปข้อมูลไม่ต้อง validate อะไร
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
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: enabled ? Colors.black87 : Colors.grey[600],
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        labelStyle: TextStyle(
          fontSize: 14,
          color: Colors.grey[700],
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(
          fontSize: 14,
          color: Colors.grey[400],
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF79D7BE), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        filled: true,
        fillColor: enabled ? Color(0xFFF6F4F0) : Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        suffixIcon: controller.text.isNotEmpty
            ? Icon(
                Icons.check_circle,
                color: Color(0xFF79D7BE),
                size: 20,
              )
            : null,
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
          color: isSelected ? Color(0xFF79D7BE).withOpacity(0.2) : Colors.white,
          border: Border.all(
            color: isSelected ? Color(0xFF79D7BE) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Color(0xFF79D7BE).withOpacity(0.08),
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
              color: isSelected ? Color(0xFF2E5077) : Colors.grey[600],
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
                color: isSelected ? Color(0xFF2E5077) : Colors.grey[700],
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
              selectedColor: Color(0xFF79D7BE).withOpacity(0.3),
              checkmarkColor: Color(0xFF2E5077),
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

  // ฟังก์ชันสำหรับ picker เลือกนาทีออกกำลังกาย
  Future<int?> _showCupertinoMinutesPicker(int initialValue) async {
    int selectedMinutes = initialValue;
    return showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: 300,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ยกเลิก'),
                ),
                const Text(
                  'เลือกระยะเวลาออกกำลังกาย',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, selectedMinutes),
                  child: const Text('เลือก'),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: 12, // 15, 30, 45, 60, 75, 90, 105, 120, 135, 150, 165, 180
                itemBuilder: (context, index) {
                  final minutes = (index + 1) * 15;
                  return ListTile(
                    title: Text('$minutes นาที'),
                    trailing: selectedMinutes == minutes 
                        ? const Icon(Icons.check, color: Color(0xFF2E5077)) 
                        : null,
                    onTap: () {
                      selectedMinutes = minutes;
                      Navigator.pop(context, selectedMinutes);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ฟังก์ชันสำหรับ picker เลือกจำนวนแก้วน้ำ
  Future<int?> _showWaterCupPicker() async {
    int selectedCups = int.tryParse(_goalWaterController.text) ?? 8;
    return showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: 300,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ยกเลิก'),
                ),
                const Text(
                  'เลือกจำนวนแก้วน้ำต่อวัน',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, selectedCups),
                  child: const Text('เลือก'),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: 15, // 1-15 แก้ว
                itemBuilder: (context, index) {
                  final cups = index + 1;
                  return ListTile(
                    leading: Icon(Icons.local_drink, color: Color(0xFF4DA1A9)),
                    title: Text('$cups แก้ว'),
                    subtitle: Text('≈ ${(cups * 250).toStringAsFixed(0)} มล.'),
                    trailing: selectedCups == cups 
                        ? const Icon(Icons.check, color: Color(0xFF2E5077)) 
                        : null,
                    onTap: () {
                      selectedCups = cups;
                      Navigator.pop(context, selectedCups);
                    },
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
