import 'dart:convert';
import 'dart:io';

import 'package:co_golden_gallery/co_golden_gallery.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'fixture.dart';

void main() {
  late Directory root;
  late Directory output;

  setUp(() {
    root = sampleSource();
    output = Directory.systemTemp.createTempSync('co_golden_site_');
  });
  tearDown(() {
    root.deleteSync(recursive: true);
    output.deleteSync(recursive: true);
  });

  Future<(int, String, String)> run(List<String> arguments) async {
    final out = StringBuffer();
    final err = StringBuffer();
    final code = await runGalleryCli(
      arguments,
      stdoutSink: out,
      stderrSink: err,
    );
    return (code, out.toString(), err.toString());
  }

  test('builds a self-contained gallery with --copy-images', () async {
    final summary = p.join(output.path, 'summary.json');
    final (code, out, _) = await run([
      'build',
      '--input',
      root.path,
      '--output',
      output.path,
      '--copy-images',
      '--noindex',
      '--summary',
      summary,
      '--meta',
      'commit=abc1234',
      '--link',
      'GitHub=https://github.com/coco-de',
    ]);

    expect(code, 0);
    expect(out, contains('2 scenarios, 3 images, 1 failed'));
    final html = File(p.join(output.path, 'index.html')).readAsStringSync();
    expect(html, contains('src="images/auth/login/phone__light__ko.png"'));
    expect(html, contains('noindex'));
    expect(
      File(
        p.join(output.path, 'images', 'regression', 'auth', 'login_page.png'),
      ).existsSync(),
      isTrue,
    );
    final json = jsonDecode(File(summary).readAsStringSync()) as Map;
    expect(json['images'], 3);
    expect(json['failed'], 1);
    expect(
      (json['failedImages'] as List).single,
      containsPair('scenario', 'login'),
    );
  });

  test('serves images from --asset-base-url with encoded paths', () async {
    writePng(p.join(root.path, 'images', 'misc', 'odd', 'a b[1].png'));

    final (code, _, _) = await run([
      'build',
      '-i',
      root.path,
      '-o',
      output.path,
      '--asset-base-url',
      'https://bucket.example/runs/abc',
    ]);

    expect(code, 0);
    final html = File(p.join(output.path, 'index.html')).readAsStringSync();
    expect(
      html,
      contains(
        'src="https://bucket.example/runs/abc/images/misc/odd/a%20b%5B1%5D.png"',
      ),
    );
    expect(Directory(p.join(output.path, 'images')).existsSync(), isFalse);
  });

  test('refers to local files relatively by default', () async {
    final (code, _, _) = await run([
      'build',
      '-i',
      root.path,
      '-o',
      output.path,
    ]);

    expect(code, 0);
    final html = File(p.join(output.path, 'index.html')).readAsStringSync();
    expect(html, contains('/images/auth/login/phone__light__ko.png"'));
    expect(html, contains('src="../'));
  });

  test('fails when a manifest names a missing image', () async {
    File(
      p.join(root.path, 'images', 'auth', 'login', 'phone__dark__ko.png'),
    ).deleteSync();

    final (code, _, err) = await run([
      'build',
      '-i',
      root.path,
      '-o',
      output.path,
    ]);
    expect(code, galleryDataError);
    expect(err, contains('images/auth/login/phone__dark__ko.png'));

    final (allowed, _, _) = await run([
      'build',
      '-i',
      root.path,
      '-o',
      output.path,
      '--allow-missing',
    ]);
    expect(allowed, 0);
  });

  test('rejects invalid arguments', () async {
    expect((await run(['-i', root.path])).$1, galleryUsageError);
    expect((await run(['build'])).$1, galleryUsageError);
    expect(
      (await run([
        'build',
        '-i',
        root.path,
        '--copy-images',
        '--asset-base-url',
        'https://x.example',
      ])).$1,
      galleryUsageError,
    );
    expect(
      (await run(['build', '-i', root.path, '--brand-color', 'blue'])).$1,
      galleryUsageError,
    );
    expect(
      (await run([
        'build',
        '-i',
        root.path,
        '--link',
        'x=javascript:alert(1)',
      ])).$1,
      galleryUsageError,
    );
  });

  test('fails on an input directory that does not exist', () async {
    final (code, _, _) = await run([
      'build',
      '-i',
      p.join(root.path, 'nope'),
      '-o',
      output.path,
    ]);

    expect(code, galleryDataError);
  });
}
