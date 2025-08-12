import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app/achievement_service.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final achievementService = AchievementService();

  Future<void> saveUserProfile(Map<String, dynamic> userProfileData) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("No signed-in user");

    final dataToSave = {
      ...userProfileData,
      'uid': user.uid,
      'email': user.email,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _db
        .collection('users')
        .doc(user.uid)
        .set(dataToSave, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("No signed-in user");

    final doc = await _db.collection('users').doc(user.uid).get();
    if (doc.exists) {
      return doc.data();
    } else {
      return null;
    }
  }

  Future<void> updateUserData(Map<String, dynamic> updates) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("No signed-in user");

    await _db.collection('users').doc(user.uid).update(updates);
  }

  Future<void> addFoodLog({
    required String date,
    required Map<String, dynamic> mealData,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("No signed-in user");

    final dateDocRef = _db
        .collection('users')
        .doc(user.uid)
        .collection('foodLogs')
        .doc(date);

    await dateDocRef.set({
      'lastModified': FieldValue.serverTimestamp(),
      'mealCount': FieldValue.increment(1),
    }, SetOptions(merge: true));

    await dateDocRef.collection('meals').add({
      ...mealData,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>> getFoodLogsForDate(String date) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final snapshot = await _db
        .collection('users')
        .doc(user.uid)
        .collection('foodLogs')
        .doc(date)
        .collection('meals')
        .orderBy('createdAt', descending: false)
        .get();

    return snapshot.docs.map((doc) {
      return {'id': doc.id, ...doc.data()};
    }).toList();
  }

  Future<void> updateFoodLog({
    required String date,
    required String mealId,
    required Map<String, dynamic> mealData,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("No signed-in user");

    final dataToUpdate = {
      ...mealData,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('foodLogs')
        .doc(date)
        .collection('meals')
        .doc(mealId)
        .update(dataToUpdate);
  }

  Future<void> deleteFoodLog({
    required String date,
    required String mealId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("No signed-in user");

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('foodLogs')
        .doc(date)
        .collection('meals')
        .doc(mealId)
        .delete();
  }

  Future<void> saveDailyTask(
    Map<String, dynamic> taskData,
    DateTime dateTime,
  ) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("No signed-in user");

    final String date =
        "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}";

    final data = {...taskData, 'updatedAt': FieldValue.serverTimestamp()};

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('tasks_log')
        .doc(date)
        .set(data, SetOptions(merge: true));

    await achievementService.checkAndUpdateAchievements();
  }

  Future<Map<String, dynamic>?> getDailyTask(DateTime dateTime) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("No signed-in user");

    final String date =
        "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}";

    final docSnapshot = await _db
        .collection('users')
        .doc(user.uid)
        .collection('tasks_log')
        .doc(date)
        .get();

    if (docSnapshot.exists) {
      return docSnapshot.data();
    } else {
      return null;
    }
  }

  Future<int> getSavedDaysCount() async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    final snapshot = await _db
        .collection('users')
        .doc(user.uid)
        .collection('tasks_log')
        .get();

    int savedDaysCount = snapshot.docs.length;

    await _db.collection('users').doc(user.uid).update({
      'savedDaysCount': {
        'Days': savedDaysCount,
        'lastUpdated': FieldValue.serverTimestamp(),
      },
    });

    return savedDaysCount;
  }

  Future<int> getStreakCount() async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    final snapshot = await _db
        .collection('users')
        .doc(user.uid)
        .collection('tasks_log')
        .get();

    List<String> dates = snapshot.docs.map((doc) => doc.id).toList();
    dates.sort((a, b) => b.compareTo(a));

    if (dates.isEmpty) return 0;

    int streak = 0;
    DateTime today = DateTime.now();
    DateTime currentCheckDay = today;

    bool hasTodayLog = dates.any(
      (dateStr) => isSameDay(DateTime.parse(dateStr), today),
    );

    if (!hasTodayLog) {
      currentCheckDay = today.subtract(const Duration(days: 1));
    }

    for (String dateStr in dates) {
      DateTime logDate = DateTime.parse(dateStr);

      if (isSameDay(logDate, currentCheckDay)) {
        streak++;
        currentCheckDay = currentCheckDay.subtract(const Duration(days: 1));
      } else if (logDate.isBefore(currentCheckDay)) {
        break;
      }
    }

    await _db.collection('users').doc(user.uid).update({
      'savedDaysCount': {
        'DayStreak': streak,
        'lastUpdated': FieldValue.serverTimestamp(),
      },
    });

    return streak;
  }

  bool isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  Future<Map<String, dynamic>> fetchAllLogs() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("No signed-in user");

    final foodLogsSnapshot = await _db
        .collection('users')
        .doc(user.uid)
        .collection('foodLogs')
        .get();

    Map<String, List<Map<String, dynamic>>> foodLogsByDate = {};
    for (var dateDoc in foodLogsSnapshot.docs) {
      final date = dateDoc.id;
      final mealsSnapshot = await _db
          .collection('users')
          .doc(user.uid)
          .collection('foodLogs')
          .doc(date)
          .collection('meals')
          .orderBy('createdAt', descending: false)
          .get();

      foodLogsByDate[date] = mealsSnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    }

    final taskLogsSnapshot = await _db
        .collection('users')
        .doc(user.uid)
        .collection('tasks_log')
        .orderBy(FieldPath.documentId)
        .get();

    Map<String, Map<String, dynamic>> taskLogsByDate = {};
    for (var doc in taskLogsSnapshot.docs) {
      taskLogsByDate[doc.id] = doc.data();
    }

    return {'foodLogs': foodLogsByDate, 'taskLogs': taskLogsByDate};
  }
}
