import 'package:flutter_test/flutter_test.dart';
import 'package:port/features/notifications/data/notice_push_policy.dart';

void main() {
  test('Default builds subscribe to neither topic', () {
    expect(
      noticeTopicSubscriptions(
        debugBuild: false,
        testEnabled: false,
        productionEnabled: false,
        permissionGranted: true,
      ),
      {testNoticeTopic: false, productionNoticeTopic: false},
    );
  });

  test('Test flag cannot subscribe a release build to the test topic', () {
    expect(
      noticeTopicSubscriptions(
        debugBuild: false,
        testEnabled: true,
        productionEnabled: false,
        permissionGranted: true,
      )[testNoticeTopic],
      false,
    );
  });

  test('Explicit test installation receives test notices alone', () {
    expect(
      noticeTopicSubscriptions(
        debugBuild: true,
        testEnabled: true,
        productionEnabled: true,
        permissionGranted: true,
      ),
      {testNoticeTopic: true, productionNoticeTopic: false},
    );
  });

  test('Production rollout subscribes permitted users to production alone', () {
    expect(
      noticeTopicSubscriptions(
        debugBuild: false,
        testEnabled: false,
        productionEnabled: true,
        permissionGranted: true,
      ),
      {testNoticeTopic: false, productionNoticeTopic: true},
    );
  });

  test('Denied permission unsubscribes both topics', () {
    expect(
      noticeTopicSubscriptions(
        debugBuild: true,
        testEnabled: true,
        productionEnabled: true,
        permissionGranted: false,
      ),
      {testNoticeTopic: false, productionNoticeTopic: false},
    );
  });
}
