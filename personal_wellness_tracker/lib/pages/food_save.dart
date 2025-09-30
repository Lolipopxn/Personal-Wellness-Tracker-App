import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import '../services/nutrition_service.dart';
import '../services/api_service.dart';
import '../widgets/nutrition_chart.dart';
import '../services/achievement_service.dart'; // <-- เพิ่ม import

class FoodSavePage extends StatefulWidget {
  const FoodSavePage({super.key});

  @override
  State<FoodSavePage> createState() => _FoodSavePageState();
}

class _FoodSavePageState extends State<FoodSavePage> {
  final ApiService _apiService = ApiService();

  List<Map<String, dynamic>> _mealsForSelectedDate = [];
  bool _isLoading = true;
  DateTime selectedDate = DateTime.now();
  String? _currentFoodLogId;
  Map<String, dynamic>? _userGoals;
  int _previousTotalCal = 0;
  bool _hasShownGoalDialog = false; // เพิ่มตัวแปรเก็บสถานะการแสดง dialog

  List<Map<String, dynamic>> get meals => _mealsForSelectedDate;
  int get totalCal => meals.fold(0, (sum, m) => sum + ((m['cal'] ?? 0) as int));
  int get goalCal => _userGoals?['goal_calorie_intake'] ?? 0;

  @override
  void initState() {
    super.initState();
    _hasShownGoalDialog = false; // เริ่มต้นสถานะ dialog
    _loadFoodLogs();
    _loadUserGoals();
  }

  Future<void> _loadUserGoals() async {
    try {
      final currentUser = await _apiService.getCurrentUser();
      final userId = currentUser['uid'] ?? currentUser['id'];
      
      final goals = await _apiService.getUserGoals(userId);
      if (mounted) {
        setState(() {
          _userGoals = goals;
        });
      }
    } catch (e) {
      print('DEBUG: Error fetching user goals: $e');
      // ไม่แสดง error ให้ user เพราะไม่ใช่ function หลัก
    }
  }

  void _checkCalorieGoal() {
    if (_userGoals == null || goalCal <= 0) return;
    
    final currentCal = totalCal;
    final goalCalories = goalCal;
    final difference = currentCal - goalCalories;
    
    // แสดง dialog เฉพาะเมื่อเพิ่งถึงหรือเกิน goal และยังไม่เคยแสดง dialog ในวันนี้
    if (!_hasShownGoalDialog && _previousTotalCal < goalCalories && currentCal >= goalCalories) {
      _hasShownGoalDialog = true; // ตั้งค่าให้ไม่แสดงซ้ำ
      
      if (difference <= goalCalories * 0.1) {
        // เกินไม่เกิน 10% = ยินดี
        _showCongratulationsDialog(currentCal, goalCalories, difference);
      } else {
        // เกินมากกว่า 10% = เตือน
        _showExcessCaloriesDialog(currentCal, goalCalories, difference);
      }
    }
    
    _previousTotalCal = currentCal;
  }

  void _showCongratulationsDialog(int currentCal, int goalCal, int difference) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.celebration,
                color: const Color(0xFF79D7BE),
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'ยินดีด้วย! 🎉',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E5077),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF79D7BE).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF79D7BE).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'คุณได้บรรลุเป้าหมายแคลอรี่แล้ว!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2E5077),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Text(
                              'เป้าหมาย',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '$goalCal',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF79D7BE),
                              ),
                            ),
                            Text(
                              'kcal',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        const Icon(
                          Icons.arrow_forward,
                          color: Color(0xFF79D7BE),
                        ),
                        Column(
                          children: [
                            Text(
                              'ปัจจุบัน',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '$currentCal',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF79D7BE),
                              ),
                            ),
                            Text(
                              'kcal',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (difference > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        'เกินเป้าหมาย ${difference} kcal',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'ยินดีกับความสำเร็จของคุณ! ให้ดำเนินต่อไปแบบนี้เรื่อยๆ นะ 💪',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF79D7BE),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('ดีใจด้วย!'),
            ),
          ],
        );
      },
    );
  }

  void _showExcessCaloriesDialog(int currentCal, int goalCal, int difference) {
    final percentageOver = ((difference / goalCal) * 100).round();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_rounded,
                color: Colors.orange[600],
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'เกินเป้าหมาย!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E5077),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange[200]!,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'คุณได้รับแคลอรี่เกินเป้าหมายแล้ว',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2E5077),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Text(
                              'เป้าหมาย',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '$goalCal',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF79D7BE),
                              ),
                            ),
                            Text(
                              'kcal',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        const Icon(
                          Icons.trending_up,
                          color: Colors.orange,
                        ),
                        Column(
                          children: [
                            Text(
                              'ปัจจุบัน',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '$currentCal',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[600],
                              ),
                            ),
                            Text(
                              'kcal',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'เกินเป้าหมาย ${difference} kcal ($percentageOver%)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'แนะนำให้ลดปริมาณอาหารในมื้อถัดไป หรือเพิ่มการออกกำลังกายเพื่อเผาผลาญแคลอรี่ส่วนเกิน',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'เข้าใจแล้ว',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('จะระวัง'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadFoodLogs() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final currentUser = await _apiService.getCurrentUser();
      final userId = currentUser['uid'] ?? currentUser['id'];
      
      // ดึง food log สำหรับวันที่เลือก
      var foodLog = await _apiService.getFoodLogByDate(userId, selectedDate);
      
      // ถ้าไม่มี food log สำหรับวันนี้ ให้สร้างใหม่
      if (foodLog == null) {
        print('No food log found for ${selectedDate.toString()}, creating new one...');
        foodLog = await _apiService.createFoodLog(
          userId: userId,
          date: selectedDate,
        );
        print('Created new food log with id: ${foodLog['id']}');
      }
      
      _currentFoodLogId = foodLog['id'];
      
      // ดึง meals จาก food log
      List<Map<String, dynamic>> fetchedMeals = [];
      final meals = await _apiService.getMealsByFoodLog(foodLog['id']);
      fetchedMeals = meals.map<Map<String, dynamic>>((meal) => {
        'id': meal['id'],
        'name': meal['food_name'],
        'type': _convertMealType(meal['meal_type']),
        'cal': meal['calories'] ?? 0,
        'desc': meal['description'] ?? meal['food_name'] ?? '',
        'image_url': meal['image_url'],
        // เพิ่มข้อมูลโภชนาการจากฐานข้อมูล
        'has_nutrition_data': meal['has_nutrition_data'] ?? false,
        'protein': meal['protein'],
        'carbs': meal['carbs'],
        'fat': meal['fat'],
        'fiber': meal['fiber'],
        'sugar': meal['sugar'],
      }).toList();
      
      if (mounted) {
        setState(() {
          _mealsForSelectedDate = fetchedMeals;
        });
      }
      
      // อัปเดต total calories ใน food log (ทำหลังจาก setState เพื่อให้ meals มีค่าถูกต้อง)
      await _updateFoodLogTotalCalories();

      // ตรวจสอบเป้าหมายแคลอรี่
      _checkCalorieGoal();
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e')),
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

  // เพิ่ม method สำหรับอัปเดต total calories ใน food log
  Future<void> _updateFoodLogTotalCalories() async {
    if (_currentFoodLogId == null) {
      print('Cannot update food log stats: _currentFoodLogId is null');
      return;
    }
    
    try {
      final totalCalories = meals.fold<int>(0, (sum, meal) => sum + ((meal['cal'] ?? 0) as int));
      final mealCount = meals.length;
      
      print('Updating food log $_currentFoodLogId for date ${selectedDate.toString().split(' ')[0]}: Total calories = $totalCalories, Meal count = $mealCount');
      
      // เรียก API เพื่ออัปเดต food log stats (แม้ว่าจะมี 0 meals ก็ตาม)
      await _apiService.updateFoodLogStats(
        foodLogId: _currentFoodLogId!,
        totalCalories: totalCalories,
        mealCount: mealCount,
      );
      
      print('Successfully updated food log stats for ${selectedDate.toString().split(' ')[0]}');
      
    } catch (e) {
      print('Error updating food log stats: $e');
      // ไม่แสดง error ให้ user เพราะเป็น background operation
    }
  }

  String _convertMealType(String? apiMealType) {
    switch (apiMealType) {
      case 'breakfast':
        return 'มื้อเช้า';
      case 'lunch':
        return 'กลางวัน';
      case 'dinner':
        return 'เย็น';
      case 'snack':
        return 'ของว่าง';
      default:
        return 'ของว่าง';
    }
  }

  String _convertMealTypeToApi(String thaiMealType) {
    switch (thaiMealType) {
      case 'มื้อเช้า':
        return 'breakfast';
      case 'กลางวัน':
        return 'lunch';
      case 'เย็น':
        return 'dinner';
      case 'ของว่าง':
        return 'snack';
      default:
        return 'snack';
    }
  }



  Future<void> _deleteMeal(String mealId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text('คุณต้องการลบรายการอาหารนี้ใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirm ?? false) {
      try {
        await _apiService.deleteMeal(mealId);
        
        // อัปเดต UI และ total calories
        await _loadFoodLogs();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ลบรายการอาหารสำเร็จ'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาดในการลบ: $e')));
      }
    }
  }

  Future<void> _showMealDialog({Map<String, dynamic>? meal}) async {
    final formKey = GlobalKey<FormState>();
    final List<String> mealTypes = ['มื้อเช้า', 'กลางวัน', 'เย็น', 'ของว่าง'];
    final picker = ImagePicker();
    String? type = meal?['type'];
    final nameController = TextEditingController(text: meal?['name'] ?? '');
    final calController = TextEditingController(
      text: meal?['cal']?.toString() ?? '',
    );
    final descController = TextEditingController(text: meal?['desc'] ?? '');
    final proteinController = TextEditingController();
    final carbsController = TextEditingController();
    final fatController = TextEditingController();
    final fiberController = TextEditingController();
    final sugarController = TextEditingController();
    File? pickedImage;
    NutritionData? nutritionData;
    bool isLoadingNutrition = false;
    bool showNutritionFields = false;
    Timer? searchTimer;
    


    // โหลดข้อมูลที่มีอยู่แล้วถ้าเป็นการแก้ไข
    if (meal != null) {
      // ถ้ามีข้อมูลโภชนาการที่บันทึกไว้แล้ว
      if (meal['has_nutrition_data'] == true) {
        proteinController.text = (meal['protein'] ?? 0.0).toString();
        carbsController.text = (meal['carbs'] ?? 0.0).toString();
        fatController.text = (meal['fat'] ?? 0.0).toString();
        fiberController.text = (meal['fiber'] ?? 0.0).toString();  
        sugarController.text = (meal['sugar'] ?? 0.0).toString();
        showNutritionFields = true;
        
        // สร้าง NutritionData จากข้อมูลที่บันทึกไว้
        nutritionData = NutritionData(
          calories: (meal['cal'] ?? 0).toDouble(),
          protein: (meal['protein'] ?? 0.0).toDouble(),
          carbs: (meal['carbs'] ?? 0.0).toDouble(),
          fat: (meal['fat'] ?? 0.0).toDouble(),
          fiber: (meal['fiber'] ?? 0.0).toDouble(),
          sugar: (meal['sugar'] ?? 0.0).toDouble(),
        );
        

      }
    }

    Future<void> fetchNutritionData(
      StateSetter setStateDialog, [
      String? searchText,
    ]) async {
      final searchQuery = searchText ?? nameController.text.trim();
      if (searchQuery.isEmpty) {
        setStateDialog(() {
          nutritionData = null;
        });
        return;
      }

      setStateDialog(() => isLoadingNutrition = true);
      try {
        final data = await NutritionService.getNutritionData(searchQuery);
        if (!context.mounted) return;
        setStateDialog(() {
          nutritionData = data;
          if (data != null) {
            calController.text = data.calories.toInt().toString();
            
            // เติมข้อมูลโภชนาการเฉพาะเมื่อยังไม่มีข้อมูลหรือเป็นการค้นหาใหม่
            if (meal == null || meal['has_nutrition_data'] != true) {
              proteinController.text = data.protein.toStringAsFixed(1);
              carbsController.text = data.carbs.toStringAsFixed(1);
              fatController.text = data.fat.toStringAsFixed(1);
              fiberController.text = data.fiber.toStringAsFixed(1);
              sugarController.text = data.sugar.toStringAsFixed(1);
            }
            showNutritionFields = true;
          }
          isLoadingNutrition = false;
        });
      } catch (e) {
        if (!context.mounted) return;
        setStateDialog(() => isLoadingNutrition = false);
      }
    }

    void autoSearchNutrition(StateSetter setStateDialog, String searchText) {
      searchTimer?.cancel();
      searchTimer = Timer(const Duration(milliseconds: 800), () {
        if (searchText.trim().length >= 2) {
          fetchNutritionData(setStateDialog, searchText);
        } else {
          setStateDialog(() {
            nutritionData = null;
          });
        }
      });
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: StatefulBuilder(
            builder: (context, setStateDialog) {
              void updateNutritionChart() {
                double calories = double.tryParse(calController.text) ?? 0;
                double protein = double.tryParse(proteinController.text) ?? 0;
                double carbs = double.tryParse(carbsController.text) ?? 0;
                double fat = double.tryParse(fatController.text) ?? 0;
                double fiber = double.tryParse(fiberController.text) ?? 0;
                double sugar = double.tryParse(sugarController.text) ?? 0;

                setStateDialog(() {
                  nutritionData = NutritionData(
                    calories: calories,
                    protein: protein,
                    carbs: carbs,
                    fat: fat,
                    fiber: fiber,
                    sugar: sugar,
                  );
                });
              }
              
              return SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: GestureDetector(
                          onTap: () async {
                            final XFile? image = await picker.pickImage(
                              source: ImageSource.gallery,
                            );
                            if (image != null) {
                              setStateDialog(() {
                                pickedImage = File(image.path);
                              });
                            }
                          },
                          child: pickedImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: Image.file(
                                    pickedImage!,
                                    width: 260,
                                    height: 180,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : meal?['image_url'] != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(18),
                                      child: Image.network(
                                        'http://10.0.2.2:8000${meal!['image_url']}',
                                        width: 260,
                                        height: 180,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            width: 260,
                                            height: 180,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              borderRadius: BorderRadius.circular(18),
                                            ),
                                            child: const Icon(
                                              Icons.add_a_photo,
                                              size: 48,
                                              color: Colors.grey,
                                            ),
                                          );
                                        },
                                      ),
                                    )
                                  : Container(
                                      width: 260,
                                      height: 180,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: const Icon(
                                        Icons.add_a_photo,
                                        size: 48,
                                        color: Colors.grey,
                                      ),
                                    ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'ประเภทอาหาร',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        value: type,
                        items: mealTypes
                            .map(
                              (t) => DropdownMenuItem(value: t, child: Text(t)),
                            )
                            .toList(),
                        onChanged: (v) => setStateDialog(() {
                          type = v;
                        }),
                        validator: (v) =>
                            v == null ? 'กรุณาเลือกประเภทอาหาร' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'ชื่ออาหาร',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (nutritionData != null && !isLoadingNutrition)
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 20,
                                ),
                              if (isLoadingNutrition)
                                const Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              IconButton(
                                icon: const Icon(
                                  Icons.search,
                                  color: Colors.green,
                                ),
                                onPressed: isLoadingNutrition
                                    ? null
                                    : () => fetchNutritionData(setStateDialog),
                                tooltip: 'ค้นหาข้อมูลโภชนาการ',
                              ),
                            ],
                          ),
                        ),
                        controller: nameController,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'กรุณากรอกชื่ออาหาร'
                            : null,
                        onChanged: (value) =>
                            autoSearchNutrition(setStateDialog, value),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'รายละเอียด',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        controller: descController,
                        minLines: 1,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'แคลอรี่',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          suffixText: 'cal',
                          helperText: nutritionData != null
                              ? 'ข้อมูลเริ่มต้นจาก API'
                              : 'กรอกค่าเอง (ถ้าทราบ)',
                        ),
                        keyboardType: TextInputType.number,
                        controller: calController,
                        onChanged: (value) => updateNutritionChart(),
                      ),

                      
                      
                      // ช่องกรอกข้อมูลโภชนาการ
                      if (showNutritionFields || nutritionData != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue[100]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.edit, color: Colors.blue[600], size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'ข้อมูลโภชนาการ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      decoration: InputDecoration(
                                        labelText: 'โปรตีน',
                                        suffixText: 'g',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                      keyboardType: TextInputType.number,
                                      controller: proteinController,
                                      onChanged: (value) => updateNutritionChart(),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      decoration: InputDecoration(
                                        labelText: 'คาร์บ',
                                        suffixText: 'g',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                      keyboardType: TextInputType.number,
                                      controller: carbsController,
                                      onChanged: (value) => updateNutritionChart(),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      decoration: InputDecoration(
                                        labelText: 'ไขมัน',
                                        suffixText: 'g',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                      keyboardType: TextInputType.number,
                                      controller: fatController,
                                      onChanged: (value) => updateNutritionChart(),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      decoration: InputDecoration(
                                        labelText: 'ใยอาหาร',
                                        suffixText: 'g',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                      keyboardType: TextInputType.number,
                                      controller: fiberController,
                                      onChanged: (value) => updateNutritionChart(),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'น้ำตาล',
                                  suffixText: 'g',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                controller: sugarController,
                                onChanged: (value) => updateNutritionChart(),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),
                      if (isLoadingNutrition)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        ),

                      if (!isLoadingNutrition && nutritionData != null)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green[100]!),
                          ),
                          child: Row(
                            children: [
                              NutritionChart(
                                nutritionData: nutritionData!,
                                size: 100,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildNutrientRow(
                                      'โปรตีน',
                                      '${nutritionData!.protein.toStringAsFixed(1)}g',
                                      Colors.red[400]!,
                                    ),
                                    const SizedBox(height: 4),
                                    _buildNutrientRow(
                                      'คาร์บ',
                                      '${nutritionData!.carbs.toStringAsFixed(1)}g',
                                      Colors.blue[400]!,
                                    ),
                                    const SizedBox(height: 4),
                                    _buildNutrientRow(
                                      'ไขมัน',
                                      '${nutritionData!.fat.toStringAsFixed(1)}g',
                                      Colors.orange[400]!,
                                    ),
                                    const SizedBox(height: 4),
                                    _buildNutrientRow(
                                      'ใยอาหาร',
                                      '${nutritionData!.fiber.toStringAsFixed(1)}g',
                                      Colors.green[400]!,
                                    ),
                                    const SizedBox(height: 4),
                                    _buildNutrientRow(
                                      'น้ำตาล',
                                      '${nutritionData!.sugar.toStringAsFixed(1)}g',
                                      Colors.pink[400]!,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 28),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('ยกเลิก'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (formKey.currentState?.validate() ?? false) {
                                  try {
                                    final currentUser = await _apiService.getCurrentUser();
                                    final userId = currentUser['uid'] ?? currentUser['id'];
                                    
                                    // อัปโหลดรูปภาพถ้ามี
                                    String? imageUrl;
                                    if (pickedImage != null) {
                                      final uploadResponse = await _apiService.uploadMealImage(pickedImage!.path);
                                      imageUrl = uploadResponse['image_url'];
                                    }

                                    // คำนวณแคลอรี่จาก nutrition data หรือจากที่ผู้ใช้ป้อน
                                    int calories = 0;
                                    if (calController.text.isNotEmpty) {
                                      calories = int.tryParse(calController.text) ?? 0;
                                    }

                                    // รับค่าโภชนาการจากที่ผู้ใช้แก้ไข
                                    double? protein = proteinController.text.isNotEmpty 
                                        ? double.tryParse(proteinController.text) : null;
                                    double? carbs = carbsController.text.isNotEmpty 
                                        ? double.tryParse(carbsController.text) : null;
                                    double? fat = fatController.text.isNotEmpty 
                                        ? double.tryParse(fatController.text) : null;
                                    double? fiber = fiberController.text.isNotEmpty 
                                        ? double.tryParse(fiberController.text) : null;
                                    double? sugar = sugarController.text.isNotEmpty 
                                        ? double.tryParse(sugarController.text) : null;
                                    
                                    // เช็คว่ามีการแก้ไขข้อมูลโภชนาการหรือไม่
                                    bool hasNutritionData = (protein != null && protein > 0) || 
                                                           (carbs != null && carbs > 0) || 
                                                           (fat != null && fat > 0) || 
                                                           (fiber != null && fiber > 0) || 
                                                           (sugar != null && sugar > 0);

                                    if (meal?['id'] != null) {
                                      // อัปเดต meal ที่มีอยู่
                                      await _apiService.updateMeal(
                                        mealId: meal!['id'],
                                        foodName: nameController.text.trim(),
                                        description: descController.text.trim(),
                                        mealType: _convertMealTypeToApi(type!),
                                        calories: calories,
                                        protein: protein,
                                        carbs: carbs,
                                        fat: fat,
                                        fiber: fiber,
                                        sugar: sugar,
                                        hasNutritionData: hasNutritionData,
                                        imageUrl: imageUrl,
                                      );
                                    } else {
                                      // ตรวจสอบว่ามี food log แล้วหรือไม่ (ควรจะมีแล้วจาก _loadFoodLogs())
                                      if (_currentFoodLogId == null) {
                                        print('Warning: _currentFoodLogId is null, creating food log...');
                                        final foodLog = await _apiService.createFoodLog(
                                          userId: userId,
                                          date: selectedDate,
                                        );
                                        _currentFoodLogId = foodLog['id'];
                                      }
                                      
                                      // สร้าง meal ใหม่
                                      await _apiService.createMeal(
                                        foodLogId: _currentFoodLogId!,
                                        userId: userId,
                                        foodName: nameController.text.trim(),
                                        description: descController.text.trim(),
                                        mealType: _convertMealTypeToApi(type!),
                                        calories: calories,
                                        protein: protein,
                                        carbs: carbs,
                                        fat: fat,
                                        fiber: fiber,
                                        sugar: sugar,
                                        hasNutritionData: hasNutritionData,
                                        imageUrl: imageUrl,
                                      );
                                    }
                                    
                                    if (context.mounted)
                                      Navigator.of(context).pop();
                                    
                                    // Track achievement: บันทึกอาหารสำเร็จ
                                    await AchievementService.maybeTrackMealLogged(context);

                                    // รีโหลดข้อมูลและอัปเดต total calories
                                    await _loadFoodLogs();
                                    
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            meal?['id'] != null ? 'บันทึกการแก้ไขสำเร็จ' : 'เพิ่มอาหารสำเร็จ',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted)
                                      Navigator.of(context).pop();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
                                      );
                                    }
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: Text(meal?['id'] != null ? 'บันทึก' : 'เพิ่ม'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildNutrientRow(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getCalorieColor() {
    if (goalCal <= 0) return const Color(0xFF2E5077);
    
    final percentage = (totalCal / goalCal);
    if (percentage < 0.8) {
      return Colors.orange[600]!; // ต่ำกว่าเป้าหมาย
    } else if (percentage <= 1.1) {
      return const Color(0xFF79D7BE); // ใกล้เป้าหมาย
    } else {
      return Colors.red[600]!; // เกินเป้าหมายมาก
    }
  }

  Widget _buildCalorieProgressBar() {
    if (goalCal <= 0) return const SizedBox.shrink();
    
    final progress = (totalCal / goalCal).clamp(0.0, 1.5);
    final percentage = ((totalCal / goalCal) * 100).round();
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ความคืบหน้า',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 12,
                color: _getCalorieColor(),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            FractionallySizedBox(
              widthFactor: progress > 1.0 ? 1.0 : progress,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: _getCalorieColor(),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            if (progress > 1.0)
              Positioned(
                right: 0,
                child: Container(
                  width: 20,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.red[400],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '0',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
              ),
            ),
            Text(
              '${goalCal}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(20), // ลดขนาดจาก 56 เป็น 50
        child: AppBar(
          backgroundColor: const Color(0xFF79D7BE),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          toolbarHeight: 20, // กำหนดความสูงของ toolbar
        ),
      ),
      body: Column(
        children: [
          // Header Section with Title and Add Button
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(
                  Icons.restaurant_menu,
                  color: const Color(0xFF79D7BE),
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'บันทึกอาหาร',
                    style: TextStyle(
                      color: Color(0xFF2E5077),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showMealDialog(),
                  icon: const Icon(
                    Icons.add,
                    size: 20,
                  ),
                  label: const Text('เพิ่มอาหาร'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF79D7BE),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null && picked != selectedDate) {
                          setState(() {
                            selectedDate = picked;
                            _previousTotalCal = 0; // Reset previous total
                            _hasShownGoalDialog = false; // Reset dialog status เมื่อเปลี่ยนวัน
                          });
                          _loadFoodLogs();
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF79D7BE).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF79D7BE)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: Color(0xFF79D7BE),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color(0xFF2E5077),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Text(
                              'รวม ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              '$totalCal',
                              style: TextStyle(
                                color: _getCalorieColor(),
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            Text(
                              ' kcal',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        if (goalCal > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                'เป้าหมาย ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                              Text(
                                '$goalCal kcal',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: const Color(0xFF79D7BE),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                if (goalCal > 0) ...[
                  const SizedBox(height: 12),
                  _buildCalorieProgressBar(),
                ],
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildTimeline(),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF7F8FA),
    );
  }

  Widget _buildTimeline() {
    final mealTypesMain = [
      {'type': 'มื้อเช้า', 'icon': Icons.wb_sunny, 'color': Colors.orange},
      {'type': 'กลางวัน', 'icon': Icons.sunny, 'color': Colors.amber},
      {'type': 'เย็น', 'icon': Icons.nightlight_round, 'color': Colors.blue},
    ];
    final snackType = {
      'type': 'ของว่าง',
      'icon': Icons.cake,
      'color': Colors.purple,
    };
    final allTypes = [...mealTypesMain, snackType];

    final mealsByType = <String, List<Map<String, dynamic>>>{};
    for (var t in allTypes) {
      mealsByType[t['type'] as String] = [];
    }
    for (var m in meals) {
      if (mealsByType.containsKey(m['type'])) {
        mealsByType[m['type']]!.add(m);
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 24),
      itemCount: allTypes.length,
      itemBuilder: (context, idx) {
        final t = allTypes[idx];
        final type = t['type'] as String;
        final icon = t['icon'] as IconData;
        final color = t['color'] as Color;
        final typeMeals = mealsByType[type]!;
        final isLast = idx == allTypes.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 50,
              child: Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: typeMeals.isNotEmpty ? color : Colors.grey[300],
                      shape: BoxShape.circle,
                      boxShadow: typeMeals.isNotEmpty
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.3),
                                spreadRadius: 2,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(icon, color: Colors.white, size: 18),
                  ),
                  if (!isLast)
                    Container(
                      width: 3,
                      height: typeMeals.isEmpty
                          ? 80
                          : (typeMeals.length * 160.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0, bottom: 16.0),
                      child: Text(
                        type,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: typeMeals.isNotEmpty
                              ? color
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                    if (typeMeals.isEmpty)
                      Text(
                        'ยังไม่มีอาหารในมื้อนี้',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    else
                      ...typeMeals.map(
                        (meal) => MealCard(
                          key: ValueKey(meal['id']),
                          meal: meal,
                          onEdit: () async {
                            await _showMealDialog(meal: meal);
                            // Refresh ข้อมูลหลังจากแก้ไขเสร็จ
                            _loadFoodLogs();
                          },
                          onDelete: () => _deleteMeal(meal['id']),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class MealCard extends StatefulWidget {
  final Map<String, dynamic> meal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MealCard({
    required Key key,
    required this.meal,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  State<MealCard> createState() => _MealCardState();
}

class _MealCardState extends State<MealCard> {
  NutritionData? _nutritionData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNutritionDetails();
  }

  Future<void> _fetchNutritionDetails() async {
    if (widget.meal['name'] == null || widget.meal['name'].isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      NutritionData? data;
      
      // ถ้ามีข้อมูลโภชนาการที่บันทึกไว้แล้ว ใช้ข้อมูลนั้น
      if (widget.meal['has_nutrition_data'] == true && 
          widget.meal['protein'] != null && 
          widget.meal['carbs'] != null && 
          widget.meal['fat'] != null) {
        data = NutritionData(
          calories: (widget.meal['cal'] ?? 0).toDouble(),
          protein: (widget.meal['protein'] ?? 0.0).toDouble(),
          carbs: (widget.meal['carbs'] ?? 0.0).toDouble(),
          fat: (widget.meal['fat'] ?? 0.0).toDouble(),
          fiber: (widget.meal['fiber'] ?? 0.0).toDouble(),
          sugar: (widget.meal['sugar'] ?? 0.0).toDouble(),
        );
      } else {
        // ถ้าไม่มีข้อมูลที่บันทึกไว้ ให้ดึงจาก Mock API
        data = await NutritionService.getNutritionData(widget.meal['name']);
      }
      
      if (mounted) {
        setState(() {
          _nutritionData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // เพิ่ม method สำหรับ refresh ข้อมูลโภชนาการหลังจากแก้ไข
  void refreshNutritionData() {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
      _fetchNutritionDetails();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onEdit,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[100],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: widget.meal['image_url'] != null
                          ? Image.network(
                              'http://10.0.2.2:8000${widget.meal['image_url']}',
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.restaurant,
                                  size: 40,
                                  color: Colors.grey[400],
                                );
                              },
                            )
                          : Icon(
                              Icons.restaurant,
                              size: 40,
                              color: Colors.grey[400],
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.meal['name'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if ((widget.meal['desc'] ?? '').isNotEmpty)
                          Text(
                            widget.meal['desc'],
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 6),
                        
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red[300]),
                    onPressed: widget.onDelete,
                  ),
                ],
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            if (!_isLoading && _nutritionData != null)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[100]!),
                ),
                child: Row(
                  children: [
                    NutritionChart(nutritionData: _nutritionData!, size: 100),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // แสดงสถานะข้อมูล
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'ข้อมูลโภชนาการ',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildNutrientRow(
                            'โปรตีน',
                            '${_nutritionData!.protein.toStringAsFixed(1)}g',
                            Colors.red[400]!,
                          ),
                          const SizedBox(height: 4),
                          _buildNutrientRow(
                            'คาร์บ',
                            '${_nutritionData!.carbs.toStringAsFixed(1)}g',
                            Colors.blue[400]!,
                          ),
                          const SizedBox(height: 4),
                          _buildNutrientRow(
                            'ไขมัน',
                            '${_nutritionData!.fat.toStringAsFixed(1)}g',
                            Colors.orange[400]!,
                          ),
                          const SizedBox(height: 4),
                          _buildNutrientRow(
                            'ใยอาหาร',
                            '${_nutritionData!.fiber.toStringAsFixed(1)}g',
                            Colors.green[400]!,
                          ),
                          const SizedBox(height: 4),
                          _buildNutrientRow(
                            'น้ำตาล',
                            '${_nutritionData!.sugar.toStringAsFixed(1)}g',
                            Colors.pink[400]!,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientRow(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
