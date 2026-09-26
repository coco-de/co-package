import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

/// Writes a file that starts with a PNG signature and an IHDR header of the
/// given size — enough for the gallery, which only reads the header.
void writePng(String path, {int width = 4, int height = 8}) {
  final header = ByteData(33);
  const signature = [137, 80, 78, 71, 13, 10, 26, 10];
  for (var i = 0; i < signature.length; i++) {
    header.setUint8(i, signature[i]);
  }
  header
    ..setUint32(8, 13)
    ..setUint8(12, 0x49)
    ..setUint8(13, 0x48)
    ..setUint8(14, 0x44)
    ..setUint8(15, 0x52)
    ..setUint32(16, width)
    ..setUint32(20, height);
  File(path)
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(header.buffer.asUint8List());
}

/// A co_golden run manifest result.
Map<String, Object?> result({
  required String stem,
  required String theme,
  required String locale,
  String device = 'phone',
  String status = 'passed',
  String? image,
  int overflowCount = 0,
  List<String> errors = const [],
}) => {
  'variant': {
    'device': {'name': device},
    'theme': theme,
    'locale': locale,
    'textScale': 1,
    'platform': 'android',
  },
  'fileStem': stem,
  'status': status,
  'durationMs': 12,
  'image': image,
  'overflowCount': overflowCount,
  'errors': errors,
};

/// Writes a run manifest below `<root>/runs/<suite>/<scenario>.json`.
void writeManifest(
  Directory root, {
  required String suite,
  required String scenario,
  required List<Map<String, Object?>> results,
  String? description,
  int schemaVersion = 1,
  Object? axes,
}) {
  File(p.join(root.path, 'runs', suite, '$scenario.json'))
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(
      jsonEncode({
        'schema': 'co_golden.run',
        'schemaVersion': schemaVersion,
        'suite': suite,
        'scenario': scenario,
        'description': description,
        'mode': 'capture',
        'generatedAt': '2026-09-26T00:00:00.000Z',
        'plan': {'combinations': results.length, 'excluded': 0, 'axes': ?axes},
        'results': results,
      }),
    );
}

/// A source root with one matrix scenario (one failed variant) and one plain
/// regression image.
Directory sampleSource() {
  final root = Directory.systemTemp.createTempSync('co_golden_gallery_');
  writePng(
    p.join(root.path, 'images', 'auth', 'login', 'phone__light__ko.png'),
  );
  writePng(
    p.join(root.path, 'images', 'auth', 'login', 'phone__dark__ko.png'),
    width: 6,
    height: 9,
  );
  writePng(
    p.join(root.path, 'images', 'regression', 'auth', 'login_page.png'),
    width: 20,
    height: 10,
  );
  writeManifest(
    root,
    suite: 'auth',
    scenario: 'login',
    description: 'Login <form> & social buttons',
    results: [
      result(
        stem: 'phone__light__ko',
        theme: 'light',
        locale: 'ko',
        image: 'images/auth/login/phone__light__ko.png',
      ),
      result(
        stem: 'phone__dark__ko',
        theme: 'dark',
        locale: 'ko',
        status: 'failed',
        overflowCount: 1,
        errors: ['A RenderFlex overflowed by 12 pixels </script>'],
        image: 'images/auth/login/phone__dark__ko.png',
      ),
    ],
  );
  return root;
}
