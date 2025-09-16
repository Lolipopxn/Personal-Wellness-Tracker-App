import 'package:flutter/material.dart';
import 'package:personal_wellness_tracker/pages/food_save.dart';
import 'package:personal_wellness_tracker/pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/profile.dart';
import 'pages/splash_screen.dart';
// import 'pages/dashboard.dart';
import 'pages/daily_page.dart';
import 'pages/setting_page.dart';
import 'pages/all_logs_page.dart';
import 'package:personal_wellness_tracker/์NavigationBar/main_scaffold.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app/notification_service.dart';

import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'package:firebase_messaging/firebase_messaging.dart';

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

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await initNotificationService();

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
          home: const SplashScreen(),
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: Colors.white,
            brightness: Brightness.light, // Light theme

            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              unselectedIconTheme: IconThemeData(color: Colors.black), 
              unselectedItemColor: Colors.black, // Unselected item color
              backgroundColor: Colors.white, 
            ),

            cardTheme: CardThemeData(
              color: Colors.white, // Dark card color
            ), // Dark card color

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
          
          initialRoute: 'Login,',
          routes: {
            '/main': (context) => MainScaffold(),
            '/SplashScreen': (context) => SplashScreen(),
            '/login': (context) => LoginPage(),
            '/profile': (context) => Profile(),
            '/register': (context) => RegisterPage(),
            // '/dashboard': (context) => Dashboard(),
            '/food_save': (context) => FoodSavePage(),
            '/daily': (context) => DailyPage(),
            '/settings': (context) => SettingsPage(),
            '/all_logs': (context) => LogsScreen(),
          },
        );
      },
    );
  }
}