import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {

    await _firebaseMessaging.requestPermission();


    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload != null) {
          print("Tapped notification payload: ${response.payload}");
        }
      },
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showHeadsUpNotification(message);
    });


    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  }

  Future<void> _showHeadsUpNotification(RemoteMessage message) async {

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'heads_up_channel',
      'Heads-Up Notifications', 
      description: 'This channel is for heads-up notifications.',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );


    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await _flutterLocalNotificationsPlugin.show(
      message.notification.hashCode, 
      message.notification?.title, 
      message.notification?.body, 
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id, 
          channel.name, 
          channelDescription: channel.description, 
          importance: Importance.high, 
          playSound: true,
          enableVibration: true, 
          ticker: 'ticker', 
        ),
      ),
    );
  }
}


Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  print("Handling background message: ${message.messageId}");

}
