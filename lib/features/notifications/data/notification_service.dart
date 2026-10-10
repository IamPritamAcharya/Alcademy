import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:port/features/notifications/models/notification_model.dart';
import 'notification_destination.dart';
import 'notice_push_policy.dart';
import 'notification_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static String? _selectedNotificationId;
  static String? _selectedNotificationRoute;
  static final navigationRequests = ValueNotifier<int>(0);

  static const _testNoticesEnabled = bool.fromEnvironment(
    'NOTICE_PUSH_TEST',
    defaultValue: false,
  );
  static const _productionNoticesEnabled = bool.fromEnvironment(
    'NOTICE_PUSH_PRODUCTION',
    defaultValue: false,
  );
  final _noticeTopicState = <String, bool>{};
  Future<bool>? _noticeTopicSync;
  bool _forceNoticeTopicSync = false;

  Future<void> initialize() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');

    await _initializeLocalNotifications();

    await _createNotificationChannel();

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    RemoteMessage? initialMessage = await FirebaseMessaging.instance
        .getInitialMessage();
    if (initialMessage != null) {
      debugPrint('App opened from terminated state via notification');
      await _handleNotificationTap(initialMessage);
    }

    _firebaseMessaging.onTokenRefresh.listen((_) {
      debugPrint('FCM registration refreshed; updating notice subscriptions.');
      unawaited(syncNoticeSubscriptions(force: true));
    });

    await syncNotifications();
  }

  /// Retry unsuccessful subscriptions on resume and after token refresh,
  /// without holding up app startup or repeatedly registering confirmed topics.
  Future<bool> syncNoticeSubscriptions({bool force = false}) async {
    _forceNoticeTopicSync |= force;
    if (_noticeTopicSync != null) return _noticeTopicSync!;
    final operation = _syncNoticeTopics();
    _noticeTopicSync = operation;
    try {
      return await operation;
    } finally {
      _noticeTopicSync = null;
    }
  }

  Future<bool> notificationPermissionGranted({bool request = false}) async {
    var settings = await _firebaseMessaging.getNotificationSettings().timeout(
      const Duration(seconds: 8),
    );
    if (request &&
        settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      settings = await _firebaseMessaging.requestPermission();
    }
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  Future<bool> _syncNoticeTopics() async {
    var synced = true;
    do {
      final force = _forceNoticeTopicSync;
      _forceNoticeTopicSync = false;
      synced = true;
      try {
        final permission = await notificationPermissionGranted();
        if (!kIsWeb &&
            (defaultTargetPlatform == TargetPlatform.iOS ||
                defaultTargetPlatform == TargetPlatform.macOS) &&
            await _firebaseMessaging.getAPNSToken().timeout(
                  const Duration(seconds: 8),
                ) ==
                null) {
          // Apple registration can complete after initialization. Retry on
          // FCM token refresh or app resume before attempting topic APIs.
          return false;
        }
        final preferences = await const NotificationPreferencesRepository()
            .read();
        final desired = notificationTopicSubscriptions(
          debugBuild: kDebugMode,
          testEnabled: _testNoticesEnabled,
          productionEnabled: _productionNoticesEnabled,
          permissionGranted: permission,
          noticesEnabled: preferences.notices,
          generalEnabled: preferences.general,
        );
        for (final topic in desired.entries) {
          if (!force && _noticeTopicState[topic.key] == topic.value) continue;
          try {
            await (topic.value
                    ? _firebaseMessaging.subscribeToTopic(topic.key)
                    : _firebaseMessaging.unsubscribeFromTopic(topic.key))
                .timeout(const Duration(seconds: 8));
            _noticeTopicState[topic.key] = topic.value;
            if (topic.key == testNoticeTopic && topic.value) {
              debugPrint(
                'Subscribed this debug installation to test notice alerts.',
              );
            }
          } catch (error) {
            synced = false;
            debugPrint(
              'Notice subscription will retry on resume (${error.runtimeType}).',
            );
          }
        }
      } catch (error) {
        synced = false;
        debugPrint(
          'Could not read notification permission (${error.runtimeType}).',
        );
      }
    } while (_forceNoticeTopicSync);
    return synced;
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    final launch = await _localNotifications.getNotificationAppLaunchDetails();
    final response = launch?.notificationResponse;
    if (launch?.didNotificationLaunchApp == true && response != null) {
      await _onNotificationTapped(response);
    }
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  Future<void> syncNotifications() async {
    unawaited(syncNoticeSubscriptions());
    try {
      debugPrint(' Starting notification sync...');
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();

      bool hasNewNotifications = await _processBackgroundNotifications(prefs);

      await _cleanupOldNotifications();

      debugPrint(' Notification sync completed - hasNew: $hasNewNotifications');
    } catch (e) {
      debugPrint(' Error during notification sync: $e');
    }
  }

  Future<bool> _processBackgroundNotifications(SharedPreferences prefs) async {
    try {
      final backgroundQueue =
          prefs.getStringList('background_notification_queue') ?? [];

      if (backgroundQueue.isEmpty) {
        debugPrint(' No background notifications to process');
        return false;
      }

      debugPrint(
        ' Processing ${backgroundQueue.length} background notifications',
      );

      List<NotificationModel> existingNotifications =
          await getAllNotifications();
      bool hasNewNotifications = false;
      List<String> processedIds = [];

      for (String notificationJson in backgroundQueue) {
        try {
          final Map<String, dynamic> notificationData = jsonDecode(
            notificationJson,
          );

          if (!_isValidNotificationData(notificationData)) {
            debugPrint(' Skipping invalid background notification data');
            continue;
          }

          final notification = NotificationModel.fromMap(notificationData);

          if (_isValidNotification(notification)) {
            final exists = existingNotifications.any(
              (n) => n.id == notification.id,
            );
            if (!exists) {
              existingNotifications.insert(0, notification);
              processedIds.add(notification.id);
              hasNewNotifications = true;
              debugPrint(
                'Added background notification: ${notification.title}',
              );
            } else {
              debugPrint(
                'Background notification already exists: ${notification.title}',
              );
            }
          } else {
            debugPrint('Skipping invalid notification: ${notification.title}');
          }
        } catch (e) {
          debugPrint('Error processing individual background notification: $e');
        }
      }

      if (hasNewNotifications) {
        await _saveAllNotifications(existingNotifications);
        debugPrint(
          'Processed ${processedIds.length} new background notifications',
        );
      }

      await prefs.remove('background_notification_queue');
      debugPrint('Background notification queue cleared');

      return hasNewNotifications;
    } catch (e) {
      debugPrint('Error processing background notifications: $e');
      return false;
    }
  }

  bool _isValidNotificationData(Map<String, dynamic> data) {
    if (data.isEmpty) return false;

    final title = data['title']?.toString().trim() ?? '';
    final body = data['body']?.toString().trim() ?? '';

    return title.isNotEmpty || body.isNotEmpty;
  }

  bool _isValidNotification(NotificationModel notification) {
    return notification.title.isNotEmpty &&
        notification.title != 'Error' &&
        notification.title != 'No Title' &&
        notification.body.isNotEmpty &&
        notification.body != 'No Body' &&
        notification.body != 'Failed to parse notification';
  }

  Future<void> _cleanupOldNotifications() async {
    try {
      List<NotificationModel> notifications = await getAllNotifications();

      if (notifications.length > 100) {
        notifications = notifications.take(100).toList();
        await _saveAllNotifications(notifications);
        debugPrint(
          'Cleaned up old notifications, kept ${notifications.length}',
        );
      }

      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      final backupKeys = allKeys
          .where((key) => key.startsWith('notification_backup_'))
          .toList();

      if (backupKeys.length > 50) {
        for (int i = 50; i < backupKeys.length; i++) {
          await prefs.remove(backupKeys[i]);
        }
        debugPrint('Cleaned up ${backupKeys.length - 50} old backup keys');
      }
    } catch (e) {
      debugPrint('Error during cleanup: $e');
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint(' Handling foreground message: ${message.messageId}');

    if (!_isValidRemoteMessage(message)) {
      debugPrint('Invalid foreground message received, skipping');
      return;
    }

    final preferences = await const NotificationPreferencesRepository().read();
    if (!preferences.allows(message.data)) return;

    final notification = NotificationModel.fromRemoteMessage(message);

    if (!_isValidNotification(notification)) {
      debugPrint('Created notification is invalid, skipping');
      return;
    }

    final isNew = await _saveNotification(notification);
    if (!isNew) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_new_notification', true);

    await _showLocalNotification(notification);
  }

  Future<void> _handleNotificationTap(RemoteMessage message) async {
    debugPrint('Notification tapped: ${message.messageId}');
    if (!_isValidRemoteMessage(message)) {
      debugPrint('Invalid tapped message, using fallback');
      return;
    }

    final notification = NotificationModel.fromRemoteMessage(message);
    if (_isValidNotification(notification)) {
      await _saveNotification(notification);
    }
    // Publish ID and destination together after persistence. Resume callbacks
    // must not consume the ID while the destination is still being prepared.
    _selectedNotificationId = notification.id;
    _selectedNotificationRoute = notificationDestination(message.data);
    navigationRequests.value++;
  }

  bool _isValidRemoteMessage(RemoteMessage message) {
    bool hasNotificationTitle =
        message.notification?.title != null &&
        message.notification!.title!.trim().isNotEmpty;
    bool hasNotificationBody =
        message.notification?.body != null &&
        message.notification!.body!.trim().isNotEmpty;

    bool hasDataTitle =
        message.data.containsKey('title') &&
        message.data['title']?.toString().trim().isNotEmpty == true;
    bool hasDataBody =
        message.data.containsKey('body') &&
        message.data['body']?.toString().trim().isNotEmpty == true;
    bool hasDataMessage =
        message.data.containsKey('message') &&
        message.data['message']?.toString().trim().isNotEmpty == true;

    return hasNotificationTitle ||
        hasNotificationBody ||
        hasDataTitle ||
        hasDataBody ||
        hasDataMessage;
  }

  Future<void> _onNotificationTapped(NotificationResponse response) async {
    debugPrint(' Local notification tapped: ${response.payload}');
    if (response.payload != null && response.payload!.isNotEmpty) {
      final payload = decodeNotificationTap(response.payload!);
      _selectedNotificationId = payload.id;
      _selectedNotificationRoute = payload.route;
      navigationRequests.value++;
    }
  }

  Future<void> _showLocalNotification(NotificationModel notification) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription:
              'This channel is used for important notifications.',
          importance: Importance.high,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
          autoCancel: false,
          ongoing: false,
          showWhen: true,
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      notification.id.hashCode,
      notification.title,
      notification.body,
      platformChannelSpecifics,
      payload: jsonEncode({
        'id': notification.id,
        'route': notificationDestination(notification.data),
      }),
    );
  }

  Future<bool> _saveNotification(NotificationModel notification) async {
    try {
      if (!_isValidNotification(notification)) {
        debugPrint(
          " Attempted to save invalid notification: ${notification.title} - ${notification.body}",
        );
        return false;
      }

      final notifications = await getAllNotifications();

      final exists = notifications.any((n) => n.id == notification.id);
      if (!exists) {
        notifications.insert(0, notification);
        await _saveAllNotifications(notifications);
        debugPrint(
          "Notification saved: ${notification.title} (ID: ${notification.id})",
        );
        return true;
      } else {
        debugPrint("Notification already exists: ${notification.title}");
        return false;
      }
    } catch (e) {
      debugPrint("Error saving notification: $e");
      // A storage failure should not hide an otherwise valid incoming alert.
      return true;
    }
  }

  Future<void> _saveAllNotifications(
    List<NotificationModel> notifications,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final validNotifications = notifications
          .where((n) => _isValidNotification(n))
          .toList();

      if (validNotifications.length > 100) {
        validNotifications.removeRange(100, validNotifications.length);
      }

      final notificationMaps = validNotifications
          .map((n) => n.toMap())
          .toList();
      await prefs.setString('notifications', jsonEncode(notificationMaps));

      for (int i = 0; i < validNotifications.length && i < 10; i++) {
        final notification = validNotifications[i];
        await prefs.setString(
          'notification_backup_${notification.id}',
          jsonEncode(notification.toMap()),
        );
      }

      debugPrint("Saved ${validNotifications.length} valid notifications");
    } catch (e) {
      debugPrint("Error saving all notifications: $e");
      rethrow;
    }
  }

  Future<List<NotificationModel>> getAllNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getString('notifications');

      if (notificationsJson == null || notificationsJson.isEmpty) {
        return await _recoverNotificationsFromBackup();
      }

      final List<dynamic> notificationMaps = jsonDecode(notificationsJson);
      final notifications = <NotificationModel>[];

      for (var map in notificationMaps) {
        try {
          if (map is Map<String, dynamic>) {
            final notification = NotificationModel.fromMap(map);

            if (_isValidNotification(notification)) {
              notifications.add(notification);
            } else {
              debugPrint(
                "Skipping invalid notification during load: ${notification.title}",
              );
            }
          }
        } catch (e) {
          debugPrint("Error parsing individual notification: $e");
        }
      }

      notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return notifications;
    } catch (e) {
      debugPrint("Error loading notifications: $e");

      return await _recoverNotificationsFromBackup();
    }
  }

  Future<List<NotificationModel>> _recoverNotificationsFromBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      final backupKeys = allKeys
          .where((key) => key.startsWith('notification_backup_'))
          .toList();

      List<NotificationModel> notifications = [];

      for (String key in backupKeys) {
        try {
          final notificationJson = prefs.getString(key);
          if (notificationJson != null && notificationJson.isNotEmpty) {
            final notificationMap = jsonDecode(notificationJson);
            if (notificationMap is Map<String, dynamic>) {
              final notification = NotificationModel.fromMap(notificationMap);

              if (_isValidNotification(notification)) {
                notifications.add(notification);
              }
            }
          }
        } catch (e) {
          debugPrint("Error recovering notification from key $key: $e");
        }
      }

      notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      if (notifications.isNotEmpty) {
        debugPrint(
          "Recovered ${notifications.length} valid notifications from backup",
        );

        await _saveAllNotifications(notifications);
      }

      return notifications;
    } catch (e) {
      debugPrint("Error recovering notifications: $e");
      return [];
    }
  }

  static String? getSelectedNotificationId() {
    final id = _selectedNotificationId;
    _selectedNotificationId = null;
    return id;
  }

  static void clearSelectedNotificationId() {
    _selectedNotificationId = null;
  }

  static String? takeSelectedNotificationRoute() {
    final route = _selectedNotificationRoute;
    _selectedNotificationRoute = null;
    return route;
  }

  Future<void> forceRefreshNotifications() async {
    try {
      debugPrint("Force refresh started - simulating app restart");

      final prefs = await SharedPreferences.getInstance();
      await _processBackgroundNotifications(prefs);

      await _cleanupOldNotifications();

      await prefs.setBool('has_new_notification', false);

      debugPrint(" Force refresh completed - simulated restart");
    } catch (e) {
      debugPrint(" Error during force refresh: $e");
      rethrow;
    }
  }

  Future<void> debugBackgroundQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final backgroundQueue =
          prefs.getStringList('background_notification_queue') ?? [];
      final hasNewFlag = prefs.getBool('has_new_notification') ?? false;

      debugPrint('DEBUG QUEUE STATE:');
      debugPrint('  - Queue size: ${backgroundQueue.length}');
      debugPrint('  - Has new notification flag: $hasNewFlag');
      debugPrint('  - Queue items:');

      for (int i = 0; i < backgroundQueue.length; i++) {
        try {
          final item = jsonDecode(backgroundQueue[i]);
          debugPrint(
            '    ${i + 1}. ID: ${item['id']} | Title: ${item['title']} | Body: ${item['body']}',
          );
        } catch (e) {
          debugPrint('    ${i + 1}. [CORRUPTED ITEM]: $e');
        }
      }
    } catch (e) {
      debugPrint('Debug queue error: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      debugPrint(' Deleting notification: $notificationId');

      final prefs = await SharedPreferences.getInstance();

      List<NotificationModel> notifications = await getAllNotifications();

      final originalLength = notifications.length;
      notifications.removeWhere(
        (notification) => notification.id == notificationId,
      );

      if (notifications.length < originalLength) {
        await _saveAllNotifications(notifications);

        await prefs.remove('notification_backup_$notificationId');

        debugPrint('Successfully deleted notification: $notificationId');
        debugPrint(
          'Notifications count: $originalLength → ${notifications.length}',
        );
      } else {
        debugPrint('Notification not found for deletion: $notificationId');
        throw Exception('Notification not found');
      }
    } catch (e) {
      debugPrint('Error deleting notification $notificationId: $e');
      rethrow;
    }
  }
}
