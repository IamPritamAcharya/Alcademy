import 'erp_credentials_repository.dart';
import '../presentation/erp_auto_login.dart';

enum ErpDataFailure {
  credentialsRequired,
  authentication,
  connection,
  unavailable,
}

class ErpDataException implements Exception {
  final ErpDataFailure reason;
  final String message;
  const ErpDataException(this.reason, this.message);
}

/// Enter through the same profile page as ERP to establish the student session.
/// Existing cookies are reused; credentials are read only after a login redirect.
class ErpDataFlow<T> {
  final Uri target;
  final String resource;
  final T Function(String) parse;
  final Future<ErpCredentials?> Function() readCredentials;
  final Future<void> Function(Uri) navigate;
  final Future<bool> Function(ErpCredentials) signIn;
  final Future<String> Function() readMarkup;
  final void Function(T) onLoaded;
  final void Function(ErpDataException) onError;
  final void Function(String) onStatus;
  bool _attemptedLogin = false;
  bool _loginInProgress = false;
  bool _loginNavigationStarted = false;
  bool _returnedToTimetable = false;
  bool _finished = false;
  int _visits = 0;

  ErpDataFlow({
    required this.target,
    required this.resource,
    required this.parse,
    required this.readCredentials,
    required this.navigate,
    required this.signIn,
    required this.readMarkup,
    required this.onLoaded,
    required this.onError,
    required this.onStatus,
  });

  static bool trusted(String url) {
    final uri = Uri.tryParse(url);
    return uri != null &&
        uri.scheme == 'https' &&
        uri.host == 'igit.icrp.in' &&
        uri.port == 443;
  }

  Future<void> start() async => navigate(ErpAutoLogin.profileUri);

  void pageStarted(String url) {
    if (_finished) return;
    if (_attemptedLogin) _loginNavigationStarted = true;
  }

  Future<void> pageFinished(String url) async {
    if (_finished) return;
    try {
      if (!trusted(url)) {
        fail(
          const ErpDataException(
            ErpDataFailure.connection,
            'ERP redirected to an unexpected website.',
          ),
        );
        return;
      }
      if (ErpAutoLogin.isLoginPage(url) &&
          _attemptedLogin &&
          (_loginInProgress || !_loginNavigationStarted)) {
        return;
      }
      if (++_visits > 6) {
        fail(
          const ErpDataException(
            ErpDataFailure.authentication,
            'ERP couldn’t keep the session active. Try signing in through ERP.',
          ),
        );
        return;
      }
      final uri = Uri.parse(url);
      if (uri.path.toLowerCase() == target.path.toLowerCase()) {
        final timetable = parse(await readMarkup());
        if (_finished) return;
        _finished = true;
        onLoaded(timetable);
      } else if (ErpAutoLogin.isLoginPage(url)) {
        if (_attemptedLogin) {
          // WebViews can finish the same document more than once while the
          // credential read or form submission is still in flight.
          if (!_loginNavigationStarted) return;
          fail(
            const ErpDataException(
              ErpDataFailure.authentication,
              'ERP didn’t accept the saved login. Check your credentials in Profile.',
            ),
          );
          return;
        }
        _attemptedLogin = true;
        _loginInProgress = true;
        final credentials = await readCredentials();
        if (_finished) return;
        if (credentials == null) {
          fail(
            const ErpDataException(
              ErpDataFailure.credentialsRequired,
              'Save your ERP credentials in Profile, or sign in through ERP first.',
            ),
          );
          return;
        }
        onStatus('Signing into ERP…');
        final submitted = await signIn(credentials);
        _loginInProgress = false;
        if (!submitted) {
          fail(
            const ErpDataException(
              ErpDataFailure.authentication,
              'The ERP login form couldn’t be submitted. Open ERP to sign in.',
            ),
          );
        }
      } else if (uri.path.toLowerCase() ==
          ErpAutoLogin.profileUri.path.toLowerCase()) {
        if (_returnedToTimetable) return;
        _returnedToTimetable = true;
        onStatus('Reading your $resource…');
        await navigate(target);
      } else {
        fail(
          ErpDataException(
            ErpDataFailure.unavailable,
            'ERP didn’t return $resource. Open ERP to check your account.',
          ),
        );
      }
    } on FormatException catch (error) {
      fail(ErpDataException(ErpDataFailure.unavailable, error.message));
    } catch (_) {
      fail(
        ErpDataException(
          ErpDataFailure.connection,
          'Couldn’t load $resource. Check your connection and try again.',
        ),
      );
    }
  }

  void fail(ErpDataException error) {
    if (_finished) return;
    _finished = true;
    onError(error);
  }

  bool get active => !_finished;

  void cancel() => _finished = true;
}
