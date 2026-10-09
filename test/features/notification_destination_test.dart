import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:port/features/notifications/data/notification_destination.dart';

void main() {
  test(
    'Notice retries retain their identity independently of FCM message ID',
    () {
      final data = <String, dynamic>{
        'type': 'college_notice',
        'route': '/notice',
        'batch_id': 'abcdef0123456789abcdef01',
        'test': 'true',
      };
      expect(
        noticeBatchNotificationId(data),
        'notice_test_abcdef0123456789abcdef01',
      );
      expect(
        noticeBatchNotificationId({...data, 'test': 'false'}),
        'notice_production_abcdef0123456789abcdef01',
      );
      expect(
        noticeBatchNotificationId({...data, 'batch_id': '../../invalid'}),
        isNull,
      );
      expect(noticeBatchNotificationId({'type': 'other'}), isNull);
    },
  );
  test(
    'Notice pushes open Notices; unknown routes remain in notification history',
    () {
      expect(
        notificationDestination({'type': 'college_notice', 'route': '/notice'}),
        '/notice',
      );
      expect(
        notificationDestination({
          'type': 'college_notice',
          'route': 'https://example.com',
        }),
        '/notifications',
      );
      expect(notificationDestination({'route': '/notice'}), '/notifications');
      expect(notificationDestination(null), '/notifications');
    },
  );

  test(
    'Local notification taps preserve the destination and older payloads',
    () {
      expect(
        decodeNotificationTap(
          jsonEncode({'id': 'batch-1', 'route': '/notice'}),
        ),
        (id: 'batch-1', route: '/notice'),
      );
      expect(decodeNotificationTap('old-message-id'), (
        id: 'old-message-id',
        route: '/notifications',
      ));
      expect(
        decodeNotificationTap(jsonEncode({'id': 'batch-1', 'route': '/user'})),
        (id: 'batch-1', route: '/notifications'),
      );
    },
  );
}
