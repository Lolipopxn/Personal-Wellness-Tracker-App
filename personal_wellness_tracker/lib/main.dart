import 'package:flutter/material.dart';
import 'package:personal_wellness_tracker/pages/food_save.dart';
import 'package:personal_wellness_tracker/pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/home.dart';
import 'pages/profile.dart';
import 'pages/dashboard.dart';
import 'pages/daily_page.dart';
import 'pages/setting_page.dart';


import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('th');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Multi Page App',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => HomePage(),
        '/login': (context) => LoginPage(),
        '/profile': (context) => Profile(),
        '/register': (context) => RegisterPage(),
        '/dashboard': (context) => Dashboard(),
        '/food_save': (context) => FoodSavePage(),
        '/daily': (context) => DailyPage(),
        '/settings': (context) => SettingsPage(),
      },
    );
  }
}
