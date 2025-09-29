import 'dart:io';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../services/api_service.dart';
import '../app/daily_task_api.dart';

class DataExportService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>?> _safeGetDailyTask(DateTime date) async {
    try {
      final daily = await DailyTaskApi.getDailyTask(date);
      if (daily != null) return daily;
    } catch (e) {
      print("DEBUG: DailyTaskApi.getDailyTask failed → $e");
    }
    return null;
  }

  Future<Map<String, dynamic>> _fetchLast7DaysLogs() async {
    final today = DateTime.now();
    final start = today.subtract(const Duration(days: 6));

    List<Map<String, dynamic>> dailyTasks = [];
    List<Map<String, dynamic>> foodLogs = [];

    final currentUser = await _apiService.getCurrentUser();
    final userId = currentUser['uid'] ?? currentUser['id'];

    for (int i = 0; i < 7; i++) {
      final date = start.add(Duration(days: i));

      int water = 0;
      int exercise = 0;
      double sleep = 0.0;
      int calories = 0;

      final daily = await _safeGetDailyTask(date);
      if (daily != null && daily['id'] != null) {
        final tasks = await DailyTaskApi.getTasks(daily['id'].toString());
        for (final t in tasks) {
          switch (t['task_type']) {
            case 'water':
              water = (t['value_number'] ?? 0).toInt();
              break;
            case 'exercise':
              exercise = (t['value_number'] ?? 0).toInt();
              break;
            case 'sleep':
              final tq = t['task_quality'];
              if (tq != null) {
                final num? n = tq is num ? tq : num.tryParse(tq.toString());
                if (n != null) sleep = n.toDouble();
              } else if (t['started_at'] != null && t['ended_at'] != null) {
                final start = DateTime.tryParse(t['started_at'].toString());
                final end = DateTime.tryParse(t['ended_at'].toString());
                if (start != null && end != null) {
                  sleep = end.difference(start).inMinutes / 60.0;
                }
              }
              break;
          }
        }
      } else {
        final tasks = await _apiService.getTasksByDate(date);
        for (final t in tasks) {
          switch (t['task_type']) {
            case 'water':
              water = (t['value_number'] ?? 0).toInt();
              break;
            case 'exercise':
              exercise = (t['value_number'] ?? 0).toInt();
              break;
            case 'sleep':
              final tq = t['task_quality'];
              if (tq != null) {
                final num? n = tq is num ? tq : num.tryParse(tq.toString());
                if (n != null) sleep = n.toDouble();
              } else if (t['started_at'] != null && t['ended_at'] != null) {
                final start = DateTime.tryParse(t['started_at'].toString());
                final end = DateTime.tryParse(t['ended_at'].toString());
                if (start != null && end != null) {
                  sleep = end.difference(start).inMinutes / 60.0;
                }
              }
              break;
          }
        }
      }

      final foodLog = await _apiService.getFoodLogByDate(userId, date);
      if (foodLog != null) {
        final meals = await _apiService.getMealsByFoodLog(
          foodLog['id'].toString(),
        );

        int caloriesTotal = 0;

        for (var meal in meals) {
          final mealCalories = (meal['calories'] ?? 0) as int;
          caloriesTotal += mealCalories;

          foodLogs.add({
            "date": date.toIso8601String().split("T").first,
            "meal_type": meal['meal_type'] ?? '',
            "food_name": meal['food_name'] ?? '',
            "calories": mealCalories,
            "protein": meal['protein'] ?? 0,
            "carbs": meal['carbs'] ?? 0,
            "fat": meal['fat'] ?? 0,
          });
        }

        calories = caloriesTotal;
      }

      dailyTasks.add({
        "task_date": date.toIso8601String().split("T").first,
        "water_glasses": water,
        "exercise_minutes": exercise,
        "sleep_hours": sleep.toStringAsFixed(1),
        "calories": calories,
      });
    }

    return {"daily_tasks": dailyTasks, "food_logs": foodLogs};
  }

  Future<File> exportCSV() async {
    final logs = await _fetchLast7DaysLogs();

    // ตาราง Daily Tasks
    List<List<dynamic>> dailyRows = [];
    dailyRows.add(["Date", "Water", "Exercise", "Sleep", "Calories"]);
    for (var entry in logs['daily_tasks']) {
      dailyRows.add([
        entry['task_date'],
        entry['water_glasses'],
        entry['exercise_minutes'],
        entry['sleep_hours'],
        entry['calories'],
      ]);
    }

    // ตาราง Food Logs
    List<List<dynamic>> foodRows = [];
    foodRows.add([
      "Date",
      "Meal",
      "Food",
      "Calories",
      "Protein",
      "Carbs",
      "Fat",
    ]);
    for (var entry in logs['food_logs']) {
      if (entry.containsKey("meal_type")) {
        foodRows.add([
          entry['date'],
          entry['meal_type'],
          entry['food_name'],
          entry['calories'],
          entry['protein'],
          entry['carbs'],
          entry['fat'],
        ]);
      }
    }

    String csvData =
        "Daily Tasks\n${const ListToCsvConverter().convert(dailyRows)}\n\n"
        "Food Logs\n${const ListToCsvConverter().convert(foodRows)}";

    final dir = await getTemporaryDirectory();
    final path = "${dir.path}/wellness_data.csv";
    final file = File(path);
    await file.writeAsString(csvData);
    return file;
  }

  Future<File> exportPDF() async {
    final logs = await _fetchLast7DaysLogs();

    final font = pw.Font.ttf(
      await rootBundle.load("assets/fonts/Sarabun-Regular.ttf"),
    );
    final boldFont = pw.Font.ttf(
      await rootBundle.load("assets/fonts/Sarabun-Bold.ttf"),
    );

    final pdfTheme = pw.ThemeData.withFont(base: font, bold: boldFont);
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        theme: pdfTheme,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              "รายงานสุขภาพส่วนบุคคล (7 วัน)",
              style: pw.TextStyle(font: boldFont, fontSize: 22),
            ),
          ),

          // ตาราง Daily Tasks
          pw.Paragraph(text: "กิจกรรมประจำวัน"),
          logs['daily_tasks'].isEmpty
              ? pw.Paragraph(text: "ไม่มีข้อมูล Daily Task")
              : pw.Table.fromTextArray(
                  headers: [
                    "วันที่",
                    "ดื่มน้ำ (แก้ว)",
                    "ออกกำลังกาย (นาที)",
                    "นอน (ชม.)",
                    "แคลอรี่",
                  ],
                  data: [
                    for (var entry in logs['daily_tasks'])
                      [
                        entry['task_date'],
                        entry['water_glasses'],
                        entry['exercise_minutes'],
                        entry['sleep_hours'],
                        entry['calories'],
                      ],
                  ],
                ),

          pw.SizedBox(height: 20),

          // ตาราง Food Logs
          pw.Paragraph(text: "บันทึกการกิน"),
          logs['food_logs'].isEmpty
              ? pw.Paragraph(text: "ไม่มีข้อมูลอาหารในช่วงนี้")
              : pw.Table.fromTextArray(
                  headers: [
                    "วันที่",
                    "มื้อ",
                    "อาหาร",
                    "แคลอรี่",
                    "โปรตีน",
                    "คาร์บ",
                    "ไขมัน",
                  ],
                  data: [
                    for (var entry in logs['food_logs'])
                      if (entry.containsKey("meal_type"))
                        [
                          entry['date'],
                          entry['meal_type'],
                          entry['food_name'],
                          entry['calories'],
                          entry['protein'],
                          entry['carbs'],
                          entry['fat'],
                        ],
                  ],
                ),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final path = "${dir.path}/wellness_report.pdf";
    final file = File(path);
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  Future<void> shareFile(File file, {String? text}) async {
    await Share.shareXFiles([XFile(file.path)], text: text);
  }
}
