// lib/app/daily_task_api.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/auth_service.dart';

class DailyTaskApi {
  DailyTaskApi._();

  static const _timeout = Duration(seconds: 15);

  // ---- Base URL ----
  static String get _host {
    if (kIsWeb) return 'localhost';
    if (Platform.isAndroid)
      return '10.0.2.2'; // Android emulator → host machine
    return 'localhost';
  }

  static Uri _api(String path, [Map<String, dynamic>? q]) =>
      Uri.parse('http://$_host:8000$path').replace(queryParameters: q);

  // ---- Token & User Id ----
  static Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<String?> _getUserId() async {
    final user = await AuthService.getCurrentUser();
    if (user['success'] == true && user['user'] != null) {
      return user['user']['uid']?.toString();
    }
    return null;
  }

  // ---- Helpers ----
  static Map<String, dynamic> _safeDecode(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : {'data': decoded};
    } catch (_) {
      return {'message': body};
    }
  }

  static String _fmt(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  // =========================
  //  GET /users/{user_id}/daily-tasks/{task_date}
  //  (คืน Map หรือ null ถ้าไม่พบ)
  // =========================
  static Future<Map<String, dynamic>?> getDailyTask(DateTime date) async {
    final token = await _getAccessToken();
    final userId = await _getUserId();
    if (token == null || userId == null) return null;

    final d = _fmt(date);
    final url = _api('/users/$userId/daily-tasks/$d');

    try {
      final res = await http
          .get(url, headers: {'Authorization': 'Bearer $token'})
          .timeout(_timeout);

      if (res.statusCode == 200) {
        final data = _safeDecode(res.body);
        if (data.isEmpty) return null;
        return data;
      }
      if (res.statusCode == 404) return null;

      throw Exception(
        'Failed to load daily task: ${res.statusCode} ${res.body}',
      );
    } catch (e) {
      print('Error getting daily task: $e');
      return null;
    }
  }

  // =========================
  //  ENSURE: สร้าง daily task ถ้ายังไม่มี
  //  คืน Map ของ daily task (ต้องมี field 'id')
  // =========================
  static Future<Map<String, dynamic>> ensureDailyTaskForDate(
    DateTime date,
  ) async {
    final token = await _getAccessToken();
    final userId = await _getUserId();
    if (token == null) {
      throw Exception('No access token');
    }
    if (userId == null) {
      throw Exception('No user id');
    }

    // ถ้ามีอยู่แล้ว คืนเลย
    final existing = await getDailyTask(date);
    if (existing != null && existing['id'] != null) {
      return existing;
    }

    // ไม่มี → สร้างใหม่
    final d = _fmt(date);
    final createUrl = _api('/users/$userId/daily-tasks/');
    final createRes = await http
        .post(
          createUrl,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'date': d}),
        )
        .timeout(_timeout);

    if (createRes.statusCode < 200 || createRes.statusCode >= 300) {
      throw Exception(
        'Failed to create daily task: ${createRes.statusCode} ${createRes.body}',
      );
    }

    final created = _safeDecode(createRes.body);
    if (created['id'] == null) {
      throw Exception('Daily task created but no id returned');
    }
    return created;
  }

  static Future<Map<String, dynamic>> ensureDailyTaskForToday() async {
    final now = DateTime.now();
    return ensureDailyTaskForDate(DateTime(now.year, now.month, now.day));
  }

  // =========================
  //  POST /users/{user_id}/daily-tasks/
  //  สร้าง daily task ใหม่ (ถ้ายังไม่มี) หรือ update tasks ที่มีอยู่
  // =========================
  static Future<Map<String, dynamic>?> saveDailyTask(
    Map<String, dynamic> taskData,
    DateTime date,
  ) async {
    final token = await _getAccessToken();
    if (token == null) throw Exception('No access token');

    try {
      final ensured = await ensureDailyTaskForDate(date);
      final dailyTaskId = ensured['id']?.toString();
      if (dailyTaskId == null || dailyTaskId.isEmpty) {
        throw Exception('ensureDailyTaskForDate returned invalid id');
      }

      // อัปเดต/สร้าง tasks ตาม taskData
      await _updateExistingTasks(dailyTaskId, taskData, token);
      return ensured;
    } catch (e) {
      print('Error saving daily task: $e');
      rethrow;
    }
  }

  // =========================
  //  สร้าง/อัปเดต task เดี่ยว โดย ensure daily task ให้ก่อน
  // =========================
  static Future<void> addOrUpdateTaskForDate({
    required String taskType,
    required dynamic value,
    required DateTime date,
  }) async {
    final token = await _getAccessToken();
    if (token == null) throw Exception('No access token');

    final ensured = await ensureDailyTaskForDate(date);
    final dailyTaskId = ensured['id']?.toString();
    if (dailyTaskId == null || dailyTaskId.isEmpty) {
      throw Exception('ensureDailyTaskForDate returned invalid id');
    }

    // ดึง tasks เดิม แล้วอัปเดตเฉพาะ taskType นี้
    try {
      final tasksUrl = _api('/daily-tasks/$dailyTaskId/tasks/');
      final tasksRes = await http
          .get(tasksUrl, headers: {'Authorization': 'Bearer $token'})
          .timeout(_timeout);

      if (tasksRes.statusCode == 200) {
        final decoded = jsonDecode(tasksRes.body);
        final List<dynamic> tasksListDynamic = decoded is List
            ? decoded
            : (decoded is Map<String, dynamic> && decoded['data'] is List
                  ? decoded['data'] as List
                  : <dynamic>[]);
        final List<Map<String, dynamic>> tasksList = tasksListDynamic
            .whereType<Map<String, dynamic>>()
            .toList();

        Map<String, dynamic>? existingTask;
        for (final t in tasksList) {
          if (t['task_type'] == taskType) {
            existingTask = t;
            break;
          }
        }

        if (existingTask != null) {
          final id = existingTask['id']?.toString();
          if (id != null && id.isNotEmpty) {
            await _updateTask(id, taskType, value, token);
          } else {
            await _createTasks(dailyTaskId, {taskType: value}, token);
          }
        } else {
          await _createTasks(dailyTaskId, {taskType: value}, token);
        }
      } else {
        throw Exception(
          'Error fetching tasks for dailyTaskId=$dailyTaskId: '
          '${tasksRes.statusCode} ${tasksRes.body}',
        );
      }
    } catch (e) {
      print('Error addOrUpdateTaskForDate: $e');
      rethrow;
    }
  }

  // Helper method สำหรับสร้าง tasks ใหม่
  static Future<void> _createTasks(
    String dailyTaskId,
    Map<String, dynamic> taskData,
    String token,
  ) async {
    final tasksUrl = _api('/tasks/');

    for (final entry in taskData.entries) {
      final value = entry.value;

      // รองรับทั้ง Map และ Primitive
      String? valueText;
      double? valueNumber;
      bool completed = false;
      String? taskQuality;
      DateTime? startedAt;
      DateTime? endedAt;

      if (value is Map<String, dynamic>) {
        valueText = value['value_text']?.toString();
        if (value['value_number'] != null) {
          valueNumber = (value['value_number'] as num).toDouble();
        }
        completed = value['completed'] == true;

        taskQuality = value['task_quality']?.toString();

        if (value['started_at'] != null) {
          startedAt = DateTime.tryParse(value['started_at'].toString());
        }

        if (value['ended_at'] != null) {
          endedAt = DateTime.tryParse(value['ended_at'].toString());
        } 
      } else {
        valueText = value is String ? value : null;
        valueNumber = value is num ? value.toDouble() : null;
        completed = value is bool ? value : false;
        taskQuality = value is String ? value : null;
        startedAt = null;
        endedAt = null;
      }

      final taskBody = jsonEncode({
        'daily_task_id': dailyTaskId,
        'task_type': entry.key,
        'value_text': valueText,
        'value_number': valueNumber,
        'completed': completed,
        'task_quality': taskQuality,
        'started_at': startedAt?.toIso8601String(),
        'ended_at': endedAt?.toIso8601String(),
      });

      final taskRes = await http
          .post(
            tasksUrl,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: taskBody,
          )
          .timeout(_timeout);

      if (taskRes.statusCode < 200 || taskRes.statusCode >= 300) {
        print(
          'Failed to create task ${entry.key}: ${taskRes.statusCode} ${taskRes.body}',
        );
      }
    }
  }

  // Helper method สำหรับอัปเดต tasks ที่มีอยู่
  static Future<void> _updateExistingTasks(
    String dailyTaskId,
    Map<String, dynamic> taskData,
    String token,
  ) async {
    try {
      // ดึง tasks ที่มีอยู่
      final tasksUrl = _api('/daily-tasks/$dailyTaskId/tasks/');
      final tasksRes = await http
          .get(tasksUrl, headers: {'Authorization': 'Bearer $token'})
          .timeout(_timeout);

      if (tasksRes.statusCode == 200) {
        final decoded = jsonDecode(tasksRes.body);

        final List<dynamic> tasksListDynamic = decoded is List
            ? decoded
            : (decoded is Map<String, dynamic> && decoded['data'] is List
                  ? decoded['data'] as List
                  : <dynamic>[]);

        // บังคับเป็น List<Map<String, dynamic>>
        final List<Map<String, dynamic>> tasksList = tasksListDynamic
            .whereType<Map<String, dynamic>>()
            .toList();

        // อัปเดตหรือสร้าง tasks ใหม่
        for (final entry in taskData.entries) {
          Map<String, dynamic>? existingTask;

          for (final t in tasksList) {
            if (t['task_type'] == entry.key) {
              existingTask = t;
              break;
            }
          }

          if (existingTask != null) {
            final id = existingTask['id']?.toString();
            if (id != null && id.isNotEmpty) {
              await _updateTask(id, entry.key, entry.value, token);
            } else {
              // safety fallback: ถ้า id ไม่ถูกต้อง ให้สร้างใหม่
              await _createTasks(dailyTaskId, {entry.key: entry.value}, token);
            }
          } else {
            // ไม่มี task ประเภทนี้ → สร้างใหม่
            await _createTasks(dailyTaskId, {entry.key: entry.value}, token);
          }
        }
      } else {
        print(
          'Error fetching tasks for dailyTaskId=$dailyTaskId: '
          '${tasksRes.statusCode} ${tasksRes.body}',
        );
      }
    } catch (e) {
      print('Error updating existing tasks: $e');
    }
  }

  // Helper method สำหรับอัปเดต task เดี่ยว
  static Future<void> _updateTask(
    String taskId,
    String taskType,
    dynamic value,
    String token,
  ) async {
    String? valueText;
    double? valueNumber;
    bool completed = false;
    String? taskQuality;
    DateTime? startedAt;
    DateTime? endedAt;

    if (value is Map<String, dynamic>) {
      valueText = value['value_text']?.toString();
      if (value['value_number'] != null) {
        valueNumber = (value['value_number'] as num).toDouble();
      }
      completed = value['completed'] == true;

      taskQuality = value['task_quality']?.toString();

      if (value['started_at'] != null) {
        startedAt = DateTime.tryParse(value['started_at'].toString());
      }
      if (value['ended_at'] != null) {
        endedAt = DateTime.tryParse(value['ended_at'].toString());
      } 
    } else {
      valueText = value is String ? value : null;
      valueNumber = value is num ? value.toDouble() : null;
      completed = value is bool ? value : false;
      taskQuality = value is String ? value : null;
      startedAt = null;
      endedAt = null;
    }

    final updateUrl = _api('/tasks/$taskId');
    final updateBody = jsonEncode({
      'task_type': taskType,
      'value_text': valueText,
      'value_number': valueNumber,
      'completed': completed,
      'task_quality': taskQuality,
      'started_at': startedAt?.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
    });

    final updateRes = await http
        .put(
          updateUrl,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: updateBody,
        )
        .timeout(_timeout);

    if (updateRes.statusCode < 200 || updateRes.statusCode >= 300) {
      print(
        'Failed to update task $taskId: ${updateRes.statusCode} ${updateRes.body}',
      );
    }
  }

  static Future<void> deleteTaskById(String taskId) async {
    final token = await _getAccessToken();
    if (token == null) throw Exception('No access token');
    final url = _api('/tasks/$taskId');
    final res = await http
        .delete(url, headers: {'Authorization': 'Bearer $token'})
        .timeout(_timeout);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Failed to delete task: ${res.statusCode} ${res.body}');
    }
  }

  // =========================
  //  GET /daily-tasks/{daily_task_id}/tasks/
  //  ดึง tasks ทั้งหมดของ daily task
  // =========================
  static Future<List<Map<String, dynamic>>> getTasks(String dailyTaskId) async {
    final token = await _getAccessToken();
    if (token == null) return [];

    final url = _api('/daily-tasks/$dailyTaskId/tasks/');

    try {
      final res = await http
          .get(url, headers: {'Authorization': 'Bearer $token'})
          .timeout(_timeout);

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);

        final List<dynamic> listDynamic = decoded is List
            ? decoded
            : (decoded is Map<String, dynamic> && decoded['data'] is List
                  ? decoded['data'] as List
                  : <dynamic>[]);

        return listDynamic.whereType<Map<String, dynamic>>().toList();
      }
      return [];
    } catch (e) {
      print('Error getting tasks: $e');
      return [];
    }
  }

  // =========================
  //  GET specific task by type and date
  // =========================
  static Future<Map<String, dynamic>?> getTaskForDate({
    required String taskType,
    required DateTime date,
  }) async {
    final token = await _getAccessToken();
    final userId = await _getUserId();
    if (token == null || userId == null) return null;

    try {
      final dailyTask = await getDailyTask(date);
      if (dailyTask == null || dailyTask['id'] == null) return null;

      final dailyTaskId = dailyTask['id'].toString();
      final tasks = await getTasks(dailyTaskId);

      for (final task in tasks) {
        if (task['task_type'] == taskType) {
          return task;
        }
      }
      return null;
    } catch (e) {
      print('Error getting task for date: $e');
      return null;
    }
  }
}
