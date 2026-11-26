import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The style module is pure geometry, codecs and painters: the engine and the
/// design system must stay out of it.
void main() {
  final imports = RegExp("^import '([^']+)'", multiLine: true);

  Iterable<(String, String)> importsOf(String directory) sync* {
    final files = Directory(
      directory,
    ).listSync().whereType<File>().where((file) => file.path.endsWith('.dart'));
    for (final file in files) {
      for (final match in imports.allMatches(file.readAsStringSync())) {
        yield (file.path, match.group(1)!);
      }
    }
  }

  test('style imports only the SDK, the core JSON helpers and itself', () {
    final found = importsOf('lib/src/note/style').toList();
    expect(found, isNotEmpty);
    for (final (file, target) in found) {
      final allowed =
          target.startsWith('dart:') ||
          target == 'package:flutter/foundation.dart' ||
          target == 'package:flutter/painting.dart' ||
          target == 'package:open_note/src/note/core/note_json.dart' ||
          target.startsWith('package:open_note/src/note/style/');
      expect(allowed, isTrue, reason: '$file imports $target');
    }
  });

  test('neither module imports a design system', () {
    for (final directory in ['lib/src/note/style', 'lib/src/note/template']) {
      for (final (file, target) in importsOf(directory)) {
        expect(
          target,
          isNot(anyOf(contains('material.dart'), contains('cupertino.dart'))),
          reason: file,
        );
      }
    }
  });
}
