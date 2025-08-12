import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app/notification_service.dart';

class AchievementService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> checkAndUpdateAchievements() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final snapshot = await _db
        .collection('users')
        .doc(user.uid)
        .get();

    int streak = snapshot['savedDaysCount']['DayStreak'];
    // debugPrint("Current streak: $streak");

    int goal = calculateGoal(streak);
    // debugPrint("Current Goal: $goal");

    final prefs = await SharedPreferences.getInstance();
    // await prefs.setInt('lastNotifiedGoal', 0);
    int lastNotifiedGoal = prefs.getInt('lastNotifiedGoal') ?? 0;
    // debugPrint("Current Goal2: $lastNotifiedGoal");

    if (streak >= lastNotifiedGoal) {
      await showNotification(
        "ยินดีด้วย!",
        "คุณบันทึกมา $streak วัน แล้ว 🎉",
      );

      await prefs.setInt('lastNotifiedGoal', goal);
    }
  }

  int calculateGoal(int days) {
    List<int> goals = [7, 14, 30, 60, 90, 180, 365];
    for (int g in goals) {
      if (days < g) {
        return g;
      }
    }
    return days + 30;
  }
}
