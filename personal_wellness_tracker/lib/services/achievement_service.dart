import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/achievement.dart';

class AchievementService {
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  // Get user's achievements
  static Future<Map<String, dynamic>> getUserAchievements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        return {'success': false, 'message': 'No token found'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/achievements'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<Achievement> achievements = (data['data'] as List)
            .map((json) => Achievement.fromJson(json))
            .toList();
        
        return {
          'success': true,
          'achievements': achievements,
        };
      } else {
        return {'success': false, 'message': 'Failed to load achievements'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Initialize default achievements for a user
  static Future<Map<String, dynamic>> initializeUserAchievements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        return {'success': false, 'message': 'No token found'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/achievements/initialize'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        return {'success': false, 'message': 'Failed to initialize achievements'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Parse newly_achieved from StandardResponse.data
  static Future<Map<String, dynamic>> updateAchievementProgress({
    required String achievementType,
    required int progress,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        return {'success': false, 'message': 'No token found'};
      }

      final response = await http.put(
        Uri.parse('$baseUrl/achievements/update-progress'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'achievement_type': achievementType,
          'progress': progress,
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded['data'];
        final List<String> newly = (data is Map && data['newly_achieved'] is List)
            ? List<String>.from(data['newly_achieved'])
            : <String>[];
        return {
          'success': true,
          'message': decoded['message'],
          'newly_achieved': newly,
        };
      } else {
        return {'success': false, 'message': 'Failed to update progress'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // High-level: ensure default achievements exist (idempotent)
  static Future<void> ensureInitialized() async {
    try {
      await initializeUserAchievements();
    } catch (_) {}
  }

  // High-level: only once in lifetime (local flag)
  static Future<void> trackFirstRecordOnce(BuildContext context) async {
    // final prefs = await SharedPreferences.getInstance();
    // final done = prefs.getBool('achievement_first_record_done') ?? false;
    // if (done) return;

    final res = await trackFirstRecord();
    if (res['success'] == true) {
      // await prefs.setBool('achievement_first_record_done', true);
      _showUnlockedSnack(context, (res['newly_achieved'] as List?)?.cast<String>() ?? const []);
    }
  }

  // High-level: first time exercise minutes change from 0 -> >0 per day
  static Future<void> maybeTrackExerciseLogged(
    BuildContext context, {
    required int beforeMin,
    required int afterMin,
  }) async {
    if (!(beforeMin == 0 && afterMin > 0)) return;

    final prefs = await SharedPreferences.getInstance();
    final key = _todayKey('achievement_exercise_logged_');
    if (prefs.getBool(key) == true) return;

    final res = await trackExerciseLogged();
    if (res['success'] == true) {
      await prefs.setBool(key, true);
      _showUnlockedSnack(context, (res['newly_achieved'] as List?)?.cast<String>() ?? const []);
    }
  }

  // Call this immediately after a meal is successfully saved.
  static Future<void> maybeTrackMealLogged(BuildContext context) async {
    final res = await trackMealLogged();
    if (res['success'] == true) {
      _showUnlockedSnack(context, (res['newly_achieved'] as List?)?.cast<String>() ?? const []);
    }
  }

  static Future<void> maybeTrackDayComplete(
    BuildContext context, {
    required int prevDone,
    required int newDone,
  }) async {
    if (!(prevDone < 4 && newDone == 4)) return;

    final prefs = await SharedPreferences.getInstance();
    final key = _todayKey('achievement_day_complete_');
    if (prefs.getBool(key) == true) return;

    final res = await trackDayStreak(1);
    if (res['success'] == true) {
      await prefs.setBool(key, true);
      _showUnlockedSnack(context, (res['newly_achieved'] as List?)?.cast<String>() ?? const []);
    }
  }

  // --- helpers ---
  static String _todayKey(String prefix) {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$prefix$y$m$d';
  }

  static void _showUnlockedSnack(BuildContext context, List<String> names) {
    if (names.isEmpty) return;

    // Palette
    final bg = const Color(0xFFFFFFFF);
    final chipBg = const Color(0xFFCBF1F5);
    final border = const Color(0xFFF6F4F0);
    final accent = const Color(0xFF2E5077);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: bg,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: border, width: 2),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [chipBg, accent.withOpacity(0.2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(Icons.emoji_events_rounded, color: accent, size: 34),
              ),
              const SizedBox(height: 12),
              Text(
                'ยินดีด้วย!',
                style: TextStyle(
                  color: accent,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'คุณปลดล็อกความสำเร็จ',
                style: TextStyle(fontSize: 13, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              alignment: WrapAlignment.center,
              runSpacing: 8,
              children: names.map((n) {
                return Chip(
                  backgroundColor: chipBg,
                  shape: StadiumBorder(side: BorderSide(color: border)),
                  avatar: Icon(Icons.star_rounded, color: accent, size: 18),
                  label: Text(
                    n,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('ปิด'),
              ),
            ),
          ],
        );
      },
    );
  }

  // Track specific achievements based on user actions
  static Future<Map<String, dynamic>> trackMealLogged() {
    return updateAchievementProgress(
      achievementType: AchievementType.mealLogging.value,
      progress: 1,
    );
  }

  static Future<Map<String, dynamic>> trackExerciseLogged() {
    return updateAchievementProgress(
      achievementType: AchievementType.exerciseLogging.value,
      progress: 1,
    );
  }

  static Future<Map<String, dynamic>> trackFirstRecord() {
    return updateAchievementProgress(
      achievementType: AchievementType.firstRecord.value,
      progress: 1,
    );
  }

  static Future<Map<String, dynamic>> trackMealPlanned() {
    return updateAchievementProgress(
      achievementType: AchievementType.mealPlanning.value,
      progress: 1,
    );
  }

  static Future<Map<String, dynamic>> trackDayStreak(int streakDays) {
    return updateAchievementProgress(
      achievementType: AchievementType.streakDays.value,
      progress: streakDays,
    );
  }

  static Future<Map<String, dynamic>> trackGoalAchievement() {
    return updateAchievementProgress(
      achievementType: AchievementType.goalAchievement.value,
      progress: 1,
    );
  }

  // Check and show achievement notifications
  static Future<void> checkAndShowAchievements(List<String> newlyAchieved) async {
    if (newlyAchieved.isNotEmpty) {
      // Here you can implement notification or dialog showing
      // For now, just print to console
      for (String achievementName in newlyAchieved) {
        print('Achievement Unlocked: $achievementName');
      }
    }
  }
}
