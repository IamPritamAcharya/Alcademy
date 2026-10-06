import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:port/features/private_space/data/note_repository.dart';

void main() {
  late Directory directory;
  setUp(() async =>
      directory = await Directory.systemTemp.createTemp('alcademy_notes_'));
  tearDown(() async => directory.delete(recursive: true));

  test('Editing a legacy note preserves its creation time and unknown metadata',
      () async {
    final file = File('${directory.path}/old.json');
    await file.writeAsString(jsonEncode({
      'title': 'Old',
      'content': 'Original',
      'createdAt': 123,
      'modifiedAt': 124,
      'customField': 'keep',
    }));
    final now = DateTime(2026, 10, 6);
    final repository = NoteRepository(
        now: () => now, documentsDirectory: () async => directory);
    expect((await repository.read(file.path))!.title, 'Old');
    await repository.save(
        title: 'Updated',
        content: 'New content',
        filePath: file.path,
        metadata: {
          'fontSize': 18.0,
          'formatting': {'bold': true}
        });
    final json = jsonDecode(await file.readAsString());
    expect(json['createdAt'], 123);
    expect(json['modifiedAt'], now.millisecondsSinceEpoch);
    expect(json['customField'], 'keep');
    expect(json['fontSize'], 18.0);
    expect(json['content'], 'New content');
    expect(await File('${file.path}.tmp').exists(), isFalse);
  });

  test('New notes retain the existing directory and JSON format', () async {
    final repository =
        NoteRepository(documentsDirectory: () async => directory);
    final filePath = await repository.save(title: '', content: 'Note');
    expect(filePath, contains('/private_space/notes/note_'));
    final note = await repository.read(filePath);
    expect(note!.title, 'Untitled Note');
    expect(note.content, 'Note');
    expect(note.modifiedAt, note.createdAt);
  });
}
