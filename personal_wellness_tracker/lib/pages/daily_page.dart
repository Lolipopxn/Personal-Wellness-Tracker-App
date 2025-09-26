import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ปรับ path ให้ตรงโปรเจ็กต์ของคุณ
import 'package:personal_wellness_tracker/app/daily_task_api.dart';

class Palette {
  static const navy = Color(0xFF2E5077);  // ข้อความ/ไอคอนหลัก
  static const teal = Color(0xFF4DA1A9);  // ปุ่มหลัก/แอ็กเซนต์
  static const mint = Color(0xFF79D7BE);  // พื้นหลังชิป/แทร็ก
  static const paper = Color(0xFFF8F9FA); // พื้นหลังการ์ด (เปลี่ยนเป็นสีเทาอ่อน)
  static const cardShadow = Color(0xFF000000); // เงาการ์ด
}

class DailyPage extends StatefulWidget {
  const DailyPage({super.key});

  @override
  State<DailyPage> createState() => _DailyPageState();
}

class _DailyPageState extends State<DailyPage> {
  DateTime _now = DateTime.now();

  // ---------- เป้า/ค่าวันนี้ ----------
  // น้ำ: เปลี่ยนเป็น "แก้ว"
  int waterGoalCups = 8;   // เป้าหมาย 8 แก้ว/วัน (แก้ได้ในแผ่นน้ำ)
  int waterCups = 0;       // วันนี้ดื่มไปกี่แก้ว

  int exerciseMinutes = 0;
  bool _exerciseStopwatchOn = false;
  DateTime? _exerciseStartAt;
  String exerciseType = '';
  double exerciseCalories = 0;

  DateTime? sleepStartAt;
  DateTime? sleepEndAt;
  int sleepQuality = 3;

  String? moodEmoji;
  int moodIntensity = 3;

  void Function()? _undoLast;

  // ---------- Progress ----------
  double get waterProgress => (waterCups / waterGoalCups).clamp(0, 1);
  double get exerciseProgress => (exerciseMinutes / 30).clamp(0, 1); // สมมติเป้า 30 นาที
  double get sleepProgress {
    final mins = _sleepDurationInMinutes();
    return (mins / (8 * 60)).clamp(0, 1); // สมมติเป้า 8 ชม.
  }
  double get overallProgress {
    final parts = [
      waterProgress,
      exerciseProgress,
      sleepProgress,
      moodEmoji == null ? 0.0 : 1.0,
    ];
    return parts.reduce((a, b) => a + b) / parts.length;
  }

  int _sleepDurationInMinutes() {
    if (sleepStartAt != null && sleepEndAt != null) {
      return sleepEndAt!.difference(sleepStartAt!).inMinutes;
    }
    return 0;
  }

  // ---------- โหลดข้อมูลวันนี้จาก Backend ----------
  Future<void> _loadFromApi() async {
    try {
      final daily = await DailyTaskApi.getDailyTask(DateTime.now()) ??
          await DailyTaskApi.ensureDailyTaskForToday();
      if (!mounted) return;

      final dailyTaskId = daily['id']?.toString();
      if (dailyTaskId == null) return;

      final tasks = await DailyTaskApi.getTasks(dailyTaskId);

      int _waterCups = 0;
      int _exMin = 0;
      double _exKcal = 0;
      String _exType = '';
      DateTime? _slStart, _slEnd;
      int _slQuality = 3;
      String? _mood;
      int _moodInt = 3;

      for (final t in tasks) {
        final type = (t['task_type'] ?? '').toString();
        switch (type) {
          case 'water':
            // เก็บ "จำนวนแก้ว" ใน value_number
            _waterCups = ((t['value_number'] ?? 0) as num).toInt();
            break;
          case 'exercise':
            _exMin = ((t['value_number'] ?? 0) as num).toInt();
            _exKcal = ((t['calories'] ?? t['kcal'] ?? 0) as num).toDouble();
            _exType = (t['value_text'] ?? '') as String;
            break;
          case 'sleep':
            if (t['started_at'] != null) {
              _slStart = DateTime.tryParse(t['started_at'] as String)?.toLocal();
            }
            if (t['ended_at'] != null) {
              _slEnd = DateTime.tryParse(t['ended_at'] as String)?.toLocal();
            }
            _slQuality = ((t['quality'] ?? 3) as num).toInt();
            break;
          case 'mood':
            _mood = (t['value_text'] ?? '') as String?;
            _moodInt = ((t['value_number'] ?? 3) as num).toInt();
            break;
        }
      }

      setState(() {
        _now = DateTime.now();
        waterCups = _waterCups;
        exerciseMinutes = _exMin;
        exerciseCalories = _exKcal;
        exerciseType = _exType;
        sleepStartAt = _slStart;
        sleepEndAt = _slEnd;
        sleepQuality = _slQuality;
        moodEmoji = _mood?.isEmpty ?? true ? null : _mood;
        moodIntensity = _moodInt;
      });
    } catch (e) {
      debugPrint('load error: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadFromApi();
  }

  // ---------- Optimistic Save + Undo ----------
  Future<void> _safeSave(
    Future<void> Function() save,
    VoidCallback revert,
    String okText, {
    String? failText,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    _undoLast = revert;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: Palette.navy,
        content: Text(okText, style: const TextStyle(color: Colors.white)),
        action: SnackBarAction(
          textColor: Palette.mint,
          label: 'Undo',
          onPressed: () {
            _undoLast?.call();
            _undoLast = null;
            messenger.hideCurrentSnackBar();
          },
        ),
        duration: const Duration(seconds: 5),
      ),
    );

    try {
      await save();
    } catch (e) {
      revert();
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(failText ?? 'บันทึกไม่สำเร็จ: $e',
              style: const TextStyle(color: Colors.white)),
        ),
      );
    }
  }

  // ---------- น้ำ (แก้ว) ----------
  void _addWaterCups(int deltaCups) {
    final before = waterCups;
    setState(() => waterCups = (waterCups + deltaCups).clamp(0, 200));

    _safeSave(() async {
      final data = {
        'water': {
          'task_type': 'water',
          // เก็บ "จำนวนแก้วต่อวัน" เป็น value_number
          'value_number': waterCups.toDouble(),
          'completed': waterCups >= waterGoalCups,
        }
      };
      await DailyTaskApi.saveDailyTask(data, DateTime.now());
    }, () {
      setState(() => waterCups = before);
    }, 'บันทึกน้ำ ${deltaCups >= 0 ? "+" : ""}$deltaCups แก้ว');
  }

  // ---------- อารมณ์ ----------
  void _logMood(String emoji, {int intensity = 3}) {
    final beforeEmoji = moodEmoji;
    final beforeInt = moodIntensity;
    setState(() {
      moodEmoji = emoji;
      moodIntensity = intensity;
    });

    _safeSave(() async {
      final data = {
        'mood': {
          'task_type': 'mood',
          'value_text': emoji,
          'value_number': intensity.toDouble(),
          'completed': true,
        }
      };
      await DailyTaskApi.saveDailyTask(data, DateTime.now());
    }, () {
      setState(() {
        moodEmoji = beforeEmoji;
        moodIntensity = beforeInt;
      });
    }, 'บันทึกอารมณ์ $emoji');
  }

  // ---------- ออกกำลังกาย ----------
  void _toggleExerciseTimer() {
    if (_exerciseStopwatchOn) {
      final start = _exerciseStartAt;
      if (start != null) {
        final delta = DateTime.now().difference(start).inMinutes;
        if (delta > 0) {
          final beforeMin = exerciseMinutes;
          setState(() {
            _exerciseStopwatchOn = false;
            _exerciseStartAt = null;
            exerciseMinutes = beforeMin + delta;
          });

          _safeSave(() async {
            final data = {
              'exercise': {
                'task_type': 'exercise',
                'value_text': exerciseType.isEmpty ? 'ออกกำลังกาย' : exerciseType,
                'value_number': exerciseMinutes.toDouble(),
                'calories': exerciseCalories,
                'completed': exerciseMinutes >= 30,
              }
            };
            await DailyTaskApi.saveDailyTask(data, DateTime.now());
          }, () {
            setState(() {
              _exerciseStopwatchOn = false;
              _exerciseStartAt = null;
              exerciseMinutes = beforeMin;
            });
          }, 'บันทึกเวลาออกกำลังกาย +${delta}นาที');
        } else {
          setState(() {
            _exerciseStopwatchOn = false;
            _exerciseStartAt = null;
          });
        }
      }
    } else {
      setState(() {
        _exerciseStopwatchOn = true;
        _exerciseStartAt = DateTime.now();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เริ่มจับเวลาออกกำลังกาย')),
      );
    }
  }

  Future<void> _openExerciseSheet() async {
    await showQuickBottomSheet(
      context,
      ExerciseSheet(
        initialType: exerciseType,
        initialMinutes: exerciseMinutes,
        initialCalories: exerciseCalories,
        onSubmit: (type, mins, kcal) {
          final beforeType = exerciseType;
          final beforeMin = exerciseMinutes;
          final beforeKcal = exerciseCalories;

          setState(() {
            exerciseType = type;
            exerciseMinutes = mins;
            exerciseCalories = kcal;
          });

          _safeSave(() async {
            final data = {
              'exercise': {
                'task_type': 'exercise',
                'value_text': exerciseType,
                'value_number': exerciseMinutes.toDouble(),
                'calories': exerciseCalories,
                'completed': exerciseMinutes >= 30,
              }
            };
            await DailyTaskApi.saveDailyTask(data, DateTime.now());
          }, () {
            setState(() {
              exerciseType = beforeType;
              exerciseMinutes = beforeMin;
              exerciseCalories = beforeKcal;
            });
          }, 'บันทึกออกกำลังกาย ${type.isNotEmpty ? "($type)" : ""}');
        },
      ),
    );
  }

  // ---------- การนอน ----------
  void _sleepStartNow() {
    final before = sleepStartAt;
    setState(() => sleepStartAt = DateTime.now());
    _safeSave(() async {
      final data = {
        'sleep': {
          'task_type': 'sleep',
          'started_at': sleepStartAt!.toUtc().toIso8601String(),
          'ended_at': sleepEndAt?.toUtc().toIso8601String(),
          'quality': sleepQuality,
          'completed': false,
        }
      };
      await DailyTaskApi.saveDailyTask(data, DateTime.now());
    }, () {
      setState(() => sleepStartAt = before);
    }, 'เริ่มนอนตอนนี้');
  }

  void _wakeNow() {
    final before = sleepEndAt;
    setState(() => sleepEndAt = DateTime.now());
    _safeSave(() async {
      final data = {
        'sleep': {
          'task_type': 'sleep',
          'started_at': sleepStartAt?.toUtc().toIso8601String(),
          'ended_at': sleepEndAt!.toUtc().toIso8601String(),
          'quality': sleepQuality,
          'completed': true,
        }
      };
      await DailyTaskApi.saveDailyTask(data, DateTime.now());
    }, () {
      setState(() => sleepEndAt = before);
    }, 'ตื่นตอนนี้ (+${_sleepDurationInMinutes()} นาที)');
  }

  Future<void> _openSleepSheet() async {
    await showQuickBottomSheet(
      context,
      SleepSheet(
        startAt: sleepStartAt,
        endAt: sleepEndAt,
        quality: sleepQuality,
        onSubmit: (s, e, q) {
          final beforeS = sleepStartAt;
          final beforeE = sleepEndAt;
          final beforeQ = sleepQuality;

          setState(() {
            sleepStartAt = s;
            sleepEndAt = e;
            sleepQuality = q;
          });

          _safeSave(() async {
            final data = {
              'sleep': {
                'task_type': 'sleep',
                'started_at': sleepStartAt?.toUtc().toIso8601String(),
                'ended_at': sleepEndAt?.toUtc().toIso8601String(),
                'quality': sleepQuality,
                'completed': sleepEndAt != null && sleepStartAt != null,
              }
            };
            await DailyTaskApi.saveDailyTask(data, DateTime.now());
          }, () {
            setState(() {
              sleepStartAt = beforeS;
              sleepEndAt = beforeE;
              sleepQuality = beforeQ;
            });
          }, 'บันทึกการนอน');
        },
      ),
    );
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('EEE d MMM yyyy', 'th').format(_now);

    return Scaffold(
      backgroundColor: Colors.white, // เปลี่ยนเป็นสีขาว
      appBar: AppBar(
        backgroundColor: Colors.white, // เปลี่ยนเป็นสีขาว
        surfaceTintColor: Colors.transparent,
        foregroundColor: Palette.navy,
        title: const Text('วันนี้', style: TextStyle(color: Palette.navy)),
        centerTitle: true,
        elevation: 0,
        shadowColor: Palette.cardShadow.withOpacity(0.1),
      ),
      body: RefreshIndicator(
        color: Palette.teal,
        backgroundColor: Colors.white,
        onRefresh: _loadFromApi,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            // Header ความคืบหน้า
            Card(
              color: Palette.paper, // ใช้สีเทาอ่อนแทนสีขาว
              shadowColor: Palette.cardShadow.withOpacity(0.15), // เพิ่มความเข้มของเงา
              elevation: 3, // เพิ่ม elevation
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200, width: 1), // เพิ่มขอบ
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 64, height: 64,
                          child: CircularProgressIndicator(
                            value: overallProgress,
                            strokeWidth: 8,
                            valueColor: const AlwaysStoppedAnimation(Palette.teal),
                            backgroundColor: Palette.mint.withOpacity(0.35),
                          ),
                        ),
                        Text(
                          '${(overallProgress * 100).round()}%',
                          style: const TextStyle(
                            color: Palette.navy,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(dateText,
                              style: const TextStyle(
                                color: Palette.navy,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              )),
                          const SizedBox(height: 4),
                          Text(
                            'จบไปแล้ว ${_doneCount()}/4 งาน',
                            style: TextStyle(
                              color: Palette.navy.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Quick Actions
            Card(
              color: Palette.paper, // ใช้สีเทาอ่อนแทนสีขาว
              shadowColor: Palette.cardShadow.withOpacity(0.15), // เพิ่มความเข้มของเงา
              elevation: 3, // เพิ่ม elevation
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200, width: 1), // เพิ่มขอบ
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
                  children: [

                    _QuickAction(
                      icon: Icons.water_drop,
                      label: 'น้ำ +1 แก้ว',
                      onTap: () => _addWaterCups(1),
                    ),
                    _QuickAction(
                      icon: _exerciseStopwatchOn ? Icons.pause_circle : Icons.play_circle,
                      label: _exerciseStopwatchOn ? 'หยุดจับเวลา' : 'เริ่มจับเวลา',
                      onTap: _toggleExerciseTimer,
                    ),
                    _QuickAction(
                      icon: Icons.bedtime,
                      label: 'เริ่มนอน',
                      onTap: _sleepStartNow,
                    ),
                    _QuickAction(
                      icon: Icons.wb_sunny,
                      label: 'ตื่น',
                      onTap: _wakeNow,
                    ),

                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // การ์ดภารกิจ: น้ำ (แก้ว)
            HabitCard(
              icon: Icons.water_drop,
              title: 'น้ำดื่ม',
              progress: waterProgress,
              trailing: Text(
                '$waterCups/$waterGoalCups แก้ว',
                style: const TextStyle(color: Palette.navy),
              ),
              onTap: () => showQuickBottomSheet(
                context,
                WaterSheet(
                  currentCups: waterCups,
                  goalCups: waterGoalCups,
                  onAddCups: _addWaterCups,
                  onChangeGoalCups: (g) {
                    final before = waterGoalCups;
                    setState(() => waterGoalCups = g);
                    _safeSave(() async {
                      // หากต้อง sync goal ไป backend ให้เพิ่มที่นี่
                    }, () {
                      setState(() => waterGoalCups = before);
                    }, 'ตั้งเป้าน้ำ $g แก้ว', failText: 'ตั้งเป้าไม่สำเร็จ');
                  },
                ),
              ),
            ),

            HabitCard(
              icon: Icons.fitness_center,
              title: 'ออกกำลังกาย',
              progress: exerciseProgress,
              trailing: Text(
                '${exerciseMinutes}นาที${exerciseType.isNotEmpty ? " • $exerciseType" : ""}',
                style: const TextStyle(color: Palette.navy),
              ),
              onTap: _openExerciseSheet,
            ),

            HabitCard(
              icon: Icons.bedtime,
              title: 'การนอน',
              progress: sleepProgress,
              trailing: Text(
                _sleepText(),
                style: const TextStyle(color: Palette.navy),
              ),
              onTap: _openSleepSheet,
            ),

            HabitCard(
              icon: Icons.mood,
              title: 'อารมณ์',
              progress: moodEmoji == null ? 0 : 1,
              trailing: Text(
                moodEmoji ?? 'ยังไม่บันทึก',
                style: const TextStyle(color: Palette.navy),
              ),
              onTap: () => showQuickBottomSheet(
                context,
                MoodSheet(
                  onSelect: (e, i) => _logMood(e, intensity: i),
                  initialEmoji: moodEmoji,
                  initialIntensity: moodIntensity,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _doneCount() {
    var c = 0;
    if (waterCups >= waterGoalCups) c++;
    if (exerciseMinutes >= 30) c++;
    if (sleepStartAt != null && sleepEndAt != null) c++;
    if (moodEmoji != null) c++;
    return c;
  }

  String _sleepText() {
    final mins = _sleepDurationInMinutes();
    if (mins <= 0) {
      if (sleepStartAt != null && sleepEndAt == null) {
        return 'กำลังนอน…';
      }
      return 'ยังไม่บันทึก';
    }
    final h = (mins ~/ 60);
    final m = mins % 60;
    return '${h}ชม ${m}นาที • คุณภาพ $sleepQuality/5';
  }
}

// ======================================================================
// ===================== Reusable Widgets & Sheets =======================
// ======================================================================

class HabitCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget trailing;
  final double progress; // 0..1
  final VoidCallback? onTap;

  const HabitCard({
    super.key,
    required this.icon,
    required this.title,
    required this.trailing,
    this.progress = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Palette.paper, // ใช้สีเทาอ่อนแทนสีขาว
      shadowColor: Palette.cardShadow.withOpacity(0.15), // เพิ่มความเข้มของเงา
      elevation: 3, // เพิ่ม elevation
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1), // เพิ่มขอบ
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 44, height: 44,
                    child: CircularProgressIndicator(
                      value: progress.clamp(0, 1),
                      strokeWidth: 6,
                      valueColor: const AlwaysStoppedAnimation(Palette.teal),
                      backgroundColor: Palette.mint.withOpacity(0.35),
                    ),
                  ),
                  const Icon(Icons.circle, size: 0), // spacer
                  const Icon(Icons.circle, size: 0),
                  Icon(icon, size: 22, color: Palette.navy),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Palette.navy,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              DefaultTextStyle.merge(
                style: const TextStyle(color: Palette.navy),
                child: trailing,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Palette.teal.withOpacity(0.8), width: 1.5), // เพิ่มความเข้มของขอบ
      ),
      avatar: Icon(icon, size: 18, color: Palette.navy),
      backgroundColor: Palette.mint.withOpacity(0.6), // เพิ่มความเข้มของพื้นหลัง
      label: Text(label, style: const TextStyle(color: Palette.navy, fontWeight: FontWeight.w600)),
      onPressed: onTap,
      elevation: 2, // เพิ่ม elevation
      shadowColor: Palette.cardShadow.withOpacity(0.1),
    );
  }
}

// --------------------- BottomSheet Helper --------------------------

Future<void> showQuickBottomSheet(BuildContext context, Widget child) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16, right: 16, top: 16,
      ),
      child: child,
    ),
  );
}

// --------------------- Water Sheet (แก้ว) --------------------------

class WaterSheet extends StatefulWidget {
  final int currentCups;
  final int goalCups;
  final void Function(int deltaCups) onAddCups;
  final void Function(int newGoalCups) onChangeGoalCups;

  const WaterSheet({
    super.key,
    required this.currentCups,
    required this.goalCups,
    required this.onAddCups,
    required this.onChangeGoalCups,
  });

  @override
  State<WaterSheet> createState() => _WaterSheetState();
}

class _WaterSheetState extends State<WaterSheet> {
  late int _goal;

  @override
  void initState() {
    super.initState();
    _goal = widget.goalCups;
  }

  @override
  Widget build(BuildContext context) {
    final presets = [1, 2, 3]; // เพิ่มทีละ 1/2/3 แก้ว
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('น้ำดื่มวันนี้',
            style: TextStyle(
              color: Palette.navy,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            )),
        const SizedBox(height: 8),
        Text('${widget.currentCups}/${widget.goalCups} แก้ว',
            style: TextStyle(color: Palette.navy.withOpacity(0.9))),
        const SizedBox(height: 12),
        // ปุ่มเพิ่มแก้ว
        Wrap(
          spacing: 8, runSpacing: 8,
          children: presets.map((c) => ActionChip(
            backgroundColor: Palette.mint.withOpacity(0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Palette.teal.withOpacity(0.6)),
            ),
            label: Text('+${c} แก้ว', style: const TextStyle(color: Palette.navy)),
            onPressed: () => widget.onAddCups(c),
            elevation: 0,
          )).toList(),
        ),
        const SizedBox(height: 8),
        // ปุ่มลดแก้ว
        Wrap(
          spacing: 8, runSpacing: 8,
          children: presets.map((c) => ActionChip(
            backgroundColor: Palette.mint.withOpacity(0.35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Palette.teal.withOpacity(0.4)),
            ),
            label: Text('-${c} แก้ว', style: const TextStyle(color: Palette.navy)),
            onPressed: () => widget.onAddCups(-c),
            elevation: 0,
          )).toList(),
        ),
        const SizedBox(height: 16),
        // เป้าหมายต่อวัน (แก้ว)
        Row(
          children: [
            const Expanded(child: Text('ตั้งเป้าต่อวัน (แก้ว)', style: TextStyle(color: Palette.navy))),
            IconButton(
              onPressed: () => setState(() => _goal = (_goal - 1).clamp(1, 20)),
              icon: const Icon(Icons.remove, color: Palette.navy),
            ),
            Text('$_goal', style: const TextStyle(color: Palette.navy)),
            IconButton(
              onPressed: () => setState(() => _goal = (_goal + 1).clamp(1, 20)),
              icon: const Icon(Icons.add, color: Palette.navy),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Palette.teal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {
            widget.onChangeGoalCups(_goal);
            Navigator.pop(context);
          },
          child: const Text('บันทึก'),
        ),
      ],
    );
  }
}

// --------------------- Mood Sheet --------------------------

class MoodSheet extends StatefulWidget {
  final void Function(String emoji, int intensity) onSelect;
  final String? initialEmoji;
  final int initialIntensity;

  const MoodSheet({
    super.key,
    required this.onSelect,
    this.initialEmoji,
    this.initialIntensity = 3,
  });

  @override
  State<MoodSheet> createState() => _MoodSheetState();
}

class _MoodSheetState extends State<MoodSheet> {
  final emojis = const ["😄","🙂","😐","🙁","😫","🤩","😤"];
  late int _intensity;
  String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialEmoji;
    _intensity = widget.initialIntensity;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('วันนี้รู้สึกยังไง?',
            style: TextStyle(
              color: Palette.navy,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            )),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: emojis.map((e) {
            final on = _selected == e;
            return IconButton(
              onPressed: () => setState(() => _selected = e),
              icon: Text(e, style: TextStyle(fontSize: on ? 30 : 26)),
              tooltip: e,
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('ความเข้มข้น', style: TextStyle(color: Palette.navy)),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Palette.teal,
                  inactiveTrackColor: Palette.mint.withOpacity(0.5),
                  thumbColor: Palette.teal,
                  overlayColor: Palette.teal.withOpacity(0.2),
                ),
                child: Slider(
                  value: _intensity.toDouble(),
                  min: 1, max: 5, divisions: 4,
                  label: '$_intensity',
                  onChanged: (v) => setState(() => _intensity = v.round()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Palette.teal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _selected == null ? null : () {
            widget.onSelect(_selected!, _intensity);
            Navigator.pop(context);
          },
          child: const Text('บันทึก'),
        ),
      ],
    );
  }
}

// --------------------- Exercise Sheet --------------------------

class ExerciseSheet extends StatefulWidget {
  final String initialType;
  final int initialMinutes;
  final double initialCalories;
  final void Function(String type, int minutes, double calories) onSubmit;

  const ExerciseSheet({
    super.key,
    required this.initialType,
    required this.initialMinutes,
    required this.initialCalories,
    required this.onSubmit,
  });

  @override
  State<ExerciseSheet> createState() => _ExerciseSheetState();
}

class _ExerciseSheetState extends State<ExerciseSheet> {
  final types = const ['เดิน','วิ่ง','ยกเวท','โยคะ','ปั่นจักรยาน'];
  late String _type;
  late int _minutes;
  late double _kcal;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType.isEmpty ? 'เดิน' : widget.initialType;
    _minutes = widget.initialMinutes;
    _kcal = widget.initialCalories;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('ออกกำลังกายวันนี้',
            style: TextStyle(
              color: Palette.navy,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            )),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: types.map((t) => ChoiceChip(
            label: Text(t, style: const TextStyle(color: Palette.navy)),
            selected: _type == t,
            selectedColor: Palette.teal.withOpacity(0.8),
            backgroundColor: Palette.mint.withOpacity(0.4),
            onSelected: (_) => setState(() => _type = t),
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: (_type == t) ? Palette.teal : Palette.teal.withOpacity(0.4),
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            labelStyle: TextStyle(
              color: (_type == t) ? Colors.white : Palette.navy,
              fontWeight: FontWeight.w600,
            ),
          )).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('ระยะเวลา', style: TextStyle(color: Palette.navy)),
            const Spacer(),
            IconButton(
              onPressed: () => setState(() => _minutes = (_minutes - 5).clamp(0, 600)),
              icon: const Icon(Icons.remove, color: Palette.navy),
            ),
            Text('${_minutes}นาที', style: const TextStyle(color: Palette.navy)),
            IconButton(
              onPressed: () => setState(() => _minutes = (_minutes + 5).clamp(0, 600)),
              icon: const Icon(Icons.add, color: Palette.navy),
            ),
          ],
        ),
        Row(
          children: [
            const Text('แคลอรี่ (ไม่บังคับ)', style: TextStyle(color: Palette.navy)),
            const Spacer(),
            IconButton(
              onPressed: () => setState(() => _kcal = (_kcal - 10).clamp(0, 9999)),
              icon: const Icon(Icons.remove, color: Palette.navy),
            ),
            Text('${_kcal.round()} kcal', style: const TextStyle(color: Palette.navy)),
            IconButton(
              onPressed: () => setState(() => _kcal = (_kcal + 10).clamp(0, 9999)),
              icon: const Icon(Icons.add, color: Palette.navy),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Palette.teal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {
            widget.onSubmit(_type, _minutes, _kcal);
            Navigator.pop(context);
          },
          child: const Text('บันทึก'),
        ),
      ],
    );
  }
}

// --------------------- Sleep Sheet --------------------------

class SleepSheet extends StatefulWidget {
  final DateTime? startAt;
  final DateTime? endAt;
  final int quality;
  final void Function(DateTime? s, DateTime? e, int q) onSubmit;

  const SleepSheet({
    super.key,
    required this.startAt,
    required this.endAt,
    required this.quality,
    required this.onSubmit,
  });

  @override
  State<SleepSheet> createState() => _SleepSheetState();
}

class _SleepSheetState extends State<SleepSheet> {
  DateTime? _s;
  DateTime? _e;
  late int _q;

  @override
  void initState() {
    super.initState();
    _s = widget.startAt;
    _e = widget.endAt;
    _q = widget.quality;
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final now = DateTime.now();
    final base = isStart ? (_s ?? now) : (_e ?? now);
    final date = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: now.subtract(const Duration(days: 7)),
      lastDate: now.add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Palette.teal,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Palette.navy,
                ),
          ),
          child: child!,
        );
      },
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: const TimePickerThemeData(
              dialHandColor: Palette.teal,
              hourMinuteTextColor: Palette.navy,
              dialBackgroundColor: Color(0xFFEFF9F5),
            ),
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Palette.teal,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Palette.navy,
                ),
          ),
          child: child!,
        );
      },
    );
    if (time == null) return;

    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) _s = dt; else _e = dt;
    });
  }

  String _fmt(DateTime? d) {
    if (d == null) return '—';
    return DateFormat('d MMM HH:mm', 'th').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final mins = (_s != null && _e != null) ? _e!.difference(_s!).inMinutes : 0;
    final h = mins ~/ 60, m = mins % 60;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('การนอน',
            style: TextStyle(
              color: Palette.navy,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            )),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text('เริ่ม: ${_fmt(_s)}',
                  style: const TextStyle(color: Palette.navy)),
            ),
            TextButton.icon(
              onPressed: () => _pickDateTime(isStart: true),
              icon: const Icon(Icons.edit_calendar, color: Palette.navy),
              label: const Text('แก้ไข', style: TextStyle(color: Palette.navy)),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Text('ตื่น: ${_fmt(_e)}',
                  style: const TextStyle(color: Palette.navy)),
            ),
            TextButton.icon(
              onPressed: () => _pickDateTime(isStart: false),
              icon: const Icon(Icons.edit_calendar, color: Palette.navy),
              label: const Text('แก้ไข', style: TextStyle(color: Palette.navy)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('รวม: ${h}ชม ${m}นาที', style: const TextStyle(color: Palette.navy)),
        Row(
          children: [
            const Text('คุณภาพ', style: TextStyle(color: Palette.navy)),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Palette.teal,
                  inactiveTrackColor: Palette.mint.withOpacity(0.5),
                  thumbColor: Palette.teal,
                  overlayColor: Palette.teal.withOpacity(0.2),
                ),
                child: Slider(
                  value: _q.toDouble(),
                  min: 1, max: 5, divisions: 4,
                  label: '$_q',
                  onChanged: (v) => setState(() => _q = v.round()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Palette.teal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {
            widget.onSubmit(_s, _e, _q);
            Navigator.pop(context);
          },
          child: const Text('บันทึก'),
        ),
      ],
    );
  }
}
