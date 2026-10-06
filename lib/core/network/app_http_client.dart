import 'package:http/http.dart' as http;

/// Shared transport. Repositories may inject a client for tests.
final http.Client appHttpClient = http.Client();
const requestTimeout = Duration(seconds: 10);
