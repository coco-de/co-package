import 'dart:io';

import 'package:co_golden_gallery/co_golden_gallery.dart';

Future<void> main(List<String> arguments) async {
  exitCode = await runGalleryCli(arguments);
}
