import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
}
