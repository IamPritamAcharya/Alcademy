import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:port/features/private_space/models/private_category.dart';

class PrivateSpaceRepository {
  final Future<Directory> Function() _documentsDirectory;
  final Future<SharedPreferences> Function() _preferences;
  PrivateSpaceRepository(
      {Future<Directory> Function()? documentsDirectory,
      Future<SharedPreferences> Function()? preferences})
      : _documentsDirectory =
            documentsDirectory ?? getApplicationDocumentsDirectory,
        _preferences = preferences ?? SharedPreferences.getInstance;

  Future<Directory> initialize() async {
    final documents = await _documentsDirectory();
    final root = Directory(path.join(documents.path, 'private_space'));
    for (final category in PrivateCategory.values) {
      await Directory(path.join(root.path, category.folder))
          .create(recursive: true);
    }
    return root;
  }

  Future<Map<PrivateCategory, List<String>>> loadManifest() async {
    final prefs = await _preferences();
    return {
      for (final category in PrivateCategory.values)
        category: prefs.getStringList(category.preferencesKey) ?? []
    };
  }

  Future<void> saveManifest(Map<PrivateCategory, List<String>> manifest) async {
    final prefs = await _preferences();
    for (final entry in manifest.entries) {
      await prefs.setStringList(entry.key.preferencesKey, entry.value);
    }
  }

  Future<String> importFile(
      String originalPath, PrivateCategory category) async {
    final source = File(originalPath);
    if (!await source.exists()) {
      throw const FileSystemException('Source file not found');
    }
    final root = await initialize();
    final name =
        '${DateTime.now().millisecondsSinceEpoch}_${path.basename(originalPath)}';
    final destination = path.join(root.path, category.folder, name);
    await source.copy(destination);
    return destination;
  }

  Future<void> deleteFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) await file.delete();
  }
}
