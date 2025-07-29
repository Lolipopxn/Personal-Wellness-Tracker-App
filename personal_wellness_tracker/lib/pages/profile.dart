import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/cupertino.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    return RegistrationScreen();
  }
}

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  // For water goal cup selection UI
  int _selectedWaterCups = 0;
  // Controllers for text fields
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  // --- Step 2 Controllers ---
  final TextEditingController _goalWeightController = TextEditingController();
  final TextEditingController _goalExerciseController = TextEditingController();
  final TextEditingController _goalWaterController = TextEditingController();
  final TextEditingController _goalExerciseMinutesController = TextEditingController();
  // --- Step 3 Controllers ---
  final TextEditingController _bpController = TextEditingController();
  final TextEditingController _hrController = TextEditingController();

  // Selected gender (simplified, could be a more complex dropdown)
  String? _selectedGender;
  final List<String> _genderOptions = ['Male', 'Female', 'Other'];

  // Current step index for the progress indicator
  int _currentStepIndex = 0;
  final int _totalSteps = 3; // Total number of registration steps

  // เพิ่มตัวแปรเหล่านี้ใน _RegistrationScreenState
  List<bool>? _healthProblemsChecked;
  TextEditingController? _otherProblemController;
  bool _otherChecked = false;

  // ตัวแปรสำหรับเก็บรูปโปรไฟล์
  ImageProvider? _profileImage;
  bool _isPickingImage = false;

  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _goalWeightController.dispose();
    _goalExerciseController.dispose();
    _goalWaterController.dispose();
    _bpController.dispose();
    _hrController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Registration'),
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 0, // Hide the default app bar
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top navigation steps
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
              child: _buildStepProgressBar(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: _buildStepContent(),
              ),
            ),
            // Bottom Navigation
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
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _currentStepIndex > 0
                          ? () {
                              setState(() {
                                if (_currentStepIndex > 0) {
                                  _currentStepIndex--;
                                }
                              });
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _currentStepIndex > 0 ? Colors.grey[200] : Colors.grey[100],
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'ย้อนกลับ',
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentStepIndex < _totalSteps - 1) {
                          setState(() {
                            _currentStepIndex++;
                          });
                        } else {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              contentPadding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green, size: 60),
                                  const SizedBox(height: 18),
                                  const Text('บันทึกสำเร็จ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              actions: [
                                Center(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('ตกลง'),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _currentStepIndex < _totalSteps - 1 ? Colors.green : Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        _currentStepIndex < _totalSteps - 1 ? 'ถัดไป' : 'บันทึก',
                        style: const TextStyle(fontSize: 16, color: Colors.white),
                      ),
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

  // Helper to build text form fields
  Widget _buildTextField(String label, TextEditingController controller, TextInputType keyboardType) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
      ),
    );
  }

  IconData? genderIcon(String gender) {
    switch (gender) {
      case 'Male':
        return Icons.male;
      case 'Female':
        return Icons.female;
      case 'Other':
        return Icons.transgender;
      default:
        return null;
    }
  }

  // Helper to build dropdown form fields
  Widget _buildDropdownField(String label, List<String> options, String? selectedValue, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: selectedValue,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
      ),
      items: options.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Row(
            children: [
              Icon(genderIcon(value), color: Colors.green),
              const SizedBox(width: 8),
              Text(value),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  // Helper to build step indicators with connecting lines
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
                            color: const Color.fromARGB(51, 76, 175, 80), // 0.2 opacity green
                            blurRadius: 8,
                            spreadRadius: 1,
                          )
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
                  fontWeight: isActiveStep ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          );
        } else {
          // Connector line
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

  // เพิ่มฟังก์ชันนี้ใน _RegistrationScreenState
  Widget _buildStepContent() {
    switch (_currentStepIndex) {
      case 0:
        // Step 1: ข้อมูลพื้นฐาน
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'เลือกรูปโปรไฟล์',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () async {
                if (_isPickingImage) return;
                _isPickingImage = true;
                try {
                  final ImagePicker picker = ImagePicker();
                  final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    setState(() {
                      _profileImage = FileImage(File(image.path));
                    });
                  }
                } finally {
                  _isPickingImage = false;
                }
              },
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[300],
                      image: _profileImage != null
                          ? DecorationImage(image: _profileImage!, fit: BoxFit.cover)
                          : null,
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, spreadRadius: 2)],
                    ),
                    child: _profileImage == null
                        ? Icon(Icons.person, size: 90, color: Colors.grey[600])
                        : null,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.camera_alt, size: 28, color: Colors.green),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField('อายุ (ปี)', _ageController, TextInputType.number),
                    const SizedBox(height: 15),
                    _buildDropdownField('เพศ', _genderOptions, _selectedGender, (String? newValue) {
                      setState(() {
                        _selectedGender = newValue;
                      });
                    }),
                    const SizedBox(height: 15),
                    _buildTextField('น้ำหนัก (กิโลกรัม)', _weightController, TextInputType.number),
                    const SizedBox(height: 15),
                    _buildTextField('ส่วนสูง (เซนติเมตร)', _heightController, TextInputType.number),
                  ],
                ),
              ),
            ),
          ],
        );
      case 1:
        // Step 2: เป้าหมาย
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('กรอกเป้าหมายของคุณ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 18),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.monitor_weight, color: Colors.green),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildTextField('เป้าหมายน้ำหนัก (กิโลกรัม)', _goalWeightController, TextInputType.number),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Icon(Icons.fitness_center, color: Colors.green),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildTextField('การออกกำลังกาย (ครั้ง/สัปดาห์)', _goalExerciseController, TextInputType.number),
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
                              int initial = int.tryParse(_goalExerciseMinutesController.text) ?? 30;
                              int tempValue = initial;
                              FixedExtentScrollController scrollController = FixedExtentScrollController(initialItem: (initial/5).clamp(0, 59).toInt());
                              final selected = await showDialog<int>(
                                context: context,
                                barrierDismissible: true,
                                builder: (context) {
                                  return StatefulBuilder(
                                    builder: (context, setStateDialog) {
                                      return Dialog(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Padding(
                                                padding: EdgeInsets.only(bottom: 4),
                                                child: Text('เลือกจำนวนนาที/วัน', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 21, color: Colors.blue)),
                                              ),
                                              SizedBox( 
                                                height: 180,
                                                child: CupertinoPicker(
                                                  scrollController: scrollController,
                                                  itemExtent: 36,
                                                  magnification: 1.15,
                                                  useMagnifier: true,
                                                  squeeze: 1.1,
                                                  onSelectedItemChanged: (idx) {
                                                    setStateDialog(() {
                                                      tempValue = (idx+1)*5;
                                                    });
                                                  },
                                                  selectionOverlay: Container(
                                                    decoration: BoxDecoration(
                                                      border: Border(
                                                        top: BorderSide(color: Colors.blue.withOpacity(0.18), width: 1),
                                                        bottom: BorderSide(color: Colors.blue.withOpacity(0.18), width: 1),
                                                      ),
                                                    ),
                                                  ),
                                                  children: List.generate(60, (i) => Center(
                                                    child: AnimatedDefaultTextStyle(
                                                      duration: const Duration(milliseconds: 120),
                                                      curve: Curves.easeInOut,
                                                      style: TextStyle(
                                                        fontSize: tempValue == (i+1)*5 ? 26 : 16,
                                                        fontWeight: tempValue == (i+1)*5 ? FontWeight.bold : FontWeight.normal,
                                                        color: tempValue == (i+1)*5 ? Colors.blue : Colors.grey[600],
                                                      ),
                                                      child: Text('${(i+1)*5} นาที'),
                                                    ),
                                                  )),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
                                                child: SizedBox(
                                                  width: double.infinity,
                                                  child: ElevatedButton(
                                                    onPressed: () {
                                                      Navigator.of(context).pop(tempValue);
                                                    },
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.blue,
                                                      foregroundColor: Colors.white,
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                                      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                                      elevation: 0,
                                                    ),
                                                    child: const Text('ยืนยัน'),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                              if (selected != null) {
                                setState(() {
                                  _goalExerciseMinutesController.text = selected.toString();
                                });
                              }
                            },
                            child: AbsorbPointer(
                              child: TextField(
                                controller: _goalExerciseMinutesController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'การออกกำลังกาย (นาที/วัน)',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  suffixIcon: const Icon(Icons.arrow_drop_down),
                                ),
                                readOnly: true,
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
                              final selected = await showDialog<int>(
                                context: context,
                                builder: (context) {
                                  return Dialog(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Padding(
                                            padding: EdgeInsets.only(left: 8, bottom: 8),
                                            child: Text('เลือกจำนวนแก้วน้ำ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
                                          ),
                                          Wrap(
                                            spacing: 10,
                                            runSpacing: 10,
                                            children: List.generate(12, (i) {
                                              final cupNum = i + 1;
                                              final isSelected = _selectedWaterCups == cupNum;
                                              return GestureDetector(
                                                onTap: () {
                                                  Navigator.of(context).pop(cupNum);
                                                },
                                                child: AnimatedContainer(
                                                  duration: const Duration(milliseconds: 180),
                                                  curve: Curves.easeInOut,
                                                  padding: const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color: isSelected ? Colors.blue[100] : Colors.transparent,
                                                    borderRadius: BorderRadius.circular(10),
                                                    border: Border.all(
                                                      color: isSelected ? Colors.blue : Colors.grey[300]!,
                                                      width: isSelected ? 2 : 1,
                                                    ),
                                                  ),
                                                  child: Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.local_drink,
                                                          size: 36,
                                                          color: isSelected ? Colors.blue : Colors.grey[400]),
                                                      Text('$cupNum', style: TextStyle(
                                                        color: isSelected ? Colors.blue : Colors.grey[600],
                                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                      )),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                              if (selected != null) {
                                setState(() {
                                  _selectedWaterCups = selected;
                                  _goalWaterController.text = selected.toString();
                                });
                              }
                            },
                            child: AbsorbPointer(
                              child: TextField(
                                controller: _goalWaterController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'เป้าหมายการดื่มน้ำ (แก้ว/วัน)',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  suffixIcon: const Icon(Icons.arrow_drop_down),
                                ),
                                readOnly: true,
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
        );
      case 2:
        // Step 3: ประเมินสุขภาพ
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('ประเมินสุขภาพเบื้องต้น', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 18),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.bloodtype, color: Colors.green),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildTextField('ความดันโลหิต (mmHg)', _bpController, TextInputType.text),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Icon(Icons.favorite, color: Colors.green),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildTextField('อัตราการเต้นหัวใจ (bpm)', _hrController, TextInputType.number),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('ปัญหาสุขภาพที่พบ (เลือกได้มากกว่า 1 ข้อ)',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 10),
                    _buildHealthProblemsChecklist(),
                  ],
                ),
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  // ปรับปรุง _buildHealthProblemsChecklist ให้ดูใช้งานง่ายขึ้นและเพิ่มช่องกรอกเอง
  Widget _buildHealthProblemsChecklist() {
    final List<String> problems = [
      'โรคเบาหวาน',
      'โรคความดันโลหิตสูง',
      'โรคหัวใจ',
      'โรคไขมันในเลือดสูง',
      'โรคภูมิแพ้',
    ];
    // เก็บสถานะ checkbox และข้อความอื่นๆใน State หลัก
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
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}