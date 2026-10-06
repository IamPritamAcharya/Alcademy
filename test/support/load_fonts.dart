import 'dart:io';
import 'package:flutter/services.dart';

Future<void> loadAppFonts() async {
  await (FontLoader('ProductSans')
        ..addFont(rootBundle.load('assets/fonts/Product Sans Regular.ttf'))
        ..addFont(rootBundle.load('assets/fonts/Product Sans Bold.ttf')))
      .load();
  await (FontLoader(
    'MaterialIcons',
  )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  // Match Android's fallback for symbols absent from Product Sans (e.g. ₹).
  // Locate the font relative to flutter_tester, without a machine-specific path.
  var directory = File(Platform.resolvedExecutable).parent;
  while (directory.parent.path != directory.path) {
    final font = File('${directory.path}/material_fonts/Roboto-Regular.ttf');
    if (await font.exists()) {
      await (FontLoader('Roboto')..addFont(
            font.readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
          ))
          .load();
      break;
    }
    directory = directory.parent;
  }
}
