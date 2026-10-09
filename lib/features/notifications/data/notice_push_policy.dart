const testNoticeTopic = 'alcademy_notices_test_rmx3771_v1';
const productionNoticeTopic = 'alcademy_college_notices_v1';
const generalNotificationTopic = 'alcademy_general_v1';
const testGeneralNotificationTopic = 'alcademy_general_test_rmx3771_v1';

/// A test installation receives test notices alone. Production remains opt-in
/// at build time until rollout is explicitly enabled.
Map<String, bool> noticeTopicSubscriptions({
  required bool debugBuild,
  required bool testEnabled,
  required bool productionEnabled,
  required bool permissionGranted,
  bool noticesEnabled = true,
}) {
  final testing = debugBuild && testEnabled;
  return {
    testNoticeTopic: permissionGranted && noticesEnabled && testing,
    productionNoticeTopic:
        permissionGranted && noticesEnabled && productionEnabled && !testing,
  };
}

Map<String, bool> notificationTopicSubscriptions({
  required bool debugBuild,
  required bool testEnabled,
  required bool productionEnabled,
  required bool permissionGranted,
  required bool noticesEnabled,
  required bool generalEnabled,
}) {
  final testing = debugBuild && testEnabled;
  return {
    ...noticeTopicSubscriptions(
      debugBuild: debugBuild,
      testEnabled: testEnabled,
      productionEnabled: productionEnabled,
      permissionGranted: permissionGranted,
      noticesEnabled: noticesEnabled,
    ),
    testGeneralNotificationTopic:
        permissionGranted && generalEnabled && testing,
    generalNotificationTopic:
        permissionGranted && generalEnabled && productionEnabled && !testing,
  };
}
