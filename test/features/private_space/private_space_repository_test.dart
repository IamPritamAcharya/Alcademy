import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:port/features/private_space/data/private_space_repository.dart';
import 'package:port/features/private_space/models/private_category.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('Existing manifests survive imports and saving with legacy keys',
      () async {
    final directory =
        await Directory.systemTemp.createTemp('alcademy_private_');
    addTearDown(() => directory.delete(recursive: true));
    SharedPreferences.setMockInitialValues({
      'private_photos': ['old-photo']
    });
    final repository =
        PrivateSpaceRepository(documentsDirectory: () async => directory);
    final manifest = await repository.loadManifest();
    expect(manifest[PrivateCategory.photos], ['old-photo']);
    final source = File('${directory.path}/photo.jpg');
    await source.writeAsBytes([1, 2, 3]);
    final imported =
        await repository.importFile(source.path, PrivateCategory.photos);
    expect(imported, contains('/private_space/photos/'));
    expect(await File(imported).readAsBytes(), [1, 2, 3]);
    expect(await source.exists(), isTrue);
    manifest[PrivateCategory.photos]!.add(imported);
    await repository.saveManifest(manifest);
    expect(
        (await SharedPreferences.getInstance()).getStringList('private_photos'),
        ['old-photo', imported]);
    await repository.deleteFile(imported);
    expect(await File(imported).exists(), isFalse);
  });
}
