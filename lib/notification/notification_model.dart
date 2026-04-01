import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String? imageUrl;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    required this.timestamp,
    this.data,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'data': data,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    try {
      final id = map['id']?.toString().trim() ?? '';
      final title = map['title']?.toString().trim() ?? '';
      final body = map['body']?.toString().trim() ?? '';
      final imageUrl = map['imageUrl']?.toString().trim();
      final timestamp = map['timestamp'];

      if (id.isEmpty) {
        throw Exception('Notification ID cannot be empty');
      }

      if (title.isEmpty && body.isEmpty) {
        throw Exception('Notification must have either title or body');
      }

      return NotificationModel(
        id: id,
        title: title.isNotEmpty ? title : 'New Notification',
        body: body.isNotEmpty ? body : 'You have a new notification',
        imageUrl: imageUrl?.isNotEmpty == true ? imageUrl : null,
        timestamp: timestamp != null && timestamp is int
            ? DateTime.fromMillisecondsSinceEpoch(timestamp)
            : DateTime.now(),
        data: map['data'] as Map<String, dynamic>?,
      );
    } catch (e) {
      print('Error parsing notification from map: $e');
      print('Map data: $map');
      throw Exception('Failed to parse notification: $e');
    }
  }

  factory NotificationModel.fromRemoteMessage(RemoteMessage message) {
    try {
      String title = '';
      String body = '';
      String? imageUrl;

      if (message.notification?.title != null &&
          message.notification!.title!.trim().isNotEmpty) {
        title = message.notification!.title!.trim();
      } else if (message.data.containsKey('title') &&
          message.data['title']?.toString().trim().isNotEmpty == true) {
        title = message.data['title'].toString().trim();
      }

      if (message.notification?.body != null &&
          message.notification!.body!.trim().isNotEmpty) {
        body = message.notification!.body!.trim();
      } else if (message.data.containsKey('body') &&
          message.data['body']?.toString().trim().isNotEmpty == true) {
        body = message.data['body'].toString().trim();
      } else if (message.data.containsKey('message') &&
          message.data['message']?.toString().trim().isNotEmpty == true) {
        body = message.data['message'].toString().trim();
      }

      if (message.data.containsKey('image') &&
          message.data['image']?.toString().trim().isNotEmpty == true) {
        imageUrl = message.data['image'].toString().trim();
      } else if (message.data.containsKey('imageUrl') &&
          message.data['imageUrl']?.toString().trim().isNotEmpty == true) {
        imageUrl = message.data['imageUrl'].toString().trim();
      } else if (message.notification?.android?.imageUrl != null &&
          message.notification!.android!.imageUrl!.trim().isNotEmpty) {
        imageUrl = message.notification!.android!.imageUrl!.trim();
      }

      if (title.isEmpty && body.isEmpty) {
        throw Exception('RemoteMessage has no valid title or body');
      }

      if (title.isEmpty) {
        title = 'New Notification';
      }
      if (body.isEmpty) {
        body = 'You have a new notification';
      }

      String id;
      if (message.messageId != null && message.messageId!.trim().isNotEmpty) {
        id = message.messageId!.trim();
      } else {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final contentHash =
            '${title}_${body}_${message.data.toString()}'.hashCode;
        id = 'msg_${timestamp}_${contentHash.abs()}';
      }

      return NotificationModel(
        id: id,
        title: title,
        body: body,
        imageUrl: imageUrl,
        timestamp: DateTime.now(),
        data: message.data.isNotEmpty
            ? Map<String, dynamic>.from(message.data)
            : null,
      );
    } catch (e) {
      print('Error creating notification from RemoteMessage: $e');

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return NotificationModel(
        id: 'emergency_$timestamp',
        title: 'Notification Received',
        body: 'A notification was received but could not be parsed properly',
        imageUrl: null,
        timestamp: DateTime.now(),
        data: {'error': 'parsing_failed', 'original_data': message.data},
      );
    }
  }

  bool isValid() {
    return id.isNotEmpty &&
        title.isNotEmpty &&
        title != 'Error' &&
        title != 'No Title' &&
        body.isNotEmpty &&
        body != 'No Body' &&
        body != 'Failed to parse notification';
  }

  @override
  String toString() {
    return 'NotificationModel{id: $id, title: $title, body: $body, imageUrl: $imageUrl, timestamp: $timestamp}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
