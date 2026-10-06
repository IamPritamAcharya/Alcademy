import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:port/features/private_space/models/private_note.dart';

class NoteRepository {
  final Future<Directory> Function() _documentsDirectory;
  final DateTime Function() _now;
  NoteRepository(
      {Future<Directory> Function()? documentsDirectory,
      DateTime Function()? now})
      : _documentsDirectory =
            documentsDirectory ?? getApplicationDocumentsDirectory,
        _now = now ?? DateTime.now;

  Future<PrivateNote?> read(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return null;
    return PrivateNote.fromJson(
        jsonDecode(await file.readAsString()) as Map<String, dynamic>);
  }

  Future<String> save(
      {required String title,
      required String content,
      String? filePath,
      Map<String, dynamic> metadata = const {}}) async {
    final previous = filePath == null ? null : await read(filePath);
    final now = _now().millisecondsSinceEpoch;
    final note = PrivateNote(
        title: title.isEmpty ? 'Untitled Note' : title,
        content: content,
        createdAt: previous?.createdAt ?? now,
        modifiedAt: now,
        metadata: {...?previous?.metadata, ...metadata});
    if (filePath == null) {
      final documents = await _documentsDirectory();
      final directory =
          Directory(path.join(documents.path, 'private_space', 'notes'));
      await directory.create(recursive: true);
      filePath = path.join(directory.path, 'note_$now.json');
    }
    // Finish writing before replacing an existing note.
    final temporary = File('$filePath.tmp');
    await temporary.writeAsString(jsonEncode(note.toJson()), flush: true);
    await temporary.rename(filePath);
    return filePath;
  }
}
