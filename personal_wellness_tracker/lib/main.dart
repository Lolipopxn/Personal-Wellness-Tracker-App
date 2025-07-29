import 'package:flutter/material.dart';
import 'package:personal_wellness_tracker/pages/food_save.dart';
import 'package:personal_wellness_tracker/pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/home.dart';
import 'pages/profile.dart';
import 'pages/dashboard.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Multi Page App',
      theme: ThemeData(primarySwatch: Colors.teal),
      initialRoute: '/',
      routes: {
        '/': (context) => HomePage(),
        '/login': (context) => LoginPage(),
        '/profile': (context) => Profile(),
        '/register': (context) => RegisterPage(),
        '/dashboard': (context) => Dashboard(),
        '/food_save': (context) => FoodSavePage(),
      },
    );
  }
}
