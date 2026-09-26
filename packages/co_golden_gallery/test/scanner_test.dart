import 'dart:io';

import 'package:co_golden_gallery/co_golden_gallery.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'fixture.dart';

void main() {
  late Directory root;

  setUp(() => root = sampleSource());
  tearDown(() => root.deleteSync(recursive: true));

  test('reads manifests and plain images into scenarios', () {
    final scan = scanGallerySources([root]);
    final scenarios = scan.catalog.scenarios;

    expect(scenarios.map((s) => '${s.suite}/${s.name}'), [
      'auth/login',
      'regression/auth',
    ]);
    expect(scan.catalog.imageCount, 3);
    expect(scan.catalog.failedCount, 1);
    expect(scan.missingImages, isEmpty);

    final login = scenarios.first;
    expect(login.fromManifest, isTrue);
    expect(login.description, 'Login <form> & social buttons');
    expect(login.images.map((image) => image.name), [
      'phone__light__ko',
      'phone__dark__ko',
    ]);
    final failed = login.images.last;
    expect(failed.status, GalleryStatus.failed);
    expect(failed.overflowCount, 1);
    expect((failed.width, failed.height), (6, 9));
    expect(failed.label, 'phone · dark · ko');

    final plain = scenarios.last;
    expect(plain.fromManifest, isFalse);
    expect(plain.images.single.name, 'login_page');
    expect(plain.images.single.status, GalleryStatus.unknown);
    expect(plain.images.single.path, 'images/regression/auth/login_page.png');
  });

  test('reads the declared axis order from the manifest plan', () {
    writeManifest(
      root,
      suite: 'store',
      scenario: 'header',
      results: [result(stem: 'phone__light__ko', theme: 'light', locale: 'ko')],
      axes: {
        'devices': ['phone', 'desktop'],
        'themes': ['light', 'dark'],
        'locales': ['ko', 'zh-Hant'],
        'textScales': [1, 1.3],
      },
    );

    final scenarios = scanGallerySources([root]).catalog.scenarios;
    final header = scenarios.singleWhere((s) => s.name == 'header');
    final login = scenarios.singleWhere((s) => s.name == 'login');

    expect(header.axes!.devices, ['phone', 'desktop']);
    expect(header.axes!.themes, ['light', 'dark']);
    expect(header.axes!.locales, ['ko', 'zh-Hant']);
    expect(header.axes!.textScales, [1.0, 1.3]);
    expect(login.axes, isNull, reason: 'manifests before plan.axes');
  });

  test('rejects a malformed plan.axes', () {
    writeManifest(
      root,
      suite: 'store',
      scenario: 'header',
      results: [result(stem: 'phone__light__ko', theme: 'light', locale: 'ko')],
      axes: {
        'themes': ['light', 2],
      },
    );

    expect(
      () => scanGallerySources([root]),
      throwsA(isA<GallerySourceException>()),
    );
  });

  test('reports images that a manifest names but that do not exist', () {
    File(
      p.join(root.path, 'images', 'auth', 'login', 'phone__dark__ko.png'),
    ).deleteSync();

    final scan = scanGallerySources([root]);

    expect(scan.missingImages, ['images/auth/login/phone__dark__ko.png']);
  });

  test('keeps a failed variant without an image', () {
    writeManifest(
      root,
      suite: 'auth',
      scenario: 'broken',
      results: [
        result(
          stem: 'phone__light__ko',
          theme: 'light',
          locale: 'ko',
          status: 'failed',
          errors: ['build: StateError'],
        ),
      ],
    );

    final scan = scanGallerySources([root]);
    final broken = scan.catalog.scenarios.firstWhere((s) => s.name == 'broken');

    expect(broken.images.single.path, isEmpty);
    expect(broken.failedCount, 1);
  });

  test('rejects foreign JSON below runs/', () {
    File(p.join(root.path, 'runs', 'other.json')).writeAsStringSync('{"a":1}');

    expect(
      () => scanGallerySources([root]),
      throwsA(isA<GallerySourceException>()),
    );
  });

  test('rejects a newer schema version', () {
    writeManifest(
      root,
      suite: 'auth',
      scenario: 'future',
      schemaVersion: 2,
      results: const [],
    );

    expect(
      () => scanGallerySources([root]),
      throwsA(isA<GallerySourceException>()),
    );
  });

  test('rejects an input without images', () {
    final empty = Directory.systemTemp.createTempSync('co_golden_empty_');
    addTearDown(() => empty.deleteSync(recursive: true));

    expect(
      () => scanGallerySources([empty]),
      throwsA(isA<GallerySourceException>()),
    );
  });

  test('rejects two inputs that provide the same image', () {
    final other = sampleSource();
    addTearDown(() => other.deleteSync(recursive: true));

    expect(
      () => scanGallerySources([root, other]),
      throwsA(isA<GallerySourceException>()),
    );
  });
}
