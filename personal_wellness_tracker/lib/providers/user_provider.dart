import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  Map<String, dynamic>? _userData;

  Map<String, dynamic>? get userData => _userData;

  void setUserData(Map<String, dynamic> user) {
    _userData = user;
    notifyListeners();
  }

  void updateUsername(String newName) {
    if (_userData != null) {
      _userData!['username'] = newName;
      notifyListeners();
    }
  }

  void clearUser() {
    _userData = null;
    notifyListeners();
  }
}
