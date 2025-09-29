import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:personal_wellness_tracker/app/daily_task_api.dart';
import '../services/achievement_service.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart'; // NEW: load user goals from backend

class Palette {
  static const navy = Color(0xFF2E5077); // ข้อความ/ไอคอนหลัก
  static const teal = Color(0xFF4DA1A9); // ปุ่มหลัก/แอ็กเซนต์
  static const mint = Color(0xFF79D7BE); // พื้นหลังชิป/แทร็ก
  static const paper = Color(
    0xFFF8F9FA,
  );
  static const cardShadow = Color(0xFF000000); // เงาการ์ด
}

class DailyPage extends StatefulWidget {
  const DailyPage({super.key});

  @override
  State<DailyPage> createState() => _DailyPageState();
}

class _DailyPageState extends State<DailyPage> {
  // Date being viewed/edited
  DateTime _selectedDate = DateTime.now();
  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  bool get _isViewingToday => _isSameDay(_selectedDate, DateTime.now());
  
  // NEW: API + user goals
  final ApiService _api = ApiService();
  int exerciseGoalMinutes = 0; // default; overridden by user_goals
  double sleepGoalHours = 0;  // default; overridden by user_goals

  // ---------- เป้า/ค่าวันนี้ ----------
  // น้ำ: เปลี่ยนเป็น "แก้ว"
  int waterGoalCups = 8; // เป้าหมายจาก user_goals.goal_water_intake (fallback 8)
  int waterCups = 0; // วันนี้ดื่มไปกี่แก้ว

  int exerciseMinutes = 0;
  bool _exerciseStopwatchOn = false;
  DateTime? _exerciseStartAt;
  String exerciseType = '';

  DateTime? sleepStartAt;
  DateTime? sleepEndAt;
  double sleepHours = 0; // NEW: store slept hours as number

  // NEW: planned wake time & ticker for live countdown
  DateTime? plannedWakeAt;
  Timer? _sleepTicker;
  void _startSleepTicker() {
    _sleepTicker?.cancel();
    _sleepTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {}); // update remaining time UI
    });
  }

  void _stopSleepTicker() {
    _sleepTicker?.cancel();
    _sleepTicker = null;
  }

  String? moodEmoji;
  int moodIntensity = 3;

  // NEW: ticker for live elapsed time update
  Timer? _exerciseTicker;
  void _startExerciseTicker() {
    _exerciseTicker?.cancel();
    _exerciseTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {}); // trigger rebuild to update elapsed time
    });
  }

  void _stopExerciseTicker() {
    _exerciseTicker?.cancel();
    _exerciseTicker = null;
  }

  // ---------- Progress ----------
  double get waterProgress => (waterCups / waterGoalCups).clamp(0, 1);
  double get exerciseProgress =>
      (exerciseMinutes / (exerciseGoalMinutes == 0 ? 1 : exerciseGoalMinutes)).clamp(0, 1); // NEW: use user goal
  double get sleepProgress {
    final mins = _sleepDurationInMinutes();
    final targetMins = (sleepGoalHours <= 0 ? 8.0 : sleepGoalHours) * 60.0; // NEW: use user goal
    return (mins / targetMins).clamp(0, 1);
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
  Future<void> _loadFromApi([DateTime? forDate]) async {
    try {
      final target = forDate ?? _selectedDate;
      final daily =
          await DailyTaskApi.getDailyTask(target) ??
          (_isSameDay(target, DateTime.now())
              ? await DailyTaskApi.ensureDailyTaskForToday()
              : null);
      if (!mounted) return;

      if (daily == null) {
        setState(() {
          _selectedDate = DateTime(target.year, target.month, target.day);
          waterCups = 0;
          exerciseMinutes = 0;
          exerciseType = '';
          sleepStartAt = null;
          sleepEndAt = null;
          sleepHours = 0;
          moodEmoji = null;
          moodIntensity = 3;
        });
        return;
      }

      final dailyTaskId = daily['id']?.toString();
      if (dailyTaskId == null) return;

      final tasks = await DailyTaskApi.getTasks(dailyTaskId);

      int _waterCups = 0;
      int _exMin = 0;
      String _exType = '';
      DateTime? _slStart, _slEnd;
      double _slHours = 0; // NEW
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
            _exType = (t['value_text'] ?? '') as String;
            break;
          case 'sleep':
            if (t['started_at'] != null) {
              _slStart = DateTime.tryParse(t['started_at'] as String)?.toLocal();
            }
            if (t['ended_at'] != null) {
              _slEnd = DateTime.tryParse(t['ended_at'] as String)?.toLocal();
            }
            // Read hours from task_quality; fallback to compute from duration
            final tq = t['task_quality'];
            if (tq != null) {
              final num? n = tq is num ? tq : num.tryParse(tq.toString());
              if (n != null) _slHours = n.toDouble();
            } else if (_slStart != null && _slEnd != null) {
              _slHours = _slEnd.difference(_slStart).inMinutes / 60.0;
            }
            break;
          case 'mood':
            _mood = (t['value_text'] ?? '') as String?;
            _moodInt = ((t['value_number'] ?? 3) as num).toInt();
            break;
        }
      }

      setState(() {
        _selectedDate = DateTime(target.year, target.month, target.day);
        waterCups = _waterCups;
        exerciseMinutes = _exMin;
        exerciseType = _exType;
        sleepStartAt = _slStart;
        sleepEndAt = _slEnd;
        sleepHours = _slHours; // NEW
        moodEmoji = _mood?.isEmpty ?? true ? null : _mood;
        moodIntensity = _moodInt;
      });
    } catch (e) {
      debugPrint('load error: $e');
    }
  }

  // NEW: Load current user and goals, then apply to page targets
  Future<void> _loadUserGoals() async {
    try {
      final user = await _api.getCurrentUser();
      final uid = (user['uid'] ?? user['id'])?.toString();
      if (uid == null) return;

      final goals = await _api.getUserGoals(uid);
      if (!mounted || goals == null) return;

      final int? w = (goals['goal_water_intake'] as num?)?.toInt();
      final int? ex = (goals['goal_exercise_minutes'] as num?)?.toInt();
      final double? sl = (goals['goal_sleep_hours'] as num?)?.toDouble();

      setState(() {
        if (w != null && w > 0) waterGoalCups = w.clamp(1, 200);
        if (ex != null && ex > 0) exerciseGoalMinutes = ex.clamp(1, 600);
        if (sl != null && sl > 0) sleepGoalHours = sl.clamp(1, 24);
      });
    } catch (e) {
      debugPrint('Failed to load user goals: $e');
      // Keep defaults on failure
    }
  }

  @override
  void initState() {
    super.initState();
    AchievementService.ensureInitialized();
    _loadFromApi(_selectedDate);
    _loadUserGoals(); // NEW: fetch user goals and apply targets
  }

  @override
  void dispose() {
    _stopExerciseTicker(); // NEW: ensure timer canceled
    _stopSleepTicker(); // NEW: ensure ticker canceled
    super.dispose();
  }

  // ---------- Optimistic Save + Undo ----------
  Future<void> _safeSave(
    Future<void> Function() save,
    VoidCallback revert,
    String okText, {
    String? failText,
  }) async {
    final messenger = ScaffoldMessenger.of(context);

    messenger.hideCurrentSnackBar();

    try {
      await save();
    } catch (e) {
      revert();
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(
            failText ?? 'บันทึกไม่สำเร็จ: $e',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  // ---------- น้ำ (แก้ว) ----------
  void _addWaterCups(int deltaCups) {
    final prevDone = _doneCount();
    final before = waterCups;
    setState(() => waterCups = (waterCups + deltaCups).clamp(0, 200));

    _safeSave(
      () async {
        final data = {
          'water': {
            'task_type': 'water',
            // เก็บ "จำนวนแก้วต่อวัน" เป็น value_number
            'value_number': waterCups.toDouble(),
            'completed': waterCups >= waterGoalCups,
          },
        };
        await DailyTaskApi.saveDailyTask(data, _selectedDate);
        if (_isViewingToday) {
          await AchievementService.trackFirstRecordOnce(context);
          await AchievementService.maybeTrackDayComplete(
            context,
            prevDone: prevDone,
            newDone: _doneCount(),
          );
        }
      },
      () {
        setState(() => waterCups = before);
      },
      'บันทึกน้ำ ${deltaCups >= 0 ? "+" : ""}$deltaCups แก้ว',
    );
  }

  // ---------- อารมณ์ ----------
  void _logMood(String emoji, {int intensity = 3}) {
    final prevDone = _doneCount();
    final beforeEmoji = moodEmoji;
    final beforeInt = moodIntensity;
    setState(() {
      moodEmoji = emoji;
      moodIntensity = intensity;
    });

    _safeSave(
      () async {
        final data = {
          'mood': {
            'task_type': 'mood',
            'value_text': emoji,
            'value_number': intensity.toDouble(),
            'completed': true,
          },
        };
        await DailyTaskApi.saveDailyTask(data, _selectedDate);
        if (_isViewingToday) {
          await AchievementService.trackFirstRecordOnce(context);
          await AchievementService.maybeTrackDayComplete(
            context,
            prevDone: prevDone,
            newDone: _doneCount(),
          );
        }
      },
      () {
        setState(() {
          moodEmoji = beforeEmoji;
          moodIntensity = beforeInt;
        });
      },
      'บันทึกอารมณ์ $emoji',
    );
  }

  // ---------- ออกกำลังกาย ----------
  void _toggleExerciseTimer() {
    if (_exerciseStopwatchOn) {
      final start = _exerciseStartAt;
      if (start != null) {
        final delta = DateTime.now().difference(start).inMinutes;
        if (delta > 0) {
          final prevDone = _doneCount();
          final beforeMin = exerciseMinutes;
          _stopExerciseTicker();
          setState(() {
            _exerciseStopwatchOn = false;
            _exerciseStartAt = null;
            exerciseMinutes = beforeMin + delta;
          });

          _safeSave(
            () async {
              final data = {
                'exercise': {
                  'task_type': 'exercise',
                  'value_text': exerciseType.isNotEmpty
                      ? exerciseType
                      : 'ออกกำลังกาย',
                  'value_number': exerciseMinutes.toDouble(),
                  'completed': exerciseMinutes >= exerciseGoalMinutes, // CHANGED
                },
              };
              await DailyTaskApi.saveDailyTask(data, _selectedDate);
              if (_isViewingToday) {
                await AchievementService.trackFirstRecordOnce(context);
                await AchievementService.maybeTrackExerciseLogged(
                  context,
                  beforeMin: beforeMin,
                  afterMin: exerciseMinutes,
                );
                await AchievementService.maybeTrackDayComplete(
                  context,
                  prevDone: prevDone,
                  newDone: _doneCount(),
                );
              }
            },
            () {
              setState(() {
                _exerciseStopwatchOn = false;
                _exerciseStartAt = null;
                exerciseMinutes = beforeMin;
              });
            },
            'บันทึกเวลาออกกำลังกาย +${delta}นาที',
          );
        } else {
          _stopExerciseTicker();
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
      _startExerciseTicker();
    }
  }

  Future<void> _openExerciseSheet() async {
    await showQuickBottomSheet(
      context,
      ExerciseSheet(
        initialType: exerciseType,
        initialMinutes: exerciseMinutes,
        onSubmit: (type, mins) {
          final prevDone = _doneCount();
          final beforeType = exerciseType;
          final beforeMin = exerciseMinutes;

          setState(() {
            exerciseType = type;
            exerciseMinutes = mins;
          });

          _safeSave(
            () async {
              final data = {
                'exercise': {
                  'task_type': 'exercise',
                  'value_text': exerciseType,
                  'value_number': exerciseMinutes.toDouble(),
                  'completed': exerciseMinutes >= exerciseGoalMinutes, // CHANGED
                },
              };
              await DailyTaskApi.saveDailyTask(data, _selectedDate);
              if (_isViewingToday) {
                await AchievementService.trackFirstRecordOnce(context);
                await AchievementService.maybeTrackExerciseLogged(
                  context,
                  beforeMin: beforeMin,
                  afterMin: exerciseMinutes,
                );
                await AchievementService.maybeTrackDayComplete(
                  context,
                  prevDone: prevDone,
                  newDone: _doneCount(),
                );
              }
            },
            () {
              setState(() {
                exerciseType = beforeType;
                exerciseMinutes = beforeMin;
              });
            },
            'บันทึกออกกำลังกาย ${type.isNotEmpty ? "($type)" : ""}',
          );
        },
      ),
    );
  }

  // ---------- การนอน ----------
  // Change: start sleep by selecting planned wake time and show countdown UI.
  Future<void> _startSleepPlannedFlow() async {
    final wake = await _pickWakeDateTime(
      initial: DateTime.now().add(const Duration(hours: 8)),
    );
    if (wake == null) return;

    final now = DateTime.now();
    if (!wake.isAfter(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: const Text(
            'เวลาตื่นต้องอยู่ในอนาคต',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
      return;
    }

    final beforeStart = sleepStartAt;
    final beforeEnd = sleepEndAt;
    final beforePlanned = plannedWakeAt;

    setState(() {
      sleepStartAt = now;
      sleepEndAt = null;
      plannedWakeAt = wake;
    });
    _startSleepTicker();

    await _safeSave(
      () async {
        final data = {
          'sleep': {
            'task_type': 'sleep',
            'started_at': sleepStartAt!.toUtc().toIso8601String(),
            'ended_at': null,
            'task_quality': null,
            'completed': false,
          },
        };
        await DailyTaskApi.saveDailyTask(data, _selectedDate);
        if (_isViewingToday) {
          await AchievementService.trackFirstRecordOnce(context);
        }
      },
      () {
        _stopSleepTicker();
        setState(() {
          sleepStartAt = beforeStart;
          sleepEndAt = beforeEnd;
          plannedWakeAt = beforePlanned;
        });
      },
      'เริ่มนอน (ตื่น ${DateFormat('d MMM HH:mm', 'th').format(wake)})',
    );
  }

  // NEW: open sleep options (timer vs manual hours)
  Future<void> _openSleepOptions() async {
    await showQuickBottomSheet(
      context,
      _SleepModeChooserSheet(
        onStartTimer: () {
          Navigator.pop(context);
          _startSleepPlannedFlow();
        },
        onQuickLog: () {
          Navigator.pop(context);
          showQuickBottomSheet(
            context,
            _ManualSleepHoursSheet(
              initialHours: sleepGoalHours > 0 ? sleepGoalHours : 8.0,
              onSave: (h) {
                Navigator.pop(context);
                _logSleepManual(h);
              },
            ),
          );
        },
      ),
    );
  }

  // NEW: manual log by hours for the currently selected date
  Future<void> _logSleepManual(double hours) async {
    final prevDone = _doneCount();

    final beforeStart = sleepStartAt;
    final beforeEnd = sleepEndAt;
    final beforePlan = plannedWakeAt;

    // End time: now for today; 07:00 of selected date otherwise
    final DateTime endAt = _isViewingToday
        ? DateTime.now()
        : DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 7, 0);
    final DateTime startAt =
        endAt.subtract(Duration(minutes: (hours * 60).round()));

    _stopSleepTicker();
    setState(() {
      sleepStartAt = startAt;
      sleepEndAt = endAt;
      plannedWakeAt = null;
      sleepHours = hours;
    });

    await _safeSave(
      () async {
        final data = {
          'sleep': {
            'task_type': 'sleep',
            'started_at': sleepStartAt!.toUtc().toIso8601String(),
            'ended_at': sleepEndAt!.toUtc().toIso8601String(),
            'task_quality': hours.toStringAsFixed(1),
            'completed': true,
          },
        };
        await DailyTaskApi.saveDailyTask(data, _selectedDate);
        if (_isViewingToday) {
          await AchievementService.trackFirstRecordOnce(context);
          await AchievementService.maybeTrackDayComplete(
            context,
            prevDone: prevDone,
            newDone: _doneCount(),
          );
        }
      },
      () {
        setState(() {
          sleepStartAt = beforeStart;
          sleepEndAt = beforeEnd;
          plannedWakeAt = beforePlan;
        });
      },
      'บันทึกการนอน ${hours.toStringAsFixed(1)} ชม.',
    );
  }

  // NEW: finalize sleep when countdown reached
  // CHANGED: accept optional endAt; allow finalize anytime (early/late).
  Future<void> _finalizePlannedWake([DateTime? endAt]) async {
    if (sleepStartAt == null) return;

    final prevDone = _doneCount();
    final DateTime finalEndAt = endAt ?? plannedWakeAt ?? DateTime.now();
    final beforeEnd = sleepEndAt;
    final beforePlanned = plannedWakeAt;

    _stopSleepTicker();
    setState(() {
      sleepEndAt = finalEndAt;
      plannedWakeAt = null;
    });

    // NEW: compute slept hours for saving and state
    final minutes = sleepEndAt!.difference(sleepStartAt!).inMinutes;
    final hours = (minutes / 60.0).clamp(0, 48).toDouble();

    await _safeSave(
      () async {
        final data = {
          'sleep': {
            'task_type': 'sleep',
            'started_at': sleepStartAt?.toUtc().toIso8601String(),
            'ended_at': sleepEndAt!.toUtc().toIso8601String(),
            // 'task_quality': sleepQuality, // OLD
            'task_quality': hours.toStringAsFixed(1), // NEW: store hours
            'completed': true,
          },
        };
        await DailyTaskApi.saveDailyTask(data, _selectedDate);
        if (_isViewingToday) {
          await AchievementService.trackFirstRecordOnce(context);
          await AchievementService.maybeTrackDayComplete(
            context,
            prevDone: prevDone,
            newDone: _doneCount(),
          );
        }
        // NEW: reflect to state after success
        if (mounted) setState(() => sleepHours = hours);
      },
      () {
        setState(() {
          sleepEndAt = beforeEnd;
          plannedWakeAt = beforePlanned;
        });
        if (plannedWakeAt != null && sleepEndAt == null) _startSleepTicker();
      },
      'ตื่นแล้ว (+${_sleepDurationInMinutes()} นาที)',
    );
  }

  // Optional: change planned wake time while counting down
  Future<void> _editPlannedWake() async {
    if (sleepStartAt == null) return;
    final newWake = await _pickWakeDateTime(
      initial: plannedWakeAt ?? DateTime.now().add(const Duration(hours: 8)),
    );
    if (newWake == null) return;
    if (!newWake.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: const Text(
            'เวลาตื่นต้องอยู่ในอนาคต',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
      return;
    }
    setState(() => plannedWakeAt = newWake);
  }

  // Helper: pick date & time for planned wake (styled like SleepSheet pickers)
  Future<DateTime?> _pickWakeDateTime({DateTime? initial}) async {
    final now = DateTime.now();
    final base = initial ?? now.add(const Duration(hours: 8));

    final date = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: now,
      lastDate: now.add(const Duration(days: 7)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4DA1A9), // ปุ่ม OK / ปุ่มลูกศร / เส้นเน้น
              onPrimary: Colors.white, // สีตัวอักษรบนปุ่ม OK
              surface: Colors.white, // พื้นหลังหลักของปฏิทิน
              onSurface: Color(0xFF2E5077), // ตัวเลขวันที่ + ข้อความ
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: Colors.white, // พื้นหลังของ Dialog
              headerBackgroundColor: Color(
                0xFF4DA1A9,
              ), // พื้นหลังส่วนหัวเดือน/ปี
              headerForegroundColor: Colors.white, // ตัวอักษรบนส่วนหัว
              todayForegroundColor: WidgetStateProperty.all(
                Color(0xFF2E5077),
              ), // สีตัวเลขวันที่วันนี้
              weekdayStyle: const TextStyle(
                color: Color(0xFF2E5077),
                fontWeight: FontWeight.w600,
              ),
              dayStyle: const TextStyle(color: Color(0xFF2E5077)),
            ),
          ),
          child: child!,
        );
      },
    );
    if (date == null) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
      initialEntryMode: TimePickerEntryMode.input,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: const Color(0xFF4DA1A9), // ปุ่ม OK/Cancel และเส้นเน้น
                onPrimary: Colors.white, // ตัวอักษรบนปุ่ม
                surface: Colors.white, // พื้นหลังหลักของ picker
                onSurface: const Color(0xFF2E5077), // สีข้อความ/ไอคอน
              ),

              timePickerTheme: TimePickerThemeData(
                backgroundColor: Colors.white, // พื้นหลัง dialog

                hourMinuteTextColor: const Color(0xFF2E5077),
                hourMinuteShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFF4DA1A9), width: 3),
                ),
                hourMinuteColor: const Color(0xFFFFFFFF),

                dialBackgroundColor: const Color.fromARGB(255, 224, 223, 223),
                dialHandColor: const Color(0xFF4DA1A9),
                dialTextColor: const Color(0xFF2E5077),

                entryModeIconColor: const Color(0xFF4DA1A9), // ไอคอนสลับโหมด

                helpTextStyle: const TextStyle(
                  color: Color(0xFF2E5077),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            child: child!,
          ),
        );
      },
    );
    if (time == null) return null;

    final picked = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    // Guard: ensure not in the past
    if (!picked.isAfter(now)) return null;
    return picked;
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('EEE d MMM yyyy', 'th').format(_selectedDate);
    // NEW: dynamic app bar title
    final appBarTitle = _isViewingToday ? 'วันนี้' : dateText;

    // NEW: overlay visibility helpers (only for today)
    final bool exerciseOverlayVisible =
        _isViewingToday && _exerciseStopwatchOn && _exerciseStartAt != null;
    final bool sleepOverlayVisible =
        _isViewingToday &&
        sleepStartAt != null &&
        sleepEndAt == null &&
        plannedWakeAt != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Palette.navy,
        title: Text(appBarTitle, style: const TextStyle(color: Palette.navy)),
        centerTitle: true,
        elevation: 0,
        shadowColor: Palette.cardShadow.withOpacity(0.1),
      ),
      // NEW: Wrap body with Stack and render timer bar when running
      body: Stack(
        children: [
          RefreshIndicator(
            color: Palette.teal,
            backgroundColor: Colors.white,
            onRefresh: () => _loadFromApi(_selectedDate),
            child: ListView(
              // NEW: dynamic bottom padding for overlays
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                24 +
                    (exerciseOverlayVisible ? 72 : 0) +
                    (sleepOverlayVisible ? 72 : 0),
              ),
              children: [
                // Header ความคืบหน้า
                Card(
                  color: Palette.paper, // ใช้สีเทาอ่อนแทนสีขาว
                  shadowColor: Palette.cardShadow.withOpacity(
                    0.15,
                  ), // เพิ่มความเข้มของเงา
                  elevation: 3, // เพิ่ม elevation
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1,
                    ), // เพิ่มขอบ
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 64,
                              height: 64,
                              child: CircularProgressIndicator(
                                value: overallProgress,
                                strokeWidth: 8,
                                valueColor: const AlwaysStoppedAnimation(
                                  Palette.teal,
                                ),
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
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _pickDay,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      dateText,
                                      style: const TextStyle(
                                        color: Palette.navy,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 65),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFFFFFFFF,
                                        ), // พื้นหลัง Mint
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: const Color(
                                            0xFF4DA1A9,
                                          ), // เส้นขอบ Teal
                                          width: 2,
                                        ),
                                      ),
                                      child: const Text(
                                        'สลับ',
                                        style: TextStyle(
                                          color: Palette.navy,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
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
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Quick Actions
                Card(
                  color: Palette.paper, // ใช้สีเทาอ่อนแทนสีขาว
                  shadowColor: Palette.cardShadow.withOpacity(
                    0.15,
                  ), // เพิ่มความเข้มของเงา
                  elevation: 3, // เพิ่ม elevation
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1,
                    ), // เพิ่มขอบ
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _QuickAction(
                          icon: Icons.water_drop,
                          label: 'น้ำ +1 แก้ว',
                          onTap: () => _addWaterCups(1),
                        ),
                        _QuickAction(
                          icon: _exerciseStopwatchOn
                              ? Icons.pause_circle
                              : Icons.play_circle,
                          label: _exerciseStopwatchOn
                              ? 'หยุดจับเวลา'
                              : 'เริ่มจับเวลา',
                          onTap: _toggleExerciseTimer,
                        ),
                        // Change: keep only "เริ่มนอน" and prompt for wake time
                        _QuickAction(
                          icon: Icons.bedtime,
                          label: 'เริ่มนอน',
                          onTap: _startSleepPlannedFlow,
                        ),
                        // Removed the "ตื่น" quick action
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
                        _safeSave(
                          () async {
                            // หากต้อง sync goal ไป backend ให้เพิ่มที่นี่
                          },
                          () {
                            setState(() => waterGoalCups = before);
                          },
                          'ตั้งเป้าน้ำ $g แก้ว',
                          failText: 'ตั้งเป้าไม่สำเร็จ',
                        );
                      },
                    ),
                  ),
                ),

                HabitCard(
                  icon: Icons.fitness_center,
                  title: 'ออกกำลังกาย',
                  progress: exerciseProgress,
                  trailing: Text(
                    '${exerciseMinutes}${exerciseGoalMinutes > 0 ? "/$exerciseGoalMinutes" : ""}นาที${exerciseType.isNotEmpty ? " • $exerciseType" : ""}',
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
                  onTap: _openSleepOptions, // CHANGED: open sleep options
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
          // Existing exercise timer overlay
          if (exerciseOverlayVisible)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _ExerciseTimerBar(
                elapsed: DateTime.now().difference(_exerciseStartAt!),
                onEdit: _openExerciseSheet,
                onStop: _toggleExerciseTimer,
              ),
            ),

          // NEW: Sleep countdown overlay; stack above exercise if both shown
          if (sleepOverlayVisible)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16 + (exerciseOverlayVisible ? 72 : 0),
              child: _SleepCountdownBar(
                remaining: plannedWakeAt!.difference(DateTime.now()),
                planned: plannedWakeAt!,
                onEdit: _editPlannedWake,
                // CHANGED: always allow pressing; finalize with "now"
                onWakeNow: () => _finalizePlannedWake(DateTime.now()),
              ),
            ),
        ],
      ),
    );
  }

  int _doneCount() {
    var c = 0;
    if (waterCups >= waterGoalCups) c++;
    if (exerciseMinutes >= exerciseGoalMinutes) c++; // CHANGED
    if (sleepStartAt != null && sleepEndAt != null) c++;
    if (moodEmoji != null) c++;
    return c;
  }

  String _sleepText() {
    final mins = _sleepDurationInMinutes();
    // NEW: format goal hours string
    String _goalHoursStr() {
      if (sleepGoalHours <= 0) return '';
      final isInt = sleepGoalHours == sleepGoalHours.roundToDouble();
      final v = isInt ? sleepGoalHours.toInt().toString() : sleepGoalHours.toStringAsFixed(1);
      return ' • ${v}ชม';
    }

    if (mins <= 0) {
      if (sleepStartAt != null && sleepEndAt == null) {
        return 'กำลังนอน…${_goalHoursStr()}';
      }
      return 'ยังไม่บันทึก${_goalHoursStr()}';
    }
    final h = (mins ~/ 60);
    final m = mins % 60;
    // Removed quality text; show total duration only
    return '${h}ชม ${m}นาที${_goalHoursStr()}';
  }

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4DA1A9),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF2E5077),
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: Colors.white,
              headerBackgroundColor: Color(0xFF4DA1A9),
              headerForegroundColor: Colors.white,
              todayForegroundColor: WidgetStateProperty.all(Color(0xFF2E5077)),
              weekdayStyle: const TextStyle(
                color: Color(0xFF2E5077),
                fontWeight: FontWeight.w600,
              ),
              dayStyle: const TextStyle(color: Color(0xFF2E5077)),
            ),
          ),         
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      await _loadFromApi(picked);
    }
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
                    width: 44,
                    height: 44,
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

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Palette.teal.withOpacity(0.8),
          width: 1.5,
        ), // เพิ่มความเข้มของขอบ
      ),
      avatar: Icon(icon, size: 18, color: Palette.navy),
      backgroundColor: Palette.mint.withOpacity(
        0.6,
      ), // เพิ่มความเข้มของพื้นหลัง
      label: Text(
        label,
        style: const TextStyle(
          color: Palette.navy,
          fontWeight: FontWeight.w600,
        ),
      ),
      onPressed: onTap,
      elevation: 2, // เพิ่ม elevation
      shadowColor: Palette.cardShadow.withOpacity(0.1),
    );
  }
}

// NEW: Minimal, well-organized exercise timer overlay bar
class _ExerciseTimerBar extends StatelessWidget {
  final Duration elapsed;
  final VoidCallback onEdit;
  final VoidCallback onStop;

  const _ExerciseTimerBar({
    required this.elapsed,
    required this.onEdit,
    required this.onStop,
  });

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    return h > 0 ? '${two(h)}:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(16),
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Palette.paper,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200, width: 1),
            boxShadow: [
              BoxShadow(
                color: Palette.cardShadow.withOpacity(0.12),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.timer, color: Palette.navy, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _fmt(elapsed),
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                    color: Palette.navy,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              // Icon-only edit (no text)
              OutlinedButton(
                onPressed: onEdit,
                style: OutlinedButton.styleFrom(
                  shape: const CircleBorder(),
                  minimumSize: const Size(40, 40),
                  side: BorderSide(
                    color: Palette.teal.withOpacity(0.6),
                    width: 1,
                  ),
                  foregroundColor: Palette.navy,
                  padding: EdgeInsets.zero,
                ),
                child: const Icon(Icons.edit, size: 18),
              ),
              const SizedBox(width: 6),
              // Icon-only stop (primary)
              FilledButton(
                onPressed: onStop,
                style: FilledButton.styleFrom(
                  backgroundColor: Palette.teal,
                  foregroundColor: Colors.white,
                  shape: const CircleBorder(),
                  minimumSize: const Size(44, 44),
                  padding: EdgeInsets.zero,
                ),
                child: const Icon(Icons.stop, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// NEW: Sleep countdown bar (minimal, similar to exercise bar)
class _SleepCountdownBar extends StatelessWidget {
  final Duration remaining;
  final DateTime planned;
  final VoidCallback onEdit;
  final VoidCallback onWakeNow;

  const _SleepCountdownBar({
    required this.remaining,
    required this.planned,
    required this.onEdit,
    required this.onWakeNow,
  });

  String _fmtDur(Duration d) {
    final isNeg = d.isNegative;
    final abs = isNeg ? -d : d;
    final h = abs.inHours;
    final m = abs.inMinutes % 60;
    final s = abs.inSeconds % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    final core = h > 0
        ? '${two(h)}:${two(m)}:${two(s)}'
        : '${two(m)}:${two(s)}';
    return isNeg ? '00:00:00' : core;
  }

  @override
  Widget build(BuildContext context) {
    final due = remaining <= Duration.zero;
    final plannedText = DateFormat('d MMM HH:mm', 'th').format(planned);

    return SafeArea(
      top: false,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(16),
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Palette.paper,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200, width: 1),
            boxShadow: [
              BoxShadow(
                color: Palette.cardShadow.withOpacity(0.12),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.bedtime, color: Palette.navy, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      due
                          ? 'ถึงเวลาตื่นแล้ว'
                          : 'เหลือเวลา ${_fmtDur(remaining)}',
                      style: const TextStyle(
                        color: Palette.navy,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      'ตื่น $plannedText',
                      style: TextStyle(
                        color: Palette.navy.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: onEdit,
                style: OutlinedButton.styleFrom(
                  shape: const CircleBorder(),
                  minimumSize: const Size(40, 40),
                  side: BorderSide(
                    color: Palette.teal.withOpacity(0.6),
                    width: 1,
                  ),
                  foregroundColor: Palette.navy,
                  padding: EdgeInsets.zero,
                ),
                child: const Icon(Icons.edit, size: 18),
              ),
              const SizedBox(width: 6),
              // CHANGED: enable button always (no disable when not due)
              FilledButton(
                onPressed: onWakeNow,
                style: FilledButton.styleFrom(
                  backgroundColor: Palette.teal,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                child: const Text('ตื่นแล้ว'),
              ),
            ],
          ),
        ),
      ),
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
        left: 16,
        right: 16,
        top: 16,
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
  // NEW: input controller for today's cups
  late final TextEditingController _cupsCtrl;
  late final FocusNode _cupsNode;

  @override
  void initState() {
    super.initState();
    // NEW: initialize with current cups
    _cupsCtrl = TextEditingController(text: widget.currentCups.toString());
    _cupsNode = FocusNode();
  }

  @override
  void dispose() {
    // NEW
    _cupsCtrl.dispose();
    _cupsNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final presets = [1, 2, 3]; // เพิ่มทีละ 1/2/3 แก้ว
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'น้ำดื่มวันนี้ (250 ml / แก้ว)',
          style: TextStyle(
            color: Palette.navy,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${widget.currentCups}/${widget.goalCups} แก้ว',
          style: TextStyle(color: Palette.navy.withOpacity(0.9)),
        ),

        const SizedBox(height: 14),

        // CHANGED: single centered numeric input (no +/- buttons)
        Align(
          alignment: Alignment.centerLeft,
          child: Text('จำนวนแก้ววันนี้', style: const TextStyle(color: Palette.navy)),
        ),
        const SizedBox(height: 6),
        Center(
          child: SizedBox(
            width: 140,
            child: TextField(
              controller: _cupsCtrl,
              focusNode: _cupsNode,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                color: Palette.navy,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Palette.teal, width: 2),
                ),
                suffixText: 'แก้ว',
              ),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // ปุ่มเพิ่มแก้ว
        Align(
          alignment: Alignment.centerLeft,
          child: Text('เพิ่มจำนวน', style: TextStyle(color: Palette.navy.withOpacity(0.9))),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: presets
              .map(
                (c) => ActionChip(
                  backgroundColor: Palette.mint.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Palette.teal.withOpacity(0.6)),
                  ),
                  label: Text(
                    '+${c} แก้ว',
                    style: const TextStyle(color: Palette.navy),
                  ),
                  onPressed: () => widget.onAddCups(c),
                  elevation: 0,
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),

        // ปุ่มลดแก้ว
        Align(
          alignment: Alignment.centerLeft,
          child: Text('ลดจำนวน', style: TextStyle(color: Palette.navy.withOpacity(0.9))),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: presets
              .map(
                (c) => ActionChip(
                  backgroundColor: Palette.mint.withOpacity(0.35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Palette.teal.withOpacity(0.4)),
                  ),
                  label: Text(
                    '-${c} แก้ว',
                    style: const TextStyle(color: Palette.navy),
                  ),
                  onPressed: () => widget.onAddCups(-c),
                  elevation: 0,
                ),
              )
              .toList(),
        ),

        const SizedBox(height: 16),

        // CHANGED: full-width Save button
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Palette.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onPressed: () {
              final entered = int.tryParse(_cupsCtrl.text) ?? widget.currentCups;
              final newCups = entered.clamp(0, 200);
              final delta = newCups - widget.currentCups;
              if (delta != 0) {
                widget.onAddCups(delta);
              }
              // เป้าหมายสามารถแก้ได้จากหน้า Goal แยกภายหลัง (ไม่เปลี่ยนที่นี่)
              Navigator.pop(context);
            },
            icon: const Icon(Icons.check),
            label: const Text('บันทึก'),
          ),
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
  final emojis = const ["😄", "🙂", "😐", "🙁", "😫", "🤩", "😤"];
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
        const Text(
          'วันนี้รู้สึกยังไง?',
          style: TextStyle(
            color: Palette.navy,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
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
        const SizedBox(height: 20),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Palette.teal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _selected == null
              ? null
              : () {
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
  final void Function(String type, int minutes) onSubmit; // UPDATED: drop calories

  const ExerciseSheet({
    super.key,
    required this.initialType,
    required this.initialMinutes,
    required this.onSubmit,
  });

  @override
  State<ExerciseSheet> createState() => _ExerciseSheetState();
}

class _ExerciseSheetState extends State<ExerciseSheet> {
  // REPLACED: fixed list -> dynamic list with defaults
  final List<String> _defaultTypes = const ['เดิน', 'วิ่ง', 'ยกเวท', 'โยคะ'];
  late List<String> _types;
  late String _type;
  late int _minutes;
  // REMOVED: late double _kcal;

  // NEW: persistent controller + focus node
  late final TextEditingController _minutesCtrl;
  late final FocusNode _minutesNode;
  // NEW: custom type controller
  late final TextEditingController _customTypeCtrl;

  @override
  void initState() {
    super.initState();
    _types = List.of(_defaultTypes);
    _type = widget.initialType.isEmpty ? 'เดิน' : widget.initialType;
    if (_type.isNotEmpty && !_types.contains(_type)) _types.add(_type);

    _minutes = widget.initialMinutes;

    _minutesCtrl = TextEditingController(text: '$_minutes');
    _minutesNode = FocusNode();
    _minutesCtrl.addListener(() {
      final n = int.tryParse(_minutesCtrl.text) ?? 0;
      if (n != _minutes) {
        setState(() => _minutes = n.clamp(0, 600));
      }
    });

    // NEW
    _customTypeCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _minutesCtrl.dispose();
    _minutesNode.dispose();
    // NEW
    _customTypeCtrl.dispose();
    super.dispose();
  }

  // NEW: add custom type helper
  void _addCustomType() {
    final t = _customTypeCtrl.text.trim();
    if (t.isEmpty) return;
    setState(() {
      if (!_types.contains(t)) _types.add(t);
      _type = t;
    });
    _customTypeCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    // Quick presets for minutes
    final presetMinutes = [15, 30, 45, 60];

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'ออกกำลังกายวันนี้',
            style: TextStyle(
              color: Palette.navy,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),

          // Section: ประเภท
          Row(
            children: const [
              Icon(Icons.category, color: Palette.navy, size: 18),
              SizedBox(width: 6),
              Text('ประเภทการออกกำลังกาย',
                  style: TextStyle(
                    color: Palette.navy,
                    fontWeight: FontWeight.w700,
                  )),
            ],
          ),
          const SizedBox(height: 8),

          // Custom type input first (unchanged behavior)
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customTypeCtrl,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addCustomType(),
                  decoration: InputDecoration(
                    hintText: 'เพิ่มประเภทเอง...',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  style: const TextStyle(color: Palette.navy),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _addCustomType,
                style: FilledButton.styleFrom(
                  backgroundColor: Palette.teal,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('เพิ่ม'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Type selection chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _types
                .map(
                  (t) => ChoiceChip(
                    label: Text(t,
                        style: const TextStyle(color: Palette.navy)),
                    selected: _type == t,
                    selectedColor: Palette.teal.withOpacity(0.8),
                    backgroundColor: Palette.mint.withOpacity(0.4),
                    onSelected: (_) => setState(() => _type = t),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: (_type == t)
                            ? Palette.teal
                            : Palette.teal.withOpacity(0.4),
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    labelStyle: TextStyle(
                      color: (_type == t) ? Colors.white : Palette.navy,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
                .toList(),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Section: ระยะเวลา
          Row(
            children: const [
              Icon(Icons.timer, color: Palette.navy, size: 18),
              SizedBox(width: 6),
              Text('ระยะเวลา',
                  style: TextStyle(
                    color: Palette.navy,
                    fontWeight: FontWeight.w700,
                  )),
            ],
          ),
          const SizedBox(height: 8),

          // Minutes controls
          Row(
            children: [
              const Spacer(),
              IconButton(
                onPressed: () {
                  setState(() => _minutes = (_minutes - 5).clamp(0, 600));
                  _minutesCtrl.text = '$_minutes';
                  _minutesCtrl.selection = TextSelection.collapsed(
                    offset: _minutesCtrl.text.length,
                  );
                },
                icon: const Icon(Icons.remove, color: Palette.navy),
              ),
              SizedBox(
                width: 120,
                child: TextField(
                  key: const ValueKey('exercise_minutes_input'),
                  controller: _minutesCtrl,
                  focusNode: _minutesNode,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(color: Palette.navy),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    border: OutlineInputBorder(),
                    suffixText: 'นาที',
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() => _minutes = (_minutes + 5).clamp(0, 600));
                  _minutesCtrl.text = '$_minutes';
                  _minutesCtrl.selection = TextSelection.collapsed(
                    offset: _minutesCtrl.text.length,
                  );
                },
                icon: const Icon(Icons.add, color: Palette.navy),
              ),
            ],
          ),

          // Quick presets
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.center,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: presetMinutes
                  .map(
                    (m) => ActionChip(
                      label: Text('$m นาที',
                          style: const TextStyle(color: Palette.navy)),
                      backgroundColor: Palette.mint.withOpacity(0.45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                            color: Palette.teal.withOpacity(0.6), width: 1),
                      ),
                      onPressed: () {
                        setState(() => _minutes = m);
                        _minutesCtrl.text = '$_minutes';
                        _minutesCtrl.selection = TextSelection.collapsed(
                          offset: _minutesCtrl.text.length,
                        );
                      },
                    ),
                  )
                  .toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Full-width Save button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Palette.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onPressed: () {
                widget.onSubmit(_type, _minutes);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.check),
              label: const Text('บันทึก'),
            ),
          ),
        ],
      ),
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
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: Theme(
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
          ),
        );
      },
    );
    if (time == null) return;

    final dt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {
      if (isStart)
        _s = dt;
      else
        _e = dt;
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
        const Text(
          'การนอน',
          style: TextStyle(
            color: Palette.navy,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                'เริ่ม: ${_fmt(_s)}',
                style: const TextStyle(color: Palette.navy),
              ),
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
              child: Text(
                'ตื่น: ${_fmt(_e)}',
                style: const TextStyle(color: Palette.navy),
              ),
            ),
            TextButton.icon(
              onPressed: () => _pickDateTime(isStart: false),
              icon: const Icon(Icons.edit_calendar, color: Palette.navy),
              label: const Text('แก้ไข', style: TextStyle(color: Palette.navy)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'รวม: ${h}ชม ${m}นาที',
          style: const TextStyle(color: Palette.navy),
        ),
        Row(
          children: [
            const Text('คุณภาพ', style: TextStyle(color: Palette.navy)),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Palette.teal,
                  inactiveTrackColor: Palette.mint.withOpacity(0.5),
                  thumbColor: Palette.teal,
                  overlayColor: Palette.teal.withOpacity(0.15),
                ),
                child: Slider(
                  value: _q.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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

// NEW: Sleep options chooser sheet
class _SleepModeChooserSheet extends StatelessWidget {
  final VoidCallback onStartTimer;
  final VoidCallback onQuickLog;

  const _SleepModeChooserSheet({
    required this.onStartTimer,
    required this.onQuickLog,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'บันทึกการนอน',
          style: TextStyle(
            color: Palette.navy,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        ListTile(
          leading: const Icon(Icons.play_circle_fill, color: Palette.navy),
          title: const Text('จับเวลาการนอน', style: TextStyle(color: Palette.navy)),
          subtitle: const Text('เลือกเวลาตื่นล่วงหน้าแล้วเริ่มนอน',
              style: TextStyle(color: Palette.navy)),
          onTap: onStartTimer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        const SizedBox(height: 6),
        ListTile(
          leading: const Icon(Icons.schedule, color: Palette.navy),
          title: const Text('กรอกจำนวนชั่วโมงด้วยตัวเอง', style: TextStyle(color: Palette.navy)),
          subtitle: const Text('ระบุจำนวนชั่วโมงที่นอนแล้วบันทึกทันที',
              style: TextStyle(color: Palette.navy)),
          onTap: onQuickLog,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ],
    );
  }
}

// NEW: Manual hours input sheet
class _ManualSleepHoursSheet extends StatefulWidget {
  final double initialHours;
  final void Function(double hours) onSave;

  const _ManualSleepHoursSheet({
    required this.initialHours,
    required this.onSave,
  });

  @override
  State<_ManualSleepHoursSheet> createState() => _ManualSleepHoursSheetState();
}

class _ManualSleepHoursSheetState extends State<_ManualSleepHoursSheet> {
  late double _hours;
  late final TextEditingController _ctrl;
  late final FocusNode _node;

  @override
  void initState() {
    super.initState();
    _hours = widget.initialHours.clamp(0.5, 24);
    _ctrl = TextEditingController(text: _hours.toStringAsFixed(1));
    _node = FocusNode();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _node.dispose();
    super.dispose();
  }

  void _syncFromText() {
    final t = _ctrl.text.replaceAll(',', '.');
    final v = double.tryParse(t);
    if (v == null) return;
    setState(() {
      _hours = v.clamp(0.5, 24.0);
      _ctrl.text = _hours.toStringAsFixed(1);
      _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
    });
  }

  void _setHours(double v) {
    setState(() {
      _hours = v.clamp(0.5, 24.0);
      _ctrl.text = _hours.toStringAsFixed(1);
      _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    final quicks = <double>[6, 7, 8, 9];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'กรอกจำนวนชั่วโมงที่นอน',
          style: TextStyle(
            color: Palette.navy,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 14),

        // Input
        TextField(
          controller: _ctrl,
          focusNode: _node,
          textAlign: TextAlign.center,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
          ],
          onChanged: (_) => _syncFromText(),
          style: const TextStyle(
            color: Palette.navy,
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
          decoration: InputDecoration(
            hintText: 'เช่น 7.5',
            suffixText: 'ชม.',
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Palette.teal, width: 2),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Slider
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Palette.teal,
            inactiveTrackColor: Palette.mint.withOpacity(0.5),
            thumbColor: Palette.teal,
            overlayColor: Palette.teal.withOpacity(0.15),
            valueIndicatorColor: Palette.teal,
            valueIndicatorTextStyle: const TextStyle(color: Colors.white),
          ),
          child: Slider(
            min: 0.5,
            max: 24.0,
            divisions: 47, // step 0.5
            label: '${_hours.toStringAsFixed(1)} ชม.',
            value: _hours.clamp(0.5, 24.0),
            onChanged: (v) => _setHours((v * 2).round() / 2.0), // snap to 0.5
          ),
        ),

        // Quick chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: quicks.map((v) {
            final sel = (_hours - v).abs() < 0.01;
            return ChoiceChip(
              label: Text('${v.toStringAsFixed(0)} ชม.',
                  style: TextStyle(
                    color: sel ? Colors.white : Palette.navy,
                    fontWeight: FontWeight.w600,
                  )),
              selected: sel,
              selectedColor: Palette.teal,
              backgroundColor: Palette.mint.withOpacity(0.45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: sel ? Palette.teal : Palette.teal.withOpacity(0.5),
                ),
              ),
              onSelected: (_) => _setHours(v),
            );
          }).toList(),
        ),

        const SizedBox(height: 8),
        Text(
          'แนะนำ: 6-8 ชม.',
          style: TextStyle(color: Palette.navy.withOpacity(0.7), fontSize: 12),
        ),

        const SizedBox(height: 14),

        // Save
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            icon: const Icon(Icons.check),
            label: const Text('บันทึก'),
            style: FilledButton.styleFrom(
              backgroundColor: Palette.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onPressed: () => widget.onSave(_hours),
          ),
        ),
      ],
    );
  }
}

