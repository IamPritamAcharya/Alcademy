import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:port/app/theme.dart';
import 'package:port/features/notifications/data/notification_preferences.dart';
import 'package:port/features/notifications/data/notice_push_policy.dart';
import 'package:port/features/profile/presentation/notification_preferences_section.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'Choices persist independently and filter notice and general messages',
    () async {
      const repository = NotificationPreferencesRepository();
      expect((await repository.read()).notices, true);
      await repository.setEnabled(NotificationCategory.notices, false);
      var saved = await const NotificationPreferencesRepository().read();
      expect(saved.notices, false);
      expect(saved.general, true);
      expect(saved.allows({'type': 'college_notice'}), false);
      expect(saved.allows({}), true);
      await repository.setEnabled(NotificationCategory.general, false);
      await repository.setEnabled(NotificationCategory.notices, true);
      saved = await repository.read();
      expect(saved.notices, true);
      expect(saved.general, false);
      expect(saved.allows({'type': 'announcement'}), false);
    },
  );

  test(
    'Production categories and test categories respect individual opt-outs',
    () {
      for (final testing in [false, true]) {
        final policy = notificationTopicSubscriptions(
          debugBuild: testing,
          testEnabled: testing,
          productionEnabled: true,
          permissionGranted: true,
          noticesEnabled: false,
          generalEnabled: true,
        );
        expect(policy[productionNoticeTopic], false);
        expect(policy[testNoticeTopic], false);
        expect(policy[generalNotificationTopic], !testing);
        expect(policy[testGeneralNotificationTopic], testing);
      }
    },
  );

  test('Denied phone permission unsubscribes all four topic variants', () {
    expect(
      notificationTopicSubscriptions(
        debugBuild: true,
        testEnabled: true,
        productionEnabled: true,
        permissionGranted: false,
        noticesEnabled: true,
        generalEnabled: true,
      ).values,
      everyElement(false),
    );
  });

  Future<void> mount(
    WidgetTester tester, {
    Future<bool> Function(bool)? sync,
    bool permission = true,
    double scale = 1,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: SingleChildScrollView(
              child: NotificationPreferencesSection(
                readPermission: () async => permission,
                syncSubscriptions: sync ?? (_) async => true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Profile switches persist and restore independent choices', (
    tester,
  ) async {
    var syncs = 0;
    await mount(
      tester,
      sync: (_) async {
        syncs++;
        return true;
      },
    );
    await tester.tap(find.byType(SwitchListTile).first);
    await tester.pumpAndSettle();
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile).first).value,
      false,
    );
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile).last).value,
      true,
    );
    expect(syncs, 1);
    await tester.pumpWidget(const SizedBox());
    await mount(tester);
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile).first).value,
      false,
    );
    await tester.tap(find.byType(SwitchListTile).last);
    await tester.pumpAndSettle();
    expect(
      (await const NotificationPreferencesRepository().read()).general,
      false,
    );
  });

  testWidgets(
    'Failed topic update preserves the saved choice and explains retry',
    (tester) async {
      await mount(tester, sync: (_) async => false);
      await tester.tap(find.byType(SwitchListTile).first);
      await tester.pumpAndSettle();
      expect(
        (await const NotificationPreferencesRepository().read()).notices,
        false,
      );
      expect(find.textContaining('Topic changes will retry'), findsOneWidget);
      expect(
        tester
            .widget<SwitchListTile>(find.byType(SwitchListTile).first)
            .onChanged,
        isNotNull,
      );
    },
  );

  testWidgets(
    'Blocked permission keeps preferences editable and explains phone settings',
    (tester) async {
      await mount(tester, permission: false);
      expect(
        find.textContaining('blocked in your phone settings'),
        findsOneWidget,
      );
      await tester.tap(find.byType(SwitchListTile).last);
      await tester.pumpAndSettle();
      expect(
        (await const NotificationPreferencesRepository().read()).general,
        false,
      );
    },
  );

  testWidgets('Pending sync keeps switches usable and ignores stale failures', (
    tester,
  ) async {
    final pending = Completer<bool>();
    var calls = 0;
    await mount(
      tester,
      sync: (_) {
        calls++;
        return calls == 1 ? pending.future : Future.value(true);
      },
    );
    await tester.tap(find.byType(SwitchListTile).first);
    await tester.pumpAndSettle();
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile).last).onChanged,
      isNotNull,
    );
    await tester.tap(find.byType(SwitchListTile).last);
    await tester.pumpAndSettle();
    pending.complete(false);
    await tester.pumpAndSettle();
    final preferences = await const NotificationPreferencesRepository().read();
    expect(preferences.notices, false);
    expect(preferences.general, false);
    expect(find.textContaining('Topic changes will retry'), findsNothing);
  });

  testWidgets('Notification controls fit 320px with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mount(tester, scale: 1.6);
    expect(tester.takeException(), isNull);
  });
}
