import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import '../services/nutrition_service.dart';
import '../services/offline_data_service.dart';
import '../services/sync_service.dart';
import '../widgets/nutrition_chart.dart';
import 'mock_api_manager_page.dart';

class FoodSavePage extends StatefulWidget {
  const FoodSavePage({super.key});

  @override
  State<FoodSavePage> createState() => _FoodSavePageState();
}

class _FoodSavePageState extends State<FoodSavePage> {
  final OfflineDataService _offlineDataService = OfflineDataService();
  final SyncService _syncService = SyncService();

  List<Map<String, dynamic>> _mealsForSelectedDate = [];
  bool _isLoading = true;
  DateTime selectedDate = DateTime.now();

  List<Map<String, dynamic>> get meals => _mealsForSelectedDate;
  int get totalCal => meals.fold(0, (sum, m) => sum + ((m['cal'] ?? 0) as int));
  String _dateKey(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _loadFoodLogs();
  }

  Future<void> _loadFoodLogs() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final key = _dateKey(selectedDate);
      print('🍽️ Loading food logs for date: $key (${selectedDate.toString()})');
      
      final fetchedMeals = await _offlineDataService.getFoodLogsForDate(key);
      print('🍽️ Loaded ${fetchedMeals.length} meals from service');
      
      if (mounted) {
        setState(() {
          _mealsForSelectedDate = fetchedMeals;
        });
        print('🍽️ Updated UI with ${fetchedMeals.length} meals');
      }
    } catch (e) {
      print('❌ Error loading food logs: $e');
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
        await _offlineDataService.deleteFoodLog(
          date: _dateKey(selectedDate),
          mealId: mealId,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ลบรายการอาหารสำเร็จ'),
            backgroundColor: Colors.green,
          ),
        );
        _loadFoodLogs();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาดในการลบ: $e')));
      }
    }
  }

  void _showMealDialog({Map<String, dynamic>? meal}) {
    final formKey = GlobalKey<FormState>();
    final List<String> mealTypes = ['มื้อเช้า', 'กลางวัน', 'เย็น', 'ของว่าง'];
    final picker = ImagePicker();
    String? type = meal?['type'];
    final nameController = TextEditingController(text: meal?['name'] ?? '');
    final calController = TextEditingController(
      text: meal?['cal']?.toString() ?? '',
    );
    final descController = TextEditingController(text: meal?['desc'] ?? '');
    File? pickedImage;
    NutritionData? nutritionData;
    bool isLoadingNutrition = false;
    Timer? searchTimer;

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

    showModalBottomSheet(
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
                          child: pickedImage == null
                              ? Container(
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
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: Image.file(
                                    pickedImage!,
                                    width: 260,
                                    height: 180,
                                    fit: BoxFit.cover,
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
                          enabled: nutritionData == null,
                          helperText: nutritionData != null
                              ? 'ใช้ข้อมูลจาก API'
                              : 'กรอกค่าเอง (ถ้าทราบ)',
                        ),
                        keyboardType: TextInputType.number,
                        controller: calController,
                      ),

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
                                  int caloriesValue =
                                      int.tryParse(calController.text.trim()) ??
                                      (meal?['cal'] as int? ?? 0);
                                  if (nutritionData != null) {
                                    caloriesValue = nutritionData!.calories
                                        .toInt();
                                  }

                                  final mealData = {
                                    'type': type,
                                    'name': nameController.text.trim(),
                                    'cal': caloriesValue,
                                    'desc': descController.text.trim(),
                                  };

                                  try {
                                    if (meal?['id'] != null) {
                                      await _offlineDataService.updateFoodLog(
                                        date: _dateKey(selectedDate),
                                        mealId: meal!['id'],
                                        mealData: mealData,
                                      );
                                    } else {
                                      await _offlineDataService.addFoodLog(
                                        date: _dateKey(selectedDate),
                                        mealData: mealData,
                                      );
                                    }
                                    if (context.mounted)
                                      Navigator.of(context).pop();
                                    _loadFoodLogs();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            meal?['id'] != null
                                                ? 'บันทึกการแก้ไขสำเร็จ'
                                                : 'เพิ่มอาหารสำเร็จ',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted)
                                      Navigator.of(context).pop();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('เกิดข้อผิดพลาด: $e'),
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: Text(
                                meal?['id'] != null ? 'บันทึก' : 'เพิ่ม',
                              ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Meal Logging',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.orange, size: 24),
            onPressed: () async {
              try {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('กำลัง sync ข้อมูลจาก Firebase...')),
                );
                await _syncService.forceSyncFromFirestore();
                _loadFoodLogs();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sync เสร็จสิ้น'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Sync ล้มเหลว: $e')),
                );
              }
            },
            tooltip: 'Force Sync from Firebase',
          ),
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
            icon: const Icon(
              Icons.add_circle_outline,
              color: Colors.green,
              size: 28,
            ),
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
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null && picked != selectedDate) {
                      setState(() {
                        selectedDate = picked;
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
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'รวม ',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '$totalCal',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const Text(' cal', style: TextStyle(fontSize: 16)),
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
                          onEdit: () => _showMealDialog(meal: meal),
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
      final data = await NutritionService.getNutritionData(widget.meal['name']);
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
                      child: Icon(
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
