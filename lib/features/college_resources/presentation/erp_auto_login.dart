import 'dart:convert';

import '../data/erp_credentials_repository.dart';

abstract final class ErpAutoLogin {
  static final loginUri = Uri.parse('https://igit.icrp.in/academic/Index.aspx');

  static bool isLoginPage(String url) {
    final uri = Uri.tryParse(url);
    return uri != null &&
        uri.scheme == 'https' &&
        uri.host == loginUri.host &&
        uri.port == 443 &&
        const [
          '/academic/',
          '/academic/index.aspx',
        ].contains(uri.path.toLowerCase());
  }

  // Check the live document as well as the navigation callback: a redirect may
  // have completed between onPageFinished and this script executing.
  static String script(ErpCredentials credentials) =>
      '''
    (() => {
      if (location.origin !== 'https://igit.icrp.in' ||
          !['/academic/', '/academic/index.aspx'].includes(location.pathname.toLowerCase())) return 'skipped';
      const username = document.getElementById('txt_uname');
      const password = document.getElementById('txt_password');
      const login = document.getElementById('btn_login');
      if (!username || !password || !login || !username.form ||
          username.form !== password.form || username.form !== login.form) return 'skipped';
      const action = new URL(username.form.action, location.href);
      if (action.origin !== location.origin ||
          !['/academic/', '/academic/index.aspx'].includes(action.pathname.toLowerCase())) return 'skipped';
      username.value = ${jsonEncode(credentials.username)};
      password.value = ${jsonEncode(credentials.password)};
      for (const field of [username, password]) {
        field.dispatchEvent(new Event('input', { bubbles: true }));
        field.dispatchEvent(new Event('change', { bubbles: true }));
      }
      login.click();
      return 'submitted';
    })();
  ''';
}
