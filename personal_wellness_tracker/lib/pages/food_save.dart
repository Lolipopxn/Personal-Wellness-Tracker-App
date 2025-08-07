import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import '../services/nutrition_service.dart';
import '../widgets/nutrition_chart.dart';
import 'mock_api_manager_page.dart';

class FoodSavePage extends StatefulWidget {
  const FoodSavePage({super.key});

  @override
  State<FoodSavePage> createState() => _FoodSavePageState();
}

class _FoodSavePageState extends State<FoodSavePage> {
  final Map<String, List<Map<String, dynamic>>> mealsByDate = {};
  DateTime selectedDate = DateTime.now();

  List<Map<String, dynamic>> get meals => mealsByDate[_dateKey(selectedDate)] ?? [];
  int get totalCal => meals.fold(0, (sum, m) => sum + (m['cal'] as int));
  String _dateKey(DateTime date) => '${date.year}-${date.month}-${date.day}';

  void _showMealDialog({Map<String, dynamic>? meal, int? editIdx}) {
    final formKey = GlobalKey<FormState>();
    final List<String> mealTypes = ['มื้อเช้า', 'กลางวัน', 'เย็น', 'ของว่าง'];
    final picker = ImagePicker();
    String? type = meal?['type'];
    final nameController = TextEditingController(text: meal?['name'] ?? '');
    final calController = TextEditingController(text: meal?['cal']?.toString() ?? '');
    final descController = TextEditingController(text: meal?['desc'] ?? '');
    File? pickedImage = meal?['image'];
    NutritionData? nutritionData = meal?['nutrition'] != null ? 
        NutritionData.fromJson(meal!['nutrition']) : null;
    bool isLoadingNutrition = false;
    Timer? searchTimer;

    // ฟังก์ชันสำหรับดึงข้อมูลโภชนาการ
    Future<void> fetchNutritionData(StateSetter setStateDialog, [String? searchText]) async {
      final searchQuery = searchText ?? nameController.text.trim();
      print('🚀 fetchNutritionData called with: "$searchQuery"');
      if (searchQuery.isEmpty) {
        print('❌ Search query is empty, returning');
        return;
      }
      
      print('⏳ Setting loading state to true');
      setStateDialog(() {
        isLoadingNutrition = true;
      });

      try {
        print('📡 Calling NutritionService.getNutritionData...');
        final data = await NutritionService.getNutritionData(searchQuery);
        
        print('📊 Received data: ${data != null ? "Found!" : "Not found"}');
        setStateDialog(() {
          nutritionData = data;
          isLoadingNutrition = false;
          // อัปเดตแคลอรี่จาก API ถ้ามีข้อมูล
          if (data != null) {
            print('✅ Updating calories to: ${data.calories.toInt()}');
            calController.text = data.calories.toInt().toString();
          }
        });
      } catch (e) {
        print('❌ Error in fetchNutritionData: $e');
        setStateDialog(() {
          isLoadingNutrition = false;
        });
      }
    }

    // ฟังก์ชันสำหรับค้นหาอัตโนมัติด้วย debounce
    void autoSearchNutrition(StateSetter setStateDialog, String searchText) {
      print('⏰ autoSearchNutrition called with: "$searchText"');
      // ยกเลิก timer เก่า
      searchTimer?.cancel();
      
      // สร้าง timer ใหม่
      searchTimer = Timer(const Duration(milliseconds: 800), () {
        print('⏰ Timer triggered for: "$searchText" (length: ${searchText.trim().length})');
        if (searchText.trim().length >= 2) {
          print('✅ Text length >= 2, calling fetchNutritionData');
          fetchNutritionData(setStateDialog, searchText);
        } else {
          print('❌ Text too short, skipping search');
        }
      });
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: StatefulBuilder(
            builder: (context, setStateDialog) {
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
                            final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                            if (image != null) {
                              setStateDialog(() {
                                pickedImage = File(image.path);
                              });
                            }
                          },
                          child: pickedImage == null
                              ? Container(
                                  width: 260,
                                  height: 180,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: const Icon(Icons.add_a_photo, size: 48, color: Colors.grey),
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: Image.file(pickedImage!, width: 260, height: 180, fit: BoxFit.cover),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'ประเภทอาหาร',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        value: type,
                        items: mealTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (v) => setStateDialog(() { type = v; }),
                        validator: (v) => v == null ? 'กรุณาเลือกประเภทอาหาร' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'ชื่ออาหาร',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (nutritionData != null)
                                Icon(Icons.check_circle, color: Colors.green, size: 20),
                              if (isLoadingNutrition)
                                const Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                              IconButton(
                                icon: const Icon(Icons.search, color: Colors.green),
                                onPressed: isLoadingNutrition 
                                    ? null 
                                    : () => fetchNutritionData(setStateDialog),
                                tooltip: 'ค้นหาข้อมูลโภชนาการ',
                              ),
                            ],
                          ),
                          helperText: 'พิมพ์ชื่ออาหารเพื่อค้นหาข้อมูลโภชนาการอัตโนมัติ',
                          helperStyle: const TextStyle(fontSize: 12),
                        ),
                        controller: nameController,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'กรุณากรอกชื่ออาหาร' : null,
                        onChanged: (value) {
                          print('📝 onChanged triggered with: "$value"');
                          // รีเซ็ตข้อมูลโภชนาการเมื่อผู้ใช้เปลี่ยนชื่ออาหาร
                          if (nutritionData != null) {
                            print('🔄 Resetting previous nutrition data');
                            setStateDialog(() {
                              nutritionData = null;
                              // ไม่ลบค่าแคลอรี่ที่ผู้ใช้อาจกรอกไว้
                            });
                          }
                          
                          // เริ่มการค้นหาอัตโนมัติ
                          print('🚀 Starting auto search...');
                          autoSearchNutrition(setStateDialog, value);
                        },
                      ),
                      const SizedBox(height: 16),
                      // แสดงข้อมูลโภชนาการ
                      if (nutritionData != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green[600], size: 24),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'พบข้อมูลโภชนาการ',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  NutritionChart(nutritionData: nutritionData!, size: 140),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        NutritionLegend(nutritionData: nutritionData!),
                                        const SizedBox(height: 8),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'รายละเอียด',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        controller: descController,
                        minLines: 1,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'แคลอรี่ (ไม่บังคับ)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          suffixText: 'cal',
                          enabled: nutritionData == null, // ปิดการแก้ไขถ้ามีข้อมูลจาก API
                          helperText: nutritionData != null 
                              ? 'ใช้ข้อมูลจาก API' 
                              : 'ถ้าไม่กรอก ระบบจะใช้ข้อมูลจาก API หรือค่าเริ่มต้น 100 cal',
                          helperStyle: TextStyle(
                            color: nutritionData != null ? Colors.green : Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        controller: calController,
                        validator: (v) {
                          // ตรวจสอบเฉพาะในกรณีที่มีการกรอกข้อมูล
                          if (v != null && v.trim().isNotEmpty) {
                            if (int.tryParse(v) == null || int.parse(v) < 0) {
                              return 'กรุณากรอกตัวเลขแคลอรี่ที่ถูกต้อง';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                searchTimer?.cancel(); // ยกเลิก timer
                                Navigator.of(context).pop();
                              },
                              child: const Text('ยกเลิก'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                if (formKey.currentState?.validate() ?? false) {
                                  searchTimer?.cancel(); // ยกเลิก timer
                                  final key = _dateKey(selectedDate);
                                  
                                  // คำนวณแคลอรี่: ลำดับความสำคัญ API > ผู้ใช้กรอก > ค่าเริ่มต้น 100
                                  int caloriesValue;
                                  if (nutritionData != null) {
                                    // ใช้ข้อมูลจาก API
                                    caloriesValue = nutritionData!.calories.toInt();
                                  } else if (calController.text.trim().isNotEmpty) {
                                    // ใช้ข้อมูลที่ผู้ใช้กรอก
                                    caloriesValue = int.parse(calController.text.trim());
                                  } else {
                                    // ใช้ค่าเริ่มต้น
                                    caloriesValue = 100;
                                  }
                                  
                                  if (editIdx != null) {
                                    setState(() {
                                      final mealData = {
                                        'type': type,
                                        'name': nameController.text.trim(),
                                        'cal': caloriesValue,
                                        'desc': descController.text.trim(),
                                        'image': pickedImage,
                                        'nutrition': nutritionData?.toJson(),
                                      };
                                      mealsByDate[key]![editIdx] = mealData;
                                    });
                                  } else {
                                    setState(() {
                                      mealsByDate.putIfAbsent(key, () => []);
                                      final mealData = {
                                        'type': type,
                                        'name': nameController.text.trim(),
                                        'cal': caloriesValue,
                                        'desc': descController.text.trim(),
                                        'image': pickedImage,
                                        'nutrition': nutritionData?.toJson(),
                                      };
                                      mealsByDate[key]!.add(mealData);
                                    });
                                  }
                                  Navigator.of(context).pop();
                                } else {
                                  // แสดงข้อผิดพลาดเฉพาะเมื่อมีฟิลด์ที่จำเป็นไม่ได้กรอก (เช่น ประเภทอาหาร, ชื่ออาหาร)
                                  // ไม่แสดงข้อผิดพลาดเกี่ยวกับแคลอรี่เนื่องจากไม่บังคับแล้ว
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              child: Text(editIdx != null ? 'บันทึก' : 'เพิ่ม'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Meal Logging', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.blue, size: 24),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MockApiManagerPage(),
                ),
              );
            },
            tooltip: 'จัดการ MockAPI',
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.green, size: 28),
            onPressed: () => _showMealDialog(),
            tooltip: 'เพิ่มอาหาร',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18, color: Colors.green),
                        const SizedBox(width: 6),
                        Text(
                          '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          style: const TextStyle(fontSize: 15, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Text('รวม ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('$totalCal', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
                const Text(' cal', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
          Expanded(
            child: _buildTimeline(),
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
    final snackType = {'type': 'ของว่าง', 'icon': Icons.cake, 'color': Colors.purple};
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
    // Build timeline: main meals first, snack last
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 24),
      itemCount: allTypes.length,
      itemBuilder: (context, idx) {
        final isSnack = idx == allTypes.length - 1;
        final t = isSnack ? snackType : mealTypesMain[idx];
        final type = t['type'] as String;
        final icon = t['icon'] as IconData;
        final color = t['color'] as Color;
        final typeMeals = mealsByType[type]!;
        final isLast = idx == allTypes.length - 1;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline
            Container(
              width: 50,
              child: Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: typeMeals.isNotEmpty ? color : Colors.grey[300],
                      shape: BoxShape.circle,
                      boxShadow: typeMeals.isNotEmpty ? [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ] : null,
                    ),
                    child: Icon(
                      icon, 
                      color: Colors.white, 
                      size: 18
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 3,
                      height: typeMeals.isEmpty ? 80 : 
                             (typeMeals.length > 1 || (typeMeals.isNotEmpty && typeMeals[0]['nutrition'] != null)) ? 
                             160 : 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                ],
              ),
            ),
            // Meals for this type
            Expanded(
              child: typeMeals.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 12.0, bottom: 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              type,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: color,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'ยังไม่มีอาหารในมื้อนี้',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // หัวข้อมื้อ
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(color: color.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, color: color, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                type,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: color,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${typeMeals.length} รายการ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...typeMeals.map((meal) => GestureDetector(
                              onTap: () => _showMealDialog(meal: meal, editIdx: meals.indexOf(meal)),
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
                                    // ส่วนหลัก: รูปภาพ + ข้อมูลพื้นฐาน
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          // รูปภาพอาหาร
                                          Container(
                                            width: 80,
                                            height: 80,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(12),
                                              color: Colors.grey[100],
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                              child: meal['image'] != null
                                                  ? Image.file(
                                                      meal['image'], 
                                                      width: 80, 
                                                      height: 80, 
                                                      fit: BoxFit.cover
                                                    )
                                                  : Icon(
                                                      Icons.restaurant, 
                                                      size: 40, 
                                                      color: Colors.grey[400]
                                                    ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          // ข้อมูลอาหาร
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // ชื่ออาหาร
                                                Text(
                                                  meal['name'] ?? '',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                // รายละเอียด (ถ้ามี)
                                                if ((meal['desc'] ?? '').isNotEmpty)
                                                  Text(
                                                    meal['desc'],
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.grey[600],
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                              ],
                                            ),
                                          ),
                                          // ไอคอนแก้ไข
                                          Icon(
                                            Icons.edit,
                                            color: Colors.grey[400],
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                    // ส่วนข้อมูลโภชนาการ (ถ้ามี)
                                    if (meal['nutrition'] != null) 
                                      Container(
                                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.green[50],
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.green[100]!),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // หัวข้อ
                                            Row(
                                              children: [
                                                Icon(Icons.verified, size: 16, color: Colors.green[600]),
                                                const SizedBox(width: 6),
                                                Text(
                                                  'ข้อมูลโภชนาการ',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green[700],
                                                  ),
                                                ),
                                                const Spacer(),
                                                Text(
                                                  'จาก API',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.green[600],
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            // กราฟและข้อมูลโภชนาการ
                                            Row(
                                              children: [
                                                // กราฟโภชนาการขนาดใหญ่
                                                NutritionChart(
                                                  nutritionData: NutritionData.fromJson(meal['nutrition']), 
                                                  size: 100
                                                ),
                                                const SizedBox(width: 16),
                                                // ข้อมูลโภชนาการละเอียด
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      _buildNutrientRow(
                                                        'โปรตีน',
                                                        '${NutritionData.fromJson(meal['nutrition']).protein.toStringAsFixed(1)}g',
                                                        Colors.red[400]!,
                                                      ),
                                                      const SizedBox(height: 4),
                                                      _buildNutrientRow(
                                                        'คาร์โบไฮเดรต',
                                                        '${NutritionData.fromJson(meal['nutrition']).carbs.toStringAsFixed(1)}g',
                                                        Colors.blue[400]!,
                                                      ),
                                                      const SizedBox(height: 4),
                                                      _buildNutrientRow(
                                                        'ไขมัน',
                                                        '${NutritionData.fromJson(meal['nutrition']).fat.toStringAsFixed(1)}g',
                                                        Colors.orange[400]!,
                                                      ),
                                                      const SizedBox(height: 4),
                                                      _buildNutrientRow(
                                                        'ใยอาหาร',
                                                        '${NutritionData.fromJson(meal['nutrition']).fiber.toStringAsFixed(1)}g',
                                                        Colors.green[400]!,
                                                      ),
                                                      const SizedBox(height: 4),
                                                      _buildNutrientRow(
                                                        'น้ำตาล',
                                                        '${NutritionData.fromJson(meal['nutrition']).sugar.toStringAsFixed(1)}g',
                                                        Colors.pink[400]!,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            // สรุปแคลอรี่
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              decoration: BoxDecoration(
                                                color: Colors.red[50],
                                                borderRadius: BorderRadius.circular(16),
                                                border: Border.all(color: Colors.red[300]!, width: 1.5),
                                              ),
                                              child: Text(
                                                'รวม ${NutritionData.fromJson(meal['nutrition']).calories.toStringAsFixed(0)} แคลอรี่',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.red[700],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            )),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }

  // Helper function สำหรับแสดงข้อมูลโภชนาการแต่ละบรรทัด
  Widget _buildNutrientRow(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
            ),
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
