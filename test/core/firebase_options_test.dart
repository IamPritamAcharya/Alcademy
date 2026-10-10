import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:port/firebase_options.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('iOS initialization uses its native Firebase plist', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(DefaultFirebaseOptions.currentPlatform, isNull);
  });

  test('Android initialization retains its existing Firebase app', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(
      DefaultFirebaseOptions.currentPlatform,
      DefaultFirebaseOptions.android,
    );
  });
}
