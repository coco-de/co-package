import 'dart:convert';
import 'dart:io';

import 'package:co_golden_gallery/co_golden_gallery.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'fixture.dart';

void main() {
  late Directory root;
  late Directory output;
  late Map<String, Object?> comparison;

  void write() {
    writeManifest(
      root,
      suite: 'auth',
      scenario: 'login',
      results: [
        {
          ...result(
            stem: 'phone__light__ko',
            theme: 'light',
            locale: 'ko',
            image: 'images/auth/login/phone__light__ko.png',
          ),
          'designComparison': comparison,
        },
      ],
    );
  }

  setUp(() {
    root = sampleSource();
    output = Directory.systemTemp.createTempSync('co_golden_design_site_');
    writePng(p.join(root.path, 'references/auth/login/phone__light__ko.png'));
    writePng(p.join(root.path, 'differences/auth/login/phone__light__ko.png'));
    comparison = {
      'reference': 'references/auth/login/phone__light__ko.png',
      'label': 'Figma </script>',
      'sourceUrl': 'https://www.figma.com/design/example?node-id=1-8',
      'status': 'different',
      'referenceWidth': 4,
      'referenceHeight': 8,
      'renderWidth': 4,
      'renderHeight': 8,
      'diff': 'differences/auth/login/phone__light__ko.png',
      'differentPixels': 1,
      'totalPixels': 32,
      'differenceRatio': 1 / 32,
    };
  });
  tearDown(() {
    root.deleteSync(recursive: true);
    output.deleteSync(recursive: true);
  });

  test(
    'associates auxiliary assets without adding image or scenario counts',
    () {
      write();
      final scan = scanGallerySources([root]);
      final image = scan.catalog.scenarios.first.images.first;
      expect(image.designComparison!.summary, '디자인 차이 3.125%');
      expect(image.status, GalleryStatus.passed);
      expect(
        scan.catalog.imageCount,
        3,
      ); // Includes the now-unclaimed dark PNG.
      expect(scan.catalog.scenarios.length, 2);
      expect(
        scan.files.keys,
        containsAll([comparison['reference'], comparison['diff']]),
      );
    },
  );

  test(
    'copies comparison artifacts and resolves every URL in all serving modes',
    () async {
      write();
      for (final mode in ['copy', 'cdn', 'relative']) {
        final code = await runGalleryCli(
          [
            'build',
            '-i',
            root.path,
            '-o',
            output.path,
            if (mode == 'copy') '--copy-images',
            if (mode == 'cdn') ...[
              '--asset-base-url',
              'https://cdn.example/run',
            ],
          ],
          stdoutSink: StringBuffer(),
          stderrSink: StringBuffer(),
        );
        expect(code, 0);
        final html = File(p.join(output.path, 'index.html')).readAsStringSync();
        final match = RegExp(
          r'id="gallery-data">(.*?)</script>',
          dotAll: true,
        ).firstMatch(html)!;
        expect(match.group(1), isNot(contains('</script>')));
        final data = jsonDecode(match.group(1)!) as List;
        final design = (data.first as Map)['design'] as Map;
        final prefix = mode == 'cdn' ? 'https://cdn.example/run/' : '';
        for (final key in ['reference', 'diff']) {
          if (mode == 'relative') {
            expect(design[key], startsWith('../'));
          } else {
            expect(design[key], '$prefix${comparison[key]}');
          }
          if (mode == 'copy') {
            expect(
              File(
                p.join(output.path, comparison[key]! as String),
              ).readAsBytesSync(),
              File(
                p.join(root.path, comparison[key]! as String),
              ).readAsBytesSync(),
            );
          }
        }
        expect(html, contains('aria-label="디자인 비교 모드"'));
        expect(html, contains('aria-label="구현 화면 투명도"'));
      }
    },
  );

  test('keeps size mismatch explicit without inventing a pixel score', () {
    comparison.addAll({
      'status': 'sizeMismatch',
      'referenceWidth': 8,
      'diff': null,
      'differentPixels': null,
      'totalPixels': null,
      'differenceRatio': null,
    });
    write();
    final design = scanGallerySources([
      root,
    ]).catalog.scenarios.first.images.first.designComparison!;
    expect(design.sameSize, isFalse);
    expect(design.summary, '디자인 크기 다름');
    expect(design.differenceRatio, isNull);
  });

  test('does not round a nonzero design difference into an apparent match', () {
    const design = GalleryDesignComparison(
      reference: 'references/large.png',
      label: 'Figma',
      status: 'different',
      referenceWidth: 4000,
      referenceHeight: 4000,
      renderWidth: 4000,
      renderHeight: 4000,
      differentPixels: 1,
      totalPixels: 16000000,
      differenceRatio: 1 / 16000000,
    );
    expect(design.summary, '디자인 차이 <0.001%');
  });

  test(
    'missing reference fails CLI unless allow-missing is explicit',
    () async {
      write();
      File(p.join(root.path, comparison['reference']! as String)).deleteSync();
      final args = ['build', '-i', root.path, '-o', output.path];
      final errors = StringBuffer();
      expect(
        await runGalleryCli(
          args,
          stdoutSink: StringBuffer(),
          stderrSink: errors,
        ),
        65,
      );
      expect(errors.toString(), contains(comparison['reference']));
      expect(
        await runGalleryCli(
          [...args, '--allow-missing'],
          stdoutSink: StringBuffer(),
          stderrSink: StringBuffer(),
        ),
        0,
      );
    },
  );

  for (final invalid in <Map<String, Object?>>[
    {'reference': '../outside.png'},
    {'reference': '/tmp/outside.png'},
    {'reference': r'references\outside.png'},
    {'reference': 'references/../outside.png'},
    {'diff': 'index.html'},
    {'sourceUrl': 'javascript:alert(1)'},
    {'status': 'matched'},
    {'differenceRatio': 0.5},
    {'status': 'sizeMismatch'},
    {'referenceWidth': 0},
  ]) {
    test('rejects invalid design metadata $invalid', () {
      comparison.addAll(invalid);
      write();
      expect(
        () => scanGallerySources([root]),
        throwsA(isA<GallerySourceException>()),
      );
    });
  }

  test('rejects a reference symlink escaping the input root', () {
    final file = File(p.join(root.path, comparison['reference']! as String));
    file.deleteSync();
    final outside = p.join(output.path, 'outside.png');
    writePng(outside);
    Link(file.path).createSync(outside);
    write();
    expect(
      () => scanGallerySources([root]),
      throwsA(isA<GallerySourceException>()),
    );
  });
}
