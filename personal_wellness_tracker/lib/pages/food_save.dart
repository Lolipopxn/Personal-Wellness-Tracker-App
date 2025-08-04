import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

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
    final _formKey = GlobalKey<FormState>();
    final List<String> mealTypes = ['มื้อเช้า', 'กลางวัน', 'เย็น', 'ของว่าง'];
    final picker = ImagePicker();
    String? type = meal?['type'];
    final nameController = TextEditingController(text: meal?['name'] ?? '');
    final calController = TextEditingController(text: meal?['cal']?.toString() ?? '');
    final descController = TextEditingController(text: meal?['desc'] ?? '');
    File? pickedImage = meal?['image'];
    String? errorText;
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
                  key: _formKey,
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
                        ),
                        controller: nameController,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'กรุณากรอกชื่ออาหาร' : null,
                      ),
                      const SizedBox(height: 16),
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
                          labelText: 'แคลอรี่',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        keyboardType: TextInputType.number,
                        controller: calController,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'กรุณากรอกแคลอรี่';
                          if (int.tryParse(v) == null || int.parse(v) < 0) return 'กรุณากรอกตัวเลขแคลอรี่ที่ถูกต้อง';
                          return null;
                        },
                      ),
                      if (errorText != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                          child: Text(errorText!, style: const TextStyle(color: Colors.red, fontSize: 14)),
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
                              onPressed: () {
                                if (_formKey.currentState?.validate() ?? false) {
                                  final key = _dateKey(selectedDate);
                                  if (editIdx != null) {
                                    setState(() {
                                      mealsByDate[key]![editIdx] = {
                                        'type': type,
                                        'name': nameController.text.trim(),
                                        'cal': int.parse(calController.text.trim()),
                                        'desc': descController.text.trim(),
                                        'image': pickedImage,
                                      };
                                    });
                                  } else {
                                    setState(() {
                                      mealsByDate.putIfAbsent(key, () => []);
                                      mealsByDate[key]!.add({
                                        'type': type,
                                        'name': nameController.text.trim(),
                                        'cal': int.parse(calController.text.trim()),
                                        'desc': descController.text.trim(),
                                        'image': pickedImage,
                                      });
                                    });
                                  }
                                  Navigator.of(context).pop();
                                } else {
                                  setStateDialog(() {
                                    errorText = 'กรุณากรอกข้อมูลให้ครบถ้วนและถูกต้อง';
                                  });
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
              width: 40,
              child: Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: typeMeals.isNotEmpty ? color : Colors.grey[300],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey[400]!, width: 2),
                    ),
                    child: Icon(icon, color: typeMeals.isNotEmpty ? Colors.white : Colors.grey[500], size: 16),
                  ),
                  if (!isLast)
                    Container(
                      width: 4,
                      height: 60,
                      color: Colors.grey[300],
                    ),
                ],
              ),
            ),
            // Meals for this type
            Expanded(
              child: typeMeals.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 32),
                      child: Text('ไม่มี${type}', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 0, bottom: 8, top: 4),
                          child: Text(type, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: color)),
                        ),
                        ...typeMeals.map((meal) => GestureDetector(
                              onTap: () => _showMealDialog(meal: meal, editIdx: meals.indexOf(meal)),
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 12, right: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 2,
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: meal['image'] != null
                                          ? Image.file(meal['image'], width: 70, height: 70, fit: BoxFit.cover)
                                          : Container(
                                              width: 70,
                                              height: 70,
                                              color: Colors.grey[200],
                                              child: const Icon(Icons.image, size: 32, color: Colors.grey),
                                            ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(meal['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                            Row(
                                              children: [
                                                Text('${meal['cal'] ?? ''} cal', style: const TextStyle(fontSize: 15, color: Colors.red)),
                                                const SizedBox(width: 8),
                                                if ((meal['desc'] ?? '').isNotEmpty)
                                                  Flexible(child: Text(meal['desc'], style: const TextStyle(fontSize: 14, color: Colors.black87), overflow: TextOverflow.ellipsis)),
                                              ],
                                            ),
                                          ],
                                        ),
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
}
