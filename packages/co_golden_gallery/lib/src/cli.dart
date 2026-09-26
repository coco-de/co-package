import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

import 'html.dart';
import 'model.dart';
import 'scanner.dart';

/// Exit code for invalid arguments.
const int galleryUsageError = 64;

/// Exit code for unusable input data (bad manifests, missing images).
const int galleryDataError = 65;

ArgParser _parser() => ArgParser()
  ..addMultiOption(
    'input',
    abbr: 'i',
    valueHelp: 'dir',
    help: 'Source root with runs/ manifests and an images/ tree. Repeatable.',
  )
  ..addOption(
    'output',
    abbr: 'o',
    valueHelp: 'dir',
    defaultsTo: 'build/golden-gallery',
    help: 'Directory that receives index.html.',
  )
  ..addOption('title', defaultsTo: 'Golden Gallery', help: 'Page title.')
  ..addOption(
    'plain-title',
    valueHelp: 'text',
    defaultsTo: '축 없는 이미지',
    help:
        'Heading of the section with images that have no device, theme, or '
        'locale, such as regression baselines.',
  )
  ..addOption(
    'asset-base-url',
    valueHelp: 'url',
    help:
        'Serve images from this http(s) URL plus their gallery path instead '
        'of from local files, for example a bucket prefix.',
  )
  ..addFlag(
    'copy-images',
    negatable: false,
    help: 'Copy the images next to index.html (self-contained output).',
  )
  ..addFlag(
    'noindex',
    negatable: false,
    help: 'Ask search engines not to index the page.',
  )
  ..addOption(
    'brand-color',
    valueHelp: '#RRGGBB',
    defaultsTo: '#0062D1',
    help: 'Accent color.',
  )
  ..addMultiOption(
    'meta',
    valueHelp: 'label=value',
    help: 'Header entry such as commit=abc1234. Repeatable.',
  )
  ..addMultiOption(
    'link',
    valueHelp: 'label=url',
    help: 'Header link. Repeatable.',
  )
  ..addOption(
    'summary',
    valueHelp: 'file',
    help: 'Write a JSON summary (counts and failed images) to this file.',
  )
  ..addFlag(
    'allow-missing',
    negatable: false,
    help: 'Build even when a manifest names an image that does not exist.',
  )
  ..addFlag('help', abbr: 'h', negatable: false, help: 'Show this help.');

/// Runs the `co_golden_gallery` command line and returns the exit code.
///
/// Only the `build` command exists:
/// `co_golden_gallery build --input build/co_golden --output site`.
Future<int> runGalleryCli(
  List<String> arguments, {
  StringSink? stdoutSink,
  StringSink? stderrSink,
}) async {
  final out = stdoutSink ?? stdout;
  final err = stderrSink ?? stderr;
  final parser = _parser();
  final ArgResults args;
  try {
    args = parser.parse(arguments);
  } on FormatException catch (error) {
    err.writeln('${error.message}\n\n${_usage(parser)}');
    return galleryUsageError;
  }
  if (args.flag('help')) {
    out.writeln(_usage(parser));
    return 0;
  }
  if (args.rest.length != 1 || args.rest.single != 'build') {
    err.writeln('Expected the "build" command.\n\n${_usage(parser)}');
    return galleryUsageError;
  }

  final inputs = args.multiOption('input');
  final baseUrl = args.option('asset-base-url');
  final copyImages = args.flag('copy-images');
  final brandColor = args.option('brand-color')!;
  final List<(String, String)> metadata;
  final List<(String, String)> links;
  try {
    if (inputs.isEmpty) {
      throw const FormatException('Pass at least one --input directory.');
    }
    if (baseUrl != null && copyImages) {
      throw const FormatException(
        'Use either --asset-base-url or --copy-images, not both.',
      );
    }
    if (baseUrl != null && !_isHttpUrl(baseUrl)) {
      throw FormatException(
        '--asset-base-url must be an http(s) URL: $baseUrl',
      );
    }
    if (!isGalleryColor(brandColor)) {
      throw FormatException('--brand-color must be #RRGGBB: $brandColor');
    }
    metadata = _pairs(args.multiOption('meta'), 'meta');
    links = _pairs(args.multiOption('link'), 'link');
    for (final (label, url) in links) {
      if (!_isHttpUrl(url)) {
        throw FormatException('--link $label must point to an http(s) URL.');
      }
    }
  } on FormatException catch (error) {
    err.writeln(error.message);
    return galleryUsageError;
  }

  final GalleryScan scan;
  try {
    scan = scanGallerySources([for (final input in inputs) Directory(input)]);
  } on GallerySourceException catch (error) {
    err.writeln(error.message);
    return galleryDataError;
  }
  if (scan.missingImages.isNotEmpty && !args.flag('allow-missing')) {
    err.writeln(
      '${scan.missingImages.length} image(s) named by a manifest are '
      'missing:\n${scan.missingImages.map((path) => '  $path').join('\n')}',
    );
    return galleryDataError;
  }

  final output = Directory(args.option('output')!);
  output.createSync(recursive: true);
  final base = baseUrl == null
      ? null
      : (baseUrl.endsWith('/') ? baseUrl : '$baseUrl/');
  String imageUrl(GalleryImage image) {
    final encoded = image.path.split('/').map(Uri.encodeComponent).join('/');
    if (base != null) {
      return '$base$encoded';
    }
    if (copyImages) {
      return encoded;
    }
    final source = scan.files[image.path];
    if (source == null) {
      return encoded;
    }
    return p.posix
        .joinAll(p.split(p.relative(source, from: output.path)))
        .split('/')
        .map(Uri.encodeComponent)
        .join('/');
  }

  final html = renderGalleryHtml(
    scan.catalog,
    GalleryPageOptions(
      title: args.option('title')!,
      brandColor: brandColor,
      noindex: args.flag('noindex'),
      metadata: metadata,
      links: links,
      plainTitle: args.option('plain-title')!,
    ),
    imageUrl: imageUrl,
  );
  File(p.join(output.path, 'index.html')).writeAsStringSync(html);

  if (copyImages) {
    for (final MapEntry(key: path, value: source) in scan.files.entries) {
      final target = File(p.join(output.path, p.joinAll(path.split('/'))));
      target.parent.createSync(recursive: true);
      File(source).copySync(target.path);
    }
  }

  final summaryPath = args.option('summary');
  if (summaryPath != null) {
    final summary = File(summaryPath);
    summary.parent.createSync(recursive: true);
    summary.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(_summary(scan)),
    );
  }

  final catalog = scan.catalog;
  out.writeln(
    'co_golden_gallery: ${catalog.scenarios.length} scenarios, '
    '${catalog.imageCount} images, ${catalog.failedCount} failed → '
    '${p.join(output.path, 'index.html')}',
  );
  return 0;
}

Map<String, Object?> _summary(GalleryScan scan) {
  final catalog = scan.catalog;
  return {
    'scenarios': catalog.scenarios.length,
    'images': catalog.imageCount,
    'failed': catalog.failedCount,
    'missingImages': scan.missingImages,
    'failedImages': [
      for (final scenario in catalog.scenarios)
        for (final image in scenario.images)
          if (image.status == GalleryStatus.failed)
            {
              'suite': scenario.suite,
              'scenario': scenario.name,
              'variant': image.label,
              'overflowCount': image.overflowCount,
              'errors': image.errors,
            },
    ],
  };
}

List<(String, String)> _pairs(List<String> values, String option) => [
  for (final value in values)
    switch (value.indexOf('=')) {
      <= 0 => throw FormatException('--$option expects label=value: $value'),
      final at => (value.substring(0, at), value.substring(at + 1)),
    },
];

bool _isHttpUrl(String value) {
  final uri = Uri.tryParse(value);
  return uri != null &&
      (uri.scheme == 'https' || uri.scheme == 'http') &&
      uri.host.isNotEmpty;
}

String _usage(ArgParser parser) =>
    'Usage: co_golden_gallery build --input <dir> [options]\n\n'
    '${parser.usage}';
