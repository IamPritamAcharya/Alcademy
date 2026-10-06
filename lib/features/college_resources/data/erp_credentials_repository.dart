import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ErpCredentials {
  final String username;
  final String password;

  const ErpCredentials({required this.username, required this.password});
}

class ErpCredentialsRepository {
  static const storageKey = 'erp_credentials';
  final FlutterSecureStorage storage;

  const ErpCredentialsRepository({
    this.storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(storageNamespace: 'AlcademyErp'),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.unlocked_this_device,
      ),
    ),
  });

  Future<ErpCredentials?> read() async {
    final value = await storage.read(key: storageKey);
    if (value == null) return null;
    final data = jsonDecode(value) as Map<String, dynamic>;
    final username = data['username'] as String;
    final password = data['password'] as String;
    if (username.isEmpty || password.isEmpty) return null;
    return ErpCredentials(username: username, password: password);
  }

  Future<void> save(ErpCredentials credentials) {
    if (credentials.username.trim().isEmpty || credentials.password.isEmpty) {
      throw ArgumentError('Both ERP fields are required.');
    }
    return storage.write(
      key: storageKey,
      value: jsonEncode({
        'username': credentials.username.trim(),
        'password': credentials.password,
      }),
    );
  }

  Future<void> delete() => storage.delete(key: storageKey);
}
