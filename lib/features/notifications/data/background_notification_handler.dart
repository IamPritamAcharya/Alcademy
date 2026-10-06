import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message received: ${message.messageId}');
  debugPrint('Message data: ${message.data}');
  debugPrint(
      'Message notification: ${message.notification?.title} - ${message.notification?.body}');

  try {
    String title = message.notification?.title?.trim() ?? '';
    String body = message.notification?.body?.trim() ?? '';

    debugPrint('Extracted - Title: "$title", Body: "$body"');

    if (title.isEmpty && message.data.containsKey('title')) {
      title = message.data['title']?.toString().trim() ?? '';
    }
    if (body.isEmpty) {
      if (message.data.containsKey('body')) {
        body = message.data['body']?.toString().trim() ?? '';
      } else if (message.data.containsKey('message')) {
        body = message.data['message']?.toString().trim() ?? '';
      }
    }

    if (title.isEmpty && body.isEmpty) {
      debugPrint('Background message has no valid title or body, rejecting');
      return;
    }

    if (title.isEmpty) {
      title = 'New Notification';
    }
    if (body.isEmpty) {
      body = 'You have a new notification';
    }

    String id = message.messageId?.trim() ??
        'bg_${DateTime.now().millisecondsSinceEpoch}';

    final notificationData = {
      'id': id,
      'title': title,
      'body': body,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'data': message.data.isNotEmpty
          ? Map<String, dynamic>.from(message.data)
          : <String, dynamic>{},
    };

    debugPrint('Saving notification data: $notificationData');

    final prefs = await SharedPreferences.getInstance();

    List<String> backgroundQueue =
        prefs.getStringList('background_notification_queue') ?? [];
    debugPrint('Current queue size: ${backgroundQueue.length}');

    bool alreadyQueued = false;
    for (String queuedJson in backgroundQueue) {
      try {
        final queuedData = jsonDecode(queuedJson);
        if (queuedData['id'] == id) {
          alreadyQueued = true;
          debugPrint('Notification already in queue: $id');
          break;
        }
      } catch (e) {
        debugPrint('Error checking queue item: $e');
      }
    }

    if (!alreadyQueued) {
      if (backgroundQueue.length >= 50) {
        backgroundQueue = backgroundQueue.sublist(backgroundQueue.length - 40);
        debugPrint(
            'Cleaned background queue to ${backgroundQueue.length} items');
      }

      backgroundQueue.add(jsonEncode(notificationData));

      await prefs.setStringList(
          'background_notification_queue', backgroundQueue);
      await prefs.setInt('last_background_notification',
          DateTime.now().millisecondsSinceEpoch);
      await prefs.setBool('has_new_notification', true);

      debugPrint(
          "Background notification queued successfully: $title (Queue size: ${backgroundQueue.length})");

      final savedQueue =
          prefs.getStringList('background_notification_queue') ?? [];
      debugPrint("Queue verification - Saved ${savedQueue.length} items");
    } else {
      debugPrint("Background notification already queued: $title");
    }
  } catch (e) {
    debugPrint("Critical error in background handler: $e");

    try {
      final title =
          message.notification?.title?.trim() ?? 'Emergency Notification';
      final body =
          message.notification?.body?.trim() ?? 'Notification parsing failed';

      final prefs = await SharedPreferences.getInstance();
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final emergencyNotification = {
        'id': 'emergency_$timestamp',
        'title': title,
        'body': body,
        'timestamp': timestamp,
        'data': <String, dynamic>{},
      };

      List<String> backgroundQueue =
          prefs.getStringList('background_notification_queue') ?? [];
      backgroundQueue.add(jsonEncode(emergencyNotification));
      await prefs.setStringList(
          'background_notification_queue', backgroundQueue);
      await prefs.setBool('has_new_notification', true);

      debugPrint("Emergency notification saved: $title");
    } catch (emergencyError) {
      debugPrint("Emergency save also failed: $emergencyError");
    }
  }
}
