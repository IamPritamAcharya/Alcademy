import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:port/features/college_resources/data/erp_credentials_repository.dart';
import 'package:port/features/college_resources/data/erp_data_flow.dart';
import 'package:port/features/college_resources/presentation/erp_auto_login.dart';

void main() {
  const credentials = ErpCredentials(
    username: 'student',
    password: 'test-only',
  );
  final login = ErpAutoLogin.loginUri.toString();
  final profile = ErpAutoLogin.profileUri.toString();

  test('waits for the trusted document and stops after submission', () async {
    var evaluations = 0;
    expect(
      await ErpAutoLogin.submitWhenReady(
        credentials: credentials,
        evaluate: (_) async => ++evaluations < 3 ? 'skipped' : '"submitted"',
        isActive: () => true,
        wait: (_) async {},
      ),
      isTrue,
    );
    expect(evaluations, 3);
  });

  test(
    'readiness retries are bounded and cancellation stops injection',
    () async {
      var evaluations = 0;
      expect(
        await ErpAutoLogin.submitWhenReady(
          credentials: credentials,
          evaluate: (_) async {
            evaluations++;
            return 'skipped';
          },
          isActive: () => true,
          wait: (_) async {},
        ),
        isFalse,
      );
      expect(evaluations, 48);
      expect(
        await ErpAutoLogin.submitWhenReady(
          credentials: credentials,
          evaluate: (_) async {
            evaluations++;
            return 'submitted';
          },
          isActive: () => false,
          wait: (_) async {},
        ),
        isFalse,
      );
      expect(evaluations, 48);
    },
  );

  for (final path in [
    'Form_Students_Attendance_Monthy_Count.aspx',
    'Form_students_pay_fees.aspx',
    'Student_Result.aspx',
    'Form_Display_Division_TimeTableS.aspx',
    'List_Students_College_Wise_Holidays.aspx',
  ]) {
    test(
      'fresh session bootstraps and loads $path without opening ERP',
      () async {
        final target = Uri.parse(
          'https://igit.icrp.in/academic/Student-cp/$path',
        );
        final visits = <Uri>[];
        final errors = <ErpDataException>[];
        final loaded = <String>[];
        final pendingCredentials = Completer<ErpCredentials?>();
        final pendingSubmission = Completer<bool>();
        var submissions = 0;
        final flow = ErpDataFlow<String>(
          target: target,
          resource: 'records',
          parse: (markup) => markup,
          readCredentials: () => pendingCredentials.future,
          navigate: (url) async => visits.add(url),
          signIn: (saved) async {
            expect(saved, credentials);
            submissions++;
            return pendingSubmission.future;
          },
          readMarkup: () async => 'student records',
          onLoaded: loaded.add,
          onError: errors.add,
          onStatus: (_) {},
        );
        await flow.start();
        expect(visits, [ErpAutoLogin.profileUri]);
        flow.pageStarted(login);
        final signingIn = flow.pageFinished(login);
        // Repeated callbacks while secure storage is pending must not reject it.
        for (var i = 0; i < 10; i++) {
          await flow.pageFinished(login);
        }
        pendingCredentials.complete(credentials);
        await Future<void>.delayed(Duration.zero);
        flow.pageStarted(login);
        await flow.pageFinished(login);
        expect(errors, isEmpty);
        pendingSubmission.complete(true);
        await signingIn;
        expect(errors, isEmpty);
        expect(submissions, 1);
        flow.pageStarted(profile);
        await flow.pageFinished(profile);
        await flow.pageFinished(profile); // Duplicate redirect callback.
        flow.pageStarted(target.toString());
        await flow.pageFinished(target.toString());
        expect(visits, [ErpAutoLogin.profileUri, target]);
        expect(loaded, ['student records']);
        expect(errors, isEmpty);
      },
    );
  }

  test(
    'a real login POST returning to login fails once, without a retry loop',
    () async {
      final errors = <ErpDataException>[];
      var submissions = 0;
      final flow = ErpDataFlow<String>(
        target: Uri.parse(
          'https://igit.icrp.in/academic/Student-cp/Student_Result.aspx',
        ),
        resource: 'results',
        parse: (value) => value,
        readCredentials: () async => credentials,
        navigate: (_) async {},
        signIn: (_) async {
          submissions++;
          return true;
        },
        readMarkup: () async => 'must not load',
        onLoaded: (_) => fail('Rejected login must not load records'),
        onError: errors.add,
        onStatus: (_) {},
      );
      await flow.start();
      flow.pageStarted(login);
      await flow.pageFinished(login);
      flow.pageStarted(
        login,
      ); // POST response, unlike a duplicate finish event.
      await flow.pageFinished(login);
      await flow.pageFinished(login);
      expect(submissions, 1);
      expect(errors.single.reason, ErpDataFailure.authentication);
    },
  );
}
