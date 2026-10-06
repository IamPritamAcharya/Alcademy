import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:port/app/theme.dart';
import 'package:port/features/college_resources/data/erp_credentials_repository.dart';
import 'package:port/features/college_resources/presentation/erp_auto_login.dart';
import 'package:port/features/profile/presentation/profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/load_fonts.dart';

class _FailingRepository extends ErpCredentialsRepository {
  @override
  Future<void> save(ErpCredentials credentials) async =>
      throw StateError('Storage unavailable');
}

bool _hasNode() {
  try {
    return Process.runSync('node', ['--version']).exitCode == 0;
  } on ProcessException {
    return false;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({
      'userName': 'Student',
      'userBranch': 'CSE',
    });
  });
  const repository = ErpCredentialsRepository();

  test(
    'credentials round trip, preserve password whitespace and delete only ERP data',
    () async {
      await repository.storage.write(key: 'another_secret', value: 'keep');
      expect(await repository.read(), isNull);
      await repository.save(
        const ErpCredentials(username: ' student ', password: ' secret '),
      );
      final saved = await repository.read();
      expect(saved!.username, 'student');
      expect(saved.password, ' secret ');
      expect(
        (await SharedPreferences.getInstance()).getKeys(),
        isNot(contains(ErpCredentialsRepository.storageKey)),
      );
      await repository.delete();
      expect(await repository.read(), isNull);
      expect(await repository.storage.read(key: 'another_secret'), 'keep');
    },
  );

  test('automatic login is restricted to the HTTPS ERP login document', () {
    expect(
      ErpAutoLogin.isLoginPage('https://igit.icrp.in/academic/Index.aspx'),
      isTrue,
    );
    expect(ErpAutoLogin.isLoginPage('https://igit.icrp.in/academic/'), isTrue);
    for (final url in [
      'http://igit.icrp.in/academic/Index.aspx',
      'https://igit.icrp.in.evil.example/academic/Index.aspx',
      'https://igit.icrp.in:8443/academic/Index.aspx',
      'https://igit.icrp.in/academic/Student-cp/Students_profile.aspx',
    ]) {
      expect(ErpAutoLogin.isLoginPage(url), isFalse);
    }
  });

  test(
    'login script submits the real button and rejects foreign documents or form actions',
    () async {
      const password = 'quote"\\\n; globalThis.injected = true; //';
      final script = ErpAutoLogin.script(
        const ErpCredentials(username: 'student', password: password),
      );
      // Execute the generated JavaScript, rather than just comparing its text.
      for (final scenario in [
        'valid',
        'foreign-document',
        'foreign-action',
        'wrong-path',
        'missing-password',
      ]) {
        final result = await Process.run('node', [
          '-e',
          '''
        const scenario = ${jsonEncode(scenario)};
        global.location = {
          origin: scenario === 'foreign-document' ? 'https://evil.example' : 'https://igit.icrp.in',
          pathname: scenario === 'wrong-path' ? '/academic/other.aspx' : '/academic/Index.aspx',
          href: 'https://igit.icrp.in/academic/Index.aspx'
        };
        const form = { action: scenario === 'foreign-action' ? 'https://evil.example/login' : './Index.aspx' };
        const events = [];
        const username = { form, dispatchEvent: e => events.push(e.type) };
        const password = { form, dispatchEvent: e => events.push(e.type) };
        let clicked = 0;
        const login = { form, click: () => clicked++ };
        global.document = { getElementById: id => ({
          txt_uname: username, txt_password: scenario === 'missing-password' ? null : password, btn_login: login
        })[id] };
        const result = ${script.trim().replaceFirst(RegExp(r';$'), '')};
        process.stdout.write(JSON.stringify({ result, clicked, username: username.value, password: password.value, events, injected: !!global.injected }));
      ''',
        ]);
        expect(result.exitCode, 0, reason: result.stderr.toString());
        final data =
            jsonDecode(result.stdout as String) as Map<String, dynamic>;
        expect(data['injected'], false);
        expect(data['clicked'], scenario == 'valid' ? 1 : 0);
        if (scenario == 'valid') {
          expect(data['username'], 'student');
          expect(data['password'], password);
          expect(data['events'], ['input', 'change', 'input', 'change']);
        } else {
          expect(data.containsKey('password'), isFalse);
        }
      }
    },
    skip: _hasNode()
        ? false
        : 'Install Node.js to execute the ERP JavaScript test.',
  );

  testWidgets('Profile validates, saves, updates and forgets ERP credentials', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const UserProfilePage(focusErpCredentials: true),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save credentials'));
    await tester.tap(find.text('Save credentials'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your ERP username'), findsOneWidget);
    expect(find.text('Enter your ERP password'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'student');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret');
    await tester.ensureVisible(find.text('Save credentials'));
    await tester.tap(find.text('Save credentials'));
    await tester.pumpAndSettle();
    expect((await repository.read())!.password, 'secret');
    expect(find.text('Automatic login is enabled'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).at(1))
          .controller!
          .text,
      isEmpty,
    );
    await tester.enterText(find.byType(TextFormField).at(0), 'updated');
    await tester.ensureVisible(find.text('Save credentials'));
    await tester.tap(find.text('Save credentials'));
    await tester.pumpAndSettle();
    expect((await repository.read())!.username, 'updated');
    expect((await repository.read())!.password, 'secret');
    await tester.ensureVisible(find.text('Forget credentials'));
    await tester.tap(find.text('Forget credentials'));
    await tester.pumpAndSettle();
    expect(await repository.read(), isNull);
    expect(find.text('Automatic login is enabled'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed secure save never reports automatic login enabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: UserProfilePage(erpCredentials: _FailingRepository()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'student');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret');
    await tester.ensureVisible(find.text('Save credentials'));
    await tester.tap(find.text('Save credentials'));
    await tester.pumpAndSettle();
    expect(
      find.text('Couldn’t save securely. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Automatic login is enabled'), findsNothing);
    expect(await repository.read(), isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'ERP fields remain usable at narrow width with enlarged text and keyboard',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.6)),
            child: child!,
          ),
          home: const UserProfilePage(focusErpCredentials: true),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Save credentials'));
      await tester.pumpAndSettle();
      expect(find.text('Save credentials').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
