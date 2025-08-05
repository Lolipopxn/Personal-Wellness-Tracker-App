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
}
