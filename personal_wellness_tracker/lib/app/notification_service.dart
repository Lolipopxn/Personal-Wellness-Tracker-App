import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

bool notificationsEnabled = true;

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Background Message: ${message.notification?.title}");
}

Future<void> initNotificationService() async {
  // Init local notification
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Init FCM
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  NotificationSettings settings = await FirebaseMessaging.instance
      .requestPermission(alert: true, badge: true, sound: true);

  debugPrint('Permission status: ${settings.authorizationStatus}');

  // Get token
  String? token = await FirebaseMessaging.instance.getToken();
  debugPrint("FCM Token: $token");

  // await saveDeviceToken();

  await loadNotificationSetting();
  // Foreground message
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (notificationsEnabled) {
      debugPrint("Foreground Message: ${message.notification?.title}");
      showNotification(
        message.notification?.title ?? '',
        message.notification?.body ?? '',
      );
    }
  });

  // Click notification
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint("Notification clicked: ${message.notification?.title}");
  });
}

// Future<void> saveDeviceToken() async {
//   String? token = await FirebaseMessaging.instance.getToken();
//   final user = FirebaseAuth.instance.currentUser;
//   debugPrint("Saving FCM Token: $token for user: ${user?.uid}");

//   if (token != null && user != null) {
//     await FirebaseFirestore.instance
//         .collection('users')
//         .doc(user.uid)
//         .update({'fcmToken': token});
//   }
// }

Future<void> loadNotificationSetting() async {
  final prefs = await SharedPreferences.getInstance();
  notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;

  debugPrint("Notifications enabled: $notificationsEnabled");
}

Future<void> showNotification(String title, String body) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'fcm_channel',
        'FCM Notifications',
        channelDescription: 'This channel is used for FCM notifications',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
      );

  const NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
  );

  if (notificationsEnabled) {
    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );
  }
}
