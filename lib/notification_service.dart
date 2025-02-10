import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Request notification permissions for iOS
    await _firebaseMessaging.requestPermission();

    // Initialize Flutter Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    // Initialize the FlutterLocalNotificationsPlugin
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload != null) {
          print("Tapped notification payload: ${response.payload}");
          // You can handle what happens when the notification is tapped here.
        }
      },
    );

    // Set up Firebase Messaging listeners
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Show heads-up notification when the app is in the foreground
      _showHeadsUpNotification(message);
    });

    // Handle background notifications
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  }

  Future<void> _showHeadsUpNotification(RemoteMessage message) async {
    // Define a notification channel for heads-up notifications
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'heads_up_channel', // Unique channel ID
      'Heads-Up Notifications', // Channel name
      description: 'This channel is for heads-up notifications.',
      importance: Importance.high, // High importance for heads-up notifications
      playSound: true,
      enableVibration: true,
    );

    // Ensure the channel is created (use resolvePlatformSpecificImplementation for Android)
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Show the heads-up notification
    await _flutterLocalNotificationsPlugin.show(
      message.notification.hashCode, // Notification ID (unique for each message)
      message.notification?.title, // Notification title
      message.notification?.body, // Notification body
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id, // Channel ID
          channel.name, // Channel name
          channelDescription: channel.description, // Channel description
          importance: Importance.high, // Ensures heads-up notification
          playSound: true, // Play sound for notification
          enableVibration: true, // Enable vibration
          ticker: 'ticker', // Optional, the text shown when the notification is tapped
        ),
      ),
    );
  }
}

// Background message handler
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  print("Handling background message: ${message.messageId}");

  // Here you can add custom background logic to handle notifications while the app is in the background
}
