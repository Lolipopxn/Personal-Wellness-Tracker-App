import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:personal_wellness_tracker/app/auth_service.dart';

class ProfileWidget extends StatelessWidget {
  const ProfileWidget({super.key});

  void logout() async {
    try {
      await authService.value.signOut();
    } on FirebaseAuthException catch (e) {
      print(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Logout')),
      body: Center(
        child: ElevatedButton(onPressed: logout, child: const Text('Logout')),
      ),
    );
  }
}
