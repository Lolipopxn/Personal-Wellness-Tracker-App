import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Helper method to convert Firestore data and handle Timestamps
  Map<String, dynamic> _processFirestoreData(Map<String, dynamic> data) {
    final processedData = <String, dynamic>{};
    
    for (final entry in data.entries) {
      if (entry.value is Timestamp) {
        processedData[entry.key] = (entry.value as Timestamp).toDate().toIso8601String();
      } else if (entry.value is Map<String, dynamic>) {
        processedData[entry.key] = _processFirestoreData(entry.value);
      } else if (entry.value is List) {
        processedData[entry.key] = (entry.value as List).map((item) {
          if (item is Map<String, dynamic>) {
            return _processFirestoreData(item);
          } else if (item is Timestamp) {
            return item.toDate().toIso8601String();
          } else {
            return item;
          }
        }).toList();
      } else {
        processedData[entry.key] = entry.value;
      }
    }
    
    return processedData;
  }

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

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('foodLogs')
        .doc(date)
        .collection('meals')
        .add({...mealData, 'createdAt': FieldValue.serverTimestamp()});
  }

  Future<List<Map<String, dynamic>>> getFoodLogsForDate(String date) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    print('🔍 Firebase Query - UID: ${user.uid}, Date: $date');
    
    try {
      // วิธีที่ 1: ลองหาใน subcollection meals ก่อน
      print('🔍 Method 1: Query Path: users/${user.uid}/foodLogs/$date/meals');
      final mealsSnapshot = await _db
          .collection('users')
          .doc(user.uid)
          .collection('foodLogs')
          .doc(date)
          .collection('meals')
          .get();

      if (mealsSnapshot.docs.isNotEmpty) {
        print('🔍 Found ${mealsSnapshot.docs.length} meals in subcollection');
        return mealsSnapshot.docs.map((doc) {
          final data = doc.data();
          final processedData = _processFirestoreData(data);
          return {'id': doc.id, ...processedData};
        }).toList();
      }

      // วิธีที่ 2: ถ้าไม่เจอใน subcollection ลองดูใน document โดยตรง
      print('🔍 Method 2: Query document: users/${user.uid}/foodLogs/$date');
      final dateDoc = await _db
          .collection('users')
          .doc(user.uid)
          .collection('foodLogs')
          .doc(date)
          .get();

      if (dateDoc.exists && dateDoc.data() != null) {
        final docData = dateDoc.data()!;
        print('🔍 Found document data: $docData');
        
        // ถ้าข้อมูลเป็น array ของ meals
        if (docData.containsKey('meals') && docData['meals'] is List) {
          final mealsList = docData['meals'] as List;
          print('🔍 Found ${mealsList.length} meals in document array');
          return mealsList.asMap().entries.map((entry) {
            final index = entry.key;
            final meal = entry.value as Map<String, dynamic>;
            final processedData = _processFirestoreData(meal);
            return {'id': 'meal_$index', ...processedData};
          }).toList();
        }
        
        // ถ้าข้อมูลเป็น single meal object
        else if (docData.containsKey('name') || docData.containsKey('cal')) {
          print('🔍 Found single meal in document');
          final processedData = _processFirestoreData(docData);
          return [{'id': date, ...processedData}];
        }
        
        // ถ้าข้อมูลเป็น key-value pairs ของ meals
        else {
          final meals = <Map<String, dynamic>>[];
          for (final entry in docData.entries) {
            if (entry.value is Map<String, dynamic>) {
              final mealData = entry.value as Map<String, dynamic>;
              if (mealData.containsKey('name') || mealData.containsKey('cal')) {
                final processedData = _processFirestoreData(mealData);
                meals.add({'id': entry.key, ...processedData});
              }
            }
          }
          if (meals.isNotEmpty) {
            print('🔍 Found ${meals.length} meals in document key-value pairs');
            return meals;
          }
        }
      }

      print('🔍 No food data found for date: $date');
      return [];
      
    } catch (e) {
      print('❌ Error fetching food logs for $date: $e');
      return [];
    }
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
  }

  Future<Map<String, dynamic>?> getDailyTask(DateTime dateTime) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("No signed-in user");

    final String date =
        "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}";
        
    print('🔥 FirestoreService.getDailyTask: Fetching for date=$date, uid=${user.uid}');
    final docPath = 'users/${user.uid}/tasks_log/$date';
    print('🔥 FirestoreService.getDailyTask: Document path = $docPath');

    final docSnapshot = await _db
        .collection('users')
        .doc(user.uid)
        .collection('tasks_log')
        .doc(date)
        .get();

    print('🔥 FirestoreService.getDailyTask: Document exists = ${docSnapshot.exists}');
    
    if (docSnapshot.exists) {
      final data = docSnapshot.data();
      print('🔥 FirestoreService.getDailyTask: Raw Firestore data = $data');
      
      if (data != null) {
        final processedData = _processFirestoreData(data);
        print('🔥 FirestoreService.getDailyTask: Processed data = $processedData');
        return processedData;
      } else {
        print('🔥 FirestoreService.getDailyTask: Document exists but data is null');
      }
    } else {
      print('🔥 FirestoreService.getDailyTask: No document found');
      
      // Let's also check alternative collection names
      print('🔥 FirestoreService.getDailyTask: Checking alternative collections...');
      
      // Try dailyTasks collection
      final altDoc1 = await _db
          .collection('users')
          .doc(user.uid)
          .collection('dailyTasks')
          .doc(date)
          .get();
      print('🔥 FirestoreService.getDailyTask: dailyTasks/$date exists = ${altDoc1.exists}');
      if (altDoc1.exists) print('🔥 FirestoreService.getDailyTask: dailyTasks data = ${altDoc1.data()}');
      
      // Try daily_tasks collection  
      final altDoc2 = await _db
          .collection('users')
          .doc(user.uid)
          .collection('daily_tasks')
          .doc(date)
          .get();
      print('🔥 FirestoreService.getDailyTask: daily_tasks/$date exists = ${altDoc2.exists}');
      if (altDoc2.exists) print('🔥 FirestoreService.getDailyTask: daily_tasks data = ${altDoc2.data()}');
    }
    
    return null;
  }
}
