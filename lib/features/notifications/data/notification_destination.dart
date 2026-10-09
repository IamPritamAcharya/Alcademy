import 'dart:convert';

/// FCM can redeliver the same outbox batch with a different transport message ID.
/// Use its stable batch identity for local history and foreground deduplication.
String? noticeBatchNotificationId(Map<String, dynamic>? data) {
  final batch = data?['batch_id'];
  if (notificationDestination(data) != '/notice' ||
      batch is! String ||
      !RegExp(r'^[a-f0-9]{24}$').hasMatch(batch)) {
    return null;
  }
  final audience = data?['test'] == 'true' ? 'test' : 'production';
  return 'notice_${audience}_$batch';
}

/// Only known in-app routes can be requested by a push payload.
String notificationDestination(Map<String, dynamic>? data) =>
    data?['type'] == 'college_notice' && data?['route'] == '/notice'
    ? '/notice'
    : '/notifications';

/// Preserve local notifications already posted with a plain ID payload.
({String id, String route}) decodeNotificationTap(String payload) {
  try {
    final value = jsonDecode(payload);
    if (value is Map<String, dynamic> && value['id'] is String) {
      return (
        id: value['id'] as String,
        route: value['route'] == '/notice' ? '/notice' : '/notifications',
      );
    }
  } on FormatException {
    // Older app versions used the notification ID directly.
  }
  return (id: payload, route: '/notifications');
}
