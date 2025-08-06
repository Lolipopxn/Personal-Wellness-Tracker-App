import 'package:flutter/material.dart';
import 'package:personal_wellness_tracker/pages/food_save.dart';
import 'package:personal_wellness_tracker/pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/profile.dart';
import 'pages/dashboard.dart';
import 'pages/daily_page.dart';
import 'pages/setting_page.dart';
import 'package:personal_wellness_tracker/์NavigationBar/main_scaffold.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  // Load theme preference from SharedPreferences
  Future<void> loadThemeFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isDarkMode = prefs.getBool('isDarkMode');
    if (isDarkMode != null) {
      _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    }
    notifyListeners();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await initializeDateFormatting('th');

  final themeProvider = ThemeProvider();
  await themeProvider.loadThemeFromPrefs();

  runApp(
    ChangeNotifierProvider(
      create: (context) => themeProvider,
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Multi Page App',
          home: MainScaffold(),
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: Colors.white,
            brightness: Brightness.light, // Light theme

            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              unselectedIconTheme: IconThemeData(color: Colors.black), 
              unselectedItemColor: Colors.black, // Unselected item color
              backgroundColor: Colors.white, 
            ),

          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: Colors.grey[900], // Dark background
            brightness: Brightness.dark, // Dark theme
            
            appBarTheme: AppBarTheme(
              foregroundColor: Colors.white,
              backgroundColor: Color(0xFF79D7BE), // Dark app bar color
            ),

            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              unselectedIconTheme: IconThemeData(color: Colors.white), 
              unselectedItemColor: Colors.white, // Unselected item color
              backgroundColor: Colors.grey[900], 
            ),

            textTheme: TextTheme(
              bodyMedium: TextStyle(color: Colors.white70),
              titleMedium: TextStyle(color: Colors.white),
            ),
            listTileTheme: ListTileThemeData(
              iconColor: Colors.white70,
              textColor: Colors.white70,
            ),
            cardTheme: CardThemeData(
              color: Colors.grey[800], // Dark card color
            ), // Dark card color

          ),
          themeMode: themeProvider.themeMode, // Use themeMode from ThemeProvider
          
          initialRoute: '/login',
          routes: {
            // '/': (context) => HomePage(),
            '/login': (context) => LoginPage(),
            '/profile': (context) => Profile(),
            '/register': (context) => RegisterPage(),
            '/dashboard': (context) => Dashboard(),
            '/food_save': (context) => FoodSavePage(),
            '/daily': (context) => DailyPage(),
            '/settings': (context) => SettingsPage(),
          },
        );
      },
    );
  }
}